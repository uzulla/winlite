# Cortana を完全削除するスクリプト
# ・全ユーザーから Cortana アプリ(Appxパッケージ)をアンインストール
# ・新規ユーザーにもインストールされないようプロビジョニングパッケージを解除
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Remove-Cortana.ps1
#
# 注意: 元に戻すには Microsoft Store から Cortana を再インストールしてください。

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$cortanaName = "Microsoft.549981C3F5F10"

# --- 1. 全ユーザーからアンインストール ---
Write-Host "Cortana をアンインストールしています(全ユーザー)..." -ForegroundColor Cyan
Get-AppxPackage -AllUsers -Name $cortanaName -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

# --- 2. 新規ユーザーにも入らないようプロビジョニングパッケージを解除 ---
Write-Host "プロビジョニングパッケージを解除しています..." -ForegroundColor Cyan
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq $cortanaName } |
    ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }

# --- 3. 最終確認 ---
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan
if (Get-AppxPackage -AllUsers -Name $cortanaName -ErrorAction SilentlyContinue) {
    Write-Warning "Cortana がまだ残っています。管理者権限で再実行するか、PCを再起動してから再実行してください。"
} else {
    Write-Host "Cortana の削除が完了しました。" -ForegroundColor Green
}
