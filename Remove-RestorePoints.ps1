# 現在までの復元ポイント(システムの保護のシャドウコピー)をすべて削除して
# ディスク領域を解放するスクリプト
#
# 「システムのプロパティ > システムの保護 > 構成 > 削除」と同等の操作です。
# 削除されるのは過去の復元ポイントのみで、システムの保護の有効/無効設定は変更しません。
#
# 注意: 削除すると過去の状態には一切戻せなくなります。
#       エクスプローラーの「以前のバージョン」の履歴も消えます。
#       デブロート系スクリプトを試す前に作った復元ポイントも消えるので、
#       システムが安定していることを確認してから実行してください。
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Remove-RestorePoints.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

function Show-ShadowStorage {
    $storages = Get-CimInstance -ClassName Win32_ShadowStorage -ErrorAction SilentlyContinue
    if (-not $storages) {
        Write-Host "シャドウコピー用の記憶域はありません。"
        return
    }
    foreach ($s in $storages) {
        $volume = Get-CimInstance -ClassName Win32_Volume -Filter "DeviceID='$($s.Volume.DeviceID.Replace('\', '\\'))'" -ErrorAction SilentlyContinue
        $label = if ($volume -and $volume.DriveLetter) { $volume.DriveLetter } else { "(ドライブ不明)" }
        $usedGB = [Math]::Round($s.UsedSpace / 1GB, 2)
        $allocatedGB = [Math]::Round($s.AllocatedSpace / 1GB, 2)
        Write-Host "${label} 使用中: ${usedGB}GB / 割り当て済み: ${allocatedGB}GB"
    }
}

# --- 1. 削除前の状態を表示 ---
Write-Host "===== 削除前の状態 =====" -ForegroundColor Cyan
$shadows = Get-CimInstance -ClassName Win32_ShadowCopy -ErrorAction SilentlyContinue
Write-Host "復元ポイント(シャドウコピー)の数: $(@($shadows).Count)"
Show-ShadowStorage

if (-not $shadows) {
    Write-Host "`n削除する復元ポイントはありません。" -ForegroundColor Green
    exit 0
}

# --- 2. すべて削除 ---
Write-Host "`n復元ポイントを削除しています..." -ForegroundColor Cyan
$shadows | Remove-CimInstance -ErrorAction SilentlyContinue

# --- 3. 削除後の状態を表示 ---
Start-Sleep -Seconds 2
Write-Host "`n===== 削除後の状態 =====" -ForegroundColor Cyan
$remaining = @(Get-CimInstance -ClassName Win32_ShadowCopy -ErrorAction SilentlyContinue)
Write-Host "復元ポイント(シャドウコピー)の数: $($remaining.Count)"
Show-ShadowStorage

if ($remaining.Count -eq 0) {
    Write-Host "`nすべての復元ポイントを削除しました。" -ForegroundColor Green
} else {
    Write-Warning "$($remaining.Count) 個の復元ポイントが削除できずに残っています。管理者権限で再実行してください。"
}
