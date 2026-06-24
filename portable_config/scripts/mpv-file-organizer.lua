-- mpv-file-organizer.lua — 媒體檔案整理工具
-- 根據 Album 中繼資料將目前播放的檔案複製到指定目錄
-- 來源: https://github.com/borasavkar/mpv-file-organizer
-- 快捷鍵: Ctrl+c

local mp = require 'mp'
local msg = require 'mp.msg'

local ARCHIVE_ROOT = "C:\\Media"
local KEY_BINDING = "ctrl+c"

local function sanitize_name(name)
    if not name then return "Unknown_Album" end
    name = name:gsub("[\\/:*?\"<>|]", "-")
    name = name:gsub("^%s*(.-)%s*$", "%1")
    return name
end

local function archive_file()
    local current_path = mp.get_property("path")
    local filename = mp.get_property("filename")
    local album_tag = mp.get_property("metadata/by-key/album")
    if not current_path then
        mp.osd_message("沒有正在播放的媒體！", 2)
        return
    end
    if not album_tag or album_tag == "" then
        mp.osd_message("錯誤：找不到 Album 中繼資料標籤！", 4)
        return
    end
    local safe_album = sanitize_name(album_tag)
    local target_folder = ARCHIVE_ROOT .. "\\" .. safe_album
    local target_file_path = target_folder .. "\\" .. filename
    mp.osd_message("正在歸檔: " .. safe_album, 999)
    local cmd = string.format(
        'cmd /c mkdir "%s" & copy "%s" "%s" & explorer /select,"%s"',
        target_folder, current_path, target_folder, target_file_path
    )
    os.execute(cmd)
    mp.osd_message("已複製到: " .. safe_album, 3)
end

mp.add_key_binding(KEY_BINDING, "archive-media", archive_file)
