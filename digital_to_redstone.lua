-- 引入必要的组件
local component = require("component")
local event = require("event")
local os = require("os")

-- 获取所有铁音符盒组件，并存储到表 note_blocks 中
local note_blocks = {}
for addr, type in component.list("iron_noteblock") do
    table.insert(note_blocks, component.proxy(addr))
end

-- 定义乐器映射（乐器名称 -> 乐器编号）
-- 铁音符盒支持的乐器：
-- 0：竖琴（Harp）
-- 1：贝斯（Bass）
-- 2：小鼓（Snare）
-- 3：踩镲（Hat）
-- 4：长笛（Flute）
-- 5：钟（Bell）
-- 6：吉他（Guitar）

local instruments = {
    harp = 0,       -- 竖琴
    bass = 1,       -- 贝斯
    snare = 2,      -- 小鼓（打击乐）
    hat = 3,        -- 踩镲（打击乐）
    flute = 4,      -- 长笛
    bell = 5,       -- 钟
    guitar = 6,     -- 吉他
}

-- 设置一个元表，任何未定义的键都返回 0（竖琴）
setmetatable(instruments, {
    __index = function(t, key)
        return 0
    end
})

-- 定义乐器 ID 映射表，将不支持的乐器 ID 映射到支持的乐器
local instrument_id_map = {
    [35] = "bass",    -- 将乐器 ID 35 映射到贝斯
    [106] = "harp",  -- 将乐器 ID 106 映射到竖琴 * 
    [73] = "bell",   -- 将乐器 ID 73 映射到钟
    [48] = "bell",
    [96] = "bell",     -- 将乐器 ID 96 映射到钟 *
    [2] = "harp",    -- 将乐器 ID 2 映射到竖琴 *(可能吉他效果更好)
    [74] = "bell",   -- 将乐器 ID 74 映射到钟
    [68] = "bell",
    [85] = "bell",
    [9] = "snare",   -- 将乐器 ID 9 映射到小鼓
    [0] = "harp",    -- 将乐器 ID 0 映射到竖琴
}

-- 读取数字谱文件
local function load_score(file_path)
    local score = {}
    local file = io.open(file_path, "r")
    for line in file:lines() do
        -- 解析每行数据：音轨编号,通道编号,乐器id,音符编号,开始时间,持续时间
        local track, channel, instrument, note, start_time, duration = line:match("(%d+),(%d+),(%w+),(%d+),(%d+%.%d+),(%d+%.%d+)")
        instrument = tonumber(instrument)
        -- 将不支持的乐器 ID 映射到支持的乐器
        local instrument_name = instrument_id_map[instrument] or "harp"
        table.insert(score, {
            track = tonumber(track),      -- 音轨编号
            channel = tonumber(channel),  -- 通道编号
            instrument = instrument_name, -- 乐器名称
            note = tonumber(note),        -- 音符编号
            start = tonumber(start_time), -- 开始时间
            duration = tonumber(duration) -- 持续时间
        })
    end
    file:close()
    -- 按开始时间对所有音符进行排序
    table.sort(score, function(a, b) return a.start < b.start end)
    return score
end

-- 计算每个乐器所需的最大铁音符盒数
-- 算法思路：
-- 维护一个 active_notes 表，它按乐器分组存储当前活跃的音符。
-- 当处理每个音符时，添加它到对应乐器的活跃音符列表，并移除那些已经结束的音符。
-- 然后计算每个乐器在任意时刻活跃音符的数量，并更新最大铁音符盒数

local function calculate_max_noteblocks(score)

    local max_noteblocks = {} -- 存储每个音轨所需的最大铁音符盒数
    local active_notes = {} -- 当前活跃的音符，按音轨分组

    -- 遍历所有音符
    for _, note in ipairs(score) do
        -- 如果音轨尚未在表中，则初始化
        if not active_notes[note.track] then
            active_notes[note.track] = {}
        end

        -- 添加音符到活跃音符表
        table.insert(active_notes[note.track], note)

        -- 移除已结束的音符
        for i = #active_notes[note.track], 1, -1 do
            local active_note = active_notes[note.track][i]
            if active_note.start + active_note.duration <= note.start then
                table.remove(active_notes[note.track], i)
            end
        end

        -- 更新最大铁音符盒数
        local count = #active_notes[note.track]
        if not max_noteblocks[note.track] or max_noteblocks[note.track] < count then
            max_noteblocks[note.track] = count
        end
    end

    return max_noteblocks
end

