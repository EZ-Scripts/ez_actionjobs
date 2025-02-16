

local Core = exports.vorp_core:GetCore()

local function getPay(level, table)
    if table[level] then
        return table[level]
    end
    
    -- Find the closest lower-defined level
    local closestLevel = 0
    for definedLevel in pairs(table) do
        if definedLevel <= level and definedLevel > closestLevel then
            closestLevel = definedLevel
        end
    end

    return table[closestLevel]
end

RegisterServerEvent("ez_actionjobs:server:getTrust", function()
    local _source = source
    local user = Core.getUser(source) --[[@as User]]  
    if not user then return end -- is player in session?
    local character = user.getUsedCharacter --[[@as Character]]

    exports.ghmattimysql:execute("SELECT trust FROM characters WHERE identifier=@identifier AND charidentifier = @charidentifier", {['identifier'] = character.identifier, ['charidentifier'] = character.charIdentifier}, function(result)
        if result[1] ~= nil then 
            local trust = result[1].trust
            TriggerClientEvent("ez_actionjobs:setTrust", _source, trust)
        end
    end)
end)

RegisterServerEvent("ez_actionjobs:reward", function(jobType, quality, tasksdone, totaltasks)
    local _source = source
    if 10 > quality then 
        quality = 10
    end
    if tasksdone > totaltasks/2 then
        local user = Core.getUser(source) --[[@as User]]  
        if not user then return end -- is player in session?
        local character = user.getUsedCharacter --[[@as Character]]
        exports.ghmattimysql:execute("SELECT trust FROM characters WHERE identifier=@identifier AND charidentifier = @charidentifier", {['identifier'] = character.identifier, ['charidentifier'] = character.charIdentifier}, function(result)
            if result[1] ~= nil then 
                local trust = result[1].trust
                trust = json.decode(trust)
                if not (trust and type(trust) == "table") then
                    trust = {
                        [jobType] = 0
                    }
                elseif not trust[jobType] then
                    trust[jobType] = 0
                end
                local pay = getPay(trust[jobType], Config.Jobs[jobType].pay) * tasksdone/totaltasks * (quality/100)
                character.addCurrency(0, pay)
                TriggerClientEvent("vorp:TipRight", _source, Config.Language.Pay..pay, 5000)
                if tasksdone == totaltasks then 
                    trust[jobType] = trust[jobType] + 1
                    TriggerClientEvent("ez_actionjobs:setTrust", _source, trust)
                end
                exports.ghmattimysql:execute("UPDATE characters Set trust=@trust WHERE identifier=@identifier AND charidentifier = @charidentifier", {['trust'] = json.encode(trust),['identifier'] = character.identifier, ['charidentifier'] = character.charIdentifier})
            end
        end)
    else
        TriggerClientEvent("vorp:TipRight", _source, Config.Language.UnsufficientWork, 5000)
    end
end)
