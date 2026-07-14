# 検索ボックスの「検索のハイライト」(今日のイラスト・ニュース等)を無効化するスクリプト
# 「設定 > プライバシーとセキュリティ > 検索のアクセス許可 > その他の設定 >
#  検索のハイライトを表示する」をオフにするのと同等です。
#
# 管理者権限は不要(現在のユーザーの設定のみ変更します)。
# 使い方: powershell -ExecutionPolicy Bypass -File .\Disable-SearchHighlights.ps1

Write-Host "検索のハイライトを無効化しています..." -ForegroundColor Cyan

$searchPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $searchPolicyPath)) { New-Item -Path $searchPolicyPath -Force | Out-Null }

New-ItemProperty -Path $searchPolicyPath -Name "EnableDynamicContentInWSB" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "EnableDynamicContentInWSB: $((Get-ItemProperty -Path $searchPolicyPath -Name 'EnableDynamicContentInWSB' -ErrorAction SilentlyContinue).EnableDynamicContentInWSB) (0=検索のハイライト非表示)"

Write-Host "`n完了しました。" -ForegroundColor Green
