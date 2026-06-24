local mp = require "mp"
local input = require "mp.input"
local utils = require "mp.utils"

local options = {
    format = "png",
    directory = "~~desktop/",
    template = "mpv-shot%n",
    jpeg_quality = 100,
    png_compression = 4,
    webp_lossless = true,
    webp_quality = 100,
    jxl_distance = 1,
}
require "mp.options".read_options(options, "screenshot")

local FORMATS = { "png", "jpg", "webp", "jxl", "avif" }
local FORMAT_LABELS = {
    png = "PNG（無失真）",
    jpg = "JPEG（有損）",
    webp = "WebP",
    jxl = "JPEG XL",
    avif = "AVIF",
}

local function get_format_label(fmt)
    return FORMAT_LABELS[fmt] or fmt:upper()
end

local function apply_screenshot_settings()
    mp.set_property("screenshot-format", options.format)
    mp.set_property("screenshot-jpeg-quality", tostring(options.jpeg_quality))
    mp.set_property("screenshot-png-compression", tostring(options.png_compression))
    mp.set_property("screenshot-webp-lossless", options.webp_lossless and "yes" or "no")
    mp.set_property("screenshot-webp-quality", tostring(options.webp_quality))
    mp.set_property("screenshot-jxl-distance", tostring(options.jxl_distance))
    mp.set_property("screenshot-template", options.template)
    mp.set_property("screenshot-directory", options.directory)
end

local function open_settings()
    local format_labels = {}
    local format_values = {}
    for _, fmt in ipairs(FORMATS) do
        local prefix = (fmt == options.format) and "✓ " or "  "
        table.insert(format_labels, prefix .. get_format_label(fmt))
        table.insert(format_values, fmt)
    end

    table.insert(format_labels, "---")
    table.insert(format_labels, "編輯 screenshot.conf（路徑/品質）")
    table.insert(format_labels, "立即截圖")

    input.select({
        prompt = "目前格式: " .. get_format_label(options.format),
        items = format_labels,
        submit = function(idx)
            if idx <= #format_values then
                options.format = format_values[idx]
                apply_screenshot_settings()
                mp.osd_message("截圖格式: " .. get_format_label(options.format), 2)
            elseif idx == #format_values + 2 then
                local dir = mp.command_native({ "expand-path", "~~/script-opts/" })
                local path = utils.join_path(dir, "screenshot.conf")
                mp.commandv("run", "notepad", path)
                mp.osd_message("編輯 " .. path .. "，儲存後重啟 mpv", 4)
            elseif idx == #format_values + 3 then
                mp.commandv("screenshot")
            end
        end,
    })
end

mp.add_key_binding(nil, "screenshot-menu", open_settings)

apply_screenshot_settings()

mp.observe_property("file-loaded", function()
    apply_screenshot_settings()
end)
