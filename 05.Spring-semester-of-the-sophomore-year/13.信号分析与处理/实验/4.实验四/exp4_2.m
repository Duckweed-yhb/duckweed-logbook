%exp4_2.m 实验四 任务2：冲激响应不变法设计巴特沃斯数字低通滤波器
%设计指标：Fs=100Hz，wp=0.4π，ws=0.8π，Rp=3dB，Rs=15dB
clear;clc;close all;

%% ==========1. 参数定义==========
Fs = 100;         %采样频率(Hz)
T = 1/Fs;         %采样周期(s)
wp = 0.4*pi;      %数字通带截止角频率(rad)
ws = 0.8*pi;      %数字阻带截止角频率(rad)
Rp = 3;           %通带波纹dB
Rs = 15;          %阻带最小衰减dB

%% ==========2. 数字角频率→模拟角频率（冲激不变无预畸变：Ω=ω/T）==========
Omega_p = wp / T;
Omega_s = ws / T;

%% ==========3. 求解模拟原型阶数与截止频率==========
[n,Wn] = buttord(Omega_p,Omega_s,Rp,Rs,'s');
fprintf('冲激不变法：模拟原型阶数 n = %d\n',n);
[b_s,a_s] = butter(n,Wn,'s'); %生成模拟H(s)系数

%% ==========4. impinvar：s域→z域 冲激响应不变变换==========
[bz,az] = impinvar(b_s,a_s,Fs); %输入模拟系数+采样频率，输出数字滤波器系数

%% ==========5. tf构建离散系统H(z)，命令行输出==========
sys_z = tf(bz,az,T);
disp('=========冲激响应不变法 数字滤波器H(z)=========');
disp(sys_z);

% 输出分式形式（方便写实验报告）
num_str = poly2str(bz,'z');
den_str = poly2str(az,'z');
fprintf('\n========= H(z) 分式形式 =========\n');
fprintf('H(z) = \n');
fprintf('        %s\n',num_str);
fprintf('--------------------------------------------\n');
fprintf('        %s\n',den_str);

%% ==========6. 绘图：脉冲响应+幅频特性（横轴单位Hz）==========
figure('Name','exp4_2 冲激响应不变法数字低通');
%子图1：单位脉冲响应h(n)
subplot(2,1,1);
impz(bz,az);
title('冲激不变法 单位脉冲响应 h(n)');
grid on;

%子图2：幅频特性，freqz求频响，归一化频率转真实Hz
subplot(2,1,2);
[H_z,w] = freqz(bz,az,1024); %1024点FFT细化频谱
mag_dB = 20*log10(abs(H_z));
f_Hz = w/(2*pi)*Fs; %归一化角频率w→实际频率Hz
plot(f_Hz,mag_dB,'LineWidth',1.2);
title('冲激不变法 幅频特性曲线');
xlabel('频率 f (Hz)');
ylabel('幅度 (dB)');
grid on;