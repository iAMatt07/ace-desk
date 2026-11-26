# ACE Desk Energia - ajudante de hibernacao (roda escondido na sessao do usuario)
# Le as regras em <servidor>/api/ace/power/<id> a cada minuto e:
#  - hiberna depois de X minutos sem mouse/teclado (e sem render rodando)
#  - hiberna no horario marcado (dias escolhidos), esperando render terminar
#  - deixa uma tarefa do Windows marcada para acordar o PC no horario de ligar
# Antes de hibernar mostra um aviso de 60 s com o botao Cancelar.

$ErrorActionPreference = 'Continue'
$Dir = Join-Path $env:ProgramData 'ACEDesk-Energia'
$LogFile = Join-Path $Dir 'log.txt'
$StateFile = Join-Path $Dir ("estado-" + $env:USERNAME + ".json")
$CacheFile = Join-Path $Dir 'regras.json'

function Log([string]$m) {
  try {
    if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt 300KB) {
      Get-Content $LogFile -Tail 400 | Set-Content ($LogFile + '.tmp'); Move-Item ($LogFile + '.tmp') $LogFile -Force
    }
    Add-Content -Path $LogFile -Value ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m)
  } catch {}
}

# So uma copia rodando por usuario
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ACEDeskEnergia', [ref]$created)
if (-not $created) { exit 0 }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Cfg = Get-Content (Join-Path $Dir 'config.json') -Raw | ConvertFrom-Json

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class AceEnergia {
  [StructLayout(LayoutKind.Sequential)] struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
  [DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO p);
  [DllImport("kernel32.dll")] static extern ulong GetTickCount64();
  public static double IdleSeconds() {
    LASTINPUTINFO l = new LASTINPUTINFO(); l.cbSize = (uint)Marshal.SizeOf(l);
    if (!GetLastInputInfo(ref l)) return 0;
    uint now = (uint)Environment.TickCount;
    return (double)(uint)(now - l.dwTime) / 1000.0;
  }
}
"@

function Load-State {
  try { if (Test-Path $StateFile) { return Get-Content $StateFile -Raw | ConvertFrom-Json } } catch {}
  return [pscustomobject]@{ lastScheduledDate = '' }
}
function Save-State($s) { try { $s | ConvertTo-Json | Set-Content $StateFile } catch {} }

function Get-Rules {
  $url = "{0}/api/ace/power/{1}?t={2}" -f $Cfg.url, $Cfg.id, $Cfg.token
  try {
    $r = Invoke-RestMethod -Uri $url -TimeoutSec 20 -UseBasicParsing
    try { $r | ConvertTo-Json | Set-Content $CacheFile } catch {}
    return $r
  } catch {
    if (Test-Path $CacheFile) { try { return Get-Content $CacheFile -Raw | ConvertFrom-Json } catch {} }
    return $null
  }
}

# Carga do PC (CPU e placa de video). Render/exportacao = ocupado.
function Get-Load {
  $cpu = 0; $gpu = 0
  try { $cpu = [double](Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average } catch {}
  try {
    $eng = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -ErrorAction Stop
    $by = @{}
    foreach ($e in $eng) {
      if ($e.Name -match 'engtype_([A-Za-z0-9]+)') {
        $t = $Matches[1]; if (-not $by.ContainsKey($t)) { $by[$t] = 0 }
        $by[$t] += [double]$e.UtilizationPercentage
      }
    }
    foreach ($t in @('3D', 'Compute', 'Compute_0', 'Compute_1', 'Cuda', 'VideoEncode', 'VideoDecode', 'Copy')) {
      if ($by.ContainsKey($t) -and $by[$t] -gt $gpu) { $gpu = $by[$t] }
    }
  } catch {}
  return [pscustomobject]@{ cpu = [math]::Round($cpu); gpu = [math]::Round([math]::Min($gpu, 100)) }
}

$BusyHistory = New-Object System.Collections.Generic.List[bool]
function Is-Busy {
  $l = Get-Load
  $now = ($l.cpu -ge 25) -or ($l.gpu -ge 25)
  $BusyHistory.Add($now); while ($BusyHistory.Count -gt 3) { $BusyHistory.RemoveAt(0) }
  $script:LastLoad = $l
  return ($BusyHistory -contains $true)
}

# Aviso de 60 s. Devolve $true se pode hibernar, $false se alguem cancelou.
function Show-Warning([string]$why) {
  Add-Type -AssemblyName System.Windows.Forms, System.Drawing
  $script:cancelled = $false
  $script:left = 60
  $f = New-Object System.Windows.Forms.Form
  $f.Text = 'ACE Desk'; $f.TopMost = $true; $f.StartPosition = 'CenterScreen'
  $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
  $f.ClientSize = New-Object System.Drawing.Size(480, 190)
  $f.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 30); $f.ForeColor = [System.Drawing.Color]::White
  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Font = New-Object System.Drawing.Font('Segoe UI', 12)
  $lbl.SetBounds(20, 18, 440, 100)
  $btn = New-Object System.Windows.Forms.Button
  $btn.Text = 'Cancelar'; $btn.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
  $btn.SetBounds(160, 128, 160, 44)
  $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 61, 20); $btn.FlatStyle = 'Flat'
  $btn.Add_Click({ $script:cancelled = $true; $f.Close() })
  $upd = { $lbl.Text = "Este PC vai HIBERNAR em $($script:left) segundos`n($why).`nTudo o que esta aberto continua aberto quando ele ligar de novo." }
  & $upd
  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 1000
  $timer.Add_Tick({ $script:left--; & $upd; if ($script:left -le 0) { $timer.Stop(); $f.Close() } })
  $f.Controls.Add($lbl); $f.Controls.Add($btn)
  $f.Add_Shown({ $f.Activate(); $timer.Start() })
  [void]$f.ShowDialog()
  $timer.Dispose(); $f.Dispose()
  return (-not $script:cancelled)
}

