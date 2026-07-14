# Microsoft Defender のスキャン対象からフォルダを除外するスクリプト
# 指定したフォルダをリアルタイムスキャンの対象外にすることで、
# Defender の保護を保ったまま、そのフォルダへのアクセス時のCPU/ディスク負荷を下げます。
#
# 除外はビルド用ディレクトリや大量のファイル入出力が起きる作業フォルダなど、
# 「自分が中身を信頼できるフォルダ」に限定してください。
# ダウンロードフォルダなど外部ファイルが入る場所は除外しないでください。
#
# 要管理者権限。
# 使い方:
#   pwsh -ExecutionPolicy Bypass -File .\Add-DefenderExclusion.ps1 -Path "C:\dev\myproject"
#   pwsh -ExecutionPolicy Bypass -File .\Add-DefenderExclusion.ps1 "C:\dev\a","D:\build"

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Path
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

foreach ($p in $Path) {
    $full = $p
    try {
        # 相対パスを絶対パスに解決(存在する場合)
        $resolved = Resolve-Path -Path $p -ErrorAction Stop
        $full = $resolved.Path
    } catch {
        Write-Warning "[$p] フォルダが存在しません。存在しないパスをそのまま除外に追加します。"
    }

    Add-MpPreference -ExclusionPath $full -ErrorAction SilentlyContinue
    Write-Host "[$full] を除外に追加しました。" -ForegroundColor Green
}

# --- 最終確認 ---
Write-Host "`n===== 現在の除外フォルダ一覧 =====" -ForegroundColor Cyan
$current = (Get-MpPreference).ExclusionPath
if ($current) {
    $current | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host "(除外フォルダはありません)"
}
