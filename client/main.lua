-- * ==================================================
-- * WORLD: manager peds, job blips, and the one prompt used for everything
-- * (talk to the manager, pick up, work)
-- * ==================================================

Busy = false -- an action (pickup, work, menu) is running

local peds = {}  -- { key = ped }
local props = {} -- { key = { entities } } props the manager holds (pedSpawning)
local blips = {}

-- * ==================================================
-- * HELPERS for the job functions in shared/config.lua
-- * ==================================================

--- Creates a prop in a bone of the ped
---@param networked? boolean default: true (others see it)
function AttachProp(ped, model, bone, offset, rotation, networked)
    jo.utils.loadGameData(model, true)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(joaat(model), coords.x, coords.y, coords.z, networked ~= false, false, true, false, true)
    SetEntityAsMissionEntity(prop, true, true)
    AttachEntityToEntity(prop, ped, GetEntityBoneIndexByName(ped, bone), offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(joaat(model))
    return prop
end

function PlayAnim(ped, dict, name, flag, duration, rate)
    jo.utils.loadGameData(dict, true)
    TaskPlayAnim(ped, dict, name, 1.0, 1.0, duration or -1, flag or 0, rate or 1.0, false, false, false, "", false)
end

function RemoveProp(prop)
    if not prop or not DoesEntityExist(prop) then return end
    DetachEntity(prop, false, true)
    DeleteObject(prop)
end

-- * ==================================================
-- * BLIPS
-- * ==================================================

--- jo.blip.create with the style, scale and colour modifier the job blips use
function CreateBlip(coords, name, sprite, style, scale, color)
    local blip = jo.blip.create(coords, name, sprite, style)
    if not blip then return nil end
    SetBlipScale(blip, scale or 0.2)
    if color then
        BlipAddModifier(blip, type(color) == "string" and joaat(color) or color)
    end
    return blip
end

CreateThread(function()
    for _, job in pairs(Config.Jobs) do
        for _, place in pairs(job.locations) do
            local b = place.blip
            if b and b.enabled then
                blips[#blips + 1] = CreateBlip(place.loc, b.name, b.sprite, b.style, b.scale, b.color)
            end
        end
    end
end)

-- * ==================================================
-- * MANAGERS: spawned when a player comes close
-- * ==================================================

local function spawnManager(key, job, place)
    local npc = place.npc
    local model = joaat(npc.model)
    jo.utils.loadGameData(model, true)
    local ped = CreatePed(model, npc.ped.x, npc.ped.y, npc.ped.z - 1.0, npc.ped.w, false, false, false, false)
    SetModelAsNoLongerNeeded(model)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    peds[key] = ped
    if job.pedSpawning then
        local ok, result = pcall(job.pedSpawning, ped)
        if ok then props[key] = result else print("[ez_actionjobs] pedSpawning failed: " .. tostring(result)) end
    end
end

local function deleteManager(key)
    for _, prop in ipairs(props[key] or {}) do
        if DoesEntityExist(prop) then DeleteObject(prop) end
    end
    props[key] = nil
    if peds[key] and DoesEntityExist(peds[key]) then DeletePed(peds[key]) end
    peds[key] = nil
end

CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        for jobName, job in pairs(Config.Jobs) do
            for placeName, place in pairs(job.locations) do
                local key = jobName .. ":" .. placeName
                local near = #(coords - place.loc) < Config.renderDistance
                if near and place.npc and place.npc.enabled and not peds[key] then
                    spawnManager(key, job, place)
                elseif not near and peds[key] then
                    deleteManager(key)
                end
            end
        end
        Wait(1000)
    end
end)

-- * ==================================================
-- * INTERACTIONS: one jo_libs prompt, its label set to whatever is closest
-- * ==================================================

local prompts = jo.promptNui.createGroup(false, "bottom-right")
local prompt = prompts:addPrompt(Config.keys.interact, "")

local function hidePrompt()
    if prompts:isVisible() then prompts:hide() end
end

local function findManager(coords)
    for jobName, job in pairs(Config.Jobs) do
        for placeName, place in pairs(job.locations) do
            if #(coords - place.loc) < Config.distances.manager then
                return {
                    label = ("%s %s: %s"):format(placeName, JobLabel(jobName), __("talk")),
                    run = function() OpenJobMenu(jobName, placeName) end,
                }
            end
        end
    end
end

local function canInteract(ped)
    return not Busy
        and not jo.menu.isOpen()
        and not IsMinigameRunning()
        and not IsEntityDead(ped)
        and not IsPedOnMount(ped)
        and not IsPedInAnyVehicle(ped, false)
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if Job and CheckCarry(ped) then sleep = 0 end

        local interaction = nil
        if canInteract(ped) then
            local coords = GetEntityCoords(ped)
            interaction = findManager(coords) or GetJobInteraction(coords)
        end

        if interaction then
            sleep = 0
            if prompt:getLabel() ~= interaction.label then prompt:setLabel(interaction.label) end
            if not prompts:isVisible() then prompts:display() end
            if jo.promptNui.isCompleted(prompts, Config.keys.interact, false) then
                hidePrompt()
                Busy = true
                local ok, err = pcall(interaction.run)
                if not ok then print("^1[ez_actionjobs] " .. tostring(err) .. "^0") end
                Busy = false
            end
        else
            hidePrompt()
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for key in pairs(peds) do deleteManager(key) end
    for _, blip in ipairs(blips) do RemoveBlip(blip) end
end)
