# Microsoft Edge の新しいタブページに表示されるニュース/コンテンツを無効化するスクリプト
# 「設定(歯車)>コンテンツ>コンテンツをオフ」に相当する公式ポリシーをレジストリで設定します。
#
# 注意: 新しいタブの「画面の表示設定(フォーカス/インスピレーション/情報)」自体は
#       Edgeのローカルなユーザー設定であり、企業向けの公開ポリシーが存在しないため
#       レジストリからは制御できません。ここではニュースフィードなどの「コンテンツ」を
#       丸ごとオフにすることで、実質的に同じ(背景負荷が減る)状態にします。
#
# 管理者権限は不要(現在のユーザーの設定のみ変更します)。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-EdgeNewsFeed.ps1

Write-Host "Microsoft Edge の新しいタブのコンテンツ(ニュース)を無効化しています..." -ForegroundColor Cyan

$edgePolicyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePolicyPath)) { New-Item -Path $edgePolicyPath -Force | Out-Null }

# 新しいタブページのコンテンツ(ニュースフィード等)を無効化
New-ItemProperty -Path $edgePolicyPath -Name "NewTabPageContentEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

# クイックリンク下の広告的なおすすめコンテンツも合わせて無効化
New-ItemProperty -Path $edgePolicyPath -Name "NewTabPageHideDefaultTopSites" -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "設定が完了しました。反映にはMicrosoft Edgeの再起動が必要です。" -ForegroundColor Green

if (Get-Process -Name "msedge" -ErrorAction SilentlyContinue) {
    Write-Host "Edgeが起動中です。設定を反映するには手動でEdgeを再起動してください。" -ForegroundColor Yellow
}

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "NewTabPageContentEnabled: $((Get-ItemProperty -Path $edgePolicyPath -Name 'NewTabPageContentEnabled' -ErrorAction SilentlyContinue).NewTabPageContentEnabled) (0=コンテンツ非表示)"
Write-Host "NewTabPageHideDefaultTopSites: $((Get-ItemProperty -Path $edgePolicyPath -Name 'NewTabPageHideDefaultTopSites' -ErrorAction SilentlyContinue).NewTabPageHideDefaultTopSites) (1=非表示)"

Write-Host "`n完了しました。" -ForegroundColor Green
