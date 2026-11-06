# 编译高等数学A（微积分A）课程笔记
# 用法：在 PowerShell 中执行
#   powershell -ExecutionPolicy Bypass -File "…\12.微积分A\课程笔记\build.ps1"
# 产物：…\12.微积分A\课程笔记\pdf\微积分A课程笔记.pdf
# 中间文件（.aux/.log/.toc 等）留在 pdf\.build\，不污染 pdf\ 目录

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot                      # …\12.微积分A\课程笔记
$src  = Join-Path $here 'latex'            # tex 源目录
$main = '1.main.tex'
$pdfDir = Join-Path $here 'pdf'
$outDir = Join-Path $pdfDir '.build'
$finalName = '微积分A课程笔记.pdf'

New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Push-Location $src
try {
    # 两遍：第一遍写 .aux/.toc，第二遍补目录与交叉引用
    foreach ($pass in 1, 2) {
        Write-Host "== xelatex pass $pass =="
        & xelatex -interaction=nonstopmode -file-line-error "-output-directory=$outDir" $main | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "编译失败（pass $pass），错误摘要："
            Select-String -LiteralPath (Join-Path $outDir '1.main.log') -Pattern '^!' -Context 0,3 |
                Select-Object -First 10 | ForEach-Object { $_.Line; $_.Context.PostContext }
            throw "xelatex 退出码 $LASTEXITCODE"
        }
    }
} finally {
    Pop-Location
}

Copy-Item -LiteralPath (Join-Path $outDir ([IO.Path]::ChangeExtension($main, '.pdf'))) `
          -Destination (Join-Path $pdfDir $finalName) -Force

$info = Get-Item -LiteralPath (Join-Path $pdfDir $finalName)
Write-Host ("完成：" + $info.FullName + "（" + [math]::Round($info.Length / 1KB) + " KB）")
