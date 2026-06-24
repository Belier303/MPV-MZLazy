-- yt-dlp 下載輔助腳本
-- 透過右鍵選單觸發，非同步下載目前影片

local mp = require("mp")

local O = {
    download_path = "~~desktop/",
    preset = "1080p",
}

local output_format = "mp4"

local CONFIG_NAME = "~~/ytdl_download.conf"

local function read_config()
    local conf_path = mp.command_native({"expand-path", CONFIG_NAME})
    local f = io.open(conf_path, "r")
    if f then
        local c = f:read("*all")
        f:close()
        local dp = c:match("download_path%s*=%s*(%S+)")
        if dp then O.download_path = dp end
        local pr = c:match("preset%s*=%s*(%S+)")
        if pr then O.preset = pr end
        local of = c:match("output_format%s*=%s*(%S+)")
        if of then output_format = of end
    end
end
read_config()

local function set_output_format(fmt)
    output_format = fmt
    local conf_path = mp.command_native({"expand-path", CONFIG_NAME})
    local f = io.open(conf_path, "r")
    if f then
        local c = f:read("*all")
        f:close()
        c = c:gsub("output_format%s*=%s*%S+", "output_format=" .. fmt)
        f = io.open(conf_path, "w")
        if f then
            f:write(c)
            f:close()
        end
    end
    mp.osd_message("輸出格式：" .. fmt:upper(), 2)
end

local FORMATS = {
    best      = "bestvideo+bestaudio/best",
    ["1080p"] = "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
    ["720p"]  = "bestvideo[height<=720]+bestaudio/best[height<=720]",
    audio_best = "bestaudio/best",
    audio_m4a  = "bestaudio[ext=m4a]/bestaudio",
}

local function expand_path(p)
    local ok, result = pcall(mp.command_native, {"expand-path", p})
    return ok and result or p
end

local function get_path()
    return mp.get_property("path", "")
end

local function download(preset)
    local path = get_path()
    if path == "" or path:find("^http") == nil then
        mp.osd_message("目前播放的內容無法下載（非網路串流）", 4)
        return
    end

    local fmt = FORMATS[preset] or FORMATS["1080p"]
    local dir = expand_path(O.download_path)
    local template = dir .. "%(title)s-%(id)s.%(ext)s"

    mp.osd_message("正在下載（" .. preset .. ", " .. output_format:upper() .. "）→ " .. dir, 0)

    mp.command_native_async({
        name = "subprocess",
        args = {
            "yt-dlp",
            "-f", fmt,
            "--merge-output-format", output_format,
            "--remux-video", output_format,
            "-o", template,
            "--no-playlist",
            "--print", "after_move:filepath",
            "--no-progress",
            path,
        },
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, res)
        if not success then
            mp.osd_message("下載失敗：無法執行 yt-dlp", 5)
            return
        end
        if res.status == 0 then
            local name = (res.stdout or ""):match("[^\r\n]+")
            mp.osd_message("下載完成：" .. (name or "ok"), 6)
        else
            local msg = (res.stderr or ""):gsub("[\r\n]", " "):sub(1, 80)
            mp.osd_message("下載失敗：" .. msg, 6)
        end
    end)
end

local function download_best()
    download("best")
end

local function download_1080p()
    download("1080p")
end

local function download_720p()
    download("720p")
end

local function download_audio_best()
    download("audio_best")
end

local function download_audio_m4a()
    download("audio_m4a")
end

local function open_settings()
    mp.commandv("script-message-to", "input_plus", "edit", "~~/ytdl_download.conf")
end

local function open_folder()
    local dir = expand_path(O.download_path)
    mp.command_native_async({
        name = "subprocess",
        args = {"explorer.exe", dir},
        detach = true,
    }, function() end)
end

mp.register_script_message("ytdl_best",      download_best)
mp.register_script_message("ytdl_1080p",     download_1080p)
mp.register_script_message("ytdl_720p",      download_720p)
mp.register_script_message("ytdl_audio_best", download_audio_best)
mp.register_script_message("ytdl_audio_m4a",  download_audio_m4a)
mp.register_script_message("ytdl_settings",   open_settings)
mp.register_script_message("ytdl_open_folder", open_folder)
mp.register_script_message("ytdl_fmt_mp4",  function() set_output_format("mp4") end)
mp.register_script_message("ytdl_fmt_mkv",  function() set_output_format("mkv") end)
