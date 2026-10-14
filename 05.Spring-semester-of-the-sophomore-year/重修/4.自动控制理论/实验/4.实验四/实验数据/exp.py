import pandas as pd
import numpy as np

# ====================== 已改为完整路径，直接运行！======================
file_list = {
    "unc_step": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/1.1.xlsx",
    "unc_mag": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/1.2.xlsx",
    "unc_phase": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/1.3.xlsx",
    "cor_step": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/2.1.xlsx",
    "cor_mag": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/2.2.xlsx",
    "cor_phase": r"e:/本科/Spring-semester-of-the-sophomore-year/4.自动控制理论/实验/4.实验四/实验数据/2.3.xlsx"
}

# ====================== 函数1：由阶跃响应数据计算【超调%、调节时间ts(2%误差带)】 ======================
def calc_step_index(t_arr, y_arr):
    y_final = np.mean(y_arr[-20:])    # 稳态值：末尾20点平均
    y_max = np.max(y_arr)
    sigma = ((y_max - y_final)/y_final)*100    # 超调百分比

    # 调节时间：首次进入±2%稳态区间不再跳出的时间
    band_low = y_final * 0.98
    band_high = y_final * 1.02
    idx_list = np.where((y_arr < band_low)|(y_arr > band_high))[0]
    if len(idx_list) == 0:
        ts = t_arr[0]
    else:
        last_out_idx = idx_list[-1]
        ts = t_arr[last_out_idx]
    return round(sigma,2), round(ts,3)

# ====================== 函数2：由波特数据找【剪切频率ωc(增益=0dB)、相角裕度γ】 ======================
def calc_bode_index(w_arr, mag_arr, phase_arr):
    diff = np.abs(mag_arr - 0)
    idx_c = np.argmin(diff)
    wc = w_arr[idx_c]
    phase_at_wc = phase_arr[idx_c]
    gamma = phase_at_wc + 180
    return round(wc,2), round(gamma,1)

# ====================== 读取并计算 ======================
# 未校正
df_unc_step = pd.read_excel(file_list["unc_step"])
t_unc = df_unc_step.iloc[:,0].values
y_unc = df_unc_step.iloc[:,1].values
unc_sigma, unc_ts = calc_step_index(t_unc, y_unc)

df_unc_mag = pd.read_excel(file_list["unc_mag"])
w_unc_m = df_unc_mag.iloc[:,0].values
mag_unc = df_unc_mag.iloc[:,1].values

df_unc_phase = pd.read_excel(file_list["unc_phase"])
phase_unc = df_unc_phase.iloc[:,1].values
unc_wc, unc_gamma = calc_bode_index(w_unc_m, mag_unc, phase_unc)

# 已校正
df_cor_step = pd.read_excel(file_list["cor_step"])
t_cor = df_cor_step.iloc[:,0].values
y_cor = df_cor_step.iloc[:,1].values
cor_sigma, cor_ts = calc_step_index(t_cor, y_cor)

df_cor_mag = pd.read_excel(file_list["cor_mag"])
w_cor_m = df_cor_mag.iloc[:,0].values
mag_cor = df_cor_mag.iloc[:,1].values

df_cor_phase = pd.read_excel(file_list["cor_phase"])
phase_cor = df_cor_phase.iloc[:,1].values
cor_wc, cor_gamma = calc_bode_index(w_cor_m, mag_cor, phase_cor)

# ====================== 输出结果 ======================
print("======= 实测结果（直接填入LaTeX）=======")
print(f"未校正 超调量：{unc_sigma}%")
print(f"未校正 调节时间：{unc_ts} s")
print(f"未校正 剪切频率：{unc_wc} rad/s")
print(f"未校正 相角裕度：{unc_gamma} °")
print("-"*30)
print(f"已校正 超调量：{cor_sigma}%")
print(f"已校正 调节时间：{cor_ts} s")
print(f"已校正 剪切频率：{cor_wc} rad/s")
print(f"已校正 相角裕度：{cor_gamma} °")

# ====================== 自动生成 LaTeX 表格 ======================
print("\n======== 填好实测值的 LaTeX 表格 ========")
latex_out = f"""
\\begin{{table}}[h]
\\centering
\\zihao{{-4}}
\\renewcommand{{\\arraystretch}}{{1.5}}
\\caption{{实验数据记录与对比表}}
\\begin{{tabular}}{{|c|c|c|c|c|}}
\\hline
\\textbf{{系统类型}} & \\textbf{{指标}} & \\textbf{{理论值}} & \\textbf{{实测值}} & \\textbf{{误差}} \\\\
\\hline
\\multirow{{4}}{{*}}{{未校正系统}} & 超调量 $\\sigma\\%$ & 60.8\\% & {unc_sigma}\\% & \\\\
\\cline{{2-5}}
 & 调节时间 $t_s$(s) & 4.0 & {unc_ts} & \\\\
\\cline{{2-5}}
 & 剪切频率 $\\omega_c$(rad/s) & $\\approx6.3$ & {unc_wc} & \\\\
\\cline{{2-5}}
 & 相角裕度 $\\gamma$ & $\\approx14^\\circ$ & ${unc_gamma}^\\circ$ & \\\\
\\hline
\\multirow{{4}}{{*}}{{已校正系统}} & 超调量 $\\sigma\\%$ & 16.3\\% & {cor_sigma}\\% & \\\\
\\cline{{2-5}}
 & 调节时间 $t_s$(s) & 0.4 & {cor_ts} & \\\\
\\cline{{2-5}}
 & 剪切频率 $\\omega_c$(rad/s) & 20 & {cor_wc} & \\\\
\\cline{{2-5}}
 & 相角裕度 $\\gamma$ & $45^\\circ$ & ${cor_gamma}^\\circ$ & \\\\
\\hline
\\end{{tabular}}
\\end{{table}}
"""
print(latex_out)