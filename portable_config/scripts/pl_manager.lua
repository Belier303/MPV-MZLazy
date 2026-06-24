local ass = require("mp.assdraw")
local utils = require("mp.utils")

local ov = nil
local active = false
local cursor = 0
local items = {}
local n_items = 0

local function file_dialog()
    local was = mp.get_property_native("ontop")
    if was then mp.command("no-osd set ontop no") end
    local res = utils.subprocess({
        args = {"powershell", "-NoProfile", "-Command", [[& {
            Trap { Write-Error -ErrorRecord $_; Exit 1 }
            Add-Type -AssemblyName PresentationFramework
            $u8 = [System.Text.Encoding]::UTF8
            $out = [Console]::OpenStandardOutput()
            $ofd = New-Object Microsoft.Win32.OpenFileDialog
            $ofd.Multiselect = $true
            If ($ofd.ShowDialog() -eq $true) {
                ForEach ($f in $ofd.FileNames) {
                    $b = $u8.GetBytes("$f`n"); $out.Write($b, 0, $b.Length)
                }
            }
        }]]},
        cancellable = false, capture_stdout = true, capture_stderr = true,
    })
    if was then mp.command("no-osd set ontop yes") end
    if res.status ~= 0 or not res.stdout then return end
    for f in string.gmatch(res.stdout, '[^\n]+') do
        local safe = f:gsub('\\', '/'):gsub('"', '\\"')
        mp.command('no-osd loadfile "' .. safe .. '" append')
    end
end

local function folder_dialog()
    local was = mp.get_property_native("ontop")
    if was then mp.command("no-osd set ontop no") end
    local res = utils.subprocess({
        args = {"powershell", "-NoProfile", "-Command", [[& {
            Trap { Write-Error -ErrorRecord $_; Exit 1 }
            Add-Type -AssemblyName PresentationFramework, System.Windows.Forms
            $u8 = [System.Text.Encoding]::UTF8
            $out = [Console]::OpenStandardOutput()
            $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
            $fbd.Description = "選取資料夾"
            If ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $b = $u8.GetBytes($fbd.SelectedPath + "`n"); $out.Write($b, 0, $b.Length)
            }
        }]]},
        cancellable = false, capture_stdout = true, capture_stderr = true,
    })
    if was then mp.command("no-osd set ontop yes") end
    if res.status ~= 0 or not res.stdout then return end
    local dir = res.stdout:match('[^\n]+')
    if dir then mp.commandv("loadfile", dir, "append") end
end

local function build_items()
    items = {}
    items[#items+1] = {type="add_file", label="加入檔案..."}
    items[#items+1] = {type="add_folder", label="加入資料夾..."}
    items[#items+1] = {type="clear", label="清空播放清單"}
    items[#items+1] = {type="sep", label="────────────────"}
    local pl = mp.get_property_native("playlist") or {}
    local pos = mp.get_property_number("playlist-pos", 0)
    for i, e in ipairs(pl) do
        local fn = e.title or e.filename:match("[^/\\]+$") or e.filename
        local p = (i-1)==pos and "> " or "  "
        items[#items+1] = {type="item", index=i-1, label=p..fn}
    end
    n_items = #items
end

local function render()
    if not active then return end
    build_items()
    local a = ass.ass_new()
    local y = 80
    for i = 1, n_items do
        local it = items[i]
        local isc = (i-1) == cursor
        a:new_event()
        a:pos(100, y)
        if it.type == "sep" then
            a:append("{\\bord0\\fs12\\1c&H666666&}" .. it.label)
        elseif isc then
            a:append("{\\bord0\\b1\\fs18\\1c&HFF8232&}> " .. it.label)
        else
            a:append("{\\bord0\\fs18\\1c&HCCCCCC&}  " .. it.label)
        end
        y = y + 28
    end
    a:new_event()
    a:pos(100, y + 10)
    a:append("{\\bord0\\fs12\\1c&H999999&}[上/下選 Enter確認 Esc關閉]")

    if not ov then ov = mp.create_osd_overlay("ass-events") end
    ov.data = a.text
    ov:update()
end

local function do_select()
    if not active then return end
    local it = items[cursor+1]
    if not it then return end
    if it.type == "add_file" then
        hide(); file_dialog(); show()
    elseif it.type == "add_folder" then
        hide(); folder_dialog(); show()
    elseif it.type == "clear" then
        mp.commandv("playlist-clear")
        render()
    elseif it.type == "item" then
        mp.commandv("set", "playlist-pos", it.index)
        hide()
    end
end

function show()
    active = true; cursor = 0
    render()
    mp.add_forced_key_binding("UP", "pl_up", function()
        if not active then return end
        cursor = (cursor - 1 + n_items) % n_items
        render()
    end)
    mp.add_forced_key_binding("DOWN", "pl_dn", function()
        if not active then return end
        cursor = (cursor + 1) % n_items
        render()
    end)
    mp.add_forced_key_binding("ENTER", "pl_en", do_select)
    mp.add_forced_key_binding("ESC", "pl_es", hide)
end

function hide()
    if not active then return end
    active = false
    if ov then ov:remove(); ov = nil end
    mp.remove_key_binding("pl_up")
    mp.remove_key_binding("pl_dn")
    mp.remove_key_binding("pl_en")
    mp.remove_key_binding("pl_es")
end

mp.register_script_message("pl-add-file", show)
