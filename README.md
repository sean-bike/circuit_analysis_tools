# 符号电路求解器以及公式化简函数
这是一个基于改进节点电压法（Modified Node Analysis, MNA）的符号电路求解器，完全使用MATLAB实现，并基于符号计算。该求解器能够自动分析电路拓扑结构，计算电路中所有节点的电压和支路电流，为电路分析和设计提供强大的计算支持。在得到结果以后，使用内置的基于阶数的公式化简函数对结果进行进一步化简，通过保留低阶或高阶项来进一步分析。

## 电路拓扑输入格式说明

电路描述采用结构化的输入格式，支持以下元件类型：

电阻、电容、电感

独立电压源、电流源

VCCS

MOS管的一阶小信号模型（包含作为跨导的VCCS，和表征沟道调制的阻抗ro）（寄生电容可以手动添加）

支持元件类型可自行拓展，于函数apply_component_stamp()中添加对应type处理即可。
示例如下：（详细示例见mlx文件）

```matlab
circuit = struct();
circuit.elements = {
    % 类型, 名称, 节点+, 节点-, 值, (控制节点+, 控制节点-)
    struct('type', 'V', 'name', 'Vin', 'nodes', {{'1', '2'}}, 'value', vin),
    struct('type', 'I', 'name', 'Itest', 'nodes', {{'1', '2'}}, 'value', i1),
    struct('type', 'R', 'name', 'R1', 'nodes', {{'1', '2'}}, 'value', R1),
    struct('type', 'Gm', 'name', 'gm', 'nodes', {{'1', '2'}}, 'value', gm1, 'control_nodes',{{'3','4'}}),
    % 类型，名称，Gate节点，Drain节点，Source节点，gm值，ro值
    struct('type', 'MOS', 'name', 'M1', 'nodes', {{'g', 'd', 's'}}, 'gm_value', gm1, 'ro_value', ro1),
    
};
```
## 核心函数generate_mna()
输入电路结构体，频率变量s（$={j\omega}$，如果只关心虚轴），以及参考点的名称（在电路结构体中必须出现，例如'gnd'）。
返回电路矩阵A，目标向量x，独立源向量z，节点名称-向量索引映射node_map，和extra_info。
```matlab
[A, x, z, node_map, extra_info] = generate_mna(circuit,s,'gnd');
```
向量x包含了所有节点电压和独立电压源支路电流，可供进一步分析。
## 公式化简函数simplify_by_degree_main()
给定一个符号集合L。对于单项$M=\Pi a_i^{k_i}，定义M的L阶数为
$$
\Sigma k_i \forall a_i \in L
$
通过保留较低或较高的项，对多项式或多项式分式进行化简。

输入公式，保留高阶项（'large'）还是低阶项（'small'），保留阶数，符号集合L。
返回化简后的公式。
```matlab
large_var = [gm1,gm2,gm3];
gain_dc_simplify = simplify_by_degree_main(gain_dc,'large',1,large_var)
```

## 示例：
见mna.mlx文件