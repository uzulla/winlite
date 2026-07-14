# スタートメニュー検索でのBing/クラウド検索連携を無効化するスクリプト
# ローカル検索のみを行い、ネットから結果を拾ってこないようにします。
#
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-SearchSuggestions.ps1

Write-Host "検索ボックスのサジェスト・Bing連携を無効化しています..." -ForegroundColor Cyan

# 検索ボックスのサジェスト自体を無効化
$explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $explorerPolicyPath)) { New-Item -Path $explorerPolicyPath -Force | Out-Null }
New-ItemProperty -Path $explorerPolicyPath -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null

# Bing検索・Cortana同意の無効化
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
New-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $searchPath -Name "CortanaConsent" -Value 0 -PropertyType DWord -Force | Out-Null

# クラウド検索(Microsoftアカウント/職場アカウントの履歴検索)を無効化
$searchSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
if (-not (Test-Path $searchSettingsPath)) { New-Item -Path $searchSettingsPath -Force | Out-Null }
New-ItemProperty -Path $searchSettingsPath -Name "IsAADCloudSearchEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $searchSettingsPath -Name "IsMSACloudSearchEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $searchSettingsPath -Name "IsDeviceSearchHistoryEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "DisableSearchBoxSuggestions: $((Get-ItemProperty -Path $explorerPolicyPath -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions) (1=無効)"
Write-Host "BingSearchEnabled: $((Get-ItemProperty -Path $searchPath -Name 'BingSearchEnabled' -ErrorAction SilentlyContinue).BingSearchEnabled) (0=無効)"
Write-Host "IsDeviceSearchHistoryEnabled: $((Get-ItemProperty -Path $searchSettingsPath -Name 'IsDeviceSearchHistoryEnabled' -ErrorAction SilentlyContinue).IsDeviceSearchHistoryEnabled) (0=無効)"

Write-Host "`n完了しました。" -ForegroundColor Green
