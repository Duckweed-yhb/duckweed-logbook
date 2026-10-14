%% 1. 连续周期方波 T=4 的傅里叶级数合成
clc; clear; close all;

T = 4;              % 周期
t = linspace(0,8,2000); % 两个周期，和讲义示例一致
w0 = 2*pi/T;        % 基波角频率

% 原方波信号（和讲义定义完全一致）
f = zeros(size(t));
f( mod(t,4)>=0 & mod(t,4)<2 ) = -1;
f( mod(t,4)>=2 & mod(t,4)<4 ) = 1;

% 合成不同谐波次数（和讲义示例一致：1,3,5,49,501）
N_set = [1,3,5,49,501];
figure('Position',[100,100,900,700]);

subplot(2,3,1);
plot(t,f,'LineWidth',1.5); grid on;
title('原连续周期方波 T=4');
xlabel('t/s'); ylabel('f(t)');
axis([0 8 -1.5 1.5]);

for i = 1:length(N_set)
    N = N_set(i);
    fn = zeros(size(t));
    for n = 1:2:N  % 只算奇次谐波
        bn = -4/(n*pi);  
        fn = fn + bn*sin(n*w0*t);
    end
    subplot(2,3,i+1);
    plot(t,f,'k--',t,fn,'r','LineWidth',1.2); grid on;
    title(['合成 N=1~',num2str(N),' 次谐波']);
    xlabel('t/s'); ylabel('f(t)');
    axis([0 8 -1.5 1.5]);
end