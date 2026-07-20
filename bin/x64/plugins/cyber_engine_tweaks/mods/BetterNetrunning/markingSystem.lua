

local MarkingSystem                = {}

local SYSTEM_CLASS                 = "BetterNetrunning.Marking.MarkingStateSystem"
local PERK_SYSTEM_CLASS            = "BetterNetrunning.Perks.BNPerkSystem"

local PERK_COLD_TRACE              = 0
local PERK_TRACE_SCRAMBLER         = 6

local COUNTER_BREACH_SYSTEM_CLASS  = "BetterNetrunning.CounterBreach.CounterBreachSystem"
local COUNTER_BREACH_THRESHOLD     = 0.95 -- Heat level that arms retaliation (cap is 1.0, use 0.95 for reliable trigger)
local COUNTER_BREACH_DISARM        = 0.5  -- Heat must drop below this to cancel armed countdown
local COUNTER_BREACH_COOLDOWN      = 5.0  -- Seconds between counter-breach attempts
local COUNTER_BREACH_DELAY         = 5.0  -- Warning window before minigame fires

local HEAT_PASSIVE_DECAY_PER_SEC   = 0.001 -- Passive session heat decay per second (very slow)

local isInitialized                = false
local counterBreachTimer           = 0.0   -- cooldown between counter-breach boards (starts when board CLOSES)
local counterBreachPending         = 0.0   -- countdown until counter-breach fires (0 = not armed)
local counterBreachEngaged         = false -- true after first fire; re-arm threshold drops to DISARM until heat < DISARM
local counterBreachWasInMinigame   = false -- edge-detect: restart warning window when AP breach board closes
local counterBreachWasActive       = false -- edge-detect: start cooldown when counter-breach board closes
local isPlayerInControl            = false -- set by GameplayState listener; false = pause all timers
local currentMaxHeat               = 0.0   -- session heat, shared with DrawUI
local panelRefreshTimer            = 0.0   -- countdown to next live panel refresh (0.25s cadence)
local hudPanelsVisible             = false -- toggle state for BNTestPanel + ICEScoutLog

local function getMarkingSystem()
    local container = Game.GetScriptableSystemsContainer()
    if not container then return nil end
    return container:Get(SYSTEM_CLASS)
end

local function getCounterBreachSystem()
    local container = Game.GetScriptableSystemsContainer()
    if not container then return nil end
    return container:Get(COUNTER_BREACH_SYSTEM_CLASS)
end

local function getPerkSystem()
    local container = Game.GetScriptableSystemsContainer()
    if not container then return nil end
    return container:Get(PERK_SYSTEM_CLASS)
end

local function getHeatDecayPerSec()
    local perkSys = getPerkSystem()
    if not perkSys then return HEAT_PASSIVE_DECAY_PER_SEC end
    local ok, rank = pcall(function() return perkSys:GetPerkLevelInt(PERK_COLD_TRACE) end)
    if ok and rank and rank > 0 then
        return HEAT_PASSIVE_DECAY_PER_SEC * (1.0 + rank * 0.1)
    end
    return HEAT_PASSIVE_DECAY_PER_SEC
end

local function getCounterBreachCooldown()
    local perkSys = getPerkSystem()
    if not perkSys then return COUNTER_BREACH_COOLDOWN end
    local ok, rank = pcall(function() return perkSys:GetPerkLevelInt(PERK_TRACE_SCRAMBLER) end)
    if ok and rank and rank > 0 then
        return COUNTER_BREACH_COOLDOWN + rank * 10.0
    end
    return COUNTER_BREACH_COOLDOWN
end

