%% 最终版：X轴 0.1 ~ 50，生成标准渐近折线图 3.1.png
clear; clc; close all;

% 系统模型
G0 = tf(5, conv([1 0],[0.2 1]));
tau = 0.5;
K = 2;
Gpi = tf(K*[tau 1],[1 0]);
G_open = G0 * Gpi;

% 频率范围：0.1 ~ 50 rad/s（你要的 5×10^1）
w = logspace(-1, log10(50), 800);

[mag,~] = bode(G_open, w);
mag_dB = 20*log10(squeeze(mag));

% 关键频率
wz = 2;
w1 = 5;
wc = 10;

% 绘图
figure('Position',[100,100,800,400]);
semilogx(w, mag_dB, 'r-', 'LineWidth', 1.3); hold on; grid on;

% 渐近折线
seg1 = logspace(-1, wz, 200); L1 = -40*log10(seg1);
seg2 = logspace(wz, w1, 200); L2 = -40*log10(wz) -20*log10(seg2/wz);
seg3 = logspace(w1, 50, 200); L3 = -40*log10(wz)-20*log10(w1/wz)-40*log10(seg3/w1);

semilogx(seg1, L1, 'k--', 'LineWidth', 1.5);
semilogx(seg2, L2, 'k--', 'LineWidth', 1.5);
semilogx(seg3, L3, 'k--', 'LineWidth', 1.5);

% 标注
xline([wz,w1,wc], 'g:');
text(wz, -15, '\omega_z=2','fontsize',9);
text(w1, -35, '\omega_1=5','fontsize',9);
text(wc, 0, '\omega_c=10','fontsize',9);

xlabel('\omega (rad/s)');
ylabel('L(\omega) / dB');
title('PI校正系统幅频渐近折线图');
legend('实际曲线','渐近折线','Location','best');

% 保存图片
saveas(gcf, '3.1.png');