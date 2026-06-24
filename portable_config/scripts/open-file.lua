local utils = require 'mp.utils'

local function run_ps(ps)
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.command("no-osd set ontop no") end
    local res = utils.subprocess({
        args = {'powershell', '-NoProfile', '-Command', ps},
        cancellable = false,
        capture_stdout = true,
        capture_stderr = true,
    })
    if was_ontop then mp.command("no-osd set ontop yes") end
    if res.status ~= 0 then return end
    return res.stdout
end

function open()
    mp.command("no-osd script-binding console/disable")
    mp.set_property_number("osd-level", 0)
    mp.command("no-osd set osd-playing-msg ''")
    local out = run_ps([[& {
        Trap { Write-Error -ErrorRecord $_; Exit 1 }
        Add-Type -AssemblyName PresentationFramework
        $u8 = [System.Text.Encoding]::UTF8
        $out = [Console]::OpenStandardOutput()
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Multiselect = $true
        If ($ofd.ShowDialog() -eq $true) {
            ForEach ($f in $ofd.FileNames) {
                $b = $u8.GetBytes("$f`n")
                $out.Write($b, 0, $b.Length)
            }
        }
    }]])
    if not out then mp.add_timeout(3, function() mp.set_property_number("osd-level", 1) end) return end
    local first = true
    for f in string.gmatch(out, '[^\n]+') do
        local safe = f:gsub('\\', '/'):gsub('"', '\\"')
        mp.command('no-osd loadfile "' .. safe .. '" ' .. (first and 'replace' or 'append'))
        first = false
    end
    mp.add_timeout(3, function()
        mp.set_property_number("osd-level", 1)
    end)
end

function add_subtitle()
    local out = run_ps([[& {
        Trap { Write-Error -ErrorRecord $_; Exit 1 }
        Add-Type -AssemblyName PresentationFramework
        $u8 = [System.Text.Encoding]::UTF8
        $out = [Console]::OpenStandardOutput()
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Filter = "字幕|*.srt;*.ass;*.ssa;*.sub;*.idx;*.sup;*.vtt;*.mks|全部|*.*"
        If ($ofd.ShowDialog() -eq $true) {
            $b = $u8.GetBytes($ofd.FileName + "`n")
            $out.Write($b, 0, $b.Length)
        }
    }]])
    if not out then return end
    local fn = out:match('[^\n]+')
    if fn then
        local safe = fn:gsub('\\', '/'):gsub('"', '\\"')
        mp.command('no-osd sub-add "' .. safe .. '" select')
    end
end

function add_audio()
    local out = run_ps([[& {
        Trap { Write-Error -ErrorRecord $_; Exit 1 }
        Add-Type -AssemblyName PresentationFramework
        $u8 = [System.Text.Encoding]::UTF8
        $out = [Console]::OpenStandardOutput()
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Filter = "音訊|*.mp3;*.flac;*.aac;*.ogg;*.wav;*.m4a;*.opus;*.wma;*.mka;*.ac3;*.dts;*.ape|全部|*.*"
        If ($ofd.ShowDialog() -eq $true) {
            $b = $u8.GetBytes($ofd.FileName + "`n")
            $out.Write($b, 0, $b.Length)
        }
    }]])
    if not out then return end
    local fn = out:match('[^\n]+')
    if fn then
        local safe = fn:gsub('\\', '/'):gsub('"', '\\"')
        mp.command('no-osd audio-add "' .. safe .. '" select')
    end
end

mp.add_key_binding('Ctrl+o', 'open', open)
mp.add_key_binding('Alt+o', 'open_alt', open)
mp.add_key_binding('Ctrl+Shift+s', 'add_subtitle', add_subtitle)
mp.add_key_binding('Ctrl+Shift+a', 'add_audio', add_audio)
mp.register_script_message('open', open)
mp.register_script_message('add_subtitle', add_subtitle)
mp.register_script_message('add_audio', add_audio)

-- property-based trigger for external scripts (e.g. modernz menu)
mp.observe_property("user-data/modernz/do-add-subtitle", "bool", function(_, val)
    if val then
        mp.set_property_native("user-data/modernz/do-add-subtitle", false)
        add_subtitle()
    end
end)
