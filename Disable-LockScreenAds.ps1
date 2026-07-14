# ロック画面・スタートメニューのWindows Spotlight/おすすめ/MSNニュース的な表示を無効化するスクリプト
# 「設定 > 個人用設定 > ロック画面」の背景に出るニュースやヒント、
# スタートメニューのおすすめアプリ通知などをまとめて止めます。
#
# 要管理者権限(グループポリシー相当のHKLM設定を変更するため)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-LockScreenAds.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

Write-Host "ロック画面/スタートメニューのおすすめ・ニュース表示を無効化しています..." -ForegroundColor Cyan

# グループポリシー相当のレジストリで無効化(全ユーザー・恒久的)
$cloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $cloudContentPath)) { New-Item -Path $cloudContentPath -Force | Out-Null }
New-ItemProperty -Path $cloudContentPath -Name "DisableWindowsSpotlightFeatures" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $cloudContentPath -Name "DisableWindowsConsumerFeatures" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $cloudContentPath -Name "DisableSoftLanding" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $cloudContentPath -Name "DisableThirdPartySuggestions" -Value 1 -PropertyType DWord -Force | Out-Null

# 現在のユーザーのキャッシュ済み設定も即時オフにする
$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $cdmPath)) { New-Item -Path $cdmPath -Force | Out-Null }
$cdmSettings = @{
    "SubscribedContentEnabled"         = 0  # 提案・広告の親スイッチ
    "SubscribedContent-338387Enabled"  = 0  # ロック画面の「豆知識・ヒント」
    "RotatingLockScreenEnabled"        = 0  # Windows Spotlight(ロック画面)
    "RotatingLockScreenOverlayEnabled" = 0
    "SystemPaneSuggestionsEnabled"     = 0  # スタートメニューの提案
    "SilentInstalledAppsEnabled"       = 0  # おすすめアプリの自動インストール
}
foreach ($key in $cdmSettings.Keys) {
    New-ItemProperty -Path $cdmPath -Name $key -Value $cdmSettings[$key] -PropertyType DWord -Force | Out-Null
}

Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "DisableWindowsSpotlightFeatures: $((Get-ItemProperty -Path $cloudContentPath -Name 'DisableWindowsSpotlightFeatures' -ErrorAction SilentlyContinue).DisableWindowsSpotlightFeatures) (1=無効)"
Write-Host "DisableWindowsConsumerFeatures: $((Get-ItemProperty -Path $cloudContentPath -Name 'DisableWindowsConsumerFeatures' -ErrorAction SilentlyContinue).DisableWindowsConsumerFeatures) (1=無効)"
Write-Host "SubscribedContentEnabled: $((Get-ItemProperty -Path $cdmPath -Name 'SubscribedContentEnabled' -ErrorAction SilentlyContinue).SubscribedContentEnabled) (0=無効)"

Write-Host "`n完了しました。" -ForegroundColor Green
