# 配信の最適化(Delivery Optimization)をオフにするスクリプト
# 「設定 > Windows Update > 詳細オプション > 配信の最適化」の
# 「他のデバイスからのダウンロードを許可する」をオフにするのと同等です。
#
# 配信の最適化は、Windows Update やストアアプリの更新を他のPCと
# P2Pで分け合う仕組みです。オフにすると、
#   ・バックグラウンドでの他PCへのアップロード/ダウンロード(通信・CPU・ディスク負荷)が止まる
#   ・更新は Microsoft のサーバーから直接ダウンロードされる
# ようになります。更新の取得自体は引き続き行えます。
#
# ポリシー(HKLM)で設定するため全ユーザー・恒久的に適用され、
# 設定画面では「組織によって管理されています」と表示されます。
# 元に戻すには HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization の
# DODownloadMode を削除してください。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-DeliveryOptimization.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

Write-Host "配信の最適化(P2P共有)を無効化しています..." -ForegroundColor Cyan

# DODownloadMode = 0 : HTTPのみ(他PCとのP2P共有をしない)
$doPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (-not (Test-Path $doPolicyPath)) { New-Item -Path $doPolicyPath -Force | Out-Null }
New-ItemProperty -Path $doPolicyPath -Name "DODownloadMode" -Value 0 -PropertyType DWord -Force | Out-Null

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
$mode = (Get-ItemProperty -Path $doPolicyPath -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode
Write-Host "DODownloadMode: $mode (0=P2P共有オフ / HTTPのみ)"

Write-Host "`n完了しました。" -ForegroundColor Green
