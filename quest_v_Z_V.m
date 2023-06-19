function [V1] = quest_v_Z_V(Z1,dateset3)
%Z_V 由水位求库容
%   采用线性插补

[n,~]=size(Z1);
for i=1:n
    for k=1:70
        if Z1(i)>=dateset3(k,1)&&Z1(i)<=dateset3(k+1,1)
            V1(i,1)=(dateset3(k,2)+(dateset3(k+1,2)-dateset3(k,2))/(dateset3(k+1,1)-dateset3(k,1))*(Z1(i)-dateset3(k,1)))*1000000;
        end
    end
end
end