local function hasCyberdeckEquipped()
    local player = Game.GetPlayer()
    if not player then return false end
    local ok, result = pcall(function()
        local equipSys = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
        if not equipSys then return false end
        local playerData = equipSys:GetPlayerData(player)
        if not playerData then return false end
        local itemID = playerData:GetActiveItem(gamedataEquipmentArea.SystemReplacementCW)
        if not ItemID.IsValid(itemID) then return false end

        local tdbStr = TDBID.ToStringDEBUG(ItemID.GetTDBID(itemID))
        local cyberwareType = TweakDB:GetFlat(TDBID.Create(tdbStr .. ".cyberwareType"))
        if not cyberwareType then return false end
        return string.find(tostring(cyberwareType), "Cyberdeck", 1, true) ~= nil
    end)
    return ok and result or false
end

function MarkingSystem.ClearAll()
    local ms = getMarkingSystem()
    if ms then ms:ClearAll() end
    print("[BetterNetrunning] All breach marks cleared")
end

function MarkingSystem.SetPlayerInControl(v)
    isPlayerInControl = v
end

function MarkingSystem.Update(deltaTime)
    if not isInitialized then return end

    local ms = getMarkingSystem()
    if not ms then return end

    local shouldTick = isPlayerInControl
    local cbs        = getCounterBreachSystem()
    local inMinigame = false
    if cbs then pcall(function() inMinigame = cbs:IsMinigameActive() end) end

    local hideTimer        = 0.0
    local disarmTimer      = 0.0
    local signalNoiseTimer = 0.0
    pcall(function() hideTimer = ms:GetHidePresenceTimer() end)
    pcall(function() disarmTimer = ms:GetDisarmICETimer() end)
    pcall(function() signalNoiseTimer = ms:GetSignalNoiseTimer() end)
    if shouldTick then
        if hideTimer > 0 then pcall(function() ms:SetHidePresenceTimer(hideTimer - deltaTime) end) end
        if disarmTimer > 0 then pcall(function() ms:SetDisarmICETimer(disarmTimer - deltaTime) end) end
        if signalNoiseTimer > 0 then pcall(function() ms:SetSignalNoiseTimer(signalNoiseTimer - deltaTime) end) end
    end

    if shouldTick and hideTimer <= 0 then
        pcall(function() ms:AddSessionHeat(-getHeatDecayPerSec() * deltaTime) end)
    end

    local maxHeat = 0.0
    pcall(function() maxHeat = ms:GetSessionHeat() end)
    currentMaxHeat = maxHeat

    panelRefreshTimer = panelRefreshTimer - deltaTime
    if panelRefreshTimer <= 0 then
        panelRefreshTimer = 0.25
        local logSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.Marking.ICEScoutLogSystem")
        if logSys then
            local ok, vis = pcall(function() return logSys:IsVisible() end)
            if ok and type(vis) == "boolean" then hudPanelsVisible = vis end
        end
        if hudPanelsVisible then
            local testSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNTestPanelSystem")
            if testSys then pcall(function() testSys:Refresh(counterBreachPending) end) end
            if logSys  then pcall(function() logSys:Refresh() end) end
        end
    end

    if ms:HasAnyMarked() then
        ms:PruneExpiredMarksWithHeat(maxHeat)
    end

    local cbActive = false
    if cbs then pcall(function() cbActive = cbs:IsActive() end) end

    if counterBreachWasActive and not cbActive then
        counterBreachTimer = getCounterBreachCooldown()
        print('[BetterNetrunning] Counter-breach ended -- cooldown ' .. counterBreachTimer .. 's before next')
    end
    counterBreachWasActive = cbActive

    if counterBreachWasInMinigame and not inMinigame and counterBreachPending > 0 then
        counterBreachPending = COUNTER_BREACH_DELAY
        print('[BetterNetrunning] ICE still retaliating after breach exit -- restarting countdown')
        if cbs then pcall(function() cbs:ShowWarning('ICE IS RETALIATING, BREACH INCOMING!') end) end
    end
    counterBreachWasInMinigame = inMinigame

    if shouldTick then
        counterBreachTimer = counterBreachTimer - deltaTime
    end

    if not cbActive then
        local armThreshold = counterBreachEngaged and COUNTER_BREACH_DISARM or COUNTER_BREACH_THRESHOLD
        if maxHeat >= armThreshold and counterBreachTimer <= 0 then
            if counterBreachPending <= 0 then
                counterBreachPending = COUNTER_BREACH_DELAY
                print('[BetterNetrunning] BLACK ICE IMMINENT: heat=' .. maxHeat .. ' countdown=' .. counterBreachPending)
                if cbs then
                    pcall(function() cbs:ShowWarning('ICE IS RETALIATING, BREACH INCOMING!') end)
                else
                    print('[BetterNetrunning] WARNING: CounterBreachSystem not found, minigame cannot fire')
                end
            end
        elseif maxHeat < COUNTER_BREACH_DISARM then
            if counterBreachPending > 0 then
                print('[BetterNetrunning] Counter-breach disarmed: heat=' .. maxHeat)
                counterBreachPending = 0.0
            end
            counterBreachEngaged = false
        end
    end

    if shouldTick and counterBreachPending > 0 then
        counterBreachPending = counterBreachPending - deltaTime
        if counterBreachPending <= 0 then
            counterBreachPending = 0.0
            if cbs then
                if not cbActive then
                    print('[BetterNetrunning] Counter-breach FIRING: heat=' .. maxHeat)
                    counterBreachEngaged = true
                    cbs:Trigger()
                else
                    print('[BetterNetrunning] Counter-breach suppressed: board already active')
                end
            else
                print('[BetterNetrunning] Counter-breach FAILED TO FIRE: CounterBreachSystem is nil')
            end
        end
    end

