# 03 ESP32-S3 板卡参数设置

> [!TIP]
> 本篇是 [学习路线](00_learning_path.md) 第 1 步（环境搭建）的一部分。帮助你理解 Arduino IDE 中 ESP32-S3 的各项参数设置。

## 本节目标

- 了解 ESP32S3 Dev Module 通用板型
- 掌握推荐参数配置
- 理解原生 USB 与串口芯片的区别
- 学会使用 BOOT 和 EN 按键

---

## 1. 选择开发板型号

大多数普通 ESP32-S3 开发板可选择：

```text
Tools → Board → esp32 → ESP32S3 Dev Module
```

> [!NOTE]
> 如果你的板子厂家在菜单中提供了专用型号（如 ESP32-S3-DevKitC-1），优先选择厂家专用型号。

---

## 2. 推荐参数设置

| 选项 | 推荐值 | 说明 |
|------|--------|------|
| **Board** | `ESP32S3 Dev Module` | 通用板型 |
| **Port** | 实际 COM 口 | Windows 如 COM3，macOS 如 `/dev/cu.usbserial-0001` |
| **Upload Speed** | `460800` | 上传失败时改为 `115200` |
| **CPU Frequency** | `240MHz` | 最高性能 |
| **Flash Mode** | `QIO` 或 `DIO` | 默认即可 |
| **Flash Size** | `8MB` 或 `16MB` | 按实际板子选择 |
| **Partition Scheme** | `Default` | 默认分区方案 |
| **PSRAM** | 有则 `Enabled` 或 `OPI PSRAM` | N16R8 型号需启用 |
| **USB CDC On Boot** | 见下方说明 | **取决于你的板子 USB 类型** |

> [!IMPORTANT]
> **USB CDC On Boot** 设置取决于你的开发板 USB 类型：
> - **原生 USB 板**（直接用 ESP32-S3 芯片的 USB）：设为 **Enabled**
> - **CH340/CH343 板**（板上有独立 USB 转串口芯片）：设为 **Disabled**
> 
> 如何判断：
> 1. Windows：设备管理器看 COM 口名称（`USB JTAG` = 原生，`CH340` = 外置芯片）
> 2. macOS：系统报告 → USB 看设备名称
> 3. 不确定时先试 **Disabled**，如果串口无输出再改 Enabled

### 完整参数示例

```text
Board: ESP32S3 Dev Module
Port: COM3（或 /dev/cu.usbserial-xxx）
Upload Speed: 460800
CPU Frequency: 240MHz
Flash Mode: QIO 或 DIO
Flash Size: 8MB 或 16MB
Partition Scheme: Default
PSRAM: OPI PSRAM（或 Enabled）
USB CDC On Boot: Enabled 或 Disabled（见上方说明）
```

> [!NOTE]
> 如果使用本教程对应的 ESP32-S3 N16R8 开发板，该核心板带 8MB PSRAM。Arduino IDE 中需要把 PSRAM 设为 `OPI PSRAM` 或对应的 Enabled 选项。菜单名称会随 Arduino-ESP32 版本略有不同，以 IDE 中显示的选项为准。

---

## 3. 原生 USB 与串口芯片区别

### 原生 USB

**特点：** ESP32-S3 芯片自己提供 USB 功能。

**常见设备名：**
```text
USB JTAG/serial debug unit
USB Serial Device
```

**建议设置：**
```text
USB CDC On Boot: Enabled
```

### 外置 USB 转串口芯片

**常见芯片：**
```text
CH340 / CH343 / CP2102
```

**常见设备名：**
```text
USB-SERIAL CH340 (COMx)
```

**特点：** 这种板子通常会出现普通 COM 口，上传比较接近传统 ESP32 开发板。

**建议设置：**
```text
USB CDC On Boot: Disabled
```

> [!TIP]
> 不确定板子是哪种类型时，先设为 **Disabled**。上传程序后如果串口监视器无输出，再改为 Enabled 并重新上传。

> [!WARNING]
> ESP32-S3 开发板资料页提示，UART0 的 GPIO43/GPIO44 用于调试和下载，不建议再接外部模块。本教程的 RS485 示例默认使用 **GPIO17/GPIO18** 连接课程配套 RS485/供电转接板或外部 RS485 模块。

---

## 4. BOOT 与 EN 按键

| 按键 | 功能 |
|------|------|
| **BOOT** | 进入下载模式 |
| **EN** / **RST** | 复位开发板 |

### 上传失败时的操作

```text
1. 按住 BOOT 按键
2. 点击 Arduino IDE 的上传按钮
3. 出现 Connecting... 时松开 BOOT
4. 等待上传完成
```

### 程序复位

如果程序运行异常，按一下 **EN** 按键复位开发板，程序会从头开始运行。

---

## 完成标志

- [ ] 能在 Arduino IDE 中找到并选择 ESP32S3 Dev Module
- [ ] 了解各项参数的含义和推荐值
- [ ] 知道如何使用 BOOT 和 EN 按键

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 串口无输出 | 1. 检查 `USB CDC On Boot` 设置是否与板子类型匹配（原生 USB 用 Enabled，CH340 用 Disabled）<br>2. 重新上传程序并按 EN 复位 |
| 上传失败 | 降低 Upload Speed 到 `115200`，或按住 BOOT 上传 |
| 程序卡死 | 按 EN 复位 |
| Flash Size 不确定 | N16R8 模组选 `16MB`；其他板子先选 `8MB` |

> [!TIP]
> 上传失败时，优先尝试降低 Upload Speed 和按住 BOOT 上传。

---

**[← 上一篇：macOS 安装](02_install_macos.md)** ·
[返回学习路线](00_learning_path.md) ·
**[下一篇：网页控制入门 →](04_wifi_ap_guide.md)**
