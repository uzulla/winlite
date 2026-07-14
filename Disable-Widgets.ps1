# Windows 11 の「ウィジェット」機能を完全に無効化するスクリプト
# ・タスクバーの「ウィジェット」トグルをオフ
# ・グループポリシー相当のレジストリでウィジェット自体を無効化(全ユーザーに適用され、再度オンにできなくなる)
# ・ウィジェットのアプリ本体(Appxパッケージ)をアンインストール・プロビジョニング解除
#
# 要管理者権限。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-Widgets.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

# --- 1. グループポリシー相当のレジストリでウィジェットを無効化(全ユーザー・恒久的) ---
Write-Host "ウィジェット機能自体を無効化しています(全ユーザー)..." -ForegroundColor Cyan
$dshPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $dshPath)) {
    New-Item -Path $dshPath -Force | Out-Null
}
New-ItemProperty -Path $dshPath -Name "AllowNewsAndInterests" -Value 0 -PropertyType DWord -Force | Out-Null

# --- 2. タスクバーの「ウィジェット」トグルをオフ(現在のユーザー、即時反映用) ---
Write-Host "タスクバーのウィジェットアイコンを非表示にしています..." -ForegroundColor Cyan
$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path $advancedPath -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force | Out-Null

# --- 3. ウィジェットのアプリ本体をアンインストール ---
Write-Host "ウィジェットアプリ本体を削除しています..." -ForegroundColor Cyan
$widgetPackageName = "MicrosoftWindows.Client.WebExperience"

# 現在ログイン中の全ユーザーからアンインストール
Get-AppxPackage -AllUsers -Name $widgetPackageName -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

# 新規ユーザーにも入らないようプロビジョニングパッケージを解除
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq $widgetPackageName } |
    ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }

# --- 4. エクスプローラーを再起動して反映 ---
Write-Host "エクスプローラーを再起動しています..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

# --- 5. 最終確認 ---
Start-Sleep -Seconds 2
Write-Host "`n===== 現在の状態 =====" -ForegroundColor Cyan

$policyValue = (Get-ItemProperty -Path $dshPath -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue).AllowNewsAndInterests
Write-Host "ウィジェット無効化ポリシー(AllowNewsAndInterests): $policyValue (0=無効)"

$taskbarValue = (Get-ItemProperty -Path $advancedPath -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa
Write-Host "タスクバーのウィジェットアイコン(TaskbarDa): $taskbarValue (0=非表示)"

$stillInstalled = Get-AppxPackage -AllUsers -Name $widgetPackageName -ErrorAction SilentlyContinue
if ($stillInstalled) {
    Write-Warning "ウィジェットアプリがまだ残っています。管理者権限で再実行するか、手動で '設定 > アプリ > インストール済みアプリ' から削除してください。"
} else {
    Write-Host "ウィジェットアプリは正常に削除されています。" -ForegroundColor Green
}

Write-Host "`n完了しました。" -ForegroundColor Green
