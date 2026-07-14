# SysMain (旧Superfetch) を有効化して起動するスクリプト
# Disable-Sysmain.ps1 で無効化した設定を元(自動起動)に戻します。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Enable-Sysmain.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$svc = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Warning "SysMain サービスが見つかりませんでした。"
    exit 1
}

Write-Host "SysMain のスタートアップを「自動」に設定しています..." -ForegroundColor Cyan
Set-Service -Name "SysMain" -StartupType Automatic

if ($svc.Status -ne "Running") {
    Write-Host "SysMain を起動しています..." -ForegroundColor Cyan
    Start-Service -Name "SysMain"
}

# --- 最終確認 ---
$svc = Get-Service -Name "SysMain"
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
Write-Host "SysMain: 状態=$($svc.Status) / スタートアップ=$($svc.StartType)"

if ($svc.Status -eq "Running" -and $svc.StartType -eq "Automatic") {
    Write-Host "`nSysMain の有効化が完了しました。" -ForegroundColor Green
} else {
    Write-Warning "有効化が完了していません。管理者権限で再実行してください。"
}