end

function MarkingSystem.Init()
    isInitialized = true
    print("[BetterNetrunning] Marking system ready")
end

function MarkingSystem.HK_ClearMarks()
    MarkingSystem.ClearAll()
    local testSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNTestPanelSystem")
    local logSys  = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.Marking.ICEScoutLogSystem")
    if testSys then pcall(function() testSys:Hide() end) end
    if logSys  then pcall(function() logSys:Hide() end) end
    hudPanelsVisible = false
end

function MarkingSystem.HK_HideWidgets()
    local testSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNTestPanelSystem")
    local logSys  = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.Marking.ICEScoutLogSystem")
    if testSys then pcall(function() testSys:Hide() end) end
    if logSys  then pcall(function() logSys:Hide() end) end
    hudPanelsVisible = false
end

function MarkingSystem.HK_ShowNetworkStatus()
    if not hasCyberdeckEquipped() then
        print("[BetterNetrunning] No cyberdeck equipped - cannot show network status")
        return
    end
    local testSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNTestPanelSystem")
    local logSys  = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.Marking.ICEScoutLogSystem")
    if testSys then pcall(function() testSys:ShowTestPanel(counterBreachPending) end) end
    if logSys  then pcall(function() logSys:Show() end) end
    hudPanelsVisible = true
end

function MarkingSystem.HK_ForceJackOut()
    local cbs = getCounterBreachSystem()
    if not cbs then
        print("[BetterNetrunning] CounterBreachSystem not found")
        return
    end
    local ok, err = pcall(function() cbs:ForceJackOut() end)
    if ok then
        print("[BetterNetrunning] ForceJackOut called")
    else
        print("[BetterNetrunning] ForceJackOut error: " .. tostring(err))
    end
end

function MarkingSystem.HK_DEV_TriggerCounterBreach()
    local cbs = getCounterBreachSystem()
    if not cbs then
        print("[BetterNetrunning] CounterBreachSystem not found - check REDscript compilation")
        return
    end
    if cbs:IsActive() then
        print("[BetterNetrunning] Counter-breach already active")
        return
    end
    cbs:Trigger()
    print("[BetterNetrunning] Counter-breach manually triggered")
end

function MarkingSystem.HK_DEV_PrintHeat()
    local ms = getMarkingSystem()
    if not ms then
        print("[BetterNetrunning] MarkingSystem not found"); return
    end
    local heat = 0.0
    pcall(function() heat = ms:GetSessionHeat() end)
    print(string.format("[BetterNetrunning] Session heat = %.3f  (threshold=%.2f  timer=%.1f)",
        heat, COUNTER_BREACH_THRESHOLD, counterBreachTimer))
