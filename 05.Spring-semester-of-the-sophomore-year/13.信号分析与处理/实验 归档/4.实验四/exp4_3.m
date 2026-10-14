%exp4_2.m 冲激响应不变法设计巴特沃斯数字低通，严格匹配本题指标
clear;clc;close all;
%% 1. 参数设置（严格按题目给定）
Fs = 100;    %采样频率Hz
T = 1/Fs;
wp = 0.4;    %数字通带截止角频率 rad
ws = 0.8;    %数字阻带截止角频率 rad
Rp = 3;      %通带最大衰减dB
Rs = 15;     %阻带最小衰减dB

%% 2. 数字角频率转模拟角频率 Ω=ω/T（冲激响应不变法线性映射）
Omega_p = wp / T;
Omega_s = ws / T;

%% 3. buttord求模拟滤波器最小阶数n和截止频率Wn（题目要求第一个调用的函数）
[n, Wn] = buttord(Omega_p, Omega_s, Rp, Rs, 's');
fprintf('模拟巴特沃斯原型阶数 n = %d\n',n);

%% 4. butter设计模拟低通H(s)（第二个调用函数）
[b_s, a_s] = butter(n, Wn, 's');

%% 5. impinvar做s→z变换得到数字滤波器系数（第三个调用函数）
[bz, az] = impinvar(b_s, a_s, Fs);

%% 6. tf生成离散系统传递函数H(z)（第四个调用函数）
sys_z = tf(bz, az, T);
disp('=====数字滤波器系统函数H(z)=====');
disp(sys_z);
% 输出分式形式方便报告抄写
num_p = poly2str(bz,'z');
den_p = poly2str(az,'z');
fprintf('\nH(z)分式形式：\nH(z) = %s / (%s)\n',num_p,den_p);

%% 7. 分2行绘图：脉冲响应 + 幅频特性
figure('Name','冲激响应不变法数字低通滤波器');
% 子图1：impz绘制脉冲响应（第五个调用函数）
subplot(2,1,1);
impz(bz,az);
title('滤波器单位脉冲响应 h(n)');
grid on;

% 子图2：freqz求频响，横轴转Hz、纵轴转dB（第六个调用函数）
subplot(2,1,2);
[H, w] = freqz(bz, az, 1024); %w范围0~π归一化角频率
mag_dB = 20*log10(abs(H));
f_Hz = w/(2*pi)*Fs; % 归一化角频率→真实频率Hz
plot(f_Hz, mag_dB, 'LineWidth',1.2);
title('滤波器幅频特性');
xlabel('频率 f (Hz)');
ylabel('幅度 (dB)');
grid on;