function Do-Hibernate([string]$why) {
  Log "aviso: $why (cpu=$($script:LastLoad.cpu)% gpu=$($script:LastLoad.gpu)%)"
  if (-not (Show-Warning $why)) { Log 'cancelado pelo usuario'; return $false }
  # Ultima conferencia: se comecou um render durante o aviso, nao hiberna
  $l = Get-Load
  if ($l.cpu -ge 40 -or $l.gpu -ge 40) { Log "nao hibernou: PC ocupado (cpu=$($l.cpu)% gpu=$($l.gpu)%)"; return $false }
  Log 'hibernando'
  & shutdown.exe /h
  return $true
}

$script:WakeKey = ''
function Sync-WakeTask($r) {
  $name = 'ACE Desk Energia - Ligar'
  $days = @($r.days | ForEach-Object { [int]$_ })
  $key = "{0}|{1}|{2}" -f $r.enabled, $r.wake_time, ($days -join ',')
  if ($key -eq $script:WakeKey) { return }
  try {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
    if ($r.enabled -and $r.wake_time -and $days.Count -gt 0) {
      $map = @{1 = 'Monday'; 2 = 'Tuesday'; 3 = 'Wednesday'; 4 = 'Thursday'; 5 = 'Friday'; 6 = 'Saturday'; 7 = 'Sunday' }
      $dow = $days | ForEach-Object { $map[$_] }
      $at = [datetime]::ParseExact($r.wake_time, 'HH:mm', $null)
      $t = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $at
      $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"" + (Join-Path $Dir 'acordar.ps1') + "`"")
      $s = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
      Register-ScheduledTask -TaskName $name -Trigger $t -Action $a -Settings $s -Force | Out-Null
      Log "ligar marcado: $($r.wake_time) dias $($days -join ',')"
    } else {
      Log 'ligar automatico desativado'
    }
    $script:WakeKey = $key
  } catch { Log "erro ao marcar horario de ligar: $_" }
}

Log "ajudante iniciado (usuario $env:USERNAME, PC $($Cfg.id))"
$state = Load-State
$lastLoop = Get-Date
$resumeAt = Get-Date

while ($true) {
  $now = Get-Date
  # Voltou da hibernacao/suspensao? (o laco ficou parado mais de 3 min)
  if (($now - $lastLoop).TotalMinutes -gt 3) { $resumeAt = $now; $BusyHistory.Clear(); Log 'PC voltou (hibernacao/suspensao)' }
  $lastLoop = $now

  $r = Get-Rules
  if ($r) {
    Sync-WakeTask $r
    if ($r.enabled) {
      $busy = Is-Busy
      $idleSec = [AceEnergia]::IdleSeconds()
      $sinceResume = ($now - $resumeAt).TotalSeconds
      $idleEff = [math]::Min($idleSec, $sinceResume)
      $today = $now.ToString('yyyy-MM-dd')
      $dow = [int]$now.DayOfWeek; if ($dow -eq 0) { $dow = 7 }
      $days = @($r.days | ForEach-Object { [int]$_ })

      $acted = $false
      # 1) Horario de hibernar (janela de 3 h depois do horario, para esperar render)
      if ($r.sleep_time -and ($days -contains $dow) -and $state.lastScheduledDate -ne $today) {
        $st = [datetime]::ParseExact($r.sleep_time, 'HH:mm', $null)
        $st = $now.Date.AddHours($st.Hour).AddMinutes($st.Minute)
        if ($now -ge $st -and $now -lt $st.AddHours(3)) {
          if ($busy) {
            if (-not $script:loggedWait) { Log 'horario de hibernar: esperando o PC desocupar'; $script:loggedWait = $true }
          } else {
            $state.lastScheduledDate = $today; Save-State $state
            $script:loggedWait = $false
            [void](Do-Hibernate "horario marcado: $($r.sleep_time)")
            $acted = $true
          }
        }
      }
      # 2) Tempo parado
      $idleMin = [int]$r.idle_minutes
      if (-not $acted -and $idleMin -gt 0 -and $idleEff -ge ($idleMin * 60) -and -not $busy) {
        if (-not (Do-Hibernate "parado ha $idleMin min")) { $resumeAt = Get-Date }
      }
    }
  }
  Start-Sleep -Seconds 60
}
