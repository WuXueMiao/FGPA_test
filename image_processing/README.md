# Sobel 图像边缘检测模块

本目录为 FGPA 赛题四的图像处理模块当前版本，实现基于 3×3 Sobel 算子的流式边缘检测。

## 已实现功能

- 8 位灰度像素流输入；
- 行缓存生成 3×3 像素窗口；
- Sobel 水平、垂直梯度计算；
- 使用 `|Gx| + |Gy|` 近似梯度幅值；
- 阈值二值化：当 `magnitude > threshold` 时输出白色边缘；
- 支持 `pixel_valid` 间断、帧起始 `sof` 和行结束 `eol`；
- 输出边缘像素及其中心坐标。

## 文件说明

- `rtl/window_3_3.v`：3×3 滑动窗口生成模块。
- `rtl/sobel_core.v`：Sobel 梯度计算与阈值二值化核心。
- `rtl/sobel_stream_top.v`：窗口模块与 Sobel 核心的流式封装。
- `sim/tb_sobel_stream_top.v`：仿真测试平台。
- `Dockerfile`：包含 Icarus Verilog 的仿真环境。

## 仿真结果

测试包含一帧黑白竖直边缘图像和一帧均匀图像，并插入 `pixel_valid` 间断。

```text
有效结果总数：18，预期为 18
检测到边缘：6，预期为 6
非边缘区域：12，预期为 12