end

function MarkingSystem.HK_DEV_PrintICEState()
    local ms = getMarkingSystem()
    if not ms then
        print("[BetterNetrunning] MarkingSystem not found"); return
    end
    local info = "ICE: not initialized"
    pcall(function() info = ms:GetDebugICEString() end)
    print(string.format("[BetterNetrunning] %s  |  heat=%.3f  |  pending=%.1fs",
        info, currentMaxHeat, counterBreachPending))
end

function MarkingSystem.HK_DEV_CheckCyberdeck()
    local player = Game.GetPlayer()
    if not player then
        print("[BetterNetrunning] No player"); return
    end
    local ok, err = pcall(function()
        local equipSys = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
        if not equipSys then
            print("[BetterNetrunning] EquipmentSystem not found"); return
        end
        local playerData = equipSys:GetPlayerData(player)
        if not playerData then
            print("[BetterNetrunning] PlayerData not found"); return
        end
        local deckID = playerData:GetActiveItem(gamedataEquipmentArea.SystemReplacementCW)
        local isValid = ItemID.IsValid(deckID)
        print(string.format("[BetterNetrunning] SystemReplacementCW slot - valid=%s", tostring(isValid)))
        if isValid then
            local tdbid = ItemID.GetTDBID(deckID)
            local record = TweakDBInterface.GetItemRecord(tdbid)
            if record then
                local tags = record:Tags()
                local tagList = {}
                for i = 1, #tags do
                    table.insert(tagList, tostring(tags[i]))
                end
                local cyberwareType = TweakDB:GetFlat(TDBID.Create(TDBID.ToStringDEBUG(tdbid) .. ".cyberwareType"))
                print(string.format("[BetterNetrunning]   TDBID=%s", TDBID.ToStringDEBUG(tdbid)))
                print(string.format("[BetterNetrunning]   cyberwareType=%s", tostring(cyberwareType)))
                print(string.format("[BetterNetrunning]   Tags: %s", table.concat(tagList, ", ")))
                print(string.format("[BetterNetrunning]   hasCyberdeckEquipped() = %s", tostring(hasCyberdeckEquipped())))
            else
                print("[BetterNetrunning]   TDBID=" .. TDBID.ToStringDEBUG(tdbid) .. "  (no record)")
            end
        end
    end)
    if not ok then print("[BetterNetrunning] CheckCyberdeck error: " .. tostring(err)) end
end

function MarkingSystem.HK_DEV_ShowTestPanel()
    local testSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNTestPanelSystem")
    local logSys  = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.Marking.ICEScoutLogSystem")
    local bootSys = Game.GetScriptableSystemsContainer():Get("BetterNetrunning.UI.BNBootSystem")

    if logSys then
        local ok, result = pcall(function() return logSys:IsVisible() end)
        if ok and type(result) == "boolean" then hudPanelsVisible = result end
    end

    if hudPanelsVisible then
        if bootSys then pcall(function() bootSys:Abort() end) end
        if testSys then pcall(function() testSys:Hide() end) end
        if logSys  then pcall(function() logSys:Hide() end) end
        hudPanelsVisible = false
    else
        if bootSys then
            local ok, err = pcall(function() bootSys:Show() end)
            if not ok then print("[BetterNetrunning] BNBootOverlay Show error: " .. tostring(err)) end
        end
        if testSys then
            local ok, err = pcall(function() testSys:ShowTestPanel(counterBreachPending) end)
            if not ok then print("[BetterNetrunning] ShowTestPanel error: " .. tostring(err)) end
        end
        if logSys then
            local ok, err = pcall(function() logSys:Show() end)
            if not ok then print("[BetterNetrunning] ICEScoutLog Show error: " .. tostring(err)) end
        end
        hudPanelsVisible = true
    end
end

return MarkingSystem

