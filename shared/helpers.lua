-- * ==================================================
-- * SHARED HELPERS: same on client and server
-- * ==================================================

function dlog(...)
    if not Config.debug then return end
    print("[ez_actionjobs]", ...)
end

--- Pay for a full shift at this experience: the highest step at or below it
---@param level number
---@param payTable table { [experience] = pay }
function GetPay(level, payTable)
    local best, bestLevel = 0, -1
    for step, pay in pairs(payTable) do
        if step <= level and step > bestLevel then
            best, bestLevel = pay, step
        end
    end
    return best
end

function JobLabel(name)
    local job = Config.Jobs[name]
    return job and job.label or tostring(name)
end

--- Rounded to cents
function RoundMoney(amount)
    return math.floor(amount * 100 + 0.5) / 100
end

function FormatMoney(amount)
    return ("%.2f"):format(amount)
end
