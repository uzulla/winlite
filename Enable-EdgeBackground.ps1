# Edge のバックグラウンド常駐設定を元に戻すスクリプト (Disable-EdgeBackground.ps1 の逆操作)
# 以下の3つを元に戻します:
#   1. Edge「スタートアップ ブースト」のポリシーを削除
#   2. Edge「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を
#      続行する」のポリシーを削除
#   3. Windows「再起動可能なアプリを自動的に保存し、サインインし直したときに再起動する」をオン
#
# 1. 2. はポリシー値の削除なので、Edge設定画面のグレーアウトが解除されて
#    手動で切り替えられる状態に戻ります(Edgeのデフォルトではどちらも有効)。
#
# 要管理者権限(1. 2. がHKLMへの書き込みのため)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Enable-EdgeBackground.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 1. 2. Edge のポリシーを削除(手動で切り替えられる状態に戻す) ---
Write-Host "Edge のスタートアップブースト/バックグラウンド実行のポリシーを削除しています..." -ForegroundColor Cyan
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Remove-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue

# --- 3. 再起動可能なアプリの自動保存・再開をオン(現在のユーザー) ---
Write-Host "再起動可能なアプリの自動再開を有効化しています..." -ForegroundColor Cyan
$winlogonPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if (-not (Test-Path $winlogonPath)) { New-Item -Path $winlogonPath -Force | Out-Null }
New-ItemProperty -Path $winlogonPath -Name "RestartApps" -Value 1 -PropertyType DWord -Force | Out-Null

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
$boost = (Get-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -ErrorAction SilentlyContinue).StartupBoostEnabled
$bgMode = (Get-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue).BackgroundModeEnabled
Write-Host "StartupBoostEnabled: $(if ($null -eq $boost) { '未設定 (Edgeの設定画面から変更可能)' } else { $boost })"
Write-Host "BackgroundModeEnabled: $(if ($null -eq $bgMode) { '未設定 (Edgeの設定画面から変更可能)' } else { $bgMode })"
Write-Host "RestartApps: $((Get-ItemProperty -Path $winlogonPath -Name 'RestartApps' -ErrorAction SilentlyContinue).RestartApps) (1=自動再開オン)"

Write-Host "`n完了しました。Edge を再起動すると反映されます。" -ForegroundColor Green
