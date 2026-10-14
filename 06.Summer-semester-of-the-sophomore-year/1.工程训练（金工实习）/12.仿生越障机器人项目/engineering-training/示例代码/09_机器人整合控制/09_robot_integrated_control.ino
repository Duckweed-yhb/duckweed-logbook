/*
 * ========== 两电机四舵机机器人整合控制示例 ==========
 *
 * 【本例程学什么】
 * 这是最终的综合示例，把前面学过的所有模块整合到一起：
 * - 两个 RS485 电机（左轮 + 右轮，双轮差速底盘）
 * - 四个 PWM 舵机（机械臂或云台）
 * - 串口命令系统（通过电脑控制机器人）
 *
 * 【硬件配置】
 * - 两个 MG4010-i10 RS485 电机（ID=1 左轮，ID=2 右轮）
 * - 四个 PWM 舵机（连接到 GPIO10/11/12/13）
 * - ESP32-S3 开发板
 * - 独立 12V~24V 电源（给电机供电）
 * - 独立 5V 电源（给舵机供电，至少 3A）
 *
 * 【接线说明】
 * 重要提醒：舵机和电机必须使用独立电源，不能从 ESP32 取电。
 *
 * 1. RS485 电机接线（课程转接板）：
 *   ESP32 GPIO17 → 转接板 TTL-485 调试口 T（发送数据）
 *   ESP32 GPIO18 → 转接板 TTL-485 调试口 R（接收数据）
 *   ESP32 GND    → 转接板 GND（必须共地）
 *
 * 2. 舵机信号线接线：
 *   舵机1信号线（橙/黄） → GPIO10
 *   舵机2信号线（橙/黄） → GPIO11
 *   舵机3信号线（橙/黄） → GPIO12
 *   舵机4信号线（橙/黄） → GPIO13
 *
 * 3. 舵机电源接线：
 *   所有舵机 VCC（红线） → 独立 5V 电源 +（不能接 ESP32 的 3.3V 或 5V）
 *   所有舵机 GND（棕/黑） → 独立 5V 电源 -
 *   独立 5V 电源 - → ESP32 GND（必须共地）
 *
 * 4. 共地连接：
 *   ESP32 GND ─┬─ 转接板 GND
 *              ├─ 电机电源 GND（-）
 *              └─ 舵机电源 GND（-）
 *
 *   为什么必须共地？
 *   - RS485 通信需要共同的电压参考点，否则"高电平"和"低电平"无法判断
 *   - 舵机 PWM 信号需要共同的 0V 参考，否则信号电平错乱
 *
 * 【串口命令格式】（波特率 115200，行尾选择"换行"或"Both NL & CR"）
 *   v <左速度> <右速度>                设置电机速度（RPM，范围 -60 到 60）
 *   pose <角度1> <角度2> <角度3> <角度4>   设置四舵机角度（0-180°）
 *   home                               所有舵机回中位（90°），电机停止
 *   stop                               紧急停止所有电机
 *
 * 【命令示例】
 *   v 20 20          两轮同速前进（直线前进）
 *   v -20 -20        两轮同速后退（直线后退）
 *   v 20 -20         左轮前进、右轮后退（原地左转）
 *   v -20 20         左轮后退、右轮前进（原地右转）
 *   v 30 10          左快右慢（向右转弯）
 *   pose 45 90 135 0 设置四个舵机角度
 *   home             回到初始姿态（舵机 90°，电机停止）
 *   stop             紧急停止（只停电机）
 *
 * 【完整教程】
 * 详见 README.md 文件，包含：
 * - 详细接线图和说明
 * - 预期现象和测试方法
 * - 常见问题排查
 * - 代码学习要点（非阻塞设计、单位换算、校验和、小端序）
 */

#include <Arduino.h>

// ========== 引脚定义 ==========
const int RS485_TX = 17;        // RS485 发送引脚（连接转接板 T）
const int RS485_RX = 18;        // RS485 接收引脚（连接转接板 R）
const int RS485_DE_RE = -1;     // 课程转接板不使用 DE/RE 控制，设为 -1
                                // 如果用通用 RS485 模块，需要设置 DE/RE 引脚（如 16）

