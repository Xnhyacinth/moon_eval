
### Quickstrat

```bash
bash run.sh
```

### 依赖

按照lm-evaluation-harness安装lm_eval

### 公开结果

本目录下[pub.md](pub.md)

### Result

在deepseek-ai__DeepSeek-R1-Distill-Qwen-1.5B 和deepseek-ai__DeepSeek-R1-Distill-Qwen-7B上实现对MATH-500的评测


结果在output中可见

对1.5B分析，目前在max_new_tokens长度设为8192时最优，EM指标为61.6，但与报告的83.9仍然有较大差距。发现随着数目从1024->2048->4096->8192性能逐步提升。

对结果分析可知，蒸馏的reasoning model很多出现了过度思考和复读机现象，特别是更小的model。且发现很多回复还没有到生成结果部分或者没有按照要求输出答案，以至于评测代码只能判错。


### 难点

1. **答案提取的复杂性**  
   - 模型输出格式多样，尤其是在生成式任务中，模型可能会以多种形式表达最终答案（如直接给出数字、使用特殊标记如 `####` 或 `\boxed{}` 包裹答案、或者在冗长的推理过程中隐藏答案）。这种多样性增加了答案提取的难度。
   - 即使通过 Prompt 明确约束输出格式，模型仍可能未完全遵循要求。例如，部分输出可能存在复述现象或过度思考，导致答案被埋没在冗长的文本中。
   - 正则表达式的编写需要尽可能覆盖各种可能的答案格式，但仍然难以应对所有情况，尤其是当模型输出不符合预期时。

2. **API 模型的稳定性**  
   - 调用api model容易出现违反规定或者超出最大请求次数

3. **评测指标的局限性**  
   - 当前使用的 EM（Exact Match）指标对答案的精确匹配要求较高，无法容忍任何形式的格式差异或近似正确答案。这可能导致一些实际上正确的答案被判为错误。
   - 对于数学问题，某些答案可能有多种等价形式（如分数与小数、简化与未简化形式），EM 指标无法有效捕捉这些等价性。


### 解决方案

1. **优化答案提取流程**  
   - **多模式正则匹配**：针对不同模型的输出特点，设计多个正则表达式以覆盖更多可能的答案格式。例如：
     - 提取 `####` 包裹的答案：`r"####\s*([\-\+]?[0-9\.,]+)"`
     - 提取 `\boxed{}` 包裹的答案：`r"\\boxed\{([^}]+)\}"`
     - 提取独立数字或表达式：`r"([\-+]?\d*\.?\d+)"`  
   - **后处理逻辑**：在提取到多个候选答案时，增加优先级排序逻辑，例如优先选择符合特定格式的答案（如 `\boxed{}` 的优先级高于其他格式）。
   - **Prompt 优化**：通过调整 Prompt，明确要求模型以某种固定格式输出答案（如始终使用 `\boxed{}` 包裹答案），从而减少后续提取的复杂性。

2. **改进评测方法**  
   - **引入宽松匹配机制**：除了 EM 指标外，还可以引入基于规则或语义相似度的宽松匹配机制。例如，允许分数与小数之间的转换，或者通过符号计算工具验证答案的等价性。
   - **人工复核**：对于自动评测结果存在争议的样本，引入人工复核机制，确保评测结果的准确性。
   - **多样化测试数据**：扩展测试数据集，涵盖更多样化的输入和答案格式，从而全面评估模型的鲁棒性和泛化能力。

### 提升的思考


#### (1) **高质量数据增强**
- **增加多样性**：扩展训练数据集，涵盖更多样化的数学问题类型（如代数、几何、概率等）。
- **引入多步推理数据**：收集或生成包含详细推理步骤的数据，帮助模型学习如何分解复杂问题为更简单的子问题。
- **答案格式统一化**：在训练数据中强制要求使用固定格式输出答案（如 `\boxed{}` 包裹答案），从而引导模型在推理过程中遵循一致的输出规范。


#### (2) **蒸馏**
- 在蒸馏过程中，不仅关注最终答案的正确性，还应保留教师模型的推理能力。例如，通过强化学习或对比学习让蒸馏模型模仿教师模型的推理步骤。


#### (3) **分步推理**
- 将复杂问题分解为多个子问题，并逐步验证每个子问题的答案正确性。例如：
  - 提供 Prompt 引导模型先解决一个子问题，再继续下一个。
  - 使用外部工具（如符号计算库 SymPy）验证中间结果的正确性。

#### (4) **Prompt 工程**
- **明确指令**：在 Prompt 中明确要求模型以某种固定格式输出答案（如始终使用 `\boxed{}` 包裹答案）。
- **多轮交互**：通过多轮对话引导模型逐步解决问题。例如，第一轮要求模型生成解题思路，第二轮要求生成具体步骤，最后一轮要求生成答案。

#### (5) **多样化评测指标**
- **宽松匹配**：除了 EM（Exact Match）指标外，引入基于规则或语义相似度的宽松匹配机制。例如：
  - 允许分数与小数之间的转换。
  - 使用符号计算工具（如 SymPy）验证答案的等价性。
- **部分得分**：对于多步推理问题，根据中间结果的正确性赋予部分得分，而不仅仅是最终答案的正确性。
