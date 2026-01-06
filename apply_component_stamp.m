function [G, B, C, D, I, E] = apply_component_stamp(...
    elem, G, B, C, D, I, E, node_map, extra_map,s,gnd_label)
% 应用元件邮票到MNA矩阵

% 获取节点索引
node_p = elem.nodes{1};  % 正节点
node_n = elem.nodes{2};  % 负节点

idx_p = 0;
idx_n = 0;

if ~strcmp(node_p, gnd_label)
    idx_p = node_map(node_p);
end
if ~strcmp(node_n, gnd_label)
    idx_n = node_map(node_n);
end

switch elem.type
    case 'R'  % 电阻
        R = elem.value;
        g = 1/R;  % 电导
        
        if idx_p > 0
            G(idx_p, idx_p) = G(idx_p, idx_p) + g;
        end
        if idx_n > 0
            G(idx_n, idx_n) = G(idx_n, idx_n) + g;
        end
        if idx_p > 0 && idx_n > 0
            G(idx_p, idx_n) = G(idx_p, idx_n) - g;
            G(idx_n, idx_p) = G(idx_n, idx_p) - g;
        end

    case 'C'  % 电容
        Cap = elem.value;
        g = s*Cap;  % 电导
        
        if idx_p > 0
            G(idx_p, idx_p) = G(idx_p, idx_p) + g;
        end
        if idx_n > 0
            G(idx_n, idx_n) = G(idx_n, idx_n) + g;
        end
        if idx_p > 0 && idx_n > 0
            G(idx_p, idx_n) = G(idx_p, idx_n) - g;
            G(idx_n, idx_p) = G(idx_n, idx_p) - g;
        end

    case 'L'  % 电感
        Ind = elem.value;
        g = 1/(s*Ind);  % 电导
        
        if idx_p > 0
            G(idx_p, idx_p) = G(idx_p, idx_p) + g;
        end
        if idx_n > 0
            G(idx_n, idx_n) = G(idx_n, idx_n) + g;
        end
        if idx_p > 0 && idx_n > 0
            G(idx_p, idx_n) = G(idx_p, idx_n) - g;
            G(idx_n, idx_p) = G(idx_n, idx_p) - g;
        end

    case 'I'  % 独立电流源
        I_value = elem.value;
        
        if idx_p > 0
            I(idx_p) = I(idx_p) - I_value;  % 从正节点流出
        end
        if idx_n > 0
            I(idx_n) = I(idx_n) + I_value;  % 流入负节点
        end
        
    case 'V'  % 独立电压源
        V_value = elem.value;
        idx_v = extra_map(elem.name);  % 电压源电流变量索引
        
        % 在B矩阵的贡献
        if idx_p > 0
            B(idx_p, idx_v - size(G,1)) = 1;
        end
        if idx_n > 0
            B(idx_n, idx_v - size(G,1)) = -1;
        end
        
        % 在C矩阵的贡献
        if idx_p > 0
            C(idx_v - size(G,1), idx_p) = 1;
        end
        if idx_n > 0
            C(idx_v - size(G,1), idx_n) = -1;
        end
        
        % 在E向量的贡献
        E(idx_v - size(G,1)) = V_value;

    case 'Gm'  % VCCS（电压控制电流源）
        gm = sym(elem.value);  % 跨导值
        
        % 获取控制节点索引
        ctrl_p = elem.control_nodes{1};
        ctrl_n = elem.control_nodes{2};
        
        idx_cp = 0;
        idx_cn = 0;
        
        if ~strcmp(ctrl_p, gnd_label)
            idx_cp = node_map(ctrl_p);
        end
        if ~strcmp(ctrl_n, gnd_label)
            idx_cn = node_map(ctrl_n);
        end
        
        % VCCS邮票: I_out = gm * (V_ctrl+ - V_ctrl-)
        % 在输出正节点: +gm * (V_cp - V_cn)
        % 在输出负节点: -gm * (V_cp - V_cn)
        
        if idx_p > 0
            if idx_cp > 0
                G(idx_p, idx_cp) = G(idx_p, idx_cp) + gm;
            end
            if idx_cn > 0
                G(idx_p, idx_cn) = G(idx_p, idx_cn) - gm;
            end
        end
        
        if idx_n > 0
            if idx_cp > 0
                G(idx_n, idx_cp) = G(idx_n, idx_cp) - gm;
            end
            if idx_cn > 0
                G(idx_n, idx_cn) = G(idx_n, idx_cn) + gm;
            end
        end

    case 'MOS'  % MOS晶体管小信号模型
        % 提取MOS的三个节点：栅极(G)、漏极(D)、源极(S)
        node_g = elem.nodes{1};  % 栅极
        node_d = elem.nodes{2};  % 漏极
        node_s = elem.nodes{3};  % 源极
        
        % 获取节点索引
        idx_g = 0;
        idx_d = 0;
        idx_s = 0;
        
        if ~strcmp(node_g, gnd_label)
            idx_g = node_map(node_g);
        end
        if ~strcmp(node_d, gnd_label)
            idx_d = node_map(node_d);
        end
        if ~strcmp(node_s, gnd_label)
            idx_s = node_map(node_s);
        end
        
        % 提取参数
        gm = sym(elem.gm_value);  % 跨导
        ro = sym(elem.ro_value);  % 输出电阻
        
        % === 第一部分：输出电阻ro (连接在漏极和源极之间) ===
        g_ro = 1/ro;  % 电导
        
        if idx_d > 0
            G(idx_d, idx_d) = G(idx_d, idx_d) + g_ro;
        end
        if idx_s > 0
            G(idx_s, idx_s) = G(idx_s, idx_s) + g_ro;
        end
        if idx_d > 0 && idx_s > 0
            G(idx_d, idx_s) = G(idx_d, idx_s) - g_ro;
            G(idx_s, idx_d) = G(idx_s, idx_d) - g_ro;
        end
        
        % === 第二部分：VCCS (控制电压: V_GS = V_G - V_S, 输出电流从D流向S) ===
        % 这等价于一个VCCS：控制节点为G和S，输出节点为D和S
        
        % 在漏极节点(D)：电流从漏极流出，所以贡献为 +gm * (V_G - V_S)
        if idx_d > 0
            if idx_g > 0
                G(idx_d, idx_g) = G(idx_d, idx_g) + gm;  % +gm * V_G
            end
            if idx_s > 0
                G(idx_d, idx_s) = G(idx_d, idx_s) - gm;  % -gm * V_S
            end
        end
        
        % 在源极节点(S)：电流流入源极，所以贡献为 -gm * (V_G - V_S)
        if idx_s > 0
            if idx_g > 0
                G(idx_s, idx_g) = G(idx_s, idx_g) - gm;  % -gm * V_G
            end
            if idx_s > 0
                G(idx_s, idx_s) = G(idx_s, idx_s) + gm;  % +gm * V_S
            end
        end
    otherwise
        warning('未知元件类型: %s，跳过', elem.type);
end
end