-- 分配铁音符盒
-- 输出：二维数组allocated[track][i]，表示音轨track的第i个铁音符盒
local function allocate_noteblocks(max_noteblocks, noteblocks)
    -- 如果没有足够的铁音符盒，则返回nil
    local total_needed = 0
    for _, count in pairs(max_noteblocks) do
        total_needed = total_needed + count
    end
    if #noteblocks < total_needed then
        print("当前音符盒数：" .. #noteblocks .. "，共需要 " .. total_needed .. " 个音符盒")
        return nil
    end

    local allocated = {} -- 存储分配的铁音符盒
    local index = 1
    for track, count in pairs(max_noteblocks) do
        allocated[track] = {}
        -- 分配铁音符盒给音轨track
        for i = 1, count do
            allocated[track][i] = noteblocks[index]
            index = index + 1
        end
    end
    return allocated
end

-- 播放音乐
-- 播放算法：
-- 按开始时间排序，每次播放相同开始时间的声音，
-- 之后休眠相邻行之间的开始时间时间差，播放之后的行。

local function play_music(score, allocated_noteblocks)
    local laststarttime = 0 -- 上一个播放的音符的开始时间
    local currentgroup = {} -- 当前时间点的音符组
    local noteblock_index = {} -- 存储每个音轨当前使用的铁音符盒索引

    -- 初始化 noteblock_index
    for track, _ in pairs(allocated_noteblocks) do
        noteblock_index[track] = 1
    end

    for _, note in ipairs(score) do
        table.insert(currentgroup, note) -- 将音符添加到当前组

        -- 打印 note 的各个值用于测试
        print("Track: " .. note.track ..
              ", Channel: " .. note.channel ..
              ", Instrument: " .. note.instrument ..
              ", Note: " .. note.note ..
              ", Start: " .. note.start ..
              ", Duration: " .. note.duration)

        -- 到达下一个时间点
        if note.start ~= laststarttime then
            -- 播放当前组的音符
            for _, group_note in ipairs(currentgroup) do
                -- 获取音轨对应的铁音符盒编号
                local track = group_note.track
                local noteblocks = allocated_noteblocks[track]
                if noteblocks then
                    -- 获取当前使用的铁音符盒
                    local noteblock = noteblocks[noteblock_index[track]]
                    -- 调整音符编号到 [0-24] 范围内
                    local adjusted_note = group_note.note
                    -- 调到对应的调
                    adjusted_note = adjusted_note - 54
                    while adjusted_note < 0 do
                        -- 增八度
                        adjusted_note = adjusted_note + 12
                    end
                    while adjusted_note > 24 do
                        -- 降八度
                        adjusted_note = adjusted_note - 12
                    end
                    -- 播放音符（乐器编号，音符编号）
                    noteblock.playNote(instruments[group_note.instrument], adjusted_note)

                    -- 更新铁音符盒索引，循环使用铁音符盒
                    noteblock_index[track] = noteblock_index[track] % #noteblocks + 1
                end
            end

            -- 计算下一个音符的开始时间与当前时间的差值，作为休眠时间
            local delay = note.start - laststarttime
            os.sleep(delay)

            currentgroup = {} -- 重置当前组的音符
            laststarttime = note.start -- 更新上一个播放的音符的开始时间
        end

    end
end

-- 列出 songs 文件夹中的所有歌曲
local function list_songs(folder_path)
    local songs = {}
    for file in io.popen('dir "'..folder_path..'" /b'):lines() do
        if file:match("%.txt$") then
            table.insert(songs, file)
        end
    end
    return songs
end

-- 主程序
-- 获取歌曲文件
local songs_folder = "./songs"
local songs = list_songs(songs_folder)

print("歌曲列表：")
for i, song in ipairs(songs) do
    print(i .. ". " .. song)
end

print("请输入要播放的歌曲编号：")
local choice = tonumber(io.read())
if choice and choice >= 1 and choice <= #songs then
    local selected_song = songs[choice]
    local score_file = songs_folder .. "/" .. selected_song  -- 选择的数字谱文件路径
    local score = load_score(score_file) -- 读取数字谱文件
    local max_noteblocks = calculate_max_noteblocks(score) -- 计算每个音轨所需的最大铁音符盒数
    for track, count in pairs(max_noteblocks) do
        print("音轨：" .. track .. "，所需铁音符盒数：" .. count)
    end
    local allocated_noteblocks = allocate_noteblocks(max_noteblocks, note_blocks) -- 分配铁音符盒
    if allocated_noteblocks then
        print("开始播放音乐...")
        play_music(score, allocated_noteblocks)
        print("音乐播放完毕！")
    else
        print("铁音符盒数量不足，无法播放音乐。")
    end
else
    print("无效的选择。")
end