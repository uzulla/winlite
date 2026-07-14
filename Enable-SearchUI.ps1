# Windows の検索UIを有効化(元に戻す)スクリプト
# Disable-SearchUI.ps1 で設定した DisableSearch ポリシーを削除します。
#
# 要管理者権限。反映にはサインアウトまたは再起動が必要です。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Enable-SearchUI.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$searchPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

Write-Host "検索UIを有効化しています(DisableSearch ポリシーを削除)..." -ForegroundColor Cyan
Remove-ItemProperty -Path $searchPolicy -Name "DisableSearch" -ErrorAction SilentlyContinue

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
$value = (Get-ItemProperty -Path $searchPolicy -Name "DisableSearch" -ErrorAction SilentlyContinue).DisableSearch
if ($null -eq $value) {
    Write-Host "DisableSearch: 未設定 (検索UI有効)"
    Write-Host "`n完了しました。" -ForegroundColor Green
} else {
    Write-Warning "DisableSearch がまだ残っています: $value"
}

Write-Host "`n*** 完全に反映するにはサインアウトまたは再起動してください。 ***" -ForegroundColor Red
