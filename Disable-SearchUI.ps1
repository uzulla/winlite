# Windows の検索UIを完全に無効化するスクリプト
# ファイルインデックス(WSearch)だけでなく、検索UIの入口をすべて停止します:
#   ・タスクバーの検索ボタン/検索ボックス
#   ・スタートメニューを開いて文字を入力するアプリ検索
#   ・Win + S の検索画面
#
# DisableSearch ポリシーによる無効化で、Windows 11 22H2 以降では Pro エディションも対象です。
# 元に戻すには Enable-SearchUI.ps1 を実行してください。
#
# 要管理者権限。反映にはサインアウトまたは再起動が必要です。
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Disable-SearchUI.ps1

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "このスクリプトは管理者権限で実行してください。"
    exit 1
}

$searchPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

Write-Host "検索UIを無効化しています..." -ForegroundColor Cyan
if (-not (Test-Path $searchPolicy)) { New-Item -Path $searchPolicy -Force | Out-Null }
New-ItemProperty -Path $searchPolicy -Name "DisableSearch" -Value 1 -PropertyType DWord -Force | Out-Null

# 実行中の検索UIプロセスを停止(常駐分のメモリを解放)
Write-Host "検索UIのプロセスを停止しています..." -ForegroundColor Cyan
Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue

# --- 最終確認 ---
Write-Host "`n===== 現在の設定 =====" -ForegroundColor Cyan
Write-Host "DisableSearch: $((Get-ItemProperty -Path $searchPolicy -Name 'DisableSearch' -ErrorAction SilentlyContinue).DisableSearch) (1=検索UI無効)"

Write-Host "`n完了しました。" -ForegroundColor Green
Write-Host "`n*** 完全に反映するにはサインアウトまたは再起動してください。 ***" -ForegroundColor Red
