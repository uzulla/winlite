# Microsoft Defender のスキャン除外フォルダを解除する / 一覧表示するスクリプト
#
# ・引数なしで実行 → 現在除外されているフォルダの一覧を表示するだけ(変更しません)
# ・引数でフォルダを指定 → そのフォルダを除外から解除します
#
# 要管理者権限。
# 使い方:
#   pwsh -ExecutionPolicy Bypass -File .\Remove-DefenderExclusion.ps1                       # 一覧表示
#   pwsh -ExecutionPolicy Bypass -File .\Remove-DefenderExclusion.ps1 -Path "C:\dev\myproject"  # 解除
#   pwsh -ExecutionPolicy Bypass -File .\Remove-DefenderExclusion.ps1 "C:\dev\a","D:\build"

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string[]]$Path
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 引数なし: 現在の除外一覧を表示して終了 ---
if (-not $Path -or $Path.Count -eq 0) {
    Write-Host "===== 現在の除外フォルダ一覧 =====" -ForegroundColor Cyan
    $current = (Get-MpPreference).ExclusionPath
    if ($current) {
        $current | ForEach-Object { Write-Host " - $_" }
        Write-Host "`n解除するには -Path でフォルダを指定して再実行してください。" -ForegroundColor Yellow
    } else {
        Write-Host "(除外フォルダはありません)"
    }
    exit 0
}

# --- 引数あり: 指定フォルダを除外から解除 ---
$current = @((Get-MpPreference).ExclusionPath)
foreach ($p in $Path) {
    $full = $p
    try {
        $resolved = Resolve-Path -Path $p -ErrorAction Stop
        $full = $resolved.Path
    } catch {
        # 存在しないパスでも、除外リストには登録されている可能性があるのでそのまま解除を試みる
    }

    # 除外リストに実際に含まれているか確認(絶対パス・元の引数の両方で照合)
    $match = $current | Where-Object { $_ -eq $full -or $_ -eq $p }
    if (-not $match) {
        Write-Warning "[$p] は除外リストに見つかりませんでした。スキップします。"
        continue
    }

    foreach ($m in $match) {
        Remove-MpPreference -ExclusionPath $m -ErrorAction SilentlyContinue
        Write-Host "[$m] を除外から解除しました。" -ForegroundColor Green
    }
}

# --- 最終確認 ---
Write-Host "`n===== 現在の除外フォルダ一覧 =====" -ForegroundColor Cyan
$after = (Get-MpPreference).ExclusionPath
if ($after) {
    $after | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host "(除外フォルダはありません)"
}
