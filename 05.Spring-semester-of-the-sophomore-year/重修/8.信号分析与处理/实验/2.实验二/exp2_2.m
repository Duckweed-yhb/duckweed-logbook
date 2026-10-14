%% 实验二：频域采样验证（独立程序）
clear; clc; close all;

%% 构造三角波序列 x(n)
M = 27;
n_x = 0:M-1;
x = zeros(1,M);
for nn = 0:M-1
    if nn <= 13
        x(nn+1) = nn+1;
    else
        x(nn+1) = 27-nn;
    end
end

%% 原信号完整频谱
N_full = 1024;
X_full = fft(x, N_full);
Amp_full = abs(X_full);
Om = linspace(0, 2*pi, N_full);

%% 频域 32 点采样 + IDFT
N32 = 32;
X32 = fft(x, N32);
x32 = real(ifft(X32, N32));

%% 频域 16 点采样 + IDFT
N16 = 16;
X16 = fft(x, N16);
x16 = real(ifft(X16, N16));

%% 绘图：3行2列
% 第1行：原图时域｜原图频谱
subplot(3,2,1);
stem(n_x, x, 'filled');
title('原始三角波序列 x(n)');
xlabel('n'); ylabel('x(n)'); grid on;

subplot(3,2,2);
plot(Om, Amp_full);
title('原序列完整频谱 |X(e^{j\Omega})|');
xlabel('\Omega(rad)'); ylabel('幅度'); grid on;

% 第2行：16点时域｜16点频域
subplot(3,2,3);
stem(0:N16-1, x16, 'filled');
title('N=16点IDFT还原 x_{16}(n)');
xlabel('n'); ylabel('x_{16}(n)'); grid on;

subplot(3,2,4);
stem(linspace(0,2*pi,N16), abs(X16), 'filled');
title('16点频域采样 |X_{16}(k)|');
xlabel('\Omega(rad)'); ylabel('幅度'); grid on;

% 第3行：32点时域｜32点频域
subplot(3,2,5);
stem(0:N32-1, x32, 'filled');
title('N=32点IDFT还原 x_{32}(n)');
xlabel('n'); ylabel('x_{32}(n)'); grid on;

subplot(3,2,6);
stem(linspace(0,2*pi,N32), abs(X32), 'filled');
title('32点频域采样 |X_{32}(k)|');
xlabel('\Omega(rad)'); ylabel('幅度'); grid on;