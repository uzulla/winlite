# 全サービスの一覧を取得し、名前・表示名・状態・スタートアップ設定をタブ区切りで出力する
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Get-ServiceList.ps1
#         ファイルに保存する場合: .\Get-ServiceList.ps1 > services.tsv

"Name`tDisplayName`tState`tStartMode"

Get-CimInstance -ClassName Win32_Service |
    Sort-Object -Property Name |
    ForEach-Object {
        $startMode = $_.StartMode
        # 自動(遅延開始)を区別する
        if ($startMode -eq 'Auto' -and $_.DelayedAutoStart) {
            $startMode = 'Auto (Delayed)'
        }
        "{0}`t{1}`t{2}`t{3}" -f $_.Name, $_.DisplayName, $_.State, $startMode
    }
