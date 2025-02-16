
local inMenu = false
local quality
local blips = {}
local peds = {}
local props = {}
local MenuData = exports.vorp_menu:GetMenuData()
local missionBlip = nil
local missionStarted = nil
local tasksDone = 0
local prop, cannotRun
local level = {}
local group = GetRandomIntInRange(0, 0xFFFFFF)
local prompt        = 0

local function registerPrompts()
    if prompt ~= 0 then UiPromptDelete(prompt) end
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, Config.Keys.G)
    local label = VarString(10, "LITERAL_STRING", Config.Language.Press)
    UiPromptSetText(prompt, label)
    UiPromptSetGroup(prompt, group, 0)
    UiPromptSetStandardMode(prompt, true)
    UiPromptRegisterEnd(prompt)
end

local function isWalking(player)
    if IsPedRunning(player) or IsPedJumping(player) or IsControlJustReleased(0, Config.Keys["E"]) or IsControlJustReleased(0, Config.Keys["Q"]) then
        return false
    end
    return true
end

local function createBlip(blipHash, sprite, scale, x, y, z, name, color)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, blipHash or 1664425300, x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale or 0.2)
    if color then
        BlipAddModifier(blip, color)
    end
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, name)
    return blip
end

local function createBlipForMission(style, sprite, scale, x, y, z, name, color)
    local blip = createBlip(style, sprite, scale, x, y, z, name, color)
    ClearGpsCustomRoute()
    StartGpsMultiRoute(0, true, true)
    AddPointToGpsMultiRoute(x, y, z)
    SetGpsCustomRouteRender(true, 8, 8)
    return blip
end

