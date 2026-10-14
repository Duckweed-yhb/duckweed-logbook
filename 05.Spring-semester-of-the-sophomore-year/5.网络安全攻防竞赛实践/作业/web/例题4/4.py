import requests as rq
import re

# ===================== 你的信息 =====================
url = "http://10.249.14.223:32776/game"

cookie = {
    "session_id": "MTc3NTkyNzgwMXxOd3dBTkZMVU1pVVVOVFROS1NGV0FOSU5GVTFTeE12VjBGUfdU1pRVXRDvpWVVVaFEvA05VVO2ZM1dvdFVVNwVDBhT1ExQXVUZUU9fAcurcAdOC1VGjuth55FwrvZomnEXaIVeVSMQpwIRGD"
}
# ====================================================

# 【关键！！！】不再用 .json()！！！直接返回文本！！！
def send(text):
    data = {"data": text}
    response = rq.post(url=url, cookies=cookie, data=data)
    print("服务器返回：", response.text)  # 看看到底返回了什么！
    return response.text


# 启动游戏
print("🚀 启动游戏...")
res = send("ready")

# 开始答题
for i in range(100):
    try:
        # 匹配算式（万能匹配，支持加减乘除括号负数）
        match = re.search(r'([\d\(\)\+\-\*/]+)\s*\(', res)
        if not match:
            print("\n🏆 完成！")
            break

        expr = match.group(1).replace(" ", "")
        ans = eval(expr)
        print(f"第{i+1}题：{expr} = {ans}")

        # 提交答案
        res = send(str(ans))
    except:
        break

print("\n🎉 最终结果：")
print(res)