const int SERVO_PINS[4] = {10, 11, 12, 13}; // 四个舵机信号引脚

// ========== RS485 串口实例 ==========
HardwareSerial RS485(2);  // 使用 UART2（与单电机例程 05-08 一致）

// ========== MG4010 协议常量 ==========
// 什么是"协议"？
// MG4010 电机通过 RS485 通信，必须按照它规定的"数据格式"发送命令。
// 就像寄快递要写"收件人、地址、电话"一样，电机也要求特定的数据格式。

const uint8_t FRAME_HEADER = 0x3E;     // 帧头：每条命令的开头标志（固定值 0x3E）
const uint8_t CMD_MOTOR_RUN = 0x88;    // 使能命令：让电机进入可控制状态
const uint8_t CMD_MOTOR_STOP = 0x81;   // 停止命令：告诉电机"停止转动"
const uint8_t CMD_SPEED_MODE = 0xA2;   // 速度控制命令：设置电机转速
const uint8_t CMD_READ_STATE2 = 0x9C;  // 读取状态2命令（本例未使用，预留）

const uint8_t MOTOR_ID_LEFT = 1;       // 左电机 ID（必须提前用调试工具设置好）
const uint8_t MOTOR_ID_RIGHT = 2;      // 右电机 ID（必须提前用调试工具设置好）

// ========== 单位换算常量 ==========
// 为什么要换算单位？
// 用户习惯用"RPM"（每分钟转多少圈），但电机协议要求用"dps"（每秒转多少度）。
// 而且 MG4010 有 1:10 的减速器，输出轴转 1 圈，电机内部转 10 圈。

const float REDUCTION = 10.0f;         // 减速比 1:10（输出轴转 1 圈 = 电机转 10 圈）
const float RPM_TO_DPS = 6.0f;         // RPM 转 dps：1 RPM = 6 dps
                                       // 推导：1 圈 = 360°，1 分钟 = 60 秒，360÷60 = 6

// ========== PWM 配置 ==========
// 舵机是通过 PWM（脉宽调制）信号控制的。
// 什么是 PWM？想象成"电信号的摩斯密码"，通过脉冲宽度告诉舵机"转到多少度"。

const int PWM_FREQ = 50;               // 舵机 PWM 频率 50Hz（每秒 50 个脉冲）
                                       // 为什么是 50Hz？这是模拟舵机的标准频率
const int PWM_RESOLUTION = 14;         // ESP32-S3 舵机 PWM 使用 14 位分辨率
const int SERVO_MIN_US = 500;          // 0° 对应 500us
const int SERVO_MAX_US = 2500;         // 180° 对应 2500us
const int SERVO_PERIOD_US = 20000;     // 50Hz PWM 周期为 20ms

// ========== 安全限制 ==========
// 为什么要限制速度？
// 1. 防止电机过载损坏（超速会导致电流过大）
// 2. 防止机器人动作过快导致失控
// 3. 新手测试时更安全

const float MAX_MOTOR_RPM = 60.0f;     // 输出轴最大转速 60 RPM（安全限制）
const float MIN_MOTOR_RPM = -60.0f;    // 输出轴最小转速 -60 RPM（负数表示反转）

// ========== 全局变量 ==========
// 为什么需要全局变量？
// 舵机需要"记住"目标角度，在主循环中持续刷新 PWM。
// 如果用局部变量，函数结束后数据就丢失了。

uint32_t servoTargets[4];                         // 舵机目标 PWM 值，setup() 中初始化到 90°
unsigned long lastServoUpdate = 0;                // 上次舵机更新的时间戳（毫秒）
const unsigned long servoUpdateInterval = 20;     // 舵机更新间隔 20ms（50Hz 刷新率）
                                                  // 为什么是 20ms？舵机 PWM 频率是 50Hz，1000ms÷50 = 20ms

uint32_t angleToDuty(int angle);
void setAllServoAngles(int angle1, int angle2, int angle3, int angle4);

// ========== RS485 通信函数 ==========

