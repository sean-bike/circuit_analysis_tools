function [node_map, node_count] = build_node_mapping(circuit,gnd_label)
% 构建节点名称到索引的映射
% 节点'0'是地节点，不分配方程

% 确保 elements 是元胞数组
if ~iscell(circuit.elements)
    error('circuit.elements 必须是元胞数组');
end

node_names = {};

for i = 1:length(circuit.elements)
    elem = circuit.elements{i};
    
    % 处理不同类型的节点
    switch elem.type
        case 'MOS'
            % MOS有3个节点：栅极、漏极、源极
            node_list = elem.nodes;  % {'G', 'D', 'S'}
        case 'G'  % VCCS
            % VCCS有4个节点：2个输出 + 2个控制
            node_list = [elem.nodes, elem.control_nodes];  % 合并所有节点
        otherwise
            % 其他元件有2个节点
            node_list = elem.nodes;
    end
    
    % 添加所有节点（排除地节点）
    for j = 1:length(node_list)
        node_name = node_list{j};
        if ~ismember(node_name, node_names) && ~strcmp(node_name, gnd_label)
            node_names{end+1} = node_name;
        end
    end
end

% 创建映射
node_map = containers.Map(node_names, 1:length(node_names));
node_count = length(node_names);
end