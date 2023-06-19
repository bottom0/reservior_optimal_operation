clc,clear
% T:             阶段
% V_max:         水库的最大水位
% V_min:         水库的最小水位
% V_SYT:         水库T时段的水位
% V_ST0:         水库0时段的水位
% Q_IN:          入库流量
% Q_OUT:         出库流量， Q_OUT是离散化的数组，其最大最小值满足一定的约束
% Q_fd_max       最大发电流量
% Q_fd_min       最小发电流量
% Q_fd:          发电流量可能取值
% V_opt          在发电流量Q_fd，和时段t下的数组，它包含其对应的库容，二维数组
% V_opt_num      在发电流量Q_fd，和时段t下的数组，它包含其对应的T~t时段的最优库容，二维字符串数组
% E_eco_         在库容V下的最大收益
% E_eco_         在V_opt对应的最优发电总效益
% Q_fd_opt       V_opt对应的发电流量
% Q_qs           弃水
% Hsl            耗水率（发电流量/水量）

%% 初始化数据
%导入入库流量和水库库容与水位关系
filename1= "试验数据1.txt";
delimiterIn1=" ";
headerlinesIn1=4;
test1=importdata(filename1,delimiterIn1,headerlinesIn1);
Q_IN=test1.data;% 入库流量
Q_IN = Q_IN;
filename3= "试验数据3.txt";
delimiterIn3=" ";
headerlinesIn3=5;
test3=importdata(filename3,delimiterIn3,headerlinesIn3);
dateset3=test3.data; %水库库容
T=20;% 阶段
V_max=quest_v_Z_V(412,dateset3)*ones(20,1); %最大库容
V_min=quest_v_Z_V(380,dateset3)*ones(20,1); %最小库容
% V_SYT=3.508e+09; %时段末库容
V_SYT=quest_v_Z_V(398.49,dateset3); %时段末库容
V_SYT0 = quest_v_Z_V(397.72,dateset3); %时段初库容
Q_fd_max=500; % Q_fd_max 最大发电流量
Q_fd_min=1; % Q_fd_min 最小发电流量
Q_fd=repmat([Q_fd_min:1:Q_fd_max],20,1)'; % Q_fd 发电流量可能取值


[a,~] = size(Q_fd);
Q_qs = zeros(a,a);
Q_fd_opt=zeros(a,T);


%% 先计算第一次
% 从最后一天开始逆向递推
V_opt(1,T+1) = V_SYT; 
V_opt_num(1,T+1) = string(V_SYT);
E_eco_(1,T+1) = 0;% 最后一天时段末最优出力为0
E_eco_stage(1,T+1) = 0;
Hsl(1,T+1)=0;


for t=T:-1:13
[V_opt, V_opt_num, E_eco_, Q_fd_opt, Q_qs,E_eco_stage, Hsl] = water_reservoir_optim(V_max, V_min,...
                                                           V_opt, V_opt_num, E_eco_,...
                                                            Q_fd_opt, Q_qs, Q_fd,Q_IN,...
                                                           t,30,a, dateset3,E_eco_stage, Hsl);
end
for t=13-1:-1:1
[V_opt, V_opt_num, E_eco_, Q_fd_opt, Q_qs,E_eco_stage, Hsl] = water_reservoir_optim(V_max, V_min,...
                                                           V_opt, V_opt_num, E_eco_,...
                                                            Q_fd_opt, Q_qs, Q_fd,Q_IN,...
                                                           t,10,a, dateset3,E_eco_stage, Hsl);
end

%% 输出数据
[~,n] = min(abs(V_opt(:,1) - V_SYT0));
ANWER_V = str2num(V_opt_num(n,1));
for an = 1:20
    ANWER_Z(an) = Z_V(ANWER_V(an),dateset3);
    [r,~] = find(abs(V_opt(:,an) - ANWER_V(an))<=0.00001);
    ANWER_Q_fd(an) = Q_fd_opt(r,an);
    ANWER_E_eco_stage(an) = E_eco_stage(r,an);
    ANWER_E_eco_(an) = E_eco_(r,an);
    ANWER_Hsl(an) = Hsl(r,an);
end
xlswrite('result1~500——1.xlsx',[{'水位'},{'库容'},{'总发电流量'},{'发电流量'},{'发电量'},{'耗水率'}],1,'A1');
xlswrite('result1~500——1.xlsx',[ANWER_Z',ANWER_V(1:20)',ANWER_Q_fd', ANWER_E_eco_stage',ANWER_E_eco_',ANWER_Hsl'],1,'A2');     
