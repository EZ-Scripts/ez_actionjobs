-- * ==================================================
-- * FOREMAN MENU (jo_libs menu): experience, pay, start / finish the shift
-- * ==================================================

local function startJob(name, locationName)
    jo.menu.show(false)
    EndJob() -- another shift: dropped, the server replaces it too
    if not jo.callback.triggerServer("ez_actionjobs:server:start", name, locationName) then
        return jo.notif.rightError(__("notStarted"))
    end
    StartJob(name, locationName)
end

local function finishJob()
    jo.menu.show(false)
    jo.callback.triggerServer("ez_actionjobs:server:finish") -- pays and tells the player
    EndJob()
end

function OpenJobMenu(name, locationName)
    local job = Config.Jobs[name]
    local place = job and job.locations[locationName]
    if not place then return end

    local level = jo.callback.triggerServer("ez_actionjobs:server:getLevel", name) or 0
    local working = Job and Job.name == name

    local stats = {
        { label = __("experience"), value = tostring(level) },
        { label = __("shiftPay"), value = "$" .. FormatMoney(GetPay(level, job.pay)) },
        { label = __("spots"), value = tostring(#place.workSpot) },
    }

    local menu = jo.menu.create("ezActionJobs", {
        title = JobLabel(name),
        subtitle = __("menuSubtitle"):format(locationName),
        distanceToClose = 4.0,
        onBack = function() jo.menu.show(false) end,
    })

    if working then
        menu:addItem({
            title = __("finishJob"),
            description = __("finishJobDesc"),
            textRight = ("%d / %d"):format(Job.done, Job.total),
            statistics = {
                { label = __("progress"), value = ("%d / %d"):format(Job.done, Job.total) },
                { label = __("quality"), value = ("%d%%"):format(Job.quality) },
                { label = __("shiftPay"), value = "$" .. FormatMoney(GetPay(level, job.pay)) },
            },
            onClick = finishJob,
        })
    else
        menu:addItem({
            title = __("startJob"),
            description = Job and __("switchJobDesc"):format(JobLabel(Job.name)) or __("startJobDesc"),
            statistics = stats,
            onClick = function() startJob(name, locationName) end,
        })
    end

    menu:addItem({
        title = __("experience"),
        description = __("experienceDesc"),
        textRight = tostring(level),
        statistics = stats,
    })

    menu:addItem({
        title = __("close"),
        onClick = function() jo.menu.show(false) end,
    })

    menu:send()
    menu:use(false, true)
    jo.menu.show(true)
end
