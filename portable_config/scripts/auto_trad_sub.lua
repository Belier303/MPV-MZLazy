local function autoselect_trad_chinese()
    local tracks = mp.get_property_native("track-list") or {}
    local sub_count = 0
    local trad_idx = nil
    local first_idx = nil
    for _, t in ipairs(tracks) do
        if t.type == "sub" then
            local lang = (t.lang or ""):lower()
            local title = (t.title or ""):lower()
            sub_count = sub_count + 1
            if not first_idx then first_idx = t.id end
            if title:match("繁") or title:match("traditional") or lang == "zh-tw" or lang == "cht" then
                trad_idx = t.id
            end
        end
    end
    if trad_idx then
        mp.set_property("sid", trad_idx)
    end
end

mp.observe_property("track-list", "native", function()
    if mp.get_property("vid") ~= "no" then
        autoselect_trad_chinese()
    end
end)
