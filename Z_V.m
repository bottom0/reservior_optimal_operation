function [Z1] = Z_V(V_1,dateset3)
%Z_V 由库容求水位
%   线性插补

[n,~]=size(V_1);
V1=V_1/1000000;
for i=1:n
    for k=1:70
        if V1(i)>=dateset3(k,2)&&V1(i)<=dateset3(k+1,2)
            Z1(i,1)=(dateset3(k,1)+(dateset3(k+1,1)-dateset3(k,1))/(dateset3(k+1,2)-dateset3(k,2))*(V1(i)-dateset3(k,2)));
        end
    end
end
end

