function [voltage_sources, extra_count, extra_map] = ...
    count_extra_variables(circuit, node_count)
    % 统计需要额外变量的元件（电压源）
    
    voltage_sources = {};
    extra_count = 0;
    extra_map = containers.Map();
    
    for i = 1:length(circuit.elements)
        elem = circuit.elements{i};
        if strcmp(elem.type, 'V')
            % 独立电压源和受控源需要额外变量
            voltage_sources{end+1} = elem.name;
            extra_count = extra_count + 1;
            extra_map(elem.name) = node_count + extra_count;
        end
    end
end