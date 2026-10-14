%% exp3_4_青花瓷_ADSR修复_脚本版(无函数报错)
% 音乐合成实验 | 标准ADSR包络 + 相位/坐标全部达标
clear;
clc;
close all;

%% 1. 基础参数
Fs = 8000;           % 采样频率(Hz)
bpm = 72;            % 速度
beat_dur = 60 / bpm; % 四分音符时长(s)
N_beat = round(Fs * beat_dur); % 单个四分音符采样点数

% ADSR四段占比
A_ratio = 0.15;   % Attack 起音
D_ratio = 0.15;   % Decay 衰减
S_ratio = 0.50;   % Sustain 保持
R_ratio = 0.20;   % Release 释放
S_level = 0.8;    % 保持段电平

%% 2. 音符-频率映射 (0=休止符)
note_freq = containers.Map(...
    {'0','1','2','3','5','b5','b6'},...
    [0,    261.63, 293.66, 329.63, 392.00, 196.00, 220.00]);

%% 3. 青花瓷曲谱 + 时值序列
note_seq = {
    '0','5','5','3','2','3','b6','0',...
    '2','3','5','3','2','0','0','0',...
    '0','5','5','3','2','3','b5','0',...
    '2','3','5','2','1','0','0','0'
};
dur_seq = [
    0.5,0.5,0.5,0.5,0.5,0.5,1.0,0,...
    0.5,0.5,0.5,0.5,1.0,0,0,0,...
    0.5,0.5,0.5,0.5,0.5,0.5,1.0,0,...
    0.5,0.5,0.5,0.5,1.0,0,0,0
];

% 长度校验
len_n = length(note_seq);
len_d = length(dur_seq);
if len_n ~= len_d
    error('音符与时值数量不匹配！');
end

%% 4. 生成 3 路信号
% 4.1 纯基波信号 s1 (无ADSR)
s1 = [];
for k = 1:len_n
    f0 = note_freq(note_seq{k});
    t_scale = dur_seq(k);
    L = round(N_beat * t_scale);
    if L < 1
        L = 1;
    end
    n = 0:L-1;
    if f0 == 0
        seg = zeros(1, L);
    else
        seg = sin(2 * pi * f0 * n / Fs);
    end
    s1 = [s1, seg];
end
s1 = s1 / max(abs(s1));
audiowrite('4-3.wav', s1, Fs);

% 4.2 基波 + ADSR包络 s2
s2 = [];
env_sample = []; % 保存第一个有效音符包络用于绘图
for k = 1:len_n
    f0 = note_freq(note_seq{k});
    t_scale = dur_seq(k);
    L = round(N_beat * t_scale);
    if L < 1
        L = 1;
    end
    n = 0:L-1;
    
    if f0 == 0
        seg = zeros(1, L);
        env = zeros(1, L);
    else
        seg = sin(2 * pi * f0 * n / Fs);
        % ========== 内嵌ADSR生成逻辑（替代外部function，消除报错） ==========
        env = zeros(1, L);
        lenA = floor(L * A_ratio);
        lenD = floor(L * D_ratio);
        lenS = floor(L * S_ratio);
        lenR = L - lenA - lenD - lenS;
        idx = 1;
        % Attack
        if lenA > 0
            env(idx : idx+lenA-1) = linspace(0, 1, lenA);
            idx = idx + lenA;
        end
        % Decay
        if lenD > 0 && idx+lenD-1 <= L
            env(idx : idx+lenD-1) = linspace(1, S_level, lenD);
            idx = idx + lenD;
        end
        % Sustain
        if lenS > 0 && idx+lenS-1 <= L
            env(idx : idx+lenS-1) = S_level * ones(1, lenS);
            idx = idx + lenS;
        end
        % Release
        if lenR > 0 && idx <= L
            env(idx : L) = linspace(S_level, 0, L - idx + 1);
        end
    end
    
    % 取第一个非休止符包络作为样本
    if isempty(env_sample) && f0 ~= 0
        env_sample = env;
    end
    s2 = [s2, seg .* env];
end
s2 = s2 / max(abs(s2));
audiowrite('4-4.wav', s2, Fs);

% 4.3 多谐波 + ADSR包络 s3
s3 = [];
for k = 1:len_n
    f0 = note_freq(note_seq{k});
    t_scale = dur_seq(k);
    L = round(N_beat * t_scale);
    if L < 1
        L = 1;
    end
    n = 0:L-1;
    
    if f0 == 0
        seg = zeros(1, L);
        env = zeros(1, L);
    else
        seg = sin(2*pi*f0*n/Fs) ...
            + 0.50*sin(2*pi*2*f0*n/Fs) ...
            + 0.30*sin(2*pi*3*f0*n/Fs) ...
            + 0.15*sin(2*pi*4*f0*n/Fs);
        % 内嵌ADSR逻辑
        env = zeros(1, L);
        lenA = floor(L * A_ratio);
        lenD = floor(L * D_ratio);
        lenS = floor(L * S_ratio);
        lenR = L - lenA - lenD - lenS;
        idx = 1;
        if lenA > 0
            env(idx : idx+lenA-1) = linspace(0, 1, lenA);
            idx = idx + lenA;
        end
        if lenD > 0 && idx+lenD-1 <= L
            env(idx : idx+lenD-1) = linspace(1, S_level, lenD);
            idx = idx + lenD;
        end
        if lenS > 0 && idx+lenS-1 <= L
            env(idx : idx+lenS-1) = S_level * ones(1, lenS);
            idx = idx + lenS;
        end
        if lenR > 0 && idx <= L
            env(idx : L) = linspace(S_level, 0, L - idx + 1);
        end
    end
    s3 = [s3, seg .* env];
