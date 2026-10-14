/*
  ESP32-S3 示例 05：MG4010-i10 RS485 基础控制

  本例程用于跑通 MG4010-i10 的厂家 RS485 私有协议。
  支持使能、停止、关闭、清除错误、读取状态 2、读取多圈角度和设置 ROM 零点。

  推荐使用课程配套 RS485/供电转接板：
  GPIO17(TX) -> 转接板 TTL-485 调试口 T
  GPIO18(RX) -> 转接板 TTL-485 调试口 R
  ESP32 5V/GND -> 转接板 USB调试 5V/G

  课程转接板已处理 RS485 收发方向，RS485_DE_RE 保持 -1。
  使用通用 RS485 模块时，把 RS485_DE_RE 改成 DE/RE 所接 GPIO，例如 16。
*/

#include <HardwareSerial.h>

#define RS485_TX      17
#define RS485_RX      18
#define RS485_DE_RE   -1
#define MOTOR_ID      0x01
#define RS485_BAUD    115200

#define CMD_SET_ZERO     0x19
#define CMD_MOTOR_OFF    0x80
#define CMD_MOTOR_STOP   0x81
#define CMD_MOTOR_RUN    0x88
#define CMD_READ_ANGLE   0x92
#define CMD_CLEAR_ERROR  0x9B
#define CMD_READ_STATE2  0x9C

HardwareSerial RS485(2);

uint8_t byteSum(const uint8_t *data, uint8_t len) {
  uint16_t sum = 0;
  for (uint8_t i = 0; i < len; i++) sum += data[i];
  return sum & 0xFF;
}

void setRS485Mode(bool tx) {
  if (tx) {
    if (RS485_DE_RE >= 0) {
      digitalWrite(RS485_DE_RE, HIGH);
      delayMicroseconds(50);
    }
  } else {
    RS485.flush();
    if (RS485_DE_RE >= 0) {
      delayMicroseconds(50);
      digitalWrite(RS485_DE_RE, LOW);
    }
  }
}

void printHex(const char *label, const uint8_t *data, uint8_t len) {
  Serial.print(label);
  for (uint8_t i = 0; i < len; i++) {
    Serial.printf("%02X ", data[i]);
  }
  Serial.println();
}

void sendCommand(uint8_t cmd, const uint8_t *data = nullptr, uint8_t dataLen = 0) {
  uint8_t header[5] = {0x3E, cmd, MOTOR_ID, dataLen, 0x00};
  header[4] = byteSum(header, 4);

  while (RS485.available()) RS485.read();

  setRS485Mode(true);
  RS485.write(header, 5);
  if (dataLen > 0 && data != nullptr) {
    RS485.write(data, dataLen);
    uint8_t dataChecksum = byteSum(data, dataLen);
    RS485.write(&dataChecksum, 1);
  }
  setRS485Mode(false);

  printHex("发送: ", header, 5);
}

bool waitBytes(uint8_t *buffer, uint8_t count, unsigned long timeoutMs) {
  uint8_t index = 0;
  unsigned long deadline = millis() + timeoutMs;
  while (millis() < deadline && index < count) {
    if (RS485.available()) {
      buffer[index++] = RS485.read();
    }
  }
  return index == count;
}

bool readFrame(uint8_t expectedCmd, uint8_t *data, uint8_t *dataLen, uint16_t timeoutMs = 200) {
  uint8_t header[5];
  uint8_t index = 0;
  unsigned long deadline = millis() + timeoutMs;

  while (millis() < deadline && index < 5) {
    if (!RS485.available()) continue;
    uint8_t b = RS485.read();
    if (index == 0 && b != 0x3E) continue;
    header[index++] = b;
  }

  if (index < 5) {
    Serial.println("响应超时");
    return false;
  }

  printHex("接收头: ", header, 5);

  if (header[4] != byteSum(header, 4)) {
    Serial.println("帧头校验失败");
    return false;
  }
  if (header[1] != expectedCmd || header[2] != MOTOR_ID) {
    Serial.println("响应命令或 ID 不匹配");
    return false;
  }

  *dataLen = header[3];
  if (*dataLen == 0) return true;
  if (*dataLen > 32) {
    Serial.println("响应数据过长");
    return false;
  }

  uint8_t payload[33];
  if (!waitBytes(payload, *dataLen + 1, timeoutMs)) {
    Serial.println("响应数据不完整");
    return false;
  }
  if (payload[*dataLen] != byteSum(payload, *dataLen)) {
    Serial.println("数据校验失败");
    return false;
  }

  memcpy(data, payload, *dataLen);
  printHex("接收数据: ", data, *dataLen);
  return true;
}

