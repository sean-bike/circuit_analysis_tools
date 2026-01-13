function circuit = parse_spice_netlist(filename)
% PARSE_SPICE_NETLIST 解析SPICE格式的网表文件
% 输入:
%   filename - 网表文件名
% 输出:
%   circuit - MATLAB结构体，包含elements字段

% 检查文件是否存在
if ~exist(filename, 'file')
    error('文件不存在: %s', filename);
end

% 读取文件
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 读取所有行
lines = textscan(fid, '%s', 'Delimiter', '\n');%, 'CommentStyle', {{'*'}, {';'}, {'//'}});
fclose(fid);
lines = lines{1};

% 初始化元件列表
elements = {};
line_num = 0;

% 解析每一行
for i = 1:length(lines)
    line = strtrim(lines{i});
    line_num = line_num + 1;
    
    % 跳过空行、注释行、控制语句
    if isempty(line) || line(1) == '*' || line(1) == '.'
        continue;
    end
    
    % 将行拆分为标记
    tokens = strsplit(line);
    
    % 提取元件名称和类型
    element_name = tokens{1};
    element_type = upper(element_name(1));  % 第一个字符表示类型
    
    % 根据元件类型解析
    switch element_type
        case 'R'  % 电阻
            elem = parse_element('R', element_name, tokens, line_num);
        
        case 'C'  % 电阻
            elem = parse_element('C', element_name, tokens, line_num);
            
        case 'V'  % 独立电压源
            elem = parse_element('V', element_name, tokens, line_num);
            
        case 'I'  % 独立电流源
            elem = parse_element('I', element_name, tokens, line_num);
            
        case 'G'  % VCCS
            elem = parse_element('G', element_name, tokens, line_num);
            
        case 'M'  % MOS晶体管
            elem = parse_element('MOS', element_name, tokens, line_num);
            
        otherwise
            warning('第%d行: 未知元件类型 "%s"，跳过', line_num, element_type);
            continue;
    end
    
    % 添加到元件列表
    elements{end+1} = elem;
end

% 创建电路结构体
circuit = struct();
circuit.elements = elements;
end

%% 统一的元件解析函数
function elem = parse_element(type, name, tokens, line_num)
% PARSE_ELEMENT 解析单个元件
% 输入:
%   type - 元件类型 ('R', 'C', 'V', 'I', 'G', 'MOS')
%   name - 元件名称
%   tokens - 行拆分的token列表
%   line_num - 行号（用于错误信息）
% 输出:
%   elem - 元件结构体

