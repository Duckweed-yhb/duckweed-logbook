%% exp3_1.m
% 实验3-1 FFT典型脉冲频谱分析（双边谱）

clear;
clc;
close all;

%% =========================
% 参数设置
%% =========================

fs = 1000;      % 采样频率
N  = 10000;     % FFT点数

%% =========================
% 构造三角脉冲 x1[n]
%% =========================

x1 = zeros(1,N);

for n = 0:N-1

    if n>=0 && n<=4
        x1(n+1)=n+1;

    elseif n>=5 && n<=8
        x1(n+1)=9-n;

    else
        x1(n+1)=0;
    end

end

%% =========================
% 构造矩形脉冲 x2[n]
%% =========================

x2 = zeros(1,N);

for n = 0:N-1

    if n>=0 && n<=6
        x2(n+1)=1;

    else
        x2(n+1)=0;
    end

end

%% =========================
% FFT
%% =========================

X1 = fft(x1,N);
X2 = fft(x2,N);

%% =========================
% 双边谱处理
%% =========================

X1_shift = fftshift(X1);
X2_shift = fftshift(X2);

%% 幅度谱

A1 = abs(X1_shift);
A2 = abs(X2_shift);

%% 相位谱

P1 = angle(X1_shift);
P2 = angle(X2_shift);

%% 去除极小值处相位抖动

P1(A1<1e-6)=0;
P2(A2<1e-6)=0;

%% =========================
% 双边频率轴
%% =========================

f = (-N/2:N/2-1)*(fs/N);

%% =========================
% 绘图
%% =========================

figure('Name','实验3-1 FFT典型脉冲频谱分析',...
       'Color','w',...
       'Position',[100 100 1200 700]);

%% ---------- 第一列：三角脉冲 ----------

subplot(3,2,1)

stem(0:19,x1(1:20),'filled');
grid on;

xlabel('n');
ylabel('幅值');

title('x_1[n] 三角脉冲时域序列');

subplot(3,2,3)

plot(f,A1,'LineWidth',1.2);

grid on;

xlabel('频率(Hz)');
ylabel('|X_1(f)|');

title('x_1[n] 双边幅度谱');

subplot(3,2,5)

plot(f,P1,'LineWidth',1.2);

grid on;

xlabel('频率(Hz)');
ylabel('相位(rad)');

title('x_1[n] 双边相位谱');

%% ---------- 第二列：矩形脉冲 ----------

subplot(3,2,2)

stem(0:19,x2(1:20),'filled');
grid on;

xlabel('n');
ylabel('幅值');

title('x_2[n] 矩形脉冲时域序列');

subplot(3,2,4)

plot(f,A2,'LineWidth',1.2);

grid on;

xlabel('频率(Hz)');
ylabel('|X_2(f)|');

title('x_2[n] 双边幅度谱');

subplot(3,2,6)

plot(f,P2,'LineWidth',1.2);

grid on;

xlabel('频率(Hz)');
ylabel('相位(rad)');

title('x_2[n] 双边相位谱');

%% 总标题

sgtitle('实验3-1 使用FFT分析典型信号频谱','FontSize',14);

disp('实验3-1运行完成');