void setRS485Mode(bool tx) {
  if (RS485_DE_RE < 0) return;

  if (tx) {
    digitalWrite(RS485_DE_RE, HIGH);
    delayMicroseconds(50);
  } else {
    RS485.flush();
    delayMicroseconds(50);
    digitalWrite(RS485_DE_RE, LOW);
  }
}

// 计算校验和（累加和，取低8位）
// 什么是"校验和"（Checksum）？
// 把数据包中的所有字节相加，取结果的低 8 位，用于检测传输错误。
// 类比：寄快递时包裹上的条形码，扫描后能判断包裹信息是否正确。
//
// 为什么需要校验和？
// RS485 长距离传输容易受电磁干扰，某个字节可能变成错误的值。
// 电机收到数据后会重新计算校验和，如果不匹配就丢弃这条命令。
uint8_t calculateChecksum(const uint8_t* data, int length) {
  uint16_t sum = 0;
  for (int i = 0; i < length; i++) {
    sum += data[i];  // 累加所有字节
  }
  return (uint8_t)(sum & 0xFF);  // 取低 8 位（相当于 sum % 256）
}

// 发送命令到指定电机
// MG4010 协议格式：0x3E + cmd + id + dataLen + headerChecksum + [data] + dataChecksum
//
// 数据帧结构（每个方框代表 1 个字节）：
// ┌──────┬──────┬──────┬──────┬──────────┬──────────┐
// │ 帧头 │ 命令 │ ID   │ 长度 │ 头校验   │ 数据     │ 数据校验 │
// │ 0x3E │ cmd  │ id   │ len  │ checksum │ [data]   │ checksum │
// └──────┴──────┴──────┴──────┴──────────┴──────────┴──────────┘
//
// 示例：发送"停止电机 ID=1"
// 0x3E + 0x81 + 0x01 + 0x00 + checksum(0x3E+0x81+0x01+0x00)
// = 0x3E + 0x81 + 0x01 + 0x00 + 0xC0
void sendMotorCommand(uint8_t motorID, uint8_t cmd, const uint8_t* params = nullptr, uint8_t paramLen = 0) {
  uint8_t frame[16];  // 临时缓冲区，存放要发送的完整数据帧
  int idx = 0;        // 当前写入位置

  frame[idx++] = FRAME_HEADER;  // 帧头 0x3E（固定值）
  frame[idx++] = cmd;            // 命令字节（如 0x88 使能、0x81 停止）
  frame[idx++] = motorID;        // 电机 ID（1 或 2）
  frame[idx++] = paramLen;       // 数据长度（如速度命令需要 4 字节参数）
  frame[idx++] = calculateChecksum(frame, 4);  // 帧头校验，包含 0x3E

  // 添加参数数据（如果有的话）
  if (params != nullptr && paramLen > 0) {
    for (int i = 0; i < paramLen; i++) {
      frame[idx++] = params[i];
    }
    frame[idx++] = calculateChecksum(params, paramLen);  // 数据区校验
  }

  // 通过 RS485 发送完整数据帧
  setRS485Mode(true);
  RS485.write(frame, idx);
  RS485.flush();  // 等待数据发送完成
  setRS485Mode(false);
}

