# SysMain (旧Superfetch) を停止して無効化するスクリプト
# SysMain はよく使うアプリを先読みしてメモリにキャッシュするサービス。
# HDD環境では効果があるが、SSD環境ではディスク/CPU負荷の原因になることがあるため
# 無効化の候補になる。無効化するとアプリの初回起動がやや遅くなる場合があります。
#
# 元に戻すには Enable-Sysmain.ps1 を実行してください。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-Sysmain.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$svc = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Warning "SysMain サービスが見つかりませんでした。"
    exit 1
}

if ($svc.Status -eq "Running") {
    Write-Host "SysMain を停止しています..." -ForegroundColor Cyan
    Stop-Service -Name "SysMain" -Force
}

Write-Host "SysMain を無効化しています..." -ForegroundColor Cyan
Set-Service -Name "SysMain" -StartupType Disabled

# --- 最終確認 ---
$svc = Get-Service -Name "SysMain"
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
Write-Host "SysMain: 状態=$($svc.Status) / スタートアップ=$($svc.StartType)"

if ($svc.Status -eq "Stopped" -and $svc.StartType -eq "Disabled") {
    Write-Host "`nSysMain の無効化が完了しました。" -ForegroundColor Green
} else {
    Write-Warning "無効化が完了していません。管理者権限で再実行してください。"
}
