# 工程训练 3D 模型（库外存放）

> **为什么在这里**：`01-学业/duckweed-logbook` 是**公开 GitHub 仓库**，7 个 `.STEP` 合计 **67.6 MB**，
> 属"可再获取/大体量二进制"，不适合进版本库。2026-10-23 从
> `duckweed-logbook/06.Summer-semester-of-the-sophomore-year/1.工程训练(金工实习)/12.仿生越障机器人项目/engineering-training/硬件资料/3D模型/`
> 移到这里，原位置留了说明与指路。

| 文件 | 大小 |
|---|---|
| `开发板/ESP32-S3开发板.STEP` | 19.3 MB |
| `电机/MG4010-i10电机.STEP` | 13.1 MB |
| `舵机/MG90S舵机主体.STEP` | 3.8 MB |
| `舵机/单向舵盘.STEP` | 0.4 MB |
| `舵机/双向舵盘.STEP` | 0.6 MB |
| `舵机/四向舵盘.STEP` | 0.6 MB |
| `转接板/电机转接板.STEP` | 29.7 MB |

**合计 7 个 / 67.6 MB**

## 用途

这些是**打印件的原始 CAD**（开发板 / MG4010-i10 电机 / MG90S 舵机 / 3 个舵盘 / 电机转接板），
用于建模、装配核对与 3D 打印。 `.STEP` 是通用交换格式，可用 FreeCAD / SolidWorks / Fusion 360 打开。

## 恢复回库

若确实需要放回仓库（例如要随仓库分发）：
```powershell
Move-Item -Path "<库外归档目录>\*" `
          -Destination "<仓库>/硬件资料/3D模型/" -Recurse
```
