# スタートメニューの「おすすめ」欄(最近追加したアプリ/よく使うアプリ/最近開いた項目)を消し、
# レイアウトを「さらにピン留めを表示する」にして無駄な余白を減らすスクリプト
#
# 管理者権限は不要(現在のユーザーの設定のみ変更します)。
# 使い方: powershell -ExecutionPolicy Bypass -File .\Disable-StartMenuRecommendations.ps1

Write-Host "スタートメニューの「おすすめ」表示を無効化しています..." -ForegroundColor Cyan

$explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $explorerPolicyPath)) { New-Item -Path $explorerPolicyPath -Force | Out-Null }

# 最近追加したアプリを表示する -> オフ
New-ItemProperty -Path $explorerPolicyPath -Name "HideRecentlyAddedApps" -Value 1 -PropertyType DWord -Force | Out-Null

# よく使うアプリを表示する -> オフ
New-ItemProperty -Path $explorerPolicyPath -Name "NoStartMenuMFUprogramsList" -Value 1 -PropertyType DWord -Force | Out-Null

$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# 最近開いた項目をスタート/ジャンプリスト/エクスプローラーに表示する -> オフ
New-ItemProperty -Path $advancedPath -Name "Start_TrackDocs" -Value 0 -PropertyType DWord -Force | Out-Null

# レイアウト: さらにピン留めを表示する (0=ピン留め優先, 1=既定, 2=おすすめ優先)
New-ItemProperty -Path $advancedPath -Name "Start_Layout" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "HideRecentlyAddedApps: $((Get-ItemProperty -Path $explorerPolicyPath -Name 'HideRecentlyAddedApps' -ErrorAction SilentlyContinue).HideRecentlyAddedApps) (1=非表示)"
Write-Host "NoStartMenuMFUprogramsList: $((Get-ItemProperty -Path $explorerPolicyPath -Name 'NoStartMenuMFUprogramsList' -ErrorAction SilentlyContinue).NoStartMenuMFUprogramsList) (1=非表示)"
Write-Host "Start_TrackDocs: $((Get-ItemProperty -Path $advancedPath -Name 'Start_TrackDocs' -ErrorAction SilentlyContinue).Start_TrackDocs) (0=非表示)"
Write-Host "Start_Layout: $((Get-ItemProperty -Path $advancedPath -Name 'Start_Layout' -ErrorAction SilentlyContinue).Start_Layout) (0=さらにピン留めを表示する)"

Write-Host "`n完了しました。" -ForegroundColor Green