local function createPed(model, x, y, z, w)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    local ped = CreatePed(model, x, y, z-1, w, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    return ped
end

local function drawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())  
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
	  SetTextScale(0.30, 0.30)
	  SetTextFontForCurrentCommand(1)
	  SetTextColor(255, 255, 255, 215)
	  SetTextCentre(1)
	  DisplayText(str,_x,_y)
	  local factor = (string.len(text)) / 225
	  DrawSprite("feeds", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
end

local function jobMenu(type, location)
    local elements = {
        {
            label = Config.Language.Level.label..(level[type] or 0).."",
            value = "trust",
            desc = Config.Language.Level.description
        },
    }
    if missionStarted == nil then 
        table.insert(elements, {
            label = Config.Language.StartJob.label,
            value = "startjob",
            desc = Config.Language.StartJob.description
        })
    elseif missionStarted == type then
        table.insert(elements, {
            label = Config.Language.FinishJob.label,
            value = "finishjob",
            desc = Config.Language.FinishJob.description
        })
    else
        tasksDone = 0
        missionStarted = nil
        DeleteObject(prop)
        prop = nil
        RemoveBlip(missionBlip)
        missionBlip = nil
        ClearGpsCustomRoute()
        SetGpsCustomRouteRender(false, 16, 16)
        table.insert(elements, {
            label = Config.Language.StartJob.label,
            value = "startjob",
            desc = Config.Language.StartJob.description
        })
    end
    inMenu = true
    MenuData.CloseAll()
    MenuData.Open("default", GetCurrentResourceName(), "JobStartingMenu", {
        title = type,
        subtext = "",
        align = Config.Align,
        elements = elements,
        itemHeight = "4vh",

    }, function(data, menu)
        if data.current.value == "startjob" then
            StartJobThread(type, location)
            menu.close()
            inMenu = false
        elseif data.current.value == "finishjob" then
            if tasksDone > 0 then 
                TriggerServerEvent("ez_actionjobs:reward", type, quality, tasksDone, #Config.Jobs[type].locations[location].workSpot)
            end
            tasksDone = 0
            missionStarted = nil
            DeleteObject(prop)
            prop = nil
            RemoveBlip(missionBlip)
            missionBlip = nil
            ClearGpsCustomRoute()
            SetGpsCustomRouteRender(false, 16, 16)
            menu.close()
            inMenu = false
        end
    end, function(data, menu)
        menu.close()
        inMenu = false
    end)
end

RegisterNetEvent("ez_actionjobs:setTrust", function(trust)
    if type(trust) == "string" then
        trust = json.decode(trust)
    end
    if type(trust) == "table" then
        level = trust
    end
end)


function StartJobThread(type, location)
    missionStarted = type
    quality = 100
    tasksDone = 0
    local job = Config.Jobs[type]
    local location = job.locations[location]
    local pickupLoc = location.pickup
    local taskLoc = nil
    local pickup = false
    local workLoc = location.workSpot

    TriggerEvent("vorp:TipBottom", Config.Language.Marked, 4000)
    missionBlip = createBlipForMission(1664425300, -924533810, 0.2, pickupLoc.x, pickupLoc.y, pickupLoc.z, job.pickup.label, 0x6F85C3CE)
    
    Citizen.CreateThread(function()
        while missionStarted do
            Citizen.Wait(10)
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            if not pickup and #workLoc ~= tasksDone then
                if #(coords - pickupLoc) < 5  then
                    drawText3D(pickupLoc.x, pickupLoc.y, pickupLoc.z, Config.Language.Press .. " G " .. Config.Language.To .. " " .. job.pickup.label)
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        pickup = true
                        cannotRun, prop = job.pickup.run(player)
                        RemoveBlip(missionBlip)
                        taskLoc = workLoc[tasksDone+1]
                        TriggerEvent("vorp:TipBottom", Config.Language.Marked, 4000)
                        missionBlip = createBlipForMission(1664425300, -924533810, 0.2, taskLoc.x, taskLoc.y, taskLoc.z, job.workSpot.label, 0x6F85C3CE)
                        Wait(500)
                    end
                end
            elseif pickup then
                if cannotRun and not isWalking(player) then
                    Wait(1000)
                    DetachEntity(prop,false,true)
                    ClearPedTasks(player)
                    DeleteObject(prop)
                    prop = nil
                    pickup = false
                    RemoveBlip(missionBlip)
                    missionBlip = createBlipForMission(1664425300, -924533810, 0.2, pickupLoc.x, pickupLoc.y, pickupLoc.z, job.pickup.label, 0x6F85C3CE)
                    SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                    if quality > 10 then 
                        quality = quality - 10
                    end
                    TriggerEvent("vorp:TipBottom", Config.Language.MessedUp, 4000)
                end
                if #(coords - taskLoc) < 2  then
                    drawText3D(taskLoc.x, taskLoc.y, taskLoc.z, Config.Language.Press .. " G " .. Config.Language.To .. " " .. job.workSpot.label)
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        if prop then
                            DetachEntity(prop,false,true)
                            ClearPedTasks(player)
                            DeleteObject(prop)
                            prop = nil
                        end
                        Wait(500)
                        local passed = job.workSpot.run(player)
                        if passed then 
                            tasksDone = tasksDone + 1
                            pickup = false
                            RemoveBlip(missionBlip)
                            ClearGpsCustomRoute()
                            SetGpsCustomRouteRender(false, 16, 16)
                            if #workLoc ~= tasksDone then 
                                TriggerEvent("vorp:TipBottom", Config.Language.Marked, 4000)
                                missionBlip = createBlipForMission(1664425300, -924533810, 0.2, pickupLoc.x, pickupLoc.y, pickupLoc.z, job.pickup.label, 0x6F85C3CE)                            
                            else
                                TriggerEvent("vorp:TipBottom", Config.Language.FinishedTasks, 4000)
                            end
                            ClearPedTasks(player)
                            Citizen.InvokeNative(0xFCCC886EDE3C63EC, PlayerPedId(), false, true)
                        else
                            if quality > 10 then 
                                quality = quality - 10
                            end
                            TriggerEvent("vorp:TipBottom", Config.Language.MessedUp, 4000)
                            ClearPedTasks(player)
                            SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                            Citizen.InvokeNative(0xFCCC886EDE3C63EC,PlayerPedId(),false,true)
                        end
                        Wait(500)
                    end
                end
            end
        end
    end)
end


function SetUp()
    Citizen.CreateThread(function()
        for jobName, jobData in pairs(Config.Jobs) do
            for locationName, locationData in pairs(jobData.locations) do
                -- CREATE BLIP
                if locationData.blip and locationData.blip.enabled then
                    local blip = createBlip(locationData.blip.style, locationData.blip.sprite, locationData.blip.scale, locationData.loc.x, locationData.loc.y, locationData.loc.z, locationData.blip.name, locationData.blip.color)
                    table.insert(blips, blip)
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        registerPrompts()
        while true do
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            local sleep = 5000
            for jobName, jobData in pairs(Config.Jobs) do
                for locationName, locationData in pairs(jobData.locations) do
                    local dist = #(coords - locationData.loc)
                    if dist < 80 then
                        if locationData.npc.enabled and not peds[jobName..locationName] then
                            local ped = createPed(locationData.npc.model, locationData.npc.ped.x, locationData.npc.ped.y, locationData.npc.ped.z, locationData.npc.ped.w)
                            SetEntityCanBeDamaged(ped, false)
                            SetEntityInvincible(ped, true)
                            SetBlockingOfNonTemporaryEvents(ped, true)
                            FreezeEntityPosition(ped, true)
                            if jobData.pedSpawing then
                                props[jobName..locationName] = jobData.pedSpawing(ped)
                            end
                            peds[jobName..locationName] = ped
                        end
                        if dist < 2 and not inMenu then
                            sleep = 10
                            local label <const> = VarString(10, "LITERAL_STRING", locationName.." "..jobName)
                            UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

                            if UiPromptHasStandardModeCompleted(prompt, 0) then
                                jobMenu(jobName, locationName)
                            end
                        else
                            sleep = 1000
                        end
                    else
                        if peds[jobName..locationName] then
                            SetPedAsNoLongerNeeded(peds[jobName..locationName])
                            DeletePed(peds[jobName..locationName])
                            peds[jobName..locationName] = nil
                            if props[jobName..locationName] then
                                SetEntityAsNoLongerNeeded(props[jobName..locationName])
                                DeleteObject(props[jobName..locationName])
                                props[jobName..locationName] = nil
                            end
                        end
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
end

RegisterNetEvent("vorp:SelectedCharacter", function(charid)
    Citizen.Wait(1000)
    TriggerServerEvent("ez_actionjobs:server:getTrust")
    SetUp()
end)

AddEventHandler("onResourceStart", function(resourceName) if resourceName ~= GetCurrentResourceName() then return end
    Citizen.Wait(5000)
    TriggerServerEvent("ez_actionjobs:server:getTrust")
    SetUp()
end)

AddEventHandler("onResourceStop",function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(blips) do
            RemoveBlip(v)
        end
        for k,v in pairs(peds) do
            DeletePed(v)
        end
        for k,v in pairs(props) do
            DeleteObject(v)
        end
        DeleteObject(prop)
        RemoveBlip(missionBlip)
        ClearGpsCustomRoute()
        SetGpsCustomRouteRender(false, 16, 16)
    end
end)