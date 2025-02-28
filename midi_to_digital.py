# midi_to_digital.py - 将 MIDI 文件转换为数字谱(.txt)文件。
# 数字谱文件格式：
# 音轨编号,通道编号,乐器ID,音符编号,开始时间,持续时间

import os
import mido

def midi_to_digital_score(midi_path, output_path):
    # 打开 MIDI 文件
    midi = mido.MidiFile(midi_path)

    # 初始化音轨数据
    tracks = []
    for i, track in enumerate(midi.tracks):
        current_time = 0  # 当前时间（以 ticks 为单位）
        current_instrument = 0  # 当前乐器（默认大钢琴）
        notes = []  # 存储音符事件

        for msg in track:
            current_time += msg.time  # 累加时间

            if msg.type == "program_change":
                # 乐器切换事件
                current_instrument = msg.program
            elif msg.type == "note_on" and msg.velocity > 0:
                # 音符开始事件
                notes.append({
                    "track": i + 1,  # 音轨编号
                    "channel": msg.channel + 1,  # 通道编号
                    "instrument": current_instrument,
                    "note": msg.note,
                    "start": current_time,
                    "duration": 0  # 持续时间暂未计算
                })
            elif msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
                # 音符结束事件
                for note in reversed(notes):
                    if note["note"] == msg.note and note["duration"] == 0:
                        note["duration"] = current_time - note["start"]
                        break

        # 将 ticks 转换为秒
        for note in notes:
            note["start"] = round(mido.tick2second(note["start"], midi.ticks_per_beat, mido.bpm2tempo(120)), 4)
            note["duration"] = round(mido.tick2second(note["duration"], midi.ticks_per_beat, mido.bpm2tempo(120)), 4)

        tracks.extend(notes)

    # 按开始时间排序
    tracks.sort(key=lambda x: x["start"])

    # 保存为数字谱文件
    with open(output_path, "w") as f:
        for note in tracks:
            # 音轨编号,通道编号,乐器ID,音符编号,开始时间,持续时间
            f.write(f"{note['track']},{note['channel']},{note['instrument']},{note['note']},{note['start']},{note['duration']}\n")

    print(f"转换完成！数字谱已保存到 {output_path}")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))  # 获取脚本所在目录
    midi_dir = os.path.join(script_dir, 'midi')  # MIDI 文件夹路径
    songs_dir = os.path.join(script_dir, 'songs')  # 输出的数字谱文件夹路径

    # 确保输出目录存在
    os.makedirs(songs_dir, exist_ok=True)

    # 遍历 MIDI 文件夹中的所有 .mid 文件
    for midi_file in os.listdir(midi_dir):
        if midi_file.endswith('.mid'):
            midi_path = os.path.join(midi_dir, midi_file)  # 源 MIDI 文件路径
            song_name = os.path.splitext(midi_file)[0]  # 去掉文件扩展名
            output_path = os.path.join(songs_dir, f'{song_name}.txt')  # 输出的数字谱文件路径
            midi_to_digital_score(midi_path, output_path)  # 转换 MIDI 文件