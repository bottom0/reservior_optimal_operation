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
KSJ=xlsread('cgb(1).xlsx'); %发电流量即初始可行解
Q=KSJ(:,3);
max_E_eco_=KSJ(22,4);
QS=397.62; % 起始水位
ZZ=397.415305592157; % 终止水位
C=10; % 增量
BC=1; % 步长

%导入入库流量和水库库容与水位关系
filename1= "试验数据1.txt";
delimiterIn1=" ";
headerlinesIn1=4;
test1=importdata(filename1,delimiterIn1,headerlinesIn1);
Q_IN=test1.data;% 入库流量
filename2= "试验数据2.txt";
delimiterIn2=" ";
headerlinesIn2=7;
test2=importdata(filename2,delimiterIn2,headerlinesIn2);
dateset2=test2.data; %调度图
headerlinesIn2_1=33;
test2_1=importdata(filename2,delimiterIn2,headerlinesIn2_1);
CL=test2_1.data; %指示出力
filename3= "试验数据3.txt";
delimiterIn3=" ";
headerlinesIn3=5;
test3=importdata(filename3,delimiterIn3,headerlinesIn3);
dateset3=test3.data; %水库库容 

V_max=quest_v_Z_V(413,dateset3)*ones(20,1); %最大库容
V_min=quest_v_Z_V(380,dateset3)*ones(20,1); %最小库容
V_SYT=quest_v_Z_V(ZZ,dateset3); %时段末库容
V_SYT0 = quest_v_Z_V(QS,dateset3); %时段初库容
for i=1:20
Q_fd(:,i)=Q(i)-C:BC:Q(i)+C; % Q_fd 发电流量可能取值
end
% 阶段
T=20;
for t=T:-1:1
    if t>=13
        tim(t)=30;
    else 
        tim(t)=10;
    end
end
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

while 1 
for i=1:20
Q_fd(:,i)=Q(i)-C:BC:Q(i)+C; % Q_fd 发电流量可能取值
end
    for t=T:-1:1
    [V_opt, V_opt_num, E_eco_, Q_fd_opt, Q_qs,E_eco_stage, Hsl] = water_reservoir_optim(V_max, V_min,V_SYT0,...
                                                               V_opt, V_opt_num, E_eco_,...
                                                                Q_fd_opt, Q_qs, Q_fd,Q_IN,...
                                                               t,tim(t),a, CL, dateset2, dateset3,E_eco_stage, Hsl);
    end


    %% 输出数据
    [~,n] = min(abs(V_opt(:,1) - V_SYT0));
    ANWER_V = str2num(V_opt_num(n,1));
    for an = 1:20
        ANWER_Z(an) = Z_V(ANWER_V(an),dateset3);
        [~,r]=min(abs(V_opt(:,an) - ANWER_V(an)));
        ANWER_Q_fd(an) = Q_fd_opt(r,an);
        ANWER_E_eco_stage(an) = E_eco_stage(r,an);
        ANWER_E_eco_(an) = E_eco_(r,an);
        ANWER_Hsl(an) = Hsl(r,an);
    end
if (abs(ANWER_E_eco_(1)-max_E_eco_)/max_E_eco_)<0.0000001%0.000001
    break
else
    Q=ANWER_Q_fd;
    max_E_eco_=ANWER_E_eco_(1);
end
end
%%
xlswrite('cgb(1)_lyl.xlsx',[{'水位'},{'库容'},{'发电流量'},{'发电量'},{'总发电量'},{'耗水率'}],1,'A1');
xlswrite('cgb(1)_lyl.xlsx',[ANWER_Z',ANWER_V(1:20)',ANWER_Q_fd', ANWER_E_eco_stage',ANWER_E_eco_',ANWER_Hsl'],1,'A2');     
