# Microsoft Defender の保護を再有効化するスクリプト (Disable-DefenderTemp.ps1 の逆操作)
# 一時的に無効化したリアルタイム保護などの各機能を元に戻します。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Enable-DefenderTemp.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

Write-Host "Microsoft Defender の保護機能を再有効化しています..." -ForegroundColor Cyan

Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableOnAccessProtection $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue

# --- 最終確認 ---
Start-Sleep -Seconds 2
$status = Get-MpComputerStatus -ErrorAction SilentlyContinue
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
if ($status) {
    Write-Host "リアルタイム保護(RealTimeProtectionEnabled): $($status.RealTimeProtectionEnabled) (True=有効)"
    Write-Host "動作監視(BehaviorMonitorEnabled): $($status.BehaviorMonitorEnabled) (True=有効)"
    Write-Host "オンアクセス保護(OnAccessProtectionEnabled): $($status.OnAccessProtectionEnabled) (True=有効)"

    if ($status.RealTimeProtectionEnabled) {
        Write-Host "`nDefender の保護を再有効化しました。" -ForegroundColor Green
    } else {
        Write-Warning "リアルタイム保護がまだ無効です。PCを再起動してから再度確認してください。"
    }
} else {
    Write-Warning "Defender の状態を取得できませんでした。"
}