// 设置电机速度（RPM）
// 这个函数完成了三层单位换算：RPM → dps → 协议值
//
// 【单位换算流程】
// 用户输入 20 RPM（每分钟转 20 圈）
//   ↓ 第一步：RPM 转 dps（度每秒）
// 输出轴速度：20 × 6 = 120 dps
//   ↓ 第二步：输出轴 dps → 电机侧 dps（考虑减速比）
// 电机侧速度：120 × 10 = 1200 dps
//   ↓ 第三步：dps → 协议值（MG4010 规定 1 LSB = 0.01 dps）
// 协议值：1200 × 100 = 120000
//
// 【什么是"小端序"？】
// 120000 = 0x0001D4C0（十六进制）需要 4 个字节传输：
// 小端序：先发低位字节，后发高位字节
// 发送顺序：0xC0, 0xD4, 0x01, 0x00
//
// 为什么是小端序？因为 MG4010 协议规定如此，必须遵守。
void setMotorSpeed(uint8_t motorID, float rpm) {
  // 安全限制：防止速度超出电机承受范围
  rpm = constrain(rpm, MIN_MOTOR_RPM, MAX_MOTOR_RPM);

  // 单位换算（三步走）
  // 步骤1：输出轴 RPM → 输出轴 dps
  // 步骤2：输出轴 dps → 电机侧 dps（乘以减速比）
  // 步骤3：电机侧 dps → 协议值（乘以 100，因为 1 LSB = 0.01 dps）
  float motorDps = rpm * RPM_TO_DPS * REDUCTION;  // 电机侧 dps
  int32_t speedValue = (int32_t)(motorDps * 100.0f); // 协议值（有符号 32 位整数）

  // 构造参数：4 字节小端序（Little-Endian）
  // 把 32 位整数拆成 4 个字节，先发低位
  uint8_t params[4];
  params[0] = (speedValue) & 0xFF;        // 最低 8 位（Byte 0）
  params[1] = (speedValue >> 8) & 0xFF;   // 第 9~16 位（Byte 1）
  params[2] = (speedValue >> 16) & 0xFF;  // 第 17~24 位（Byte 2）
  params[3] = (speedValue >> 24) & 0xFF;  // 最高 8 位（Byte 3）

  // 发送两条命令（MG4010 要求先使能后设速）
  sendMotorCommand(motorID, CMD_MOTOR_RUN);         // 先发"使能"命令
  delay(10);                                         // 等待 10ms（电机处理时间）
  sendMotorCommand(motorID, CMD_SPEED_MODE, params, 4); // 再发"速度"命令
}

// 停止电机
void stopMotor(uint8_t motorID) {
  sendMotorCommand(motorID, CMD_MOTOR_STOP);
}

// 停止所有电机
void stopAllMotors() {
  stopMotor(MOTOR_ID_LEFT);
  delay(5);
  stopMotor(MOTOR_ID_RIGHT);
}

// ========== 舵机控制函数 ==========

// 初始化所有舵机
// ESP32-S3 使用 LEDC（LED Control）外设生成 PWM 信号。
// 为什么叫 LEDC？因为 ESP32 设计时这个外设主要用于 LED 调光，但也能控制舵机。
void initServos() {
  setAllServoAngles(90, 90, 90, 90);
  for (int i = 0; i < 4; i++) {
    // 绑定引脚到 LEDC 通道，设置频率和分辨率
    ledcAttach(SERVO_PINS[i], PWM_FREQ, PWM_RESOLUTION);
    // 写入初始 PWM 值（90° 中位）
    ledcWrite(SERVO_PINS[i], servoTargets[i]);
  }
}

// 更新所有舵机 PWM 输出（非阻塞）
// 【为什么要"非阻塞"？】
// 如果用 delay() 卡住主循环，电机命令就无法及时处理，串口也无法接收新命令。
// 非阻塞设计：用 millis() 记录时间，只有到了更新时刻才执行，不会卡住其他任务。
//
// 【工作原理】
// 每次调用检查：现在的时间 - 上次更新时间 >= 20ms？
// 如果是，更新舵机 PWM；如果否，直接返回（不浪费时间）
void updateServos() {
  unsigned long now = millis();  // 获取当前时间戳（开机后经过的毫秒数）
  if (now - lastServoUpdate >= servoUpdateInterval) {
    lastServoUpdate = now;  // 更新时间戳
    for (int i = 0; i < 4; i++) {
      ledcWrite(SERVO_PINS[i], servoTargets[i]);  // 刷新 PWM 输出
    }
  }
}

// 角度转 PWM 占空比
// 输入：0~180°
// 输出：14 位占空比数值（对应 0.5ms~2.5ms 脉宽）
//
// 【为什么需要这个函数？】
// 用户习惯用"角度"（0°、90°、180°），但 ESP32 的 ledcWrite() 要求输入"占空比数值"。
// 这个函数做的就是"角度 → 占空比"的映射。
uint32_t angleToDuty(int angle) {
  angle = constrain(angle, 0, 180);  // 限制在 0~180° 范围内
  int pulseUs = map(angle, 0, 180, SERVO_MIN_US, SERVO_MAX_US);
  uint32_t maxDuty = (1UL << PWM_RESOLUTION) - 1;
  return (uint32_t)((pulseUs * maxDuty) / SERVO_PERIOD_US);
}

