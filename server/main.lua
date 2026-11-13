-- * ==================================================
-- * SHIFTS: the server counts the work itself and pays from its own count.
-- * The client only reports "I finished this spot" / "I dropped it", each report is checked
-- * ==================================================

local Shifts = {} -- { [source] = { job, location, done, quality, lastTaskAt } }

local function warn(source, reason)
    dlog(("Report from %s ignored: %s"):format(source, reason))
end

local function near(source, coords, maxDistance)
    local pos = PedCoords(source)
    if not pos then return true end
    return #(pos - coords) <= maxDistance
end

local function loseQuality(shift)
    shift.quality = math.max(Config.quality.minimum, shift.quality - Config.quality.penalty)
end

-- * ==================================================
-- * CALLBACKS
-- * ==================================================

jo.callback.register("ez_actionjobs:server:getLevel", function(source, jobName)
    if not Config.Jobs[jobName] then return 0 end
    local identity = GetIdentity(source)
    if not identity then return 0 end
    return tonumber(LoadExperience(identity)[jobName]) or 0
end)

jo.callback.register("ez_actionjobs:server:start", function(source, jobName, locationName)
    local job = Config.Jobs[jobName]
    local place = job and job.locations[locationName]
    if not place then return false end
    if not GetIdentity(source) then return false end
    if not near(source, place.loc, Config.security.startDistance) then
        warn(source, "start: too far from the foreman")
        return false
    end
    Shifts[source] = {
        job = jobName,
        location = locationName,
        done = 0,
        quality = 100,
        lastTaskAt = os.time(),
    }
    dlog(source, "started", jobName, locationName)
    return true
end)

--- passed: the minigame at the current spot was won. Returns { done, quality } or false
jo.callback.register("ez_actionjobs:server:task", function(source, passed)
    local shift = Shifts[source]
    if not shift then return false end
    local place = Config.Jobs[shift.job].locations[shift.location]
    local spot = place.workSpot[shift.done + 1]
    if not spot then return false end

    if not near(source, spot, Config.security.taskDistance) then
        warn(source, "task: too far from the work spot")
        return false
    end

    if passed == true then
        local now = os.time()
        if now - shift.lastTaskAt < Config.security.minTaskInterval then
            warn(source, "task: too fast")
            return false
        end
        shift.done = shift.done + 1
        shift.lastTaskAt = now
    else
        loseQuality(shift)
    end
    return { done = shift.done, quality = shift.quality }
end)

jo.callback.register("ez_actionjobs:server:dropped", function(source)
    local shift = Shifts[source]
    if not shift then return false end
    loseQuality(shift)
    return { quality = shift.quality }
end)

--- Pays for the shift and ends it
jo.callback.register("ez_actionjobs:server:finish", function(source)
    local shift = Shifts[source]
    if not shift then return false end
    Shifts[source] = nil

    local job = Config.Jobs[shift.job]
    local total = #job.locations[shift.location].workSpot
    if shift.done == 0 or shift.done <= total * Config.minimumWork then
        Notify(source, __("insufficientWork"), true)
        return false
    end

    local identity = GetIdentity(source)
    if not identity then return false end
    local experience = LoadExperience(identity)
    local level = tonumber(experience[shift.job]) or 0

    local pay = RoundMoney(GetPay(level, job.pay) * (shift.done / total) * (shift.quality / 100))
    AddMoney(source, pay)
    Notify(source, __("paid"):format(FormatMoney(pay)))

    if shift.done >= total then
        experience[shift.job] = level + 1
        SaveExperience(identity, experience)
        jo.notif.right(source, __("levelUp"):format(JobLabel(shift.job), level + 1), "hud_textures", "check", "COLOR_GOLD", 4000)
    end
    dlog(source, "finished", shift.job, ("%d/%d"):format(shift.done, total), shift.quality .. "%", "$" .. pay)
    return true
end)

AddEventHandler("playerDropped", function()
    Shifts[source] = nil
end)
