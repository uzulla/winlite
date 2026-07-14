# PC軽量化スクリプト(まとめて実行版)
# 以下をまとめてオフ/削除します:
#   1. Cortana の完全削除
#   2. OneDrive の停止・アンインストール
#   3. 仮想メモリ(ページングファイル)を C: 固定4GBに設定
#   4. ウィジェット機能の無効化・アプリ削除
#
# 要管理者権限。
# 使い方: powershell -ExecutionPolicy Bypass -File .\Optimize-PC.ps1
#
# 注意: いずれも元に戻すには個別に再インストール・設定変更が必要です。
#       内容を確認の上、必要な項目だけ残して実行することをおすすめします。

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$rebootRequired = $false
$FixedPageFileMB = 4096

function Write-Section($title) {
    Write-Host "`n===== $title =====" -ForegroundColor Cyan
}

# ============================================================
# 1. Cortana の完全削除
# ============================================================
Write-Section "1. Cortana を削除しています"

$cortanaName = "Microsoft.549981C3F5F10"
Get-AppxPackage -AllUsers -Name $cortanaName -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq $cortanaName } |
    ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }

if (Get-AppxPackage -AllUsers -Name $cortanaName -ErrorAction SilentlyContinue) {
    Write-Warning "Cortana がまだ残っています。"
} else {
    Write-Host "Cortana の削除が完了しました。" -ForegroundColor Green
}

# ============================================================
# 2. OneDrive の停止・アンインストール
# ============================================================
Write-Section "2. OneDrive を停止・アンインストールしています"

Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$oneDriveUninstalled = $false
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetCmd) {
    winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements | Out-Null
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        $oneDriveUninstalled = $true
    } elseif ($exitCode -eq 3010) {
        $oneDriveUninstalled = $true
        $rebootRequired = $true
    }
}

if (-not $oneDriveUninstalled) {
    $setupPaths = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDriveSetup.exe"
    )
    $setupExe = $setupPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($setupExe) {
        $proc = Start-Process -FilePath $setupExe -ArgumentList "/uninstall" -Wait -PassThru
        if ($proc.ExitCode -eq 3010) { $rebootRequired = $true }
        $oneDriveUninstalled = $true
    } else {
        Write-Warning "OneDriveSetup.exe が見つかりませんでした(既にアンインストール済みの可能性)。"
    }
}

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue

$leftoverPaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:ProgramData\Microsoft OneDrive",
    "$env:SystemDrive\OneDriveTemp"
)
foreach ($path in $leftoverPaths) {
    if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($oneDriveUninstalled) {
    Write-Host "OneDrive の処理が完了しました。" -ForegroundColor Green
}

# ============================================================
# 3. 仮想メモリ(ページングファイル)を C: 固定4GBに設定
# ============================================================
Write-Section "3. 仮想メモリを C: 固定 ${FixedPageFileMB}MB に設定しています"

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
if ($computerSystem.AutomaticManagedPagefile) {
    Set-CimInstance -InputObject $computerSystem -Property @{ AutomaticManagedPagefile = $false }
}

$pageFileName = "$($env:SystemDrive)\pagefile.sys"
$pageFile = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "Name='$($pageFileName -replace '\\', '\\\\')'"

if ($pageFile) {
    Set-CimInstance -InputObject $pageFile -Property @{
        InitialSize = $FixedPageFileMB
        MaximumSize = $FixedPageFileMB
    }
} else {
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name        = $pageFileName
        InitialSize = $FixedPageFileMB
        MaximumSize = $FixedPageFileMB
    } | Out-Null
}

Write-Host "仮想メモリの設定が完了しました(再起動後に反映)。" -ForegroundColor Green
$rebootRequired = $true

# ============================================================
# 4. ウィジェット機能の無効化・削除
# ============================================================
Write-Section "4. ウィジェットを無効化・削除しています"

$dshPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $dshPath)) { New-Item -Path $dshPath -Force | Out-Null }
New-ItemProperty -Path $dshPath -Name "AllowNewsAndInterests" -Value 0 -PropertyType DWord -Force | Out-Null

$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path $advancedPath -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force | Out-Null

$widgetPackageName = "MicrosoftWindows.Client.WebExperience"
Get-AppxPackage -AllUsers -Name $widgetPackageName -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq $widgetPackageName } |
    ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }

Write-Host "ウィジェットの処理が完了しました。" -ForegroundColor Green

# ============================================================
# 5. エクスプローラー再起動
# ============================================================
Write-Section "5. エクスプローラーを再起動しています"
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# ============================================================
# 最終確認
# ============================================================
Write-Section "最終確認"

$remaining = @()

if (Get-AppxPackage -AllUsers -Name $cortanaName -ErrorAction SilentlyContinue) {
    $remaining += "Cortana がまだ残っています。"
}
if (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue) {
    $remaining += "OneDrive プロセスがまだ動作しています。"
}
foreach ($path in $leftoverPaths) {
    if (Test-Path $path) { $remaining += "OneDriveのフォルダが残っています: $path" }
}
if (Get-AppxPackage -AllUsers -Name $widgetPackageName -ErrorAction SilentlyContinue) {
    $remaining += "ウィジェットアプリがまだ残っています。"
}

$pfCheck = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "Name='$($pageFileName -replace '\\', '\\\\')'"
if (-not $pfCheck -or $pfCheck.MaximumSize -ne $FixedPageFileMB) {
    $remaining += "仮想メモリの設定が反映されていません。"
}

if ($remaining.Count -eq 0) {
    Write-Host "すべての処理が正常に完了しました。" -ForegroundColor Green
} else {
    Write-Warning "以下が残っています:"
    $remaining | ForEach-Object { Write-Warning " - $_" }
    Write-Host "管理者権限でこのスクリプトを再実行するか、PCを再起動してから再実行してください。" -ForegroundColor Yellow
}

if ($rebootRequired) {
    Write-Host "`n*** 変更を完全に反映するには再起動が必要です。 ***" -ForegroundColor Red
}
