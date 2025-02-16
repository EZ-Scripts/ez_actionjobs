Config = {}
Config.Keys = {
    ["G"] = 0x760A9C6F,
    ["E"] = 0xCEFD9220,
    ["Q"] = 0xDE794E3E,
}

Config.Jobs = {
    Construction = {
        pickup = {
            label = "Pickup Plank",
            run = function (ped)
                local model = GetHashKey("p_woodplank01x")
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Citizen.Wait(10)
                end
                local coords = GetEntityCoords(ped)
                local prop = CreateObject(model, coords.x, coords.y, coords.z, 1, 0, 1)
                SetEntityAsMissionEntity(prop, true, true)
                RequestAnimDict("mech_carry_box")
                while not HasAnimDictLoaded("mech_carry_box") do
                    Wait(100)
                end
                TaskPlayAnim(ped, "mech_carry_box", "idle", 2.0, -2.0, -1, 67109393, 0.0, false, 1245184, false, "UpperbodyFixup_filter", false)
                Citizen.InvokeNative(0x6B9BBD38AB0796DF, prop, ped, GetEntityBoneIndexByName(ped,"SKEL_L_Hand"), 0.1, 0.15, 0.0, 90.0, 90.0, 20.0, true, true, false, true, 1, true)
                return true, prop -- cannot run, prop; prop is the object that will be deleted when the player is done
            end,
        },

        workSpot = {
            label = "Place Plank",
            run = function (ped)
                local coords = GetEntityCoords(ped)
                local prop = CreateObject("p_hammer01x", coords.x, coords.y, coords.z, true, true, false, false, true)
                local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")
                AttachEntityToEntity(prop, ped, boneIndex, 0.06, -0.13, -0.07, 106.8,
                200.0, 180.0, true, true, false, true, 1, true)
                RequestAnimDict("amb_work@world_human_hammer@wall@male_a@trans")
                while not HasAnimDictLoaded("amb_work@world_human_hammer@wall@male_a@trans") do
                    Wait(0)
                end
                TaskPlayAnim(ped, "amb_work@world_human_hammer@wall@male_a@trans", "a_trans_kneel_a", 1.0, 1.0, -1, 27, 1.0, false, false, false,'', false)
                local minigame = exports["syn_minigame"]:taskBar(4000,7)
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(3400,7)
                end
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(3000,7)
                end
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(2700,7)
                end
                if minigame == 100 then
                    DetachEntity(prop,false,true)
                    ClearPedTasks(ped)
                    DeleteObject(prop)
                    return true -- skill check passed
                else
                    DetachEntity(prop,false,true)
                    ClearPedTasks(ped)
                    DeleteObject(prop)
                    return false -- skill check failed
                end
            end,
        },
        pay = {
            [0] = 12,
            [10] = 24,
            [40] = 36,
            [70] = 48
        },
        locations = {
            ["Blackwater"] = {
                loc = vector3(-859.11, -1277.91, 43.56),
                npc = {
                    enabled = true,
                    ped = vector4(-859.46, -1279.69, 43.56, 359.94),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(-843.59, -1260.99, 43.54),
                workSpot = {
                    vector3(-832.2, -1276.19, 43.66),
                    vector3(-826.0, -1280.79, 43.62),
                    vector3(-826.24, -1274.73, 43.58),
                    vector3(-831.8, -1273.06, 43.59),
                },
            },
            ["Rhodes"] = {
                loc = vector3(1381.16, -1311.44, 77.41),
                npc = {
                    enabled = true,
                    ped = vector4(1381.12, -1311.31, 77.41, 324.11),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(1391.67, -1308.07, 77.65),
                workSpot = {
                    vector3(1398.48, -1290.19, 78.18),
                    vector3(1429.28, -1302.78, 77.82),
                    vector3(1381.53, -1289.4, 77.07), 
                    vector3(1405.7, -1266.74, 78.37),
                    vector3(1407.55, -1277.34, 78.18),
                },
            },
            ["Annesburg"] = {
                loc = vector3(2948.28, 1424.96, 44.84),
                npc = {
                    enabled = true,
                    ped = vector4(2948.28, 1424.96, 44.84, 203.43),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(2953.73, 1412.84, 44.28),
                workSpot = {
                    vector3(2966.62, 1429.31, 44.7),
                    vector3(2971.58, 1440.76, 44.87),
                    vector3(2978.34, 1440.43, 44.9),
                    vector3(2970.63, 1431.96, 44.72),
                    vector3(2956.49, 1415.57, 44.18),
                },
            },
            ["Valentine"] = {
                loc = vector3(-218.45, 680.98, 113.5),
                npc = {
                    enabled = true,
                    ped = vector4(-218.45, 680.98, 113.5, 289.94),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(-237.74, 692.77, 113.43),
                workSpot = {
                    vector3(-244.39, 675.27, 113.33),
                    vector3(-273.94, 677.31, 113.37),
                    vector3(-270.19, 706.02, 113.5),
                    vector3(-283.81, 662.72, 113.42),
                    vector3(-254.32, 623.9, 113.43),
                },
            },
            ["Strawberry"] = {
                loc = vector3(-1837.17, -418.79, 161.66),
                npc = {
                    enabled = true,
                    ped = vector4(-1837.17, -418.79, 161.66, 232.22),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(-1823.72, -428.67, 160.01),
                workSpot = {
                    vector3(-1825.67, -447.58, 159.84),
                    vector3(-1830.83, -397.35, 161.29),
                    vector3(-1810.1, -422.2, 158.54),
                    vector3(-1843.91, -422.11, 160.75),
                    vector3(-1814.69, -423.37, 160.0),
                },
            },
            ["Armadillo"] = {
                loc = vector3(-3690.48, -2633.11, -13.87),
                npc = {
                    enabled = true,
                    ped = vector4(-3690.48, -2633.11, -13.87, 177.67),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(-3684.86, -2634.88, -13.62),
                workSpot = {
                    vector3(-3679.37, -2628.03, -13.43),
                    vector3(-3703.85, -2623.41, -13.24),
                    vector3(-3693.95, -2600.24, -13.3),
                    vector3(-3658.93, -2620.84, -13.34),
                    vector3(-3652.48, -2628.26, -13.82),
                },
            },
            ["Tumbleweed"] = {
                loc = vector3(-5500.17, -2958.25, -0.69),
                npc = {
                    enabled = true,
                    ped = vector4(-5500.17, -2958.25, -0.69, 16.65),
                    model = GetHashKey("a_m_m_bivworker_01"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Construction Job",
                },
                pickup = vector3(-5492.86, -2968.59, -1.98),
                workSpot = {
                    vector3(-5482.29, -2962.48, -1.66),
                    vector3(-5511.05, -2965.95, -1.57),
                    vector3(-5477.02, -2939.71, -1.08),
                    vector3(-5478.06, -2932.15, -1.25),
                    vector3(-5492.17, -2934.13, -1.13),
                }, 
         },
    },
},
    Sweeping = {
        pedSpawing = function(ped) -- this is called to apply any changes to ped
            local model = GetHashKey("p_broom01x")
            RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(10)
            end
            local coords = GetEntityCoords(ped)
            local prop = CreateObject(model, coords.x, coords.y, coords.z, 1, 0, 1)
            Citizen.InvokeNative(0x6B9BBD38AB0796DF, prop, ped, GetEntityBoneIndexByName(ped,"SKEL_R_Finger12"), 0.49, 0.0, 0.52, 0.0, 225.0, 35.0, true, true, false, true, 1, true)
            return prop
        end,

        pickup = {
            label = "Pickup Broom",
            run = function (ped)
                local model = GetHashKey("p_broom01x")
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Citizen.Wait(10)
                end
                local coords = GetEntityCoords(ped)
                local prop = CreateObject(model, coords.x, coords.y, coords.z, 1, 0, 1)
                Citizen.InvokeNative(0x6B9BBD38AB0796DF, prop, ped, GetEntityBoneIndexByName(ped,"SKEL_R_Finger12"), 0.49, 0.0, 0.52, 0.0, 225.0, 35.0, true, true, false, true, 1, true)
                SetEntityAsMissionEntity(prop,true,true)
                return true, prop -- cannot run, prop; prop is the object that will be deleted when the player is done
            end,
        },

        workSpot = {
            label = "Sweep the floor",
            run = function (ped)
                TaskStartScenarioInPlace(ped, GetHashKey("WORLD_HUMAN_BROOM_WORKING"), 30000, true, false, false, false)
                local minigame = exports["syn_minigame"]:taskBar(4000,7)
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(3400,7)
                end
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(3000,7)
                end
                Wait(1000)
                if minigame == 100 then
                    minigame = exports["syn_minigame"]:taskBar(2700,7)
                end
                if minigame == 100 then
                    return true -- skill check passed
                else
                    return false -- skill check failed
                end
            end,
        },
        pay = {
            [0] = 12,
            [10] = 24,
            [40] = 36,
            [70] = 48
        },
        locations = {
            ["Blackwater"] = {
                loc = vector3(-840.61, -1359.88, 43.5),
                npc = {
                    enabled = true,
                    ped = vector4(-840.61, -1359.88, 43.5, 100.0),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(-840.14, -1348.91, 44.2),
                workSpot = {
                    vector3(-869.09, -1331.09, 43.81),
                    vector3(-853.73, -1359.39, 43.4),
                    vector3(-854.43, -1375.37, 43.4),
                    vector3(-843.13, -1373.69, 43.4),
                    vector3(-806.68, -1325.52, 43.4),
                },
            },
            ["SaintDenis"] = {
                loc = vector3(2852.69, -1210.28, 47.69),
                npc = {
                    enabled = true,
                    ped = vector4(2852.69, -1210.28, 47.69, 91.42),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(2848.91, -1219.85, 47.59),
                workSpot = {
                    vector3(2842.55, -1229.17, 47.67),
                    vector3(2831.83, -1238.42, 47.54),
                    vector3(2821.61, -1226.55, 47.56),
                    vector3(2858.13, -1222.52, 47.61),
                    vector3(2833.82, -1209.11, 47.65),
                    vector3(2844.09, -1235.32, 47.67),
                },
            },
            ["Rhodes"] = {
                loc = vector3(1346.38, -1319.18, 76.9),
                npc = {
                    enabled = true,
                    ped = vector4(1346.38, -1319.18, 76.9, 319.78),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(1353.43, -1329.25, 77.55),
                workSpot = {
                    vector3(1367.09, -1310.31, 77.95),
                    vector3(1331.33, -1328.47, 77.93),
                    vector3(1329.35, -1317.28, 77.93),
                    vector3(1322.95, -1295.74, 77.0),
                    vector3(1312.22, -1311.06, 76.77),
                    vector3(1348.75, -1287.22, 77.44),
                },
            },
            ["Annesburg"] = {
                loc = vector3(2955.58, 1317.67, 44.74),
                npc = {
                    enabled = true,
                    ped = vector4(2955.58, 1317.67, 44.74, 249.39),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(2943.64, 1314.27, 44.48),
                workSpot = {
                    vector3(2958.82, 1300.7, 44.5),
                    vector3(2940.14, 1295.54, 44.76),
                    vector3(2925.66, 1280.7, 44.63),
                    vector3(2954.04, 1339.8, 44.87),
                    vector3(2917.72, 1323.81, 44.46),
                    vector3(2926.43, 1347.56, 44.44),
                },
            },
            ["Valentine"] = {
                loc = vector3(-320.94, 777.82, 118.01),
                npc = {
                    enabled = true,
                    ped = vector4(-320.94, 777.82, 118.01, 10.97),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(-317.63, 799.03, 117.33),
                workSpot = {
                    vector3(-303.88, 797.14, 118.95),
                    vector3(-289.6, 785.01, 119.29),
                    vector3(-280.51, 803.72, 119.4),
                    vector3(-340.12, 794.98, 117.1),
                    vector3(-331.86, 774.32, 117.43),
                    vector3(-314.28, 767.54, 117.96),
                },
            },
            ["Strawberry"] = {
                loc = vector3(-1749.88, -383.93, 156.42),
                npc = {
                    enabled = true,
                    ped = vector4(-1749.88, -383.93, 156.42, 199.43),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(-1761.47, -394.53, 156.26),
                workSpot = {
                    vector3(-1775.32, -402.05, 156.48),
                    vector3(-1781.9, -387.56, 159.26),
                    vector3(-1807.93, -368.28, 162.84),
                    vector3(-1790.85, -355.01, 165.02),
                    vector3(-1781.18, -373.39, 159.91), 
                },
            },
            ["Armadillo"] = {
                loc = vector3(-3704.18, -2623.54, -13.24),
                npc = {
                    enabled = true,
                    ped = vector4(-3704.18, -2623.54, -13.24, 43.27),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(-1761.47, -394.53, 156.26),
                workSpot = {
                    vector3(-3695.21, -2630.58, -13.83),
                    vector3(-3730.42, -2617.58, -13.28),
                    vector3(-3711.31, -2594.73, -13.3),
                    vector3(-3684.21, -2620.36, -13.45),
                    vector3(-3660.79, -2601.76, -13.29),
                },
            },
            ["Tumbleweed"] = {
                loc = vector3(-5517.15, -2962.35, -0.8),
                npc = {
                    enabled = true,
                    ped = vector4(-5517.15, -2962.35, -0.8, 17.11),
                    model = GetHashKey("CS_PrincessIsabeau"),
                },
                blip = {
                    enabled = true,
                    style = 1664425300,
                    scale = 0.2,
                    sprite = "blip_proc_loanshark",
                    name = "Sweeping Job",
                },
                pickup = vector3(-5519.59, -2954.65, -1.65),
                workSpot = {
                    vector3(-5495.19, -2936.84, -0.45),
                    vector3(-5494.31, -2958.36, -0.71),
                    vector3(-5527.11, -2952.89, -0.71),
                    vector3(-5508.73, -2960.02, -0.67),
                    vector3(-5538.82, -2955.84, -0.73),
                    vector3(-5520.51, -2912.17, -1.74),
                },
            },
        }
    }
}

Config.Language = {
    Press = "Press",
    To = "to",
    Level = {label = "Exp: ", description = "Your current experience level in this job"},
    StartJob = {label = "Start Working", description = "Start working here"},
    FinishJob = {label = "Finish Working", description = "Finish working here"},
    Marked = "Go to the marked location",
    FinishedTasks = "Finished for the day, head back to the Manager",
    MessedUp = "You make a mess and have to start over",
    UnsufficientWork = "Your work wasn't sufficient to be paid for.",
    Pay = "You get paid $ ",
}