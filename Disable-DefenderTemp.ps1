# Microsoft Defender (Antimalware Service / MsMpEng.exe) を一時的に停止するスクリプト
#
# 【この操作は推奨しません】
#   軽量化のためであっても、Defender を停止して使うことは推奨しません。
#   保護を切っている間はPC全体がマルウェア感染のリスクにさらされます。
#   常時のCPU負荷が目的なら、まず「フォルダ除外(Add-MpPreference -ExclusionPath)」で
#   特定フォルダだけスキャン対象外にする方法を検討してください(保護を保ったまま負荷を下げられます)。
#   それでもどうしても短時間だけ止める必要がある場合に限り、自己責任で使用してください。
#
# 【重要】このスクリプトはPCのウイルス保護を一時的に無効にします。
#   ・信頼できない通信やファイルを扱わない、短時間の作業に限定してください。
#   ・作業が終わったら必ず Enable-DefenderTemp.ps1 で元に戻してください。
#
# 【技術的な注意】
#   Antimalware Service は保護プロセス(PPL)のため Stop-Service では停止できません
#   (管理者でも「アクセスが拒否されました」になります)。実際に保護を止めるには
#   Set-MpPreference でリアルタイム保護等の各機能を無効化します。
#   これには「改ざん防止(Tamper Protection)」が【オフ】であることが前提です。
#   改ざん防止がオンのままだと下記は無視される/失敗します。
#   改ざん防止は仕様上スクリプトからは安全に切り替えできないため、事前に手動で
#   「Windows セキュリティ > ウイルスと脅威の防止 > 設定の管理 > 改ざん防止」をオフにしてください。
#
#   なお、ここで無効化した設定は再起動時や Defender の自動判断で復帰することがあります
#   (=完全な永続停止ではなく、あくまで一時的な停止です)。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-DefenderTemp.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 改ざん防止の状態を確認 ---
$status = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($status -and $status.IsTamperProtected) {
    Write-Warning "改ざん防止(Tamper Protection)がオンです。この状態では保護を無効化できません。"
    Write-Host "「Windows セキュリティ > ウイルスと脅威の防止 > 設定の管理 > 改ざん防止」を" -ForegroundColor Yellow
    Write-Host "手動でオフにしてから、このスクリプトを再実行してください。" -ForegroundColor Yellow
    exit 1
}

Write-Host "Microsoft Defender の保護機能を一時的に無効化しています..." -ForegroundColor Cyan

# リアルタイム保護および常時稼働のスキャン機能を無効化
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue      # リアルタイム保護
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue      # 動作監視
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue          # スクリプトスキャン
Set-MpPreference -DisableOnAccessProtection $true -ErrorAction SilentlyContinue      # オンアクセス保護
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue          # ダウンロード/添付のスキャン
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# --- 最終確認 ---
Start-Sleep -Seconds 2
$status = Get-MpComputerStatus -ErrorAction SilentlyContinue
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
if ($status) {
    Write-Host "リアルタイム保護(RealTimeProtectionEnabled): $($status.RealTimeProtectionEnabled) (False=無効)"
    Write-Host "動作監視(BehaviorMonitorEnabled): $($status.BehaviorMonitorEnabled) (False=無効)"
    Write-Host "オンアクセス保護(OnAccessProtectionEnabled): $($status.OnAccessProtectionEnabled) (False=無効)"

    if (-not $status.RealTimeProtectionEnabled) {
        Write-Host "`nDefender のリアルタイム保護を無効化しました。" -ForegroundColor Green
    } else {
        Write-Warning "リアルタイム保護がまだ有効です。改ざん防止がオフになっているか確認してください。"
    }
} else {
    Write-Warning "Defender の状態を取得できませんでした。"
}

Write-Host "`n*** 保護が下がっています。作業後は必ず Enable-DefenderTemp.ps1 を実行してください。 ***" -ForegroundColor Red
