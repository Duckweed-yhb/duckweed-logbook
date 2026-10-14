%% 3. 周期锯齿波 合成 多阶谐波版本
clc; clear; close all;

T = 4;
t = linspace(-6,6,2000);
w0 = 2*pi/T;

% 原锯齿波
f = 0.5*mod(t,4) - 1;

% 分别计算 10、20、40 次谐波合成波形
N1 = 10;
fn10 = zeros(size(t));
for n=1:N1
    bn = -2*(-1)^n/(n*pi);
    fn10 = fn10 + bn*sin(n*w0*t);
end

N2 = 20;
fn20 = zeros(size(t));
for n=1:N2
    bn = -2*(-1)^n/(n*pi);
    fn20 = fn20 + bn*sin(n*w0*t);
end

N3 = 40;
fn40 = zeros(size(t));
for n=1:N3
    bn = -2*(-1)^n/(n*pi);
    fn40 = fn40 + bn*sin(n*w0*t);
end

% 2行2列 共4张子图
figure;
subplot(2,2,1); 
plot(t,f,'LineWidth',1.5); 
title('原始周期锯齿波 T=4'); 
grid on;
xlabel('t');ylabel('f(t)');
axis([-6 6 -1.5 1.5]);

subplot(2,2,2); 
plot(t,fn10,'LineWidth',1.5); 
title('N=10 次谐波合成'); 
grid on;
xlabel('t');ylabel('f(t)');
axis([-6 6 -1.5 1.5]);

subplot(2,2,3); 
plot(t,fn20,'LineWidth',1.5); 
title('N=20 次谐波合成'); 
grid on;
xlabel('t');ylabel('f(t)');
axis([-6 6 -1.5 1.5]);

subplot(2,2,4); 
plot(t,fn40,'LineWidth',1.5); 
title('N=40 次谐波合成'); 
grid on;
xlabel('t');ylabel('f(t)');
axis([-6 6 -1.5 1.5]);