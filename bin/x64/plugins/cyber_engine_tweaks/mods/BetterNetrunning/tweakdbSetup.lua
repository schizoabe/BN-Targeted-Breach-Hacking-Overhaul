
local TweakDBSetup = {}

function TweakDBSetup.ApplyBreachingHotkey(hotkey)
    local map = {[1] = "Choice1", [2] = "Choice2", [3] = "Choice3", [4] = "Choice4"}
    local idx = hotkey or 3
    if map[idx] == nil then idx = 3 end
    TweakDB:SetFlat("Interactions.BreachUnconsciousOfficer.action", map[idx])
end

return TweakDBSetup
