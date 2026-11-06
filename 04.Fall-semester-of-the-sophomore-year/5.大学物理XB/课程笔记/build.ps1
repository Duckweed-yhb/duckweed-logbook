# 编译本课程笔记
# 用法：powershell -ExecutionPolicy Bypass -File "<本文件路径>"
# 产物：…\课程笔记\pdf\大学物理XB课程笔记.pdf
# 中间文件（.aux/.log/.toc 等）留在 pdf\.build\，不污染 pdf\ 目录
# 注意：本脚本含中文，须以 UTF-8 with BOM 保存，否则 PowerShell 5.1 按 GBK 读会报 "Missing closing '}'"

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot                      # …\课程笔记
$src  = Join-Path $here 'latex'            # tex 源目录
$main = '1.大物笔记.tex'
$pdfDir = Join-Path $here 'pdf'
$outDir = Join-Path $pdfDir '.build'
$finalName = '大学物理XB课程笔记.pdf'

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
            $log = Join-Path $outDir ([IO.Path]::ChangeExtension($main, '.log'))
            Select-String -LiteralPath $log -Pattern '^!' -Context 0,3 |
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