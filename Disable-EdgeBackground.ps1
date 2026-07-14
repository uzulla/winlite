# Edge のバックグラウンド常駐を止めるスクリプト
# 以下の2つを設定します:
#   1. Edge「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を
#      続行する」をオフ (edge://settings/system/manageSystem の設定に相当)
#   2. Windows「再起動可能なアプリを自動的に保存し、サインインし直したときに再起動する」
#      をオフ (設定 > アカウント > サインイン オプション)
#
# ※スタートアップブーストはこのスクリプトでは変更しません。
#
# 1. はポリシー(HKLM)として設定するため全ユーザーに適用され、Edgeの設定画面では
#    「組織によって管理されています」と表示されてトグルがグレーアウトします。
#    元に戻すには HKLM:\SOFTWARE\Policies\Microsoft\Edge の BackgroundModeEnabled を削除してください。
#
# 要管理者権限(1. がHKLMへの書き込みのため)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-EdgeBackground.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 1. Edge のバックグラウンドモードをオフ(ポリシー・全ユーザー) ---
Write-Host "Edge のバックグラウンド実行を無効化しています..." -ForegroundColor Cyan
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePolicyPath)) { New-Item -Path $edgePolicyPath -Force | Out-Null }
New-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

# --- 2. 再起動可能なアプリの自動保存・再開をオフ(現在のユーザー) ---
Write-Host "再起動可能なアプリの自動再開を無効化しています..." -ForegroundColor Cyan
$winlogonPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if (-not (Test-Path $winlogonPath)) { New-Item -Path $winlogonPath -Force | Out-Null }
New-ItemProperty -Path $winlogonPath -Name "RestartApps" -Value 0 -PropertyType DWord -Force | Out-Null

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "BackgroundModeEnabled: $((Get-ItemProperty -Path $edgePolicyPath -Name 'BackgroundModeEnabled' -ErrorAction SilentlyContinue).BackgroundModeEnabled) (0=バックグラウンド実行オフ)"
Write-Host "RestartApps: $((Get-ItemProperty -Path $winlogonPath -Name 'RestartApps' -ErrorAction SilentlyContinue).RestartApps) (0=自動再開オフ)"

Write-Host "`n完了しました。" -ForegroundColor Green
Write-Host "既に常駐している Edge プロセスには次回 Edge を完全終了したときから適用されます。" -ForegroundColor Yellow
Write-Host "今すぐ消したい場合は Edge を閉じてから: Stop-Process -Name msedge -Force" -ForegroundColor Yellow
