import pandas as pd
import numpy as np

def calculate(file):
    # 读取你的 4 列 Excel
    df = pd.read_excel(file)

    # ===================== 重要修改 =====================
    # 第 2 列 = C列 = 时间
    # 第 3 列 = D列 = 幅值（你要的第二个波形）
    # ====================================================
    t = df.iloc[:, 2].values
    y = df.iloc[:, 3].values

    # 稳态值（最后 20% 数据平均）
    y_inf = np.mean(y[-int(len(y)*0.2):])

    # 峰值 & 峰值时间
    y_max = np.max(y)
    tp = t[np.argmax(y)]

    # 超调量 %
    delta = (y_max - y_inf) / y_inf * 100

    # 调节时间 ts（±5% 误差带）
    tol = 0.05
    upper = y_inf * (1 + tol)
    lower = y_inf * (1 - tol)

    ts = 0
    for i in range(len(y)):
        if lower <= y[i] <= upper:
            if all(lower <= y[j] <= upper for j in range(i, len(y))):
                ts = t[i]
                break

    return {
        "超调量 δ(%) 测量值": round(delta, 2),
        "峰值时间 Tp 测量值(s)": round(tp, 3),
        "调节时间 ts 测量值(s)": round(ts, 3)
    }

# ------------------- 直接处理你 6 个文件 -------------------
files = ["3.1.xlsx", "3.2.xlsx", "3.3.xlsx",
         "3.4.xlsx", "3.5.xlsx", "3.6.xlsx"]

for f in files:
    print("="*50)
    print(f"📄 {f}")
    try:
        res = calculate(f)
        print(f"超调量测量值: {res['超调量 δ(%) 测量值']} %")
        print(f"峰值时间测量值: {res['峰值时间 Tp 测量值(s)']} s")
        print(f"调节时间测量值: {res['调节时间 ts 测量值(s)']} s")
    except Exception as e:
        print(f"错误: {e}")