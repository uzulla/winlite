# 通知を全部オフにするスクリプト
# 「設定 > システム > 通知」の以下をまとめてオフにするのと同等です。
#   - 通知(アプリやその他の送信者からの通知を受け取る) ※マスタースイッチ
#   - ロック画面に通知を表示する / ロック画面にリマインダーとVoIPの着信を表示する
#   - 通知時にサウンドを再生する
#   - 更新後およびサインイン時にWindowsのウェルカムエクスペリエンスを表示する
#   - デバイスのセットアップを完了するための提案を表示する
#   - Windowsを使用する上でのヒントや提案を表示する
#
# マスタースイッチをオフにするため、アプリごとの通知もすべて止まります。
#
# 管理者権限は不要(現在のユーザーの設定のみ変更します)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-Notifications.ps1

Write-Host "通知を無効化しています..." -ForegroundColor Cyan

# 通知のマスタースイッチをオフ
$pushPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
if (-not (Test-Path $pushPath)) { New-Item -Path $pushPath -Force | Out-Null }
New-ItemProperty -Path $pushPath -Name "ToastEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

# ロック画面への通知表示・通知サウンドをオフ
$notifSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
if (-not (Test-Path $notifSettingsPath)) { New-Item -Path $notifSettingsPath -Force | Out-Null }
New-ItemProperty -Path $notifSettingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $notifSettingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $notifSettingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -Value 0 -PropertyType DWord -Force | Out-Null

# 更新後・サインイン時のウェルカムエクスペリエンスをオフ
$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $cdmPath)) { New-Item -Path $cdmPath -Force | Out-Null }
New-ItemProperty -Path $cdmPath -Name "SubscribedContent-310093Enabled" -Value 0 -PropertyType DWord -Force | Out-Null

# Windowsを使用する上でのヒントや提案をオフ
New-ItemProperty -Path $cdmPath -Name "SubscribedContent-338389Enabled" -Value 0 -PropertyType DWord -Force | Out-Null

# デバイスのセットアップを完了するための提案をオフ
$engagementPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
if (-not (Test-Path $engagementPath)) { New-Item -Path $engagementPath -Force | Out-Null }
New-ItemProperty -Path $engagementPath -Name "ScoobeSystemSettingEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Start-Sleep -Seconds 2

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "ToastEnabled: $((Get-ItemProperty -Path $pushPath -Name 'ToastEnabled' -ErrorAction SilentlyContinue).ToastEnabled) (0=通知オフ)"
Write-Host "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK: $((Get-ItemProperty -Path $notifSettingsPath -Name 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK' -ErrorAction SilentlyContinue).NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK) (0=ロック画面通知オフ)"
Write-Host "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK: $((Get-ItemProperty -Path $notifSettingsPath -Name 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK' -ErrorAction SilentlyContinue).NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK) (0=リマインダー/VoIPオフ)"
Write-Host "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND: $((Get-ItemProperty -Path $notifSettingsPath -Name 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' -ErrorAction SilentlyContinue).NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND) (0=サウンドオフ)"
Write-Host "SubscribedContent-310093Enabled: $((Get-ItemProperty -Path $cdmPath -Name 'SubscribedContent-310093Enabled' -ErrorAction SilentlyContinue).'SubscribedContent-310093Enabled') (0=ウェルカム表示オフ)"
Write-Host "SubscribedContent-338389Enabled: $((Get-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338389Enabled' -ErrorAction SilentlyContinue).'SubscribedContent-338389Enabled') (0=ヒント/提案オフ)"
Write-Host "ScoobeSystemSettingEnabled: $((Get-ItemProperty -Path $engagementPath -Name 'ScoobeSystemSettingEnabled' -ErrorAction SilentlyContinue).ScoobeSystemSettingEnabled) (0=セットアップ提案オフ)"

Write-Host "`n完了しました。" -ForegroundColor Green
