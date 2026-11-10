# deploy.ps1
# Run this in Atera as "Current User"

$ReleaseUrl = "https://github.com/emmanuelortiz-MTR/MTR-IT-Help.hotkey.emailprompt/releases/download/v1.0.0/MTR_IT_Help_Hotkey_EmailPrompt.exe"
$InstallPath = "$env:LOCALAPPDATA\MTR_IT_Help"
$ExeName = "MTR_IT_Help_Hotkey_EmailPrompt.exe"
$ProcessName = "MTR_IT_Help_Hotkey_EmailPrompt"

# 1. Create folder
New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
$ExePath = Join-Path $InstallPath $ExeName

# 2. Download
Write-Host "Downloading $ExeName from GitHub..." -ForegroundColor Yellow
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $ExePath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Download successful!" -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    exit 1
}

# 3. Stop any currently running instances
Write-Host "Stopping existing instances..." -ForegroundColor Yellow
Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 4. Add to startup registry (So it runs next time they log in)
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $RegPath -Name "MTR_IT_Help_Hotkey_EmailPrompt" -Value $ExePath -Force
Write-Host "✅ Added to startup registry" -ForegroundColor Green

# 5. Start the app visibly on the desktop using Task Scheduler
Write-Host "Starting application on the user's desktop..." -ForegroundColor Yellow
try {
    $TaskName = "Start_MTR_IT_Help_EmailPrompt_Now"
    $Action = New-ScheduledTaskAction -Execute $ExePath
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    # Create the task, run it, and immediately delete it so it doesn't clutter the PC
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 3
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    Write-Host "✅ Application launched!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not launch via Task Scheduler: $_" -ForegroundColor Yellow
}

Write-Host "✅ Deployment complete!" -ForegroundColor Green
