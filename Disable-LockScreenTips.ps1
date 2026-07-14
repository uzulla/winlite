# ロック画面の「豆知識やヒント」表示を無効化するスクリプト
# 「設定 > 個人用設定 > ロック画面」の
# 「背景の画像に合わせたおもしろい雑学やヒントなどの情報を表示する」チェックを外すのと同等です。
#
# 注意: 「ロック画面の状態(通知を表示するアプリ)」を「なし」にする設定は、
#       LockAppのアプリコンテナ内部設定として管理されており、確実な公開レジストリキーが
#       無いため、このスクリプトでは変更していません。お手数ですが
#       「設定 > 個人用設定 > ロック画面 > ロック画面の状態」から手動で「なし」を選択してください。
#
# 管理者権限は不要(現在のユーザーの設定のみ変更します)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-LockScreenTips.ps1

Write-Host "ロック画面の豆知識・ヒント表示を無効化しています..." -ForegroundColor Cyan

$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $cdmPath)) { New-Item -Path $cdmPath -Force | Out-Null }

# ロック画面の「豆知識・ヒント」チェックボックスをオフ
New-ItemProperty -Path $cdmPath -Name "SubscribedContent-338387Enabled" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "設定が完了しました。" -ForegroundColor Green

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "SubscribedContent-338387Enabled: $((Get-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338387Enabled' -ErrorAction SilentlyContinue).'SubscribedContent-338387Enabled') (0=非表示)"

Write-Host "`n完了しました。「ロック画面の状態」は手動設定が必要な点にご注意ください。" -ForegroundColor Yellow
