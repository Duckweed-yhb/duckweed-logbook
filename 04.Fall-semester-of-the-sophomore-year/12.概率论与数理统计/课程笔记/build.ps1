# 编译概率论与数理统计课程笔记（本课程是两个独立文档：讲义 + 习题回顾，各自完整编译）
# 用法：powershell -ExecutionPolicy Bypass -File "<本文件路径>"
# 产物：…\课程笔记\pdf\概率论与数理统计课程笔记.pdf、…\课程笔记\pdf\概率论与数理统计习题回顾.pdf
# 中间文件留在 pdf\.build\，不污染 pdf\ 目录
# 注意：本脚本含中文，须以 UTF-8 with BOM 保存，否则 PowerShell 5.1 按 GBK 读会报 "Missing closing '}'"

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot                      # …\课程笔记
$src  = Join-Path $here 'latex'
$pdfDir = Join-Path $here 'pdf'
$outDir = Join-Path $pdfDir '.build'

New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# 文档主文件 -> 成品名
$docs = @(
    @{ main = '概率论与数理统计笔记.tex'; out = '概率论与数理统计课程笔记.pdf' },
    @{ main = '习题回顾.tex';             out = '概率论与数理统计习题回顾.pdf' }
)

Push-Location $src
try {
    foreach ($doc in $docs) {
        foreach ($pass in 1, 2) {
            Write-Host ("== xelatex {0} pass {1} ==" -f $doc.main, $pass)
            & xelatex -interaction=nonstopmode -file-line-error "-output-directory=$outDir" $doc.main | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "编译失败，错误摘要："
                $log = Join-Path $outDir ([IO.Path]::ChangeExtension($doc.main, '.log'))
                Select-String -LiteralPath $log -Pattern '^!' -Context 0,3 |
                    Select-Object -First 10 | ForEach-Object { $_.Line; $_.Context.PostContext }
                throw ("xelatex 退出码 " + $LASTEXITCODE + "（" + $doc.main + "）")
            }
        }
        Copy-Item -LiteralPath (Join-Path $outDir ([IO.Path]::ChangeExtension($doc.main, '.pdf'))) `
                  -Destination (Join-Path $pdfDir $doc.out) -Force
    }
} finally {
    Pop-Location
}

Get-ChildItem -LiteralPath $pdfDir -File -Filter "*.pdf" | ForEach-Object {
    Write-Host ("完成：" + $_.FullName + "（" + [math]::Round($_.Length / 1KB) + " KB）")
}
