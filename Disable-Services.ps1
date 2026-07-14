# 大体停止してよいサービスを停止し、スタートアップの種類を「無効」にするスクリプト
#
# 対象サービス(停止すると使えなくなる機能):
#   WSearch              Windows Search (エクスプローラー/スタートメニューの高速検索)
#   DiagTrack            テレメトリ収集 (Connected User Experiences and Telemetry)
#   CDPSvc / CDPUserSvc  デバイス間連携 (クリップボード履歴の同期、スマホ連携、近距離共有)
#   MapsBroker           オフラインマップのダウンロード管理
#   RetailDemo           店頭デモモード
#   PhoneSvc             電話サービス (スマホ連携の通話)
#   MessagingService     SMSメッセージング
#   SmsRouter            SMSルーティング
#   SEMgrSvc             NFC決済等の支払い管理
#   WalletService        ウォレット
#   WMPNetworkSvc        Windows Media Playerのメディア共有
#   TrkWks               NTFSリンク追跡 (移動したショートカットの自動追跡)
#   wisvc                Windows Insider Program
#   WpcMonSvc            ファミリーセーフティ(保護者による制限)
#   workfolderssvc       ワークフォルダー (企業向けファイル同期)
#   WSAIFabricSvc        Windows Subsystem for Android
#   perceptionsimulation Windows Mixed Realityのシミュレーション
#   PushToInstall        Storeのリモートインストール (他デバイスからのアプリプッシュ)
#   PeerDistSvc          BranchCache (企業向けキャッシュ共有)
#   SNMPTrap             SNMPトラップ受信
#   SysMain              旧Superfetch (アプリ先読みキャッシュ。戻すには Enable-Sysmain.ps1)
#
# 「_*」付きのサービス(CDPUserSvc_* 等)はユーザーごとに実体が作られる Per-User Service で、
# Set-Service では無効化できないため、レジストリのテンプレートキー(Start=4)で無効化します。
#
# 要管理者権限。完全に反映するには再起動してください。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-Services.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$serviceNames = @(
    "WSearch"
    "DiagTrack"
    "CDPSvc"
    "CDPUserSvc_*"
    "MapsBroker"
    "RetailDemo"
    "PhoneSvc"
    "MessagingService_*"
    "SmsRouter"
    "SEMgrSvc"
    "WalletService"
    "WMPNetworkSvc"
    "TrkWks"
    "wisvc"
    "WpcMonSvc"
    "workfolderssvc"
    "WSAIFabricSvc"
    "perceptionsimulation"
    "PushToInstall"
    "PeerDistSvc"
    "SNMPTrap"
    "SysMain"
)

foreach ($name in $serviceNames) {
    $baseName = $name -replace '_\*$', ''

    # --- 1. 実行中のインスタンスを停止 ---
    $instances = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $instances) {
        Write-Host "[$baseName] 見つかりません(未インストール)。スキップします。" -ForegroundColor DarkGray
        continue
    }
    foreach ($svc in $instances) {
        if ($svc.Status -eq "Running") {
            Write-Host "[$($svc.Name)] 停止しています..." -ForegroundColor Cyan
            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        }
    }

    # --- 2. 無効化 ---
    # 通常サービスは SCM 経由(Set-Service)で無効化する。
    # レジストリ直接書き込みだと、キーが TrustedInstaller 保護されているサービス
    # (TrkWks 等)で管理者でもアクセス拒否されるため。
    # Per-User Service はテンプレートが SCM で構成変更できないため、
    # テンプレートキーの Start=4 をレジストリで書き換える。
    $isPerUser = $name.EndsWith("_*")
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$baseName"
    $disabled = $false
    if (-not $isPerUser) {
        try {
            Set-Service -Name $baseName -StartupType Disabled -ErrorAction Stop
            $disabled = $true
        } catch {
            # SCM で拒否された場合はレジストリを試す
        }
    }
    if (-not $disabled) {
        try {
            Set-ItemProperty -Path $regPath -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
            $disabled = $true
        } catch {
            Write-Warning "[$baseName] 無効化できませんでした: $($_.Exception.Message)"
        }
    }
    if ($disabled) {
        Write-Host "[$baseName] 無効化しました。" -ForegroundColor Green
    }
}

# --- 最終確認 ---
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
foreach ($name in $serviceNames) {
    $baseName = $name -replace '_\*$', ''
    $instances = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $instances) { continue }
    foreach ($svc in $instances) {
        $start = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$baseName" -Name "Start" -ErrorAction SilentlyContinue).Start
        $startLabel = switch ($start) { 2 {"自動"} 3 {"手動"} 4 {"無効"} default {"不明($start)"} }
        Write-Host "$($svc.Name): 状態=$($svc.Status) / スタートアップ=$startLabel"
    }
}

Write-Host "`n*** 変更を完全に反映するには再起動してください。 ***" -ForegroundColor Red
