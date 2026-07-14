# OneDriveの同期を止めてアンインストールするスクリプト
# 実行には管理者権限は不要(ユーザーごとのインストールのため)だが、
# 全ユーザー分のクリーンアップまで行う場合は管理者権限で実行してください。
#
# 使い方: pwsh -ExecutionPolicy Bypass -File .\Remove-OneDrive.ps1
#
# 注意: この操作は元に戻せません。再度使いたくなった場合は
#       https://www.microsoft.com/ja-jp/microsoft-365/onedrive/download から再インストールしてください。

$rebootRequired = $false

Write-Host "OneDriveのプロセスを停止しています..." -ForegroundColor Cyan
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# --- アンインストール: まず winget を試し、失敗した場合は OneDriveSetup.exe にフォールバックする ---
$uninstalled = $false

$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetCmd) {
    Write-Host "winget でアンインストールを試みています..." -ForegroundColor Cyan
    winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements | Out-Null
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "winget によるアンインストールが完了しました。" -ForegroundColor Green
        $uninstalled = $true
    } elseif ($exitCode -eq 3010) {
        Write-Host "winget によるアンインストールが完了しました(再起動が必要です)。" -ForegroundColor Green
        $uninstalled = $true
        $rebootRequired = $true
    } else {
        Write-Warning "winget でのアンインストールに失敗しました(終了コード: $exitCode)。OneDriveSetup.exe にフォールバックします。"
    }
} else {
    Write-Warning "winget が見つかりませんでした。OneDriveSetup.exe にフォールバックします。"
}

if (-not $uninstalled) {
    # OneDriveSetup.exe のインストール場所は環境によって異なるため、候補を順に確認する
    $setupPaths = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDriveSetup.exe"
    )
    $setupExe = $setupPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($setupExe) {
        Write-Host "アンインストールを実行しています ($setupExe)..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $setupExe -ArgumentList "/uninstall" -Wait -PassThru
        if ($proc.ExitCode -eq 3010) {
            Write-Host "アンインストールが完了しました(再起動が必要です)。" -ForegroundColor Green
            $rebootRequired = $true
        } else {
            Write-Host "アンインストールが完了しました。" -ForegroundColor Green
        }
        $uninstalled = $true
    } else {
        Write-Warning "OneDriveSetup.exe が見つかりませんでした。既にアンインストール済みの可能性があります。"
    }
}

Start-Sleep -Seconds 2

# スタートアップ登録の削除(残っている場合)
Write-Host "スタートアップ登録を削除しています..." -ForegroundColor Cyan
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue

# エクスプローラーのサイドバーからOneDriveアイコンを非表示にする
Write-Host "エクスプローラーの表示設定をクリーンアップしています..." -ForegroundColor Cyan
Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue

# 残った同期フォルダやプログラムフォルダを削除(中身は残す場合はここをコメントアウト)
$leftoverPaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:ProgramData\Microsoft OneDrive",
    "$env:SystemDrive\OneDriveTemp"
)
foreach ($path in $leftoverPaths) {
    if (Test-Path $path) {
        Write-Host "削除中: $path" -ForegroundColor Cyan
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "エクスプローラーを再起動して変更を反映します。" -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

# --- 最終確認: 削除しきれていないものが無いかチェックし、残っていれば対処を指示する ---
Start-Sleep -Seconds 2
Write-Host "`n===== 残存チェック =====" -ForegroundColor Cyan

$remaining = @()

if (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue) {
    $remaining += "OneDrive プロセスがまだ動作しています。"
}

$stillInstalled = $setupPaths | Where-Object { Test-Path $_ }
if ($stillInstalled) {
    $remaining += "OneDriveSetup.exe がまだ存在します ($($stillInstalled -join ', '))。アンインストールが正常に完了していない可能性があります。"
}

foreach ($path in $leftoverPaths) {
    if (Test-Path $path) {
        $remaining += "フォルダが削除できずに残っています: $path"
    }
}

if (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue) {
    $remaining += "スタートアップ登録(HKCU)がまだ残っています。"
}
if (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue) {
    $remaining += "スタートアップ登録(HKLM)がまだ残っています。"
}

if ($remaining.Count -eq 0) {
    Write-Host "残存物は見つかりませんでした。クリーンアップは完了です。" -ForegroundColor Green
} else {
    Write-Warning "以下の残存物が見つかりました:"
    $remaining | ForEach-Object { Write-Warning " - $_" }
    Write-Host ""
    Write-Host "【対処方法】" -ForegroundColor Yellow
    Write-Host "1. このスクリプトを管理者権限で再実行してください(ファイル使用中などでロックされている場合があります)。" -ForegroundColor Yellow
    Write-Host "2. それでも解消しない場合は、PCを再起動してから再実行してください。" -ForegroundColor Yellow
    Write-Host "3. フォルダが残る場合は手動で削除してください: $($leftoverPaths -join ', ')" -ForegroundColor Yellow
}

if ($rebootRequired) {
    Write-Host "`n*** 再起動が必要です。変更を完全に適用するにはPCを再起動してください。 ***" -ForegroundColor Red
}