// 设置单个舵机角度
// servoID：1~4（舵机编号）
// angle：0~180°
void setServoAngle(int servoID, int angle) {
  if (servoID >= 1 && servoID <= 4) {
    servoTargets[servoID - 1] = angleToDuty(angle);  // 数组下标从 0 开始，所以减 1
  }
}

// 设置所有舵机角度（一次设置四个）
void setAllServoAngles(int angle1, int angle2, int angle3, int angle4) {
  servoTargets[0] = angleToDuty(angle1);
  servoTargets[1] = angleToDuty(angle2);
  servoTargets[2] = angleToDuty(angle3);
  servoTargets[3] = angleToDuty(angle4);
}

// 回中位（所有舵机 90°）
// 同时停止所有电机，让机器人恢复到安全姿态
void homePosition() {
  setAllServoAngles(90, 90, 90, 90);
  stopAllMotors();
  Serial.println("回到初始姿态：舵机 90°，电机停止");
}

// ========== 串口命令解析 ==========

// 处理串口命令
// 这个函数从串口读取一行文本，解析成命令和参数，然后执行对应的动作。
//
// 【命令格式】
// v 20 20          → 关键字 "v" + 两个参数（左速度、右速度）
// pose 45 90 135 0 → 关键字 "pose" + 四个参数（四个舵机角度）
// home             → 只有关键字，没有参数
//
// 【解析流程】
// 1. 读取一行文本（遇到换行符 '\n' 停止）
// 2. 去掉首尾空格
// 3. 提取第一个单词作为"命令关键字"
// 4. 剩余部分作为"参数字符串"
// 5. 根据命令关键字分别处理
void processCommand() {
  if (!Serial.available()) return;  // 如果串口没有数据，直接返回

  String input = Serial.readStringUntil('\n');  // 读取一行（到换行符为止）
  input.trim();  // 去掉首尾空格和换行符

  if (input.length() == 0) return;  // 空行直接忽略

  Serial.print("收到命令: ");
  Serial.println(input);

  // 解析命令：提取第一个单词作为命令关键字
  int spaceIndex = input.indexOf(' ');  // 找到第一个空格的位置
  String cmd = (spaceIndex > 0) ? input.substring(0, spaceIndex) : input;
  String args = (spaceIndex > 0) ? input.substring(spaceIndex + 1) : "";

  cmd.toLowerCase();  // 转小写（不区分大小写，v 和 V 都能识别）

  // ========== 命令 1：v <左速度> <右速度> ==========
  if (cmd == "v") {
    // 示例输入："v 20 20"
    // 解析：args = "20 20"，需要拆成两个数字
    int space2 = args.indexOf(' ');  // 找到第二个空格
    if (space2 > 0) {
      float leftRPM = args.substring(0, space2).toFloat();      // 左速度
      float rightRPM = args.substring(space2 + 1).toFloat();   // 右速度

      setMotorSpeed(MOTOR_ID_LEFT, leftRPM);
      delay(10);  // 等待第一个电机命令处理完
      setMotorSpeed(MOTOR_ID_RIGHT, rightRPM);

      Serial.printf("设置速度：左 %.1f RPM，右 %.1f RPM\n", leftRPM, rightRPM);
    } else {
      Serial.println("错误：需要两个速度参数，如 v 20 20");
    }
  }
  // ========== 命令 2：pose <角度1> <角度2> <角度3> <角度4> ==========
  else if (cmd == "pose") {
    // 示例输入："pose 45 90 135 0"
    // 解析：args = "45 90 135 0"，需要拆成四个数字
    int angles[4];
    int count = 0;
    int lastIndex = 0;

    // 循环提取四个角度值
    for (int i = 0; i < 4; i++) {
      int nextSpace = args.indexOf(' ', lastIndex);  // 找到下一个空格
      String angleStr;

      if (i < 3) {
        // 前三个角度：提取到下一个空格为止
        if (nextSpace > lastIndex) {
          angleStr = args.substring(lastIndex, nextSpace);
          lastIndex = nextSpace + 1;
        } else {
          break;  // 如果没找到空格，说明参数不够
        }
      } else {
        // 第四个角度：提取到字符串末尾
        angleStr = args.substring(lastIndex);
      }

      angles[count++] = angleStr.toInt();  // 字符串转整数
    }

    if (count == 4) {
      setAllServoAngles(angles[0], angles[1], angles[2], angles[3]);
      Serial.printf("设置舵机角度：%d° %d° %d° %d°\n",
                    angles[0], angles[1], angles[2], angles[3]);
    } else {
      Serial.println("错误：需要四个角度参数，如 pose 45 90 135 0");
    }
  }
  // ========== 命令 3：home（回到初始姿态）==========
  else if (cmd == "home") {
    homePosition();
  }
  // ========== 命令 4：stop（紧急停止）==========
  else if (cmd == "stop") {
    stopAllMotors();
    Serial.println("紧急停止：所有电机已停止");
  }
  // ========== 未知命令：显示帮助信息 ==========
  else {
    Serial.println("未知命令。可用命令：");
    Serial.println("  v <左速度> <右速度>    设置电机速度（RPM）");
    Serial.println("  pose <角1> <角2> <角3> <角4>  设置舵机角度");
    Serial.println("  home                   回到初始姿态");
    Serial.println("  stop                   紧急停止");
  }
}

