# ACE Desk Energia - instalador (roda como administrador, chamado pelo .bat)
param([string]$Url, [string]$Id, [string]$Token, [string]$User, [string]$Report)

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Dir = Join-Path $env:ProgramData 'ACEDesk-Energia'
function R([string]$m) { Add-Content -Path $Report -Value $m; Write-Host $m }

R "===== ACE Desk Energia - instalacao $(Get-Date) ====="
R "Usuario: $User  PC: $Id"
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

foreach ($f in @('ace-energia.ps1', 'acordar.ps1', 'iniciar.vbs')) {
  try {
    Invoke-WebRequest -Uri "$Url/ace-energia/$f" -OutFile (Join-Path $Dir $f) -UseBasicParsing -TimeoutSec 60
    R "baixado: $f"
  } catch { R "ERRO ao baixar $f : $_" }
}
@{ url = $Url; id = $Id; token = $Token } | ConvertTo-Json | Set-Content (Join-Path $Dir 'config.json')
# Usuarios comuns podem gravar log/estado na pasta
& icacls $Dir /grant '*S-1-5-32-545:(OI)(CI)M' | Out-Null

R '--- Energia do Windows ---'
& powercfg /hibernate on 2>&1 | ForEach-Object { R $_ }
& powercfg /h /type full 2>&1 | ForEach-Object { R $_ }
# Permitir "timers de ativacao" (o horario de ligar)
& powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP RTCWAKE 1 2>&1 | ForEach-Object { R $_ }
# Quando acorda sozinho, nao voltar a dormir em 2 min
& powercfg -attributes SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 -ATTRIB_HIDE 2>&1 | Out-Null
& powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0 2>&1 | ForEach-Object { R $_ }
& powercfg /SETACTIVE SCHEME_CURRENT 2>&1 | ForEach-Object { R $_ }
$hib = (& powercfg /a) -join "`n"
if ($hib -match 'Hiberna') { R 'hibernacao: disponivel' } else { R "ATENCAO hibernacao: $hib" }

R '--- Tarefa do ajudante ---'
try {
  $name = 'ACE Desk Energia'
  Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
  $a = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ("`"" + (Join-Path $Dir 'iniciar.vbs') + "`"")
  $t1 = New-ScheduledTaskTrigger -AtLogOn -User $User
  $t2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
  $p = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Limited
  $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -MultipleInstances IgnoreNew
  Register-ScheduledTask -TaskName $name -Action $a -Trigger @($t1, $t2) -Principal $p -Settings $s -Force | Out-Null
  Start-ScheduledTask -TaskName $name
  R 'tarefa criada e iniciada'
} catch { R "ERRO tarefa: $_" }

Start-Sleep -Seconds 8
$log = Join-Path $Dir 'log.txt'
if (Test-Path $log) { R '--- log do ajudante ---'; Get-Content $log -Tail 10 | ForEach-Object { R $_ } }
R 'FIM'
