' ACE Desk Energia - inicia o ajudante sem abrir janela
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & CreateObject("WScript.Shell").ExpandEnvironmentStrings("%ProgramData%") & "\ACEDesk-Energia\ace-energia.ps1""", 0, False
