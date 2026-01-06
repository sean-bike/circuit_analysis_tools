function [A, x, z, node_map, extra_var_info] = generate_mna(circuit,s,gnd_label)
% GENERATE_MNA 从电路结构体生成MNA矩阵
% 输入:
%   circuit - 电路结构体，包含nodes和elements字段
% 输出:
%   A - 系统矩阵 [G, B; C, D]
%   x - 未知变量 [v; j]^T
%   z - 右侧向量 [I; e]^T
%   node_map - 节点名称到索引的映射
%   extra_var_info - 额外变量信息

% 参数验证
if nargin < 1
    error('需要提供电路结构体');
end

% 1. 构建节点映射
[node_map, node_count] = build_node_mapping(circuit,gnd_label);

% 2. 统计额外变量（电压源电流）
[voltage_sources, extra_var_count, extra_var_map] = count_extra_variables(circuit, node_count);

% 3. 计算矩阵总大小
total_vars = node_count + extra_var_count;
fprintf('总变量数: %d (节点电压: %d, 额外变量: %d)\n', ...
    total_vars, node_count, extra_var_count);

% 4. 初始化矩阵
G = sym(zeros(node_count, node_count));
B = sym(zeros(node_count, extra_var_count));
C = sym(zeros(extra_var_count, node_count));
D = sym(zeros(extra_var_count, extra_var_count));
I = sym(zeros(node_count, 1));
E = sym(zeros(extra_var_count, 1));

% 5. 应用元件
for i = 1:length(circuit.elements)
    elem = circuit.elements{i};
    [G, B, C, D, I, E] = apply_component_stamp(...
        elem, G, B, C, D, I, E, node_map, extra_var_map,s,gnd_label);
end

% 6. 组合成最终矩阵
A = [G, B; C, D];
z = [I; E];

% 7.求解节点电压和电压源电流
x = A\z;

% 创建变量说明
x_labels = cell(total_vars, 1);
node_keys = keys(node_map);
for i = 1:length(node_keys)
    idx = node_map(node_keys{i});
    x_labels{idx} = sprintf('V(%s)', node_keys{i});
end

extra_keys = keys(extra_var_map);
for i = 1:length(extra_keys)
    idx = extra_var_map(extra_keys{i});
    x_labels{idx} = sprintf('I(%s)', extra_keys{i});
end

% 返回变量信息
extra_var_info.names = extra_keys;
extra_var_info.indices = values(extra_var_map);
extra_var_info.x_labels = x_labels;

fprintf('MNA矩阵生成完成！\n');
fprintf('A矩阵大小: %d x %d, 非零元素: %d\n', ...
    size(A,1), size(A,2), nnz(A));
fprintf('x向量长度: %d\n', length(x));
fprintf('z向量长度: %d\n', length(z));
end