local mp = require "mp"
local input = require "mp.input"

local VF_PRESETS = {
    { label = "清空全部濾鏡",           cmd = 'vf clr ""' },
    { label = "補幀 MVTools_快速",     cmd = 'vf set vapoursynth="~~/vs/MEMC_MVT_LQ.vpy"' },
    { label = "補幀 RIFE_DX12",       cmd = 'vf set vapoursynth="~~/vs/MEMC_RIFE_DML.vpy"' },
    { label = "補幀 DRBA_DX12",       cmd = 'vf set vapoursynth="~~/vs/MEMC_DRBA_DML.vpy"' },
    { label = "補幀 RIFE_RTX",        cmd = 'vf set vapoursynth="~~/vs/MEMC_RIFE_NV.vpy"' },
    { label = "補幀 DRBA_RTX",        cmd = 'vf set vapoursynth="~~/vs/MEMC_DRBA_NV.vpy"' },
    { label = "自訂AI UAI_DX12",      cmd = 'vf set vapoursynth="~~/vs/MIX_UAI_DML.vpy"' },
    { label = "自訂AI UAI_RTX",       cmd = 'vf set vapoursynth="~~/vs/MIX_UAI_NV_TRT.vpy"' },
}

local function open_vf_menu()
    local items = {}
    for _, p in ipairs(VF_PRESETS) do
        table.insert(items, p.label)
    end

    input.select({
        prompt = "VF 濾鏡選單（選擇套用）",
        items = items,
        submit = function(idx)
            mp.command(VF_PRESETS[idx].cmd)
            mp.osd_message("VF: " .. VF_PRESETS[idx].label, 2)
        end,
    })
end

mp.add_key_binding("F10", "vf-menu", open_vf_menu)
