# ACE Desk Energia - roda quando o Windows acorda o PC no horario de ligar.
# Segura o PC acordado por 10 minutos (o Windows voltaria a dormir em ~2 min
# quando acorda sozinho sem ninguem mexer) e liga a tela.
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class AceAcordar { [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f); }
"@
$log = Join-Path $env:ProgramData 'ACEDesk-Energia\log.txt'
try { Add-Content $log ("{0} acordou pelo horario de ligar" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) } catch {}
# ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
[void][AceAcordar]::SetThreadExecutionState([uint32]2147483651)
Start-Sleep -Seconds 600
[void][AceAcordar]::SetThreadExecutionState([uint32]2147483648)
