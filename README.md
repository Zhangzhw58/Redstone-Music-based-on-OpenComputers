# 基于 OpenComputers 的红石音乐系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Minecraft 1.7.10](https://img.shields.io/badge/Minecraft-1.7.10-brightgreen)](https://www.minecraft.net)
[![OpenComputers GTNH](https://img.shields.io/badge/OpenComputers-1.10.27--GTNH-blue)](https://ocdoc.cil.li)

通过 MIDI 协议实现自动化红石音乐播放系统，使用 Computronics 模组的[铁音符盒](https://www.mcmod.cn/item/529971.html)实现多音轨编曲控制。

## 📦 功能特性

- **MIDI 到红石信号转换**  
  支持标准 MIDI 文件解析与数字化映射
- **多乐器支持**  
  适配铁音符盒的 7 种乐器类型（竖琴/贝斯/小鼓/踩镲/长笛/钟/吉他）
- **精确时序控制**  
  基于 OpenComputers 的高精度定时器（误差 < 0.1s）

## 🛠️ 环境要求

### 开发环境
| 组件 | 版本 |
|------|----------|
| Python | 3.11.4 |
| mido 库 | 1.3.3 |

### 游戏环境
| Mod | 版本 |
|-----|------|
| Minecraft | 1.7.10 |
| OpenComputers | 1.10.27-GTNH |
| Computronics | 1.8.5-GTNH |

## 📂 项目结构

```
redstone-music-system/
├── midi/                      # 原始 MIDI 文件
│   └── [song_name].mid      
├── songs/                     # 转换后的数字谱
│   └── [song_name].txt        # 音轨数据文件
├── midi_to_digital.py         # MIDI 转换脚本
└── digital_to_redstone.lua    # OC 控制程序
```

## 🚀 快速开始

### 步骤 1 - MIDI 文件准备
1. 从 [MidiShow](https://www.midishow.com) 网站下载 MIDI 文件
2. 将文件保存至 `midi/` 目录
3. （可选）使用 [Note Block Studio](https://opennbs.org/) 试听和编辑音轨

### 步骤 2 - 转换数字谱

将`midi/`目录下的原始 MIDI 文件转换为数字谱，保存于`songs/`目录

```bash
$ python3 midi_to_digital.py
```

### 步骤 3 - 部署到 OpenComputers

1. 将以下文件复制到 OC 计算机：
   - `songs/` 目录
   - `digital_to_redstone.lua`
2. 将 OC 计算机连接到铁音符盒阵列

### 步骤 4 - 运行程序

```lua
lua digital_to_redstone.lua
```

## ⚙️ 音轨文件格式

示例 `sample.txt`:
```plaintext
# 格式: [音轨],[通道],[乐器编号],[音符],[开始时间],[持续时间]
0,1,106,60,0.00,0.50
0,2,96,48,0.25,0.75
1,3,7,42,0.50,0.10
```

字段说明：
| 字段 | 范围 | 说明 |
|------|------|------|
| 音轨 | 0-127 | MIDI 音轨 |
| 通道 | 1-16  | MIDI 通道 |
| 乐器 | 0-127 | MIDI 乐器类型 |
| 音符 | 0-127 | MIDI 音符编号（音调） |
| 开始时间 | ≥0 | 单位：秒 |
| 持续时间 | ≥0 | 单位：秒 |

你可以在 README.md 文件中添加一个链接，指向一个包含 MIDI 乐器 ID 对应乐器表的文档。以下是如何在 README.md 文件中添加该链接的示例：

### 🎵 MIDI 乐器 ID 对应表

你可以在 [这里](https://www.midi.org/specifications-old/item/gm-level-1-sound-set) 查看完整的 MIDI 乐器 ID 对应表。

<!-- ## 🧩 扩展开发

### 自定义乐器映射
编辑 `instrument_map.json`:
```json
{
  "piano": "harp",
  "strings": "bell",
  "synth": "flute"
}
``` -->

<!-- ## 📚 技术文档

详见 [技术规范](docs/specification.md) 和 [API 参考](docs/api.md) -->

<!-- ## ❓ 常见问题

Q: 如何处理不支持的 MIDI 乐器？  
A: 通过 `--instrument-map` 参数指定映射规则

Q: 时间精度不足导致节奏不稳？  
A: 调整计算机配置文件中的 `threadPriority`

Q: 如何扩展支持更多音符盒？  
A: 继承 `NoteBlockController` 类并实现接口 -->

## 📜 许可证

Copyright © 2025 [Zhangzhw58]

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
