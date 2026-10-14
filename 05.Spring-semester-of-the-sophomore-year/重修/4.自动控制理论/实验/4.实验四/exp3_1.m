%% PI控制器校正仿真 时间轴统一版（带标注+兼容所有版本）
clear; clc; close all;

%% 1. 构建传递函数
s = tf('s');
% 原被控对象
G0 = 5 / (s*(0.2*s + 1));
Phi0 = feedback(G0, 1);   

% PI控制器（与实验参考结果一致）
tau = 2;
K = 0.158;
Gpi = K*(tau*s + 1)/s;

% 校正后系统
G_open = Gpi * G0;
Phi = feedback(G_open, 1);

%% 2. 计算频域指标
[Gm0, Pm0, Wcg0, Wcp0] = margin(G0);
[Gm, Pm, Wcg, Wcp] = margin(G_open);

%% 3. 计算时域指标
info0 = stepinfo(Phi0);
sigma0 = info0.Overshoot;
tp0 = info0.PeakTime;
ts0 = info0.SettlingTime;

info = stepinfo(Phi);
sigma = info.Overshoot;
tp = info.PeakTime;
ts = info.SettlingTime;

%% 4. 命令行打印所有指标
disp('========== 原系统性能指标 ==========');
fprintf('相角裕度 γ = %.2f °\n', Pm0);
fprintf('剪切频率 ωc = %.2f rad/s\n', Wcp0);
fprintf('超调量 σ%% = %.2f %%\n', sigma0);
fprintf('峰值时间 tp = %.2f s\n', tp0);
fprintf('调节时间 ts = %.2f s\n\n', ts0);

disp('========== 校正后系统性能指标 ==========');
fprintf('相角裕度 γ = %.2f °\n', Pm);
fprintf('剪切频率 ωc = %.2f rad/s\n', Wcp);
fprintf('超调量 σ%% = %.2f %%\n', sigma);
fprintf('峰值时间 tp = %.2f s\n', tp);
fprintf('调节时间 ts = %.2f s\n', ts);

%% 强制统一仿真时间（0~10s，步长0.01s）
t = 0:0.01:10; 

%% 5. 绘图：2行3列 共6张子图（标题带标注 + 时间轴统一）
figure('Name','PI校正仿真结果（时间轴统一+带指标）');

% ========== 子图1：原系统阶跃响应 ==========
subplot(2,3,1);
[y0,~] = step(Phi0, t); % 强制用我们定义的t绘图
plot(t, y0,'b-','LineWidth',1.2);
grid on;
title(sprintf('原系统阶跃响应\nσ=%.1f%%, tp=%.2fs, ts=%.2fs',sigma0,tp0,ts0));
xlabel('t (s)'); ylabel('输出');
xlim([0 10]); % 强制限制x轴范围，确保统一

% ========== 子图2：校正后阶跃响应 ==========
subplot(2,3,2);
[y,~] = step(Phi, t); % 强制用我们定义的t绘图
plot(t, y,'b-','LineWidth',1.2);
grid on;
title(sprintf('校正后阶跃响应\nσ=%.1f%%, tp=%.2fs, ts=%.2fs',sigma,tp,ts));
xlabel('t (s)'); ylabel('输出');
xlim([0 10]); % 强制限制x轴范围，确保统一

% ========== 子图3：阶跃响应对比（时间轴完全对齐） ==========
subplot(2,3,3);
plot(t, y0,'r--','LineWidth',1.2);
hold on;
plot(t, y,'b-','LineWidth',1.2);
hold off;
grid on;
title('阶跃响应对比（时间轴统一）');
xlabel('t (s)'); ylabel('输出');
legend('原系统','校正后');
xlim([0 10]);

% ========== 子图4：原系统伯德图 ==========
subplot(2,3,4);
margin(G0);
grid on;
title(sprintf('原系统伯德图\nγ=%.2f°, ωc=%.2frad/s',Pm0,Wcp0));

% ========== 子图5：校正后伯德图 ==========
subplot(2,3,5);
margin(G_open);
grid on;
title(sprintf('校正后伯德图\nγ=%.2f°, ωc=%.2frad/s',Pm,Wcp));

% ========== 子图6：伯德图对比 ==========
subplot(2,3,6);
bode(G0);
hold on;
bode(G_open);
hold off;
grid on;
title('伯德图对比');
legend('原系统','校正后');
