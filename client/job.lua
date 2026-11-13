-- * ==================================================
-- * THE SHIFT: pick up -> work spot -> pick up ... -> back to the manager.
-- * The server keeps its own count (server/main.lua) and decides the pay, this only drives what the player sees
-- * ==================================================

---@type table|nil { name, location, cfg, place, done, total, quality, carrying, prop, cannotRun, blip }
Job = nil

local function notify(text)
    jo.notif.right(text, "hud_textures", "check", "COLOR_WHITE", 4000)
end

-- * ==================================================
-- * MISSION BLIP + GPS
-- * ==================================================

local function clearMissionBlip()
    if Job and Job.blip then
        RemoveBlip(Job.blip)
        Job.blip = nil
    end
    ClearGpsCustomRoute()
    SetGpsCustomRouteRender(false, 16, 16)
end

local function setMissionBlip(coords, label)
    clearMissionBlip()
    local b = Config.missionBlip
    Job.blip = CreateBlip(coords, label, b.sprite, b.style, b.scale, b.color)
    StartGpsMultiRoute(0, true, true)
    AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)
    SetGpsCustomRouteRender(true, 8, 8)
end

local function goToPickup()
    setMissionBlip(Job.place.pickup, Job.cfg.pickup.label)
end

local function currentSpot()
    return Job.place.workSpot[Job.done + 1]
end

-- * ==================================================
-- * START / END
-- * ==================================================

function StartJob(name, locationName)
    local cfg = Config.Jobs[name]
    local place = cfg.locations[locationName]
    Job = {
        name = name,
        location = locationName,
        cfg = cfg,
        place = place,
        done = 0,
        total = #place.workSpot,
        quality = 100,
        carrying = false,
    }
    dlog("Started", name, locationName)
    notify(__("marked"))
    goToPickup()
end

function EndJob()
    if not Job then return end
    dlog("Ended", Job.name)
    if Job.prop then
        RemoveProp(Job.prop)
        ClearPedTasks(PlayerPedId())
    end
    clearMissionBlip()
    Job = nil
end

-- * ==================================================
-- * ACTIONS
-- * ==================================================

local function pickup()
    local ped = PlayerPedId()
    local ok, cannotRun, prop = pcall(Job.cfg.pickup.run, ped)
    if not ok then
        print("^1[ez_actionjobs] pickup.run failed: " .. tostring(cannotRun) .. "^0")
        return
    end
    Job.carrying, Job.cannotRun, Job.prop = true, cannotRun, prop
    local spot = currentSpot()
    setMissionBlip(spot, Job.cfg.workSpot.label)
    notify(__("marked"))
    Wait(500)
end

local function work()
    local ped = PlayerPedId()
    if Job.prop then
        RemoveProp(Job.prop)
        Job.prop = nil
        ClearPedTasks(ped)
    end
    Wait(500)

    local ok, passed = pcall(Job.cfg.workSpot.run, ped)
    if not ok then
        print("^1[ez_actionjobs] workSpot.run failed: " .. tostring(passed) .. "^0")
        passed = false
    end
    passed = passed == true
    ClearPedTasks(ped)
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, ped, false, true) -- HidePedWeapons
    if not Job then return end

    local result = jo.callback.triggerServer("ez_actionjobs:server:task", passed)
    if not result then
        return jo.notif.rightError(__("tooFar"))
    end
    Job.done, Job.quality = result.done, result.quality

    if passed then
        Job.carrying = false
        if Job.done >= Job.total then
            setMissionBlip(Job.place.loc, __("foreman"))
            notify(__("finishedTasks"))
        else
            goToPickup()
            notify(__("marked"))
        end
    else
        jo.notif.rightError(__("messedUp"))
        SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
    end
    Wait(500)
end

--- Running, jumping, mounting... with the plank: it's dropped and has to be picked up again
local function drop(ped)
    RemoveProp(Job.prop)
    Job.prop = nil
    Job.carrying = false
    ClearPedTasks(ped)
    SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
    local result = jo.callback.triggerServer("ez_actionjobs:server:dropped")
    if result and Job then Job.quality = result.quality end
    goToPickup()
    jo.notif.rightError(__("dropped"))
end

--- Called by the loop in client/main.lua. Returns true while it needs to run every frame
function CheckCarry(ped)
    if not (Job and Job.carrying and Job.cannotRun and Job.prop) then return false end
    local mistake = false
    if Config.carry.dropWhenRunning and (IsPedRunning(ped) or IsPedSprinting(ped) or IsPedJumping(ped)) then
        mistake = true
    end
    for _, control in ipairs(Config.carry.dropControls) do
        if IsControlJustReleased(0, control) then mistake = true end
    end
    if mistake then
        Wait(1000)
        if Job and Job.prop then drop(ped) end
    end
    return true
end

--- The pickup or work spot the player stands at, for the prompt in client/main.lua
function GetJobInteraction(coords)
    if not Job then return nil end
    if Job.carrying then
        local spot = currentSpot()
        if spot and #(coords - spot) < Config.distances.workSpot then
            return { label = Job.cfg.workSpot.label, run = work }
        end
    elseif Job.done < Job.total and #(coords - Job.place.pickup) < Config.distances.pickup then
        return { label = Job.cfg.pickup.label, run = pickup }
    end
    return nil
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    EndJob()
end)
