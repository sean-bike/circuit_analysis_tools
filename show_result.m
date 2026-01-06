function show_result(A, x, z, node_map, extra_info)
    fprintf('\n=== 电路信息 ===\n');
    fprintf('节点映射:\n');
    keys = node_map.keys;
    for i = 1:length(keys)
        fprintf('  节点 %s -> 变量 %d\n', keys{i}, node_map(keys{i}));
    end
    
    fprintf('\n额外变量:\n');
    for i = 1:length(extra_info.names)
        fprintf('  %s -> 变量 %d\n', extra_info.names{i}, extra_info.indices{i});
    end
    
    fprintf('\n=== 矩阵信息 ===\n');
    fprintf('A矩阵:\n');
    full(A)
    
    fprintf('z向量:\n');
    full(z)
    
    fprintf('变量标签:\n');
    for i = 1:length(extra_info.x_labels)
        fprintf('  x(%d) = %s\n', i, extra_info.x_labels{i});
    end
end