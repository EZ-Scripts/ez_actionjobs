-- Everything that talks to the framework or the database goes through here (jo.framework + oxmysql)

local T, C = Config.database.table, Config.database.column

CreateThread(function()
    local ok, err = pcall(jo.database.addColumn, T, C, "JSON NULL DEFAULT '{}'")
    if not ok then print(("^1[ez_actionjobs] Could not add `%s`.`%s`: %s^0"):format(T, C, tostring(err))) end
end)

--- { identifier, charid } of the player's character, or nil
function GetIdentity(source)
    local ids = jo.framework:getUserIdentifiers(source)
    if not ids or not ids.charid then return nil end
    return { identifier = ids.identifier, charid = tonumber(ids.charid) }
end

--- { [jobName] = experience }
function LoadExperience(identity)
    local raw = MySQL.scalar.await(("SELECT `%s` FROM `%s` WHERE identifier = ? AND charidentifier = ?"):format(C, T), { identity.identifier, identity.charid })
    local decoded = type(raw) == "string" and json.decode(raw) or raw
    return type(decoded) == "table" and decoded or {}
end

function SaveExperience(identity, experience)
    MySQL.update.await(("UPDATE `%s` SET `%s` = ? WHERE identifier = ? AND charidentifier = ?"):format(T, C), { json.encode(experience), identity.identifier, identity.charid })
end

function AddMoney(source, amount)
    if amount <= 0 then return end
    jo.framework:addMoney(source, amount, 0)
end

function Notify(source, text, isError)
    if isError then
        jo.notif.rightError(source, text)
    else
        jo.notif.rightSuccess(source, text)
    end
end

function PedCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    -- Without OneSync the server doesn't know where players are: the distance checks are skipped
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then return nil end
    return coords
end
