
local MarkingSystem                = {}

local SYSTEM_CLASS                 = "BetterNetrunning.Marking.MarkingStateSystem"
local PERK_SYSTEM_CLASS            = "BetterNetrunning.Perks.BNPerkSystem"

local PERK_COLD_TRACE              = 0
local PERK_TRACE_SCRAMBLER         = 6

local COUNTER_BREACH_SYSTEM_CLASS  = "BetterNetrunning.CounterBreach.CounterBreachSystem"
local COUNTER_BREACH_THRESHOLD     = 0.95
local COUNTER_BREACH_DISARM        = 0.5
local COUNTER_BREACH_COOLDOWN      = 5.0
local COUNTER_BREACH_DELAY         = 5.0

local HEAT_PASSIVE_DECAY_PER_SEC   = 0.001

local isInitialized                = false
local counterBreachTimer           = 0.0
local counterBreachPending         = 0.0
local counterBreachEngaged         = false
local counterBreachWasInMinigame   = false
local counterBreachWasActive       = false
local isPlayerInControl            = false
local currentMaxHeat               = 0.0
local hudPanelsVisible             = false
local panelRefreshTimer            = 0.0

local cachedMS         = nil
local cachedCBS        = nil
local cachedPerkSys    = nil
local cachedHeatDecay  = HEAT_PASSIVE_DECAY_PER_SEC
local cachedCBCooldown = COUNTER_BREACH_COOLDOWN

local function getPerkSystem()
    if cachedPerkSys then return cachedPerkSys end
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

function MarkingSystem.SetPlayerInControl(v)
    isPlayerInControl = v
end

function MarkingSystem.Update(deltaTime)
    if not isInitialized then return end

    local ms = cachedMS
    if not ms then return end

    local shouldTick = isPlayerInControl
    local cbs        = cachedCBS
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
        pcall(function() ms:AddSessionHeat(-cachedHeatDecay * deltaTime) end)
    end

    local maxHeat = 0.0
    pcall(function() maxHeat = ms:GetSessionHeat() end)
    currentMaxHeat = maxHeat

    if ms:HasAnyMarked() then
        ms:PruneExpiredMarksWithHeat(maxHeat)
    end

    local cbActive = false
    if cbs then pcall(function() cbActive = cbs:IsActive() end) end

    if counterBreachWasActive and not cbActive then
        counterBreachTimer = cachedCBCooldown
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

function MarkingSystem.CacheSystems()
    local container = Game.GetScriptableSystemsContainer()
    if not container then return end
    cachedMS      = container:Get(SYSTEM_CLASS)
    cachedCBS     = container:Get(COUNTER_BREACH_SYSTEM_CLASS)
    cachedPerkSys = container:Get(PERK_SYSTEM_CLASS)
    cachedHeatDecay  = getHeatDecayPerSec()
    cachedCBCooldown = getCounterBreachCooldown()
    print("[BetterNetrunning] Systems cached (heatDecay=" .. cachedHeatDecay .. " cbCooldown=" .. cachedCBCooldown .. ")")
end

function MarkingSystem.InvalidateSystems()
    cachedMS         = nil
    cachedCBS        = nil
    cachedPerkSys    = nil
    cachedHeatDecay  = HEAT_PASSIVE_DECAY_PER_SEC
    cachedCBCooldown = COUNTER_BREACH_COOLDOWN
    print("[BetterNetrunning] System cache cleared")
end

function MarkingSystem.RefreshPanels()
    if not isInitialized then return end
    local container = Game.GetScriptableSystemsContainer()
    if not container then return end
    local logSys = container:Get("BetterNetrunning.Marking.ICEScoutLogSystem")
    if logSys then
        local ok, vis = pcall(function() return logSys:IsVisible() end)
        if ok and type(vis) == "boolean" then hudPanelsVisible = vis end
    end
    if hudPanelsVisible then
        local testSys = container:Get("BetterNetrunning.UI.BNTestPanelSystem")
        if testSys then pcall(function() testSys:Refresh(counterBreachPending) end) end
        if logSys  then pcall(function() logSys:Refresh() end) end
    end
end

function MarkingSystem.TickRefresh(deltaTime)
    if not isInitialized then return end

    if not cachedMS then
        local container = Game.GetScriptableSystemsContainer()
        if container then
            cachedMS = container:Get(SYSTEM_CLASS)
            if cachedMS then
                cachedCBS        = container:Get(COUNTER_BREACH_SYSTEM_CLASS)
                cachedPerkSys    = container:Get(PERK_SYSTEM_CLASS)
                cachedHeatDecay  = getHeatDecayPerSec()
                cachedCBCooldown = getCounterBreachCooldown()
                print("[BetterNetrunning] System cache recovered via TickRefresh fallback")
            end
        end
    end

    if cachedMS and not isPlayerInControl then
        local ok, breachOpen = pcall(function() return cachedMS:IsAPBreachActive() end)
        if ok and type(breachOpen) == "boolean" and not breachOpen then
            isPlayerInControl = true
        end
    end

    panelRefreshTimer = panelRefreshTimer + deltaTime
    if panelRefreshTimer >= 0.25 then
        panelRefreshTimer = panelRefreshTimer - 0.25
        MarkingSystem.RefreshPanels()
    end
end

return MarkingSystem