int64_t bytesToI64LE(const uint8_t *bytes) {
  uint64_t value = 0;
  for (uint8_t i = 0; i < 8; i++) {
    value |= ((uint64_t)bytes[i]) << (8 * i);
  }
  return (int64_t)value;
}

bool sendSimpleCommand(uint8_t cmd, const char *successText) {
  sendCommand(cmd);
  uint8_t data[32], len = 0;
  if (readFrame(cmd, data, &len)) {
    Serial.println(successText);
    return true;
  }
  return false;
}

void printHelp() {
  Serial.println("\n命令列表：");
  Serial.println("  r - 电机使能（进入可控制状态，不等于转动）");
  Serial.println("  t - 电机停止");
  Serial.println("  o - 电机关闭");
  Serial.println("  c - 清除错误");
  Serial.println("  s - 读取状态 2");
  Serial.println("  a - 读取多圈角度");
  Serial.println("  z - 设置当前位置为 ROM 零点，谨慎使用");
  Serial.println("  h - 显示帮助\n");
}

void readState2() {
  Serial.println("\n--- 读取状态 2 ---");
  sendCommand(CMD_READ_STATE2);

  uint8_t data[32], len = 0;
  if (!readFrame(CMD_READ_STATE2, data, &len) || len < 7) return;

  int8_t temperature = (int8_t)data[0];
  int16_t iq = (int16_t)(data[1] | (data[2] << 8));
  int16_t motorDps = (int16_t)(data[3] | (data[4] << 8));
  float outputRpm = (motorDps / 10.0f) / 6.0f;
  uint16_t encoder = (uint16_t)(data[5] | (data[6] << 8));

  Serial.printf("温度: %d C\n", temperature);
  Serial.printf("电流采样: %d\n", iq);
  Serial.printf("输出轴转速: %.1f RPM\n", outputRpm);
  Serial.printf("编码器: %u\n", encoder);
}

void readMultiAngle() {
  Serial.println("\n--- 读取多圈角度 ---");
  sendCommand(CMD_READ_ANGLE);

  uint8_t data[32], len = 0;
  if (!readFrame(CMD_READ_ANGLE, data, &len) || len < 8) return;

  int64_t angleRaw = bytesToI64LE(data);
  Serial.printf("电机侧多圈角度原始值: %lld\n", angleRaw);
  Serial.printf("电机侧角度: %.2f 度\n", angleRaw / 100.0);
  Serial.printf("输出轴角度估算: %.2f 度\n", angleRaw / 100.0 / 10.0);
}

void setZeroPosition() {
  Serial.println("\n--- 设置 ROM 零点 ---");
  Serial.println("此操作会写入电机 Flash，不要频繁使用。");
  Serial.println("确认执行请输入 Y，5 秒内未确认则取消。");

  unsigned long start = millis();
  bool confirmed = false;
  while (millis() - start < 5000) {
    if (Serial.available()) {
      char c = Serial.read();
      if (c == 'Y' || c == 'y') {
        confirmed = true;
        break;
      }
    }
  }

  while (Serial.available()) Serial.read();

  if (!confirmed) {
    Serial.println("操作已取消");
    return;
  }

  sendSimpleCommand(CMD_SET_ZERO, "零点设置命令已发送");
}

void handleCommand(char cmd) {
  switch (cmd) {
    case 'r': sendSimpleCommand(CMD_MOTOR_RUN, "电机已进入可控制状态（未设置速度，不会自行转动）"); break;
    case 't': sendSimpleCommand(CMD_MOTOR_STOP, "电机已停止"); break;
    case 'o': sendSimpleCommand(CMD_MOTOR_OFF, "电机已关闭"); break;
    case 'c': sendSimpleCommand(CMD_CLEAR_ERROR, "错误清除命令已发送"); break;
    case 's': readState2(); break;
    case 'a': readMultiAngle(); break;
    case 'z': setZeroPosition(); break;
    case 'h': printHelp(); break;
    default: Serial.println("无效命令，输入 h 查看帮助"); break;
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  if (RS485_DE_RE >= 0) {
    pinMode(RS485_DE_RE, OUTPUT);
    digitalWrite(RS485_DE_RE, LOW);
  }

  RS485.begin(RS485_BAUD, SERIAL_8N1, RS485_RX, RS485_TX);
  Serial.println("\n=== MG4010-i10 RS485 基础控制 ===");
  printHelp();
}

void loop() {
  if (!Serial.available()) return;

  char cmd = Serial.read();
  while (Serial.available()) Serial.read();
  handleCommand(cmd);
}
