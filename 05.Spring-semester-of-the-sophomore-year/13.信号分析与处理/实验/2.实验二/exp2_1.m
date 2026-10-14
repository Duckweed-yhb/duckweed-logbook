%% 实验二：时域采样验证（独立程序）
clear; clc; close all;

%% 参数设置
A = 444.128;
alpha = 50*sqrt(2)*pi;
omega1 = 50*sqrt(2)*pi;
Tp = 0.064;        % 观测时长64ms
Fs_set = [1000,300,200]; % 三种采样频率

%% 绘图
figure('Name','时域采样验证');
for i = 1:3
    Fs = Fs_set(i);
    Ts = 1/Fs;
    N = round(Tp*Fs);
    n = 0:N-1;
    t = n*Ts;
    
    % 生成采样序列
    x = A.*exp(-alpha.*t).*sin(omega1.*t);
    
    % FFT
    NFFT = 2^nextpow2(N*10);
    Xk = fft(x,NFFT)/N;
    Amp = abs(Xk);
    f = linspace(0,Fs,NFFT);
    
    % 时域波形
    subplot(3,2,2*i-1);
    stem(t,x,'filled','MarkerSize',2);
    xlabel('时间 t(s)');ylabel('x(n)');
    title(['Fs=',num2str(Fs),'Hz 时域采样波形']);
    grid on;
    
    % 幅度频谱（自适应横轴范围，删掉固定xlim([0,500])）
    subplot(3,2,2*i);
    plot(f,Amp);
    xlabel('频率 f(Hz)');ylabel('|X(f)|');
    title(['Fs=',num2str(Fs),'Hz 幅度频谱']);
    % 自适应截取有效频谱区间
    thr = max(Amp)*0.005;
    idx = find(Amp>thr);
    if ~isempty(idx)
        xlim([f(idx(1)), f(idx(end))]);
    end
    grid on;
end