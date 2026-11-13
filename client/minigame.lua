-- * ==================================================
-- * MINIGAMES: the built in hammer game (html/, loaded as a jo_libs NUI next to its menu and prompts),
-- * bcc-minigames' hammertime, and the ez_skillbar / syn_minigame bars
-- * ==================================================

local UI_NAME <const> = "ez_actionjobs"
local nuiReady = false
local running = nil -- the promise of the hammer game being played
local screenEffect = nil

CreateThread(function()
    Wait(200)
    jo.nui.load(UI_NAME, ("nui://%s/html/index.html"):format(GetCurrentResourceName()))
end)

local function ui(message)
    message.messageTargetUiName = UI_NAME
    SendNUIMessage(message)
end

RegisterNUICallback("ready", function(_, cb)
    cb("ok")
    nuiReady = true
end)

local function closeHammer(status)
    if not running then return end
    local p = running
    running = nil
    SetNuiFocus(false, false)
    jo.nui.resetFocus()
    if screenEffect then
        AnimpostfxStop(screenEffect)
        screenEffect = nil
    end
    p:resolve(status)
end

-- status: "success" | "failed" | "canceled"
RegisterNUICallback("hammerFinished", function(data, cb)
    cb("ok")
    closeHammer(type(data) == "table" and data.status or "failed")
end)

local function playEz(overrides)
    if running then return false end

    local waitUntil = GetGameTimer() + 5000
    while not nuiReady and GetGameTimer() < waitUntil do Wait(100) end
    if not nuiReady then
        print("^1[ez_actionjobs] The hammer minigame page didn't load (html/index.html)^0")
        return false
    end

    local options = {}
    for k, v in pairs(Config.hammerMinigame.ez) do options[k] = v end
    for k, v in pairs(overrides or {}) do options[k] = v end

    running = promise.new()
    local p = running

    if type(options.screenEffect) == "string" and options.screenEffect ~= "" then
        screenEffect = options.screenEffect
        AnimpostfxPlay(screenEffect)
    end

    ui({ action = "hammer:start", options = options, lang = Lang.minigame })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    jo.nui.forceFocus(UI_NAME)

    -- Never leave the player stuck with the mouse if the page stops answering
    SetTimeout(3 * 60 * 1000, function()
        if running == p then
            ui({ action = "hammer:stop" })
            closeHammer("failed")
        end
    end)

    local status = Citizen.Await(p)
    dlog("Hammer minigame:", status)
    return status == "success"
end

local function playBcc(overrides)
    if GetResourceState("bcc-minigames") ~= "started" then
        print("^1[ez_actionjobs] Config.hammerMinigame.provider is \"bcc\" but bcc-minigames isn't started^0")
        return false
    end
    local settings = Config.hammerMinigame.bcc
    local minigame = exports["bcc-minigames"].initiate()
    local result = nil
    minigame.Start("hammertime", {
        focus = true,
        cursor = true,
        nails = (overrides and overrides.nails) or settings.nails,
        type = settings.type,
    }, function(r)
        result = r and r.result or false
    end)
    while result == nil do Wait(250) end
    return result == true
end

--- ez_skillbar (or syn_minigame): every bar has to be hit, one after another
---@param rounds table ms per bar
---@param gap number target zone width in %
function PlaySkillbar(rounds, gap)
    for i, duration in ipairs(rounds) do
        if i > 1 then Wait(1000) end
        if exports["syn_minigame"]:taskBar(duration, gap) ~= 100 then
            return false
        end
    end
    return true
end

--- The construction minigame, from Config.hammerMinigame.provider. Blocks until it's done
---@param overrides? table Options for this plank only (see Config.hammerMinigame.ez)
---@return boolean passed
function PlayHammerMinigame(overrides)
    local provider = Config.hammerMinigame.provider
    if provider == "bcc" then
        return playBcc(overrides)
    elseif provider == "skillbar" then
        local settings = Config.hammerMinigame.skillbar
        return PlaySkillbar(settings.rounds, settings.gap)
    end
    return playEz(overrides)
end

function IsMinigameRunning()
    return running ~= nil
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if running then
        SetNuiFocus(false, false)
        if screenEffect then AnimpostfxStop(screenEffect) end
    end
end)
