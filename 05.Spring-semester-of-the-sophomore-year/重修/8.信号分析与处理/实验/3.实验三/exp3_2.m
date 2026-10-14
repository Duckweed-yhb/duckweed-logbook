%% exp3_2.m
% 使用FFT实现卷积运算
clear;
clc;
close all;

fs = 1000;
N  = 20000;

f = (0:N-1)*fs/N;

%% ====================================================
%% 第一组数据
%% ====================================================

%% x1

x1 = zeros(1,10);

for n=0:9

    if n>=0 && n<=4
        x1(n+1)=n+1;

    elseif n>=5 && n<=9
        x1(n+1)=10-n;
    end

end

%% x2

x2 = zeros(1,12);

for n=0:11

    if n>=0 && n<=5
        x2(n+1)=2^n;

    elseif n>=6 && n<=11
        x2(n+1)=-(2^(n-6));
    end

end

%% 原序列幅度谱

mag_x1 = abs(fft(x1,N));
mag_x2 = abs(fft(x2,N));

%% FFT实现线性卷积

L = length(x1)+length(x2)-1;

Y1 = fft(x1,L);
Y2 = fft(x2,L);

y_fft = real(ifft(Y1.*Y2));

%% conv

y_conv = conv(x1,x2);

%% cconv

y_cconv = cconv(x1,x2,L);

%% 卷积结果幅度谱

mag_fft   = abs(fft(y_fft,N));
mag_conv  = abs(fft(y_conv,N));
mag_cconv = abs(fft(y_cconv,N));

%% ====================================================
%% 图1
%% ====================================================

figure('Name','第一组 图1');

subplot(2,2,1)
stem(0:length(x1)-1,x1,'filled');
grid on;
title('x_1[n]');

subplot(2,2,2)
plot(f,mag_x1);
grid on;
title('x_1幅度谱');
xlabel('Hz');

subplot(2,2,3)
stem(0:length(x2)-1,x2,'filled');
grid on;
title('x_2[n]');

subplot(2,2,4)
plot(f,mag_x2);
grid on;
title('x_2幅度谱');
xlabel('Hz');

%% ====================================================
%% 图2
%% ====================================================

figure('Name','第一组 图2');

subplot(3,1,1)
stem(y_fft,'filled');
grid on;
title('FFT卷积结果');

subplot(3,1,2)
stem(y_conv,'filled');
grid on;
title('conv卷积结果');

subplot(3,1,3)
stem(y_cconv,'filled');
grid on;
title('cconv卷积结果');

%% ====================================================
%% 图3
%% ====================================================

figure('Name','第一组 图3');

subplot(3,1,1)
plot(f,mag_fft);
grid on;
title('FFT卷积幅度谱');

subplot(3,1,2)
plot(f,mag_conv);
grid on;
title('conv卷积幅度谱');

subplot(3,1,3)
plot(f,mag_cconv);
grid on;
title('cconv卷积幅度谱');

%% ====================================================
%% 第二组数据
%% ====================================================

%% x3

x3 = zeros(1,12);

for n=0:11

    if n>=0 && n<=6
        x3(n+1)=0.8^n;

    elseif n>=7 && n<=11
        x3(n+1)=n-3;
    end

end

%% x4

x4 = zeros(1,13);

for n=0:12

    if n>=0 && n<=4
        x4(n+1)=n-1;

    elseif n>=5 && n<=12
        x4(n+1)=-(0.6^(n-6));
    end

end

%% 幅度谱

mag_x3 = abs(fft(x3,N));
mag_x4 = abs(fft(x4,N));

%% FFT卷积

L2 = length(x3)+length(x4)-1;

Y3 = fft(x3,L2);
Y4 = fft(x4,L2);

y_fft2 = real(ifft(Y3.*Y4));

%% conv

y_conv2 = conv(x3,x4);

%% cconv

y_cconv2 = cconv(x3,x4,L2);

%% 卷积频谱

mag_fft2   = abs(fft(y_fft2,N));
mag_conv2  = abs(fft(y_conv2,N));
mag_cconv2 = abs(fft(y_cconv2,N));

%% ====================================================
%% 图4
%% ====================================================

figure('Name','第二组 图1');

subplot(2,2,1)
stem(0:length(x3)-1,x3,'filled');
grid on;
title('x_3[n]');

subplot(2,2,2)
plot(f,mag_x3);
grid on;
title('x_3幅度谱');

subplot(2,2,3)
stem(0:length(x4)-1,x4,'filled');
grid on;
title('x_4[n]');

subplot(2,2,4)
plot(f,mag_x4);
grid on;
title('x_4幅度谱');

%% ====================================================
%% 图5
%% ====================================================

figure('Name','第二组 图2');

subplot(3,1,1)
stem(y_fft2,'filled');
grid on;
title('FFT卷积结果');

subplot(3,1,2)
stem(y_conv2,'filled');
grid on;
title('conv卷积结果');

subplot(3,1,3)
stem(y_cconv2,'filled');
grid on;
title('cconv卷积结果');

%% ====================================================
%% 图6
%% ====================================================

figure('Name','第二组 图3');

subplot(3,1,1)
plot(f,mag_fft2);
grid on;
title('FFT卷积幅度谱');

subplot(3,1,2)
plot(f,mag_conv2);
grid on;
title('conv卷积幅度谱');

subplot(3,1,3)
plot(f,mag_cconv2);
grid on;
title('cconv卷积幅度谱');

disp('实验完成');