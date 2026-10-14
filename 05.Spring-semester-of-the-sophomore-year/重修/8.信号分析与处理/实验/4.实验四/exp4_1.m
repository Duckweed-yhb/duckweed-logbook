%exp4_1.m 实验四 任务1：模拟巴特沃斯低通滤波器设计
%指标：通带截止300rad/s，阻带截止500rad/s，通带波纹3dB，阻带衰减≥20dB
clear;clc;close all;
%% ==========1. 滤波器性能指标赋值==========
Omega_p = 300;    %模拟通带截止角频率(rad/s)
Omega_s = 500;    %模拟阻带截止角频率(rad/s)
Rp = 3;           %通带最大衰减(dB)
Rs = 20;          %阻带最小衰减(dB)

%% ==========2. buttord求解滤波器最小阶数N、截止临界频率Wn==========
%带's'代表模拟滤波器设计
[n,Wn] = buttord(Omega_p,Omega_s,Rp,Rs,'s');
fprintf('模拟巴特沃斯滤波器阶数 n = %d\n',n);
fprintf('模拟滤波器临界截止角频率 Wn = %.2f rad/s\n',Wn);

%% ==========3. butter生成模拟滤波器分子b、分母a系数==========
[b,a] = butter(n,Wn,'s');

%% ==========4. tf构建系统传递函数H(s)，命令行输出==========
sys = tf(b,a);
disp('=========模拟滤波器系统传递函数 H(s)=========');
disp(sys);

% 新增：输出标准多项式分式形式
num_poly = poly2str(b,'s');
den_poly = poly2str(a,'s');
fprintf('\n========= 多项式分式形式 H(s) =========\n');
fprintf('H(s) = \n');
fprintf('        %s\n',num_poly);
fprintf('--------------------------------------------\n');
fprintf('        %s\n',den_poly);

%% ==========5. impulse求解0~0.1s冲激响应h(t)==========
t = 0:0.001:0.1;   %时间轴：步长0.001s，范围0~0.1s
h_t = impulse(b,a,t);

%% ==========6. freqs求解0~600rad/s幅频特性==========
f_axis = 0:1:600;  %频率轴范围0~600rad/s
[H_s,freq] = freqs(b,a,f_axis);
mag_dB = 20*log10(abs(H_s)); %幅度转换为dB

%% ==========7. 分2行绘图：冲激响应+幅频特性==========
figure('Name','exp4_1 模拟低通滤波器');
%子图1：时域冲激响应
subplot(2,1,1);
plot(t,h_t,'LineWidth',1.2);
title('模拟低通滤波器 单位冲激响应 h(t)');
xlabel('时间 t (s)');
ylabel('h(t)');
grid on;

%子图2：频域幅频特性，约束坐标axis([0 600 -30 8])
subplot(2,1,2);
plot(f_axis,mag_dB,'LineWidth',1.2);
title('模拟低通滤波器 幅频特性曲线');
xlabel('角频率 \Omega (rad/s)');
ylabel('幅度 (dB)');
axis([0 600 -30 8]); %严格遵照指导书坐标轴范围
grid on;