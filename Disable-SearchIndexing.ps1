# ファイルのインデックス(Windows Search)をオフにするスクリプト
# ・Windows Search サービスを停止し、スタートアップの種類を「無効」に変更
# ・C:ドライブの「このドライブのファイルにインデックスを付ける」を無効化
#
# 要管理者権限。
# 使い方: powershell -ExecutionPolicy Bypass -File .\Disable-SearchIndexing.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 1. Windows Search サービスを停止・無効化 ---
Write-Host "Windows Search サービスを停止・無効化しています..." -ForegroundColor Cyan
Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
Set-Service -Name "WSearch" -StartupType Disabled

# --- 2. C:ドライブのインデックス設定を無効化 ---
Write-Host "C:ドライブのインデックス設定を無効化しています..." -ForegroundColor Cyan
$volume = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter='C:'"
if ($volume) {
    Set-CimInstance -InputObject $volume -Property @{ IndexingEnabled = $false }
} else {
    Write-Warning "C:ドライブのボリューム情報が取得できませんでした。"
}

Write-Host "設定が完了しました。" -ForegroundColor Green

# --- 3. 最終確認 ---
Start-Sleep -Seconds 2
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan

$service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
Write-Host "WSearch サービス状態: $($service.Status) / スタートアップの種類: $($service.StartType)"

$volumeCheck = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter='C:'"
Write-Host "C:ドライブ IndexingEnabled: $($volumeCheck.IndexingEnabled) (False=無効)"

$remaining = @()
if ($service.Status -ne "Stopped") { $remaining += "WSearch サービスがまだ停止していません。" }
if ($service.StartType -ne "Disabled") { $remaining += "WSearch のスタートアップの種類がまだ無効になっていません。" }
if ($volumeCheck.IndexingEnabled) { $remaining += "C:ドライブのインデックス設定がまだ有効です。" }

if ($remaining.Count -eq 0) {
    Write-Host "`nすべての処理が正常に完了しました。" -ForegroundColor Green
} else {
    Write-Warning "`n以下が残っています:"
    $remaining | ForEach-Object { Write-Warning " - $_" }
    Write-Host "管理者権限で再実行するか、PCを再起動してから再実行してください。" -ForegroundColor Yellow
}