switch type
    case 'R'  % 电阻
        % 格式: Rxxx n1 n2 value
        if length(tokens) < 4
            error('第%d行: 电阻 "%s" 参数不足，需要节点1、节点2和阻值', line_num, name);
        end
        
        elem = struct();
        elem.type = 'R';
        elem.name = name;
        elem.nodes = {tokens{2}, tokens{3}};
        elem.value = parse_value(tokens{4});

    case 'C'  % 电阻
        % 格式: Cxxx n1 n2 value
        if length(tokens) < 4
            error('第%d行: 电容 "%s" 参数不足，需要节点1、节点2和阻值', line_num, name);
        end
        
        elem = struct();
        elem.type = 'C';
        elem.name = name;
        elem.nodes = {tokens{2}, tokens{3}};
        elem.value = parse_value(tokens{4});
        
    case 'V'  % 独立电压源
        % 格式: Vxxx n+ n- value 或 Vxxx n+ n- DC value
        if length(tokens) < 4
            error('第%d行: 电压源 "%s" 参数不足', line_num, name);
        end
        
        elem = struct();
        elem.type = 'V';
        elem.name = name;
        
        % 查找电压值
        if strcmpi(tokens{4}, 'DC') && length(tokens) >= 5
            value_str = tokens{5};
            nodes = {tokens{2}, tokens{3}};
        else
            value_str = tokens{4};
            nodes = {tokens{2}, tokens{3}};
        end
        
        elem.nodes = nodes;
        elem.value = parse_value(value_str);
        
    case 'I'  % 独立电流源
        % 格式: Ixxx n+ n- value 或 Ixxx n+ n- DC value
        if length(tokens) < 4
            error('第%d行: 电流源 "%s" 参数不足', line_num, name);
        end
        
        elem = struct();
        elem.type = 'I';
        elem.name = name;
        
        % 查找电流值
        if strcmpi(tokens{4}, 'DC') && length(tokens) >= 5
            value_str = tokens{5};
            nodes = {tokens{2}, tokens{3}};
        else
            value_str = tokens{4};
            nodes = {tokens{2}, tokens{3}};
        end
        
        elem.nodes = nodes;
        elem.value = parse_value(value_str);
        
    case 'G'  % VCCS
        % 格式: Gxxx n+ n- nc+ nc- value
        if length(tokens) < 6
            error('第%d行: VCCS "%s" 参数不足，需要输出+、输出-、控制+、控制-和跨导值', line_num, name);
        end
        
        elem = struct();
        elem.type = 'G';
        elem.name = name;
        elem.nodes = {tokens{2}, tokens{3}};  % 输出端口
        elem.control_nodes = {tokens{4}, tokens{5}};  % 控制端口
        elem.value = parse_value(tokens{6});  % 跨导值
        
    case 'MOS'  % MOS晶体管
        % 格式: Mxxx D G S B model_name gm=value ro=value
        if length(tokens) < 6
            error('第%d行: MOS "%s" 参数不足，需要D、G、S、B节点和参数', line_num, name);
        end
        
        elem = struct();
        elem.type = 'MOS';
        elem.name = name;
        
        % 标准SPICE格式: Mxxx G D S B model_name
        % 我们只需要前3个节点: G, D, S
        elem.nodes = {tokens{2}, tokens{3}, tokens{4}};  % G, D, S
        
        % 查找gm和ro参数
        gm_found = false;
        ro_found = false;
        
        for i = 5:length(tokens)
            token = tokens{i};
            
            % 检查gm参数
            if startsWith(token, 'gm=') || startsWith(token, 'GM=')
                gm_value_str = token(4:end);
                elem.gm_value = parse_value(gm_value_str);
                gm_found = true;
                
            % 检查ro参数
            elseif startsWith(token, 'ro=') || startsWith(token, 'RO=')
                ro_value_str = token(4:end);
                elem.ro_value = parse_value(ro_value_str);
                ro_found = true;
            end
        end
        
        % 如果未找到参数，使用默认值或报错
        if ~gm_found
            warning('第%d行: MOS "%s" 未找到gm参数，使用默认值0.01', line_num, name);
            elem.gm_value = 0.01;
        end
        
        if ~ro_found
            warning('第%d行: MOS "%s" 未找到ro参数，使用默认值10000', line_num, name);
            elem.ro_value = 10000;
        end
        
    otherwise
        error('不支持的元素类型: %s', type);
end
end

%% 数值解析函数
function value = parse_value(value_str)
% PARSE_VALUE 解析数值字符串，支持SI前缀
% 例如: 1k -> 1000, 2.2u -> 2.2e-6, 10m -> 0.01

% 如果已经是数字，直接返回
if ~isnan(str2double(value_str))
    value = str2double(value_str);
    return;
end

% 定义SI前缀映射
prefixes = {
    'T', 1e12;  'G', 1e9;   'MEG', 1e6;  'M', 1e6;
    'k', 1e3;   'K', 1e3;   '', 1;       'm', 1e-3;
    'u', 1e-6;  'U', 1e-6;  'n', 1e-9;   'p', 1e-12;
    'f', 1e-15
};

% 尝试匹配数值和前缀
for i = 1:size(prefixes, 1)
    prefix = prefixes{i, 1};
    factor = prefixes{i, 2};
    
    if ~isempty(prefix) && endsWith(value_str, prefix)
        num_part = value_str(1:end-length(prefix));
        if ~isnan(str2double(num_part))
            value = str2double(num_part) * factor;
            return;
        end
    end
end

% 如果没有前缀，尝试直接转换
try
    value = str2double(value_str);
    if isnan(value)
        error('无法解析数值: %s', value_str);
    end
catch
    % 如果无法解析，尝试作为符号变量
    value = sym(value_str);
end
end