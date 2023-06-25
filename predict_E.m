function [E] = predict_E(V_1,tim,dateset3)
%PREDICT_N 由库容求预想发电量
% 输入库容 时段 输出预想发电 发电单位kw*h
% 线性插补

[n,~]=size(V_1);
V1=V_1/1000000;
if V_1==0
    E=-10000000;
end
for i=1:n
    for k=1:70
        if V1(i)>=dateset3(k,2)&&V1(i)<=dateset3(k+1,2)
            N(i,1)=(dateset3(k,4)+(dateset3(k+1,4)-dateset3(k,4))/(dateset3(k+1,2)-dateset3(k,2))*(V1(i)-dateset3(k,2)));
            E(i,1)=N(i,1)*tim*24*1000;    %kW*h
        end
    end
end
end

