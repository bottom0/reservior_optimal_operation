function [V_opt, V_opt_num, E_eco_, Q_fd_opt, Q_qs,E_eco_stage, Hsl] = water_reservoir_optim(V_max, V_min,V_SYT0,...
                                                           V_opt, V_opt_num, E_eco_, Q_fd_opt, Q_qs,...
                                                           Q_fd,Q_IN,...
                                                           t,tim,a,dateset3,E_eco_stage,Hsl)
  % 变量          定义                                                                              单位
  % -------------------------------------------------------------------------------------------------------------------
  % V_opt         在不同决策发电流量Q_fd和时段t下的数组，它包含其对应的库容，二维数组                  m^3           
  % V_opt_num     在发电流量Q_fd，和时段t下的数组，它包含其对应的T~ t时段的最优库容，二维字符串数组     m^3
  % E_eco_        在库容V_opt，和时段t下的数组，它包含其对应的T~t时段的最优总效益，二维数组            kW*h
  % Q_fd_opt      在库容V_opt，和时段t下的数组，它包含其对应的t时段的最优决策，二维数组                m^3/s
  % Q_qs          弃水                                                                              m^3/s
  % E_eco_stage   在库容V_opt，和时段t下的数组，它包含其对应的t时段的最优效益，二维数组                kW*h
  % Hsl           在库容V_opt，和时段t下的数组，它包含其对应的t时段的耗水率，二维数组
  % V_max         水库的最大库容                                                                    m^3
  % V_min         水库的最小库容                                                                    m^3
  % Q_fd          满足流量约束下的发电流量可能取值                                                   m^3/s
  % Q_IN          入库流量                                                                          m^3/s
  % t             阶段变量 
  % tim           每个阶段发电的时间长度                                                            d
  % a             Q_fd在满足流量约束下的发电流量可能取值的个数
  % dateset3      水库库容，水位，耗水率，预想出力的关系表 

  % 内部变量
  % 变量          定义                                                                              单位
  % -------------------------------------------------------------------------------------------------------------------
  % V_temp       在t时段的预定发电流量（决策）和上个时段库容的矩阵，它包含库容，二维数组                m^3
  % Q_temp       在t时段的预定发电流量（决策）和上个时段库容的矩阵，它包含实际发电流量，二维数组        m^3/s
  % E_eco_temp   在t时段的预定发电流量（决策）和上个时段的矩阵，它包含T~t时段的发电总效益               kW*h
  % V_temp_sort  在V_temp中包含的所有库容取值                                                        m^3
  
    %% 状态转移方程
    % Q_temp是预定发电流量和上个时段库容的矩阵，包含发电流量
    % t>2
if t>=2
    for i=1:size(V_opt(:,t+1),1)
        V_temp(:,i) = repmat(V_opt(i,t+1),a,1) - (repmat(Q_IN(t),a,1)-Q_fd(:,t))*3600*24*tim; 
    end
else
    % t=1要收敛
    V_temp=ones(1,size(V_opt(:,t+1),1))*V_SYT0;
end
    % 约束
    % 水库约束
    [a,~] = size(V_temp);
    for q=1:a
        for v=1:size(V_opt(:,t+1),1)
            if V_temp(q,v)<V_min(t)
                 V_temp(q,v)=0;
            % V_opt_ 要删去
            elseif V_temp(q,v)>V_max(t)
                V_temp(q,v) = V_max(t);
            end
        end   
    end    
    % 计算Q_temp
    for i=1:size(V_opt(:,t+1),1)
        Q_temp(:,i) = (V_temp(:,i) - repmat(V_opt(i,t+1),a,1))/(3600*24*tim) + repmat(Q_IN(t),a,1);
    end
    % 出力约束
    % 小于预想出力，大于保证出力
    E_eco=zeros(a,size(V_opt(:,t+1),1));
    for q=1:a
        for v=1:size(V_opt(:,t+1),1)
            if V_temp(q,v) <= 0
                E_eco(q,v)=-10000;
                V_temp(q,v)=0;
            else
                E_eco(q,v) = 9.81*Q_temp(q,v)*(Z_V(V_opt(v,t+1),dateset3)-308)*24*tim;
            if E_eco(q,v) >= predict_E(V_temp(q,v),tim, dateset3)
                E_eco(q,v)=predict_E(V_temp(q,v),tim, dateset3);
            else
                if E_eco(q,v) <=167000*tim*24
                    E_eco(q,v)=-10000;
                    V_temp(q,v)=0;
                end
            end
            end
        end
    end
    A = E_eco_(:,t+1)'; % 上一个时段各容量的总最优指标函数值
    E_eco_temp = E_eco+repmat(A,a,1);% 所有决策的可能取值

    
    %% 递推方程 
    % 在相同库容下取最优值和其对应值赋值给V_opt，Q_fd_opt，E_eco_
    V_temp_sort = sort(unique(V_temp),"descend");
    n = size(V_temp_sort,1);
    for i=1:n
        if V_temp_sort(i) == 0
            break
        end
            x = find(V_temp == V_temp_sort(i)); %找到某一库容的位置
            [MAX(i),~] = max(E_eco_temp(x)); %找到某一库容的最大出力
            [r,s] = find(E_eco_temp == MAX(i)); %找到对应的行数，即为其发电流量
            E_eco_(i,t) = MAX(i);
            E_eco_stage(i,t) = MAX(i) - E_eco_(s(1),t+1);
            Q_fd_opt(i,t) = Q_temp(r(1),s(1));
            V_opt(i,t) = V_temp_sort(i);
            V_opt_num(i,t) = sprintf('%s %s',string(V_temp_sort(i)),V_opt_num(s(1),t+1));
            Hsl(i,t)=Q_fd_opt(i,t)*(3600*24*tim)/E_eco_stage(i,t);
    end

end
