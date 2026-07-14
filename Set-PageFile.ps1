# 仮想メモリ(ページングファイル)をC:ドライブのみ固定サイズ4GBに設定するスクリプト
# 「すべてのドライブのページング ファイルのサイズを自動的に管理する」をオフにし、
# C:のページングファイルを 初期サイズ=最大サイズ=4096MB(4GB) の固定サイズにする。
#
# 要管理者権限。設定変更後は再起動が必要です。
#
# 使い方: powershell -ExecutionPolicy Bypass -File .\Set-PageFile.ps1

$FixedSizeMB = 4096  # 4GB固定

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 1. 自動管理をオフにする ---
Write-Host "ページングファイルの自動管理をオフにしています..." -ForegroundColor Cyan
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
if ($computerSystem.AutomaticManagedPagefile) {
    Set-CimInstance -InputObject $computerSystem -Property @{ AutomaticManagedPagefile = $false }
} else {
    Write-Host "既に自動管理はオフになっています。" -ForegroundColor Yellow
}

# --- 2. C:ドライブのページングファイルを固定サイズ(4GB)に設定する ---
$pageFileName = "$($env:SystemDrive)\pagefile.sys"
Write-Host "C:ドライブのページングファイルを固定サイズ ${FixedSizeMB}MB に設定しています..." -ForegroundColor Cyan

$pageFile = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "Name='$($pageFileName -replace '\\', '\\\\')'"

if ($pageFile) {
    Set-CimInstance -InputObject $pageFile -Property @{
        InitialSize = $FixedSizeMB
        MaximumSize = $FixedSizeMB
    }
} else {
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name        = $pageFileName
        InitialSize = $FixedSizeMB
        MaximumSize = $FixedSizeMB
    } | Out-Null
}

Write-Host "設定が完了しました。" -ForegroundColor Green

# --- 3. 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "自動管理: $($computerSystem.AutomaticManagedPagefile)"

Get-CimInstance -ClassName Win32_PageFileSetting | ForEach-Object {
    Write-Host "$($_.Name): 初期サイズ=$($_.InitialSize)MB / 最大サイズ=$($_.MaximumSize)MB"
}

Write-Host "`n*** 変更を完全に反映するには再起動が必要です。 ***" -ForegroundColor Red