end
s3 = s3 / max(abs(s3));
audiowrite('4-5.wav', s3, Fs);

%% 5. 时域波形图(3行1列)
t1 = (0:length(s1)-1) / Fs;
t2 = (0:length(s2)-1) / Fs;
t3 = (0:length(s3)-1) / Fs;

figure('Name','时域波形','Position',[60,50,880,620]);
subplot(3,1,1);
plot(t1,s1,'LineWidth',1);
grid on; box on;
xlabel('时间 (s)'); ylabel('幅值');
title('4-3.wav 纯基波（无ADSR包络）');

subplot(3,1,2);
plot(t2,s2,'LineWidth',1);
grid on; box on;
xlabel('时间 (s)'); ylabel('幅值');
title('4-4.wav 基波 + ADSR包络');

subplot(3,1,3);
plot(t3,s3,'LineWidth',1);
grid on; box on;
xlabel('时间 (s)'); ylabel('幅值');
title('4-5.wav 多谐波 + ADSR包络');

%% 6. ADSR包络图（标准四段曲线）
figure('Name','ADSR包络','Position',[160,100,520,360]);
L_env = length(env_sample);
plot(0:L_env-1, env_sample,'LineWidth',2);
grid on; box on;
xlabel('采样点数'); ylabel('幅度系数');
title('ADSR 起音-衰减-保持-释放 标准包络曲线');
axis([0, L_env, 0, 1.05]);

%% 7. 频谱计算 + 相位处理
NFFT = 2^nextpow2(max([length(s1),length(s2),length(s3)]));
f_axis = Fs/2 * linspace(0,1,NFFT/2+1);
noise_th = 0.05;
down_step = 20;

% 幅度谱
FFT1 = fft(s1,NFFT);
Amp1 = 2*abs(FFT1)/length(s1);
Amp1(Amp1 < max(Amp1)*noise_th) = 0;

FFT2 = fft(s2,NFFT);
Amp2 = 2*abs(FFT2)/length(s2);
Amp2(Amp2 < max(Amp2)*noise_th) = 0;

FFT3 = fft(s3,NFFT);
Amp3 = 2*abs(FFT3)/length(s3);
Amp3(Amp3 < max(Amp3)*noise_th) = 0;

% 相位：无效频点置0，竖线效果
Pha1 = zeros(size(Amp1));
idx_valid1 = Amp1 > 0;
Pha1(idx_valid1) = unwrap(angle(FFT1(idx_valid1)));

Pha2 = zeros(size(Amp2));
idx_valid2 = Amp2 > 0;
Pha2(idx_valid2) = unwrap(angle(FFT2(idx_valid2)));

Pha3 = zeros(size(Amp3));
idx_valid3 = Amp3 > 0;
Pha3(idx_valid3) = unwrap(angle(FFT3(idx_valid3)));

% 数据抽点
idx_half = 1:NFFT/2+1;
idx_sel  = idx_half(1:down_step:end);
f_sel    = f_axis(idx_sel);

A1 = Amp1(idx_sel); A2 = Amp2(idx_sel); A3 = Amp3(idx_sel);
P1 = Pha1(idx_sel); P2 = Pha2(idx_sel); P3 = Pha3(idx_sel);

%% 8. 幅度谱窗口 (0~4000Hz)
figure('Name','幅度谱对比','Position',[80,70,400,650]);
subplot(3,1,1);
plot(f_sel,A1,'LineWidth',1);
grid on; box on;
title('无包络基波 幅度谱');
xlabel('频率 (Hz)'); ylabel('幅度');
xlim([0,4000]);

subplot(3,1,2);
plot(f_sel,A2,'LineWidth',1);
grid on; box on;
title('ADSR基波 幅度谱');
xlabel('频率 (Hz)'); ylabel('幅度');
xlim([0,4000]);

subplot(3,1,3);
plot(f_sel,A3,'LineWidth',1);
grid on; box on;
title('ADSR谐波 幅度谱');
xlabel('频率 (Hz)'); ylabel('幅度');
xlim([0,4000]);

%% 9. 相位谱窗口 (横轴0~4000 纵轴-3~3)
figure('Name','相位谱对比','Position',[560,70,400,650]);
subplot(3,1,1);
plot(f_sel,P1,'LineWidth',1);
grid on; box on;
title('无包络基波 相位谱');
xlabel('频率 (Hz)'); ylabel('相位 (rad)');
xlim([0,4000]);
ylim([-3,3]);

subplot(3,1,2);
plot(f_sel,P2,'LineWidth',1);
grid on; box on;
title('ADSR基波 相位谱');
xlabel('频率 (Hz)'); ylabel('相位 (rad)');
xlim([0,4000]);
ylim([-3,3]);

subplot(3,1,3);
plot(f_sel,P3,'LineWidth',1);
grid on; box on;
title('ADSR谐波 相位谱');
xlabel('频率 (Hz)'); ylabel('相位 (rad)');
xlim([0,4000]);
ylim([-3,3]);

%% 运行提示
disp('============================================');
disp('✅ 运行完毕 | 已移除外部函数，脚本直接运行');
disp('📁 音频：4-3.wav  4-4.wav  4-5.wav');
disp('📌 全部规范：');
disp('   1. ADSR四段曲线标准平滑无断层');