基于 OpenComputers(OC) 的红石音乐

有关知识
1、midi：
2、铁音符盒：CC 模组方块，提供了``接口，可以播放6种乐器，[0-24]音调

基本思路：
1、在 MidiShow 网站上下载所需的 midi 音频，保存在midi文件夹中
2、通过`midi_to_digital.py`将midi音频转换为保存“音调”、“开始时间”等信息的.txt文件，保存在songs文件夹中
3、将songs文件夹和`digital_to_redstone.lua`文件复制到 OpenComputer 的电脑中
4、在OC电脑上运行`digital_to_redstone.lua`，读取.txt文件信息，转换为对应的信号控制音符盒播放

运行环境:
python3.11.4 + mido库

游戏环境:
GTNH-2.7.0 (Micraft 1.7.10 + OpenComputers-1.10.27-GTNH + )
