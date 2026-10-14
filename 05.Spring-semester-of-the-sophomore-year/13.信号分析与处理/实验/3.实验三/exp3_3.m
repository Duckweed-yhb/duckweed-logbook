%% exp3_3.m
% FFT观察采样混叠与补零效应

clear;
clc;
close all;

f1 = 5;
f2 = 9;

t_total = 30;
N_Sample = 128;

fs_set = [5 15 40];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 第一部分
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','图1 三种采样率频谱分析');

for k = 1:length(fs_set)

    fs = fs_set(k);

    t = 0:1/fs:t_total-1/fs;

    x = sin(2*pi*f1*t) + sin(2*pi*f2*t);

    x = x(1:N_Sample);

    t_plot = t(1:N_Sample);

    X = fft(x,N_Sample);

    A = abs(X)/N_Sample;

    f = (0:N_Sample/2-1)*fs/N_Sample;

    A_half = A(1:N_Sample/2);

    % 时域

    subplot(3,2,2*k-1)

    stem(t_plot,x,'filled')

    title(['Fs=',num2str(fs),'Hz 时域'])

    xlabel('t/s')

    ylabel('Amplitude')

    grid on

    % 幅度谱

    subplot(3,2,2*k)

    plot(f,A_half,'LineWidth',1.2)

    title(['Fs=',num2str(fs),'Hz 幅度谱'])

    xlabel('Frequency(Hz)')

    ylabel('|X(f)|')

    grid on

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 第二部分
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fs = 60;

t = 0:1/fs:t_total-1/fs;

x_full = sin(2*pi*f1*t)+sin(2*pi*f2*t);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 64点补零到128点
%%%%%%%%%%%%%%%%%%%%%%%%%%

x64 = x_full(1:64);

x64_pad = [x64 zeros(1,64)];

X_pad = fft(x64_pad,128);

A_pad = abs(X_pad)/128;

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 直接采样128点
%%%%%%%%%%%%%%%%%%%%%%%%%%

x128 = x_full(1:128);

X128 = fft(x128,128);

A128 = abs(X128)/128;

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 频率轴
%%%%%%%%%%%%%%%%%%%%%%%%%%

f = (0:63)*fs/128;

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 图2
%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','图2 补零与直接采样比较');

subplot(2,2,1)

stem(0:127,x64_pad,'filled')

title('64点补零到128点')

xlabel('n')

ylabel('Amplitude')

grid on

subplot(2,2,2)

plot(f,A_pad(1:64),'LineWidth',1.2)

title('64点补零后的幅度谱')

xlabel('Frequency(Hz)')

ylabel('|X(f)|')

grid on

subplot(2,2,3)

stem(0:127,x128,'filled')

title('直接采样128点')

xlabel('n')

ylabel('Amplitude')

grid on

subplot(2,2,4)

plot(f,A128(1:64),'LineWidth',1.2)

title('直接128点采样幅度谱')

xlabel('Frequency(Hz)')

ylabel('|X(f)|')

grid on

disp('exp3_3 实验完成');