// ========== 主程序 ==========

void setup() {
  // 初始化 USB 串口（用于电脑调试和发送命令）
  Serial.begin(115200);
  delay(1000);  // 等待串口稳定（ESP32-S3 的 USB CDC 需要初始化时间）

  Serial.println("\n========== 两电机四舵机机器人整合控制 ==========");
  Serial.println("上电前确认：");
  Serial.println("   1. 电机和舵机使用独立电源（不从 ESP32 取电）");
  Serial.println("   2. 所有 GND 已连接（ESP32、电机电源、舵机电源、转接板）");
  Serial.println("   3. 两个电机 ID 分别为 1 和 2");
  Serial.println("   4. 首次测试使用低速（如 v 10 10）");
  Serial.println("=====================================================\n");

  // 初始化 RS485 串口（用于与电机通信）
  // SERIAL_8N1：8 位数据位，无校验位，1 位停止位（标准配置）
  RS485.begin(115200, SERIAL_8N1, RS485_RX, RS485_TX);
  if (RS485_DE_RE >= 0) {
    pinMode(RS485_DE_RE, OUTPUT);
    digitalWrite(RS485_DE_RE, LOW);
  }

  // 初始化舵机（设置 PWM 通道，初始角度 90°）
  initServos();
  Serial.println("舵机初始化完成（90° 中位）");

  // 设置串口超时（避免 readStringUntil 阻塞太久）
  Serial.setTimeout(50);  // 50ms 超时

  Serial.println("\n可用命令：");
  Serial.println("  v <左速度> <右速度>    设置电机速度（RPM，-60 到 60）");
  Serial.println("  pose <角1> <角2> <角3> <角4>  设置舵机角度（0-180°）");
  Serial.println("  home                   回到初始姿态");
  Serial.println("  stop                   紧急停止");
  Serial.println("\n等待命令...\n");
}

void loop() {
  // 【主循环设计原则】
  // 1. 不使用长时间 delay()，保持循环快速执行（每次几毫秒）
  // 2. 每个函数都是"非阻塞"的，不会卡住其他任务
  // 3. 舵机、电机、串口三个模块"并行"运行（实际是快速轮流执行）

  // 处理串口命令（如果有新命令就解析执行）
  processCommand();

  // 非阻塞更新舵机（每 20ms 自动刷新一次 PWM）
  updateServos();

  // 主循环结束，立即开始下一轮
  // 这样设计的好处：
  // - 电机命令发送不会卡住舵机刷新
  // - 舵机转动不会阻塞串口接收
  // - 整个系统响应速度快，没有卡顿感
}
