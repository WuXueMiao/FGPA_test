# OV5640 RGB565 Sobel 图像边缘检测模块

本目录实现 OV5640 摄像头 DVP 图像输入的实时 Sobel 边缘检测流水线，并使用 Docker + Icarus Verilog 完成仿真验证。

## 功能链路

```text
OV5640 摄像头 DVP（RGB565）
→ RGB565 转 8 位灰度
→ 3×3 滑动窗口
→ Sobel 边缘检测
→ 边缘图像输出
```

OV5640 通过 8 位 DVP 接口输出 RGB565 数据。由于每个 RGB565 像素占 16 位，因此一个像素由两个 8 位数据周期组成。本工程先将其转换为 8 位灰度像素，再进行 3×3 Sobel 边缘检测。

## 摄像头输入配置

| 项目         | 参数                             |
| ---------- | ------------------------------ |
| 摄像头型号      | OV5640                         |
| 图像接口       | 8 位 DVP                        |
| 数据格式       | RGB565                         |
| 分辨率        | 1280 × 720                     |
| 输入信号       | `PCLK`、`VSYNC`、`HREF`、`D[7:0]` |
| Sobel 默认阈值 | `11'd200`                      |

## 目录结构

```text
image_processing/
├── rtl/
│   ├── dvp_rgb565_to_gray.v   # RGB565 DVP 数据转灰度像素流
│   ├── window_3_3.v           # 3×3 滑动窗口生成
│   ├── sobel_core.v           # Sobel 梯度计算与二值化
│   ├── sobel_stream_top.v     # 灰度像素流 Sobel 顶层
│   └── camera_sobel_top.v     # OV5640 DVP 到 Sobel 的连接顶层
├── sim/
│   ├── tb_dvp_rgb565_to_gray.v # RGB565 转灰度仿真
│   ├── tb_sobel_stream_top.v   # 灰度 Sobel 流水线仿真
│   └── tb_camera_sobel_top.v   # 摄像头 RGB565 到 Sobel 端到端仿真
├── Dockerfile
└── README.md
```

## 模块说明

| 模块                   | 功能                                                                                  |     |   |     |                        |
| -------------------- | ----------------------------------------------------------------------------------- | --- | - | --- | ---------------------- |
| `dvp_rgb565_to_gray` | 接收 `PCLK/VSYNC/HREF/D[7:0]`，每两个字节组合为一个 RGB565 像素，输出灰度像素及 `pixel_valid`、`sof`、`eol`。 |     |   |     |                        |
| `window_3x3`         | 对连续灰度像素流生成 3×3 像素窗口，并输出窗口中心坐标。                                                      |     |   |     |                        |
| `sobel_core`         | 计算水平、垂直梯度，使用 (                                                                      | G_x | + | G_y | ) 近似梯度幅值，并依据阈值输出黑白边缘图。 |
| `sobel_stream_top`   | 连接滑动窗口模块与 Sobel 核心，输入灰度像素流，输出边缘像素流。                                                 |     |   |     |                        |
| `camera_sobel_top`   | 连接 DVP RGB565 输入、灰度转换与 Sobel 流水线，是后续接入 Efinity `example_top.v` 的接口模块。               |     |   |     |                        |

## 仿真环境

使用 Docker 容器中的 Icarus Verilog：

```powershell
docker build -t sobel-sim .
```

## RGB565 转灰度仿真

```powershell
docker run --rm -v "${PWD}:/work" -w /work sobel-sim iverilog -o sim/dvp_gray_test.vvp rtl/dvp_rgb565_to_gray.v sim/tb_dvp_rgb565_to_gray.v
docker run --rm -v "${PWD}:/work" -w /work sobel-sim vvp sim/dvp_gray_test.vvp
```

验证黑、红、绿、蓝、白五种 RGB565 像素的灰度转换，以及帧起始标志 `sof`、行结束标志 `eol`。

## 摄像头到 Sobel 的端到端仿真

```powershell
docker run --rm -v "${PWD}:/work" -w /work sobel-sim iverilog -o sim/camera_sobel_test.vvp rtl/dvp_rgb565_to_gray.v rtl/window_3_3.v rtl/sobel_core.v rtl/sobel_stream_top.v rtl/camera_sobel_top.v sim/tb_camera_sobel_top.v
docker run --rm -v "${PWD}:/work" -w /work sobel-sim vvp sim/camera_sobel_test.vvp
```

当前端到端仿真使用两帧 5×5 RGB565 测试图像：

1. 左黑右白图像：预期检测到竖直边缘；
2. 均匀黑色图像：预期不检测到边缘。

仿真结果：

```text
有效结果总数：18，预期为 18
检测到边缘：6，预期为 6
非边缘区域：12，预期为 12
```

说明 RGB565 数据接收、灰度转换、3×3 滑动窗口和 Sobel 边缘检测的完整流水线均已验证通过。

## 后续工作

* 将 `camera_sobel_top` 实例化到 Efinity 工程的 `example_top.v`；
* 配置 OV5640 的实际 DVP 引脚与时钟约束；
* 将 `edge_out` 接入显示输出链路；
* 根据实物图像效果调整 Sobel 阈值；
* 完成 Efinity 综合、布局布线与上板验证。
