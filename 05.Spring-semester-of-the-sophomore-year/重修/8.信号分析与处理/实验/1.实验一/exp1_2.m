%% 实验二：离散周期方波信号的分解与合成（匹配实验现象版）
clear; clc; close all;

%% (1) 参数设置
T = 4;                  % 信号周期
N1 = 60;  dt1 = T/N1;   % 周期内60个采样点
N2 = 120; dt2 = T/N2;   % 周期内120个采样点

t1 = linspace(0, T-dt1, N1);
t2 = linspace(0, T-dt2, N2);

t_smooth1 = linspace(0, T, 500);
t_smooth2 = linspace(0, T, 500);

%% (2) 生成离散周期方波
x1 = double(mod(t1, T)>=2) - double(mod(t1, T)<2);
x2 = double(mod(t2, T)>=2) - double(mod(t2, T)<2);

x1_smooth = double(mod(t_smooth1, T)>=2) - double(mod(t_smooth1, T)<2);
x2_smooth = double(mod(t_smooth2, T)>=2) - double(mod(t_smooth2, T)<2);

%% ==================== N=60 计算 ====================
% DFS 正变换
N = N1;
X1 = zeros(1, N);
for k = 0:N-1
    for n = 0:N-1
        X1(k+1) = X1(k+1) + x1(n+1) * exp(-1j * 2*pi * k * n / N);
    end
end
mag1 = abs(X1);

% 只保留前30阶奇次谐波
X1_30 = zeros(1, N1);
K_max = 30;
for k = 0:K_max
    if mod(k,2) ~= 0
        X1_30(k+1) = X1(k+1);
    end
end

% IDFS 合成 30次谐波
x1_30 = zeros(1, N1);
for n = 0:N1-1
    for k = 0:N1-1
        x1_30(n+1) = x1_30(n+1) + X1_30(k+1) * exp(1j * 2*pi * k * n / N1);
    end
end
x1_30 = real(x1_30 / N1);

% 30次谐波 连续包络
x1_30_smooth = zeros(size(t_smooth1));
for ii = 1:length(t_smooth1)
    tn = t_smooth1(ii);
    for k = 0:N1-1
        x1_30_smooth(ii) = x1_30_smooth(ii) + X1_30(k+1)*exp(1j*2*pi*k*tn/T);
    end
end
x1_30_smooth = real(x1_30_smooth / N1);

% 完整60次谐波（全部分量）
x1_60 = zeros(1, N1);
for n = 0:N1-1
    for k = 0:N1-1
        x1_60(n+1) = x1_60(n+1) + X1(k+1) * exp(1j * 2*pi * k * n / N1);
    end
end
x1_60 = real(x1_60 / N1);

% 60次谐波 连续包络
x1_60_smooth = zeros(size(t_smooth1));
for ii = 1:length(t_smooth1)
    tn = t_smooth1(ii);
    for k = 0:N1-1
        x1_60_smooth(ii) = x1_60_smooth(ii) + X1(k+1)*exp(1j*2*pi*k*tn/T);
    end
end
x1_60_smooth = real(x1_60_smooth / N1);

%% ==================== N=120 计算 ====================
% DFS 正变换
N = N2;
X2 = zeros(1, N);
for k = 0:N-1
    for n = 0:N-1
        X2(k+1) = X2(k+1) + x2(n+1) * exp(-1j * 2*pi * k * n / N);
    end
end
mag2 = abs(X2);

% 只保留前30阶奇次谐波
X2_30 = zeros(1, N2);
K_max = 30;
for k = 0:K_max
    if mod(k,2) ~= 0
        X2_30(k+1) = X2(k+1);
    end
end

% IDFS 合成 30次谐波
x2_30 = zeros(1, N2);
for n = 0:N2-1
    for k = 0:N2-1
        x2_30(n+1) = x2_30(n+1) + X2_30(k+1) * exp(1j * 2*pi * k * n / N2);
    end
end
x2_30 = real(x2_30 / N2);

% 30次谐波 连续包络
x2_30_smooth = zeros(size(t_smooth2));
for ii = 1:length(t_smooth2)
    tn = t_smooth2(ii);
    for k = 0:N2-1
        x2_30_smooth(ii) = x2_30_smooth(ii) + X2_30(k+1)*exp(1j*2*pi*k*tn/T);
    end
end
x2_30_smooth = real(x2_30_smooth / N2);

% ========== 关键修改：前60阶直接截断、后半段置零，不做共轭延拓 ==========
X2_60 = zeros(1, N2);
K_max2 = 60;
for k = 0:K_max2
    X2_60(k+1) = X2(k+1);
end

% IDFS 合成 60次谐波（幅值为 ±0.5，与实验一致）
x2_60 = zeros(1, N2);
for n = 0:N2-1
    for k = 0:N2-1
        x2_60(n+1) = x2_60(n+1) + X2_60(k+1) * exp(1j * 2*pi * k * n / N2);
    end
end
x2_60 = real(x2_60 / N2);

% 60次谐波 连续包络
x2_60_smooth = zeros(size(t_smooth2));
for ii = 1:length(t_smooth2)
    tn = t_smooth2(ii);
    for k = 0:N2-1
        x2_60_smooth(ii) = x2_60_smooth(ii) + X2(k+1)*exp(1j*2*pi*k*tn/T);
    end
end
x2_60_smooth = real(x2_60_smooth / N2);

%% ==================== 绘图部分（频谱奇数点连线） ====================
% 窗口1：N=60
figure('Name','离散方波 N=60');
subplot(2,2,1);
stem(t1, x1, 'filled','b');
grid on; title('原始方波(N=60)'); axis([0 T -1.5 1.5]);

subplot(2,2,2);
k_odd1 = 1:2:N1-1;
mag_odd1 = mag1(k_odd1+1);
stem(0:N1-1, mag1, 'filled','b'); hold on;
plot(k_odd1, mag_odd1, 'r','LineWidth',1.2);
grid on; title('DFS幅度谱(N=60)'); hold off;

subplot(2,2,3);
stem(t1, x1_30, 'filled','b');
grid on; title('30次谐波合成(N=60)'); axis([0 T -1.5 1.5]);

subplot(2,2,4);
stem(t1, x1_60, 'filled','b');
grid on; title('60次谐波合成(N=60)'); axis([0 T -1.5 1.5]);

% 窗口2：N=120
figure('Name','离散方波 N=120');
subplot(2,2,1);
stem(t2, x2, 'filled','b');
grid on; title('原始方波(N=120)'); axis([0 T -1.5 1.5]);

subplot(2,2,2);
k_odd2 = 1:2:N2-1;
mag_odd2 = mag2(k_odd2+1);
stem(0:N2-1, mag2, 'filled','b'); hold on;
plot(k_odd2, mag_odd2, 'r','LineWidth',1.2);
grid on; title('DFS幅度谱(N=120)'); hold off;

subplot(2,2,3);
stem(t2, x2_30, 'filled','b');
grid on; title('30次谐波合成(N=120)'); axis([0 T -1.5 1.5]);

subplot(2,2,4);
stem(t2, x2_60, 'filled','b');
grid on; title('60次谐波合成(N=120)'); axis([0 T -1.5 1.5]);