Config = {}

Config.debug = false -- Prints job state changes in F8 / the server console

-- jo_libs prompt keys
Config.keys = {
    interact = "G", -- Talk to the manager, pick up, work
}

Config.renderDistance = 80.0 -- Managers spawn when a player is this close

Config.distances = {
    manager = 2.0,  -- Talk to the manager
    pickup = 5.0,   -- Pick up the plank / broom
    workSpot = 2.0, -- Work at a spot
}

-- Blip that leads the player to the next pickup / work spot (GPS route included)
Config.missionBlip = {
    style = 1664425300,
    sprite = -924533810,
    color = 0x6F85C3CE,
    scale = 0.2,
}

-- While carrying something with "cannotRun" (the plank), these drop it, cost quality and ragdoll the player
Config.carry = {
    dropWhenRunning = true, -- Running or jumping
    dropControls = {
        0xCEFD9220, -- E (INPUT_ENTER: mounting, wagons)
        0xDE794E3E, -- Q (INPUT_COVER)
    },
}

-- Each mistake (failed task, dropped plank) costs `penalty` % of the pay, never below `minimum` %
Config.quality = {
    penalty = 10,
    minimum = 10,
}

-- More than this share of the spots has to be done to get paid. Experience only goes up for a full shift
Config.minimumWork = 0.5

-- ===================================
-- Hammer minigame (construction)
-- ===================================

Config.hammerMinigame = {
    -- "ez":       built in (html/): strike each nail as the ring closes on it
    -- "bcc":      bcc-minigames "hammertime" (needs bcc-minigames started)
    -- "skillbar": ez_skillbar / syn_minigame bars
    provider = "ez",

    ez = {
        nails = 4,           -- Nails per plank
        strikes = 2,         -- Good strikes to sink a nail (a perfect strike counts double)
        ringTime = 1150,     -- ms for the ring to close on the nail (a little random each strike)
        goodWindow = 150,    -- ms either side of the perfect moment that still counts
        perfectWindow = 45,  -- ms either side that counts as perfect
        mistakes = 4,        -- Mistakes allowed. The next one fails the plank
        timeLimit = 0,       -- Seconds for the whole plank, 0 for no limit
        wood = "dark",       -- "dark" | "light" | "red"
        volume = 0.6,        -- Hammer sounds, 0 to 1
        screenEffect = "PauseMenuIn", -- AnimPostFX while it's open, false for none
    },

    bcc = {
        nails = 15,
        type = "dark-wood",
    },

    skillbar = {
        rounds = { 4000, 3400, 3000 }, -- ms per bar, one after another
        gap = 7,                       -- Target zone width in %
    },
}

-- ===================================
-- Jobs
-- ===================================
-- Each job has:
--   label           Name in the menu, prompts and blips
--   pedSpawning     (optional) function(ped) -> { props } run on the manager when it spawns
--   pickup.run      function(ped) -> cannotRun, prop   Pick up the tool / material
--   workSpot.run    function(ped) -> passed            Work at a spot (minigame)
--   pay             { [experience] = pay for a full shift }. The highest step at or below the player's experience is used.
--                   It's per shift on purpose, not per spot: locations with more spots pay less per spot. Quiet towns
--                   take more work for the same pay, and Sisika (prisoners) has the most spots
--   locations       { name = { loc, npc, blip, pickup, workSpot = { spots in order } } }
-- Helpers for the run functions (client/main.lua): AttachProp, PlayAnim, RemoveProp, PlayHammerMinigame, PlaySkillbar

Config.Jobs = {
    Construction = {
        label = "Construction",

        pickup = {
            label = "Pick up plank",
            run = function(ped)
                local prop = AttachProp(ped, "p_woodplank01x", "SKEL_L_Hand", vec3(0.1, 0.15, 0.0), vec3(90.0, 90.0, 20.0))
                jo.utils.loadGameData("mech_carry_box", true)
                TaskPlayAnim(ped, "mech_carry_box", "idle", 2.0, -2.0, -1, 67109393, 0.0, false, 1245184, false, "UpperbodyFixup_filter", false)
                return true, prop -- cannotRun, prop (deleted when the plank is placed or dropped)
            end,
        },

        workSpot = {
            label = "Nail plank",
            run = function(ped)
                local hammer = AttachProp(ped, "p_hammer01x", "SKEL_R_Hand", vec3(0.06, -0.13, -0.07), vec3(106.8, 200.0, 180.0))
                PlayAnim(ped, "amb_work@world_human_hammer@wall@male_a@trans", "a_trans_kneel_a", 27)
                local passed = PlayHammerMinigame()
                RemoveProp(hammer)
                ClearPedTasks(ped)
                return passed
            end,
        },

        pay = {
            [0] = 15,
            [20] = 20,
            [50] = 25,
            [70] = 30,
        },

        locations = {
            ["Blackwater"] = {
                loc = vector3(-859.11, -1277.91, 43.56),
                npc = { enabled = true, ped = vector4(-859.46, -1279.69, 43.56, 359.94), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
                pickup = vector3(-878.68, -1301.51, 43.12),
                workSpot = {
                    vector3(-877.46, -1312.89, 42.99),
                    vector3(-866.78, -1293.79, 43.1),
                    vector3(-875.51, -1302.94, 43.02),
                    vector3(-857.84, -1293.52, 43.28),
                },
            },
            ["Annesburg"] = {
                loc = vector3(2948.28, 1424.96, 44.84),
                npc = { enabled = true, ped = vector4(2948.28, 1424.96, 44.84, 203.43), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
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
                npc = { enabled = true, ped = vector4(-218.45, 680.98, 113.5, 289.94), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
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
                loc = vector3(-1838.63, -424.81, 160.78),
                npc = { enabled = true, ped = vector4(-1838.63, -424.81, 160.78, 232.57), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
                pickup = vector3(-1823.72, -428.67, 160.01),
                workSpot = {
                    vector3(-1825.67, -447.58, 159.84),
                    vector3(-1830.83, -397.35, 161.29),
                    vector3(-1810.1, -422.2, 158.54),
                    vector3(-1843.91, -422.11, 160.75),
                    vector3(-1814.69, -423.37, 160.0),
                },
            },
            ["Sisika"] = {
                loc = vector3(3380.68, -659.07, 46.76),
                npc = { enabled = true, ped = vector4(3380.39, -657.57, 46.76, 212.9), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
                pickup = vector3(3367.73, -655.25, 46.32),
                workSpot = {
                    vector3(3354.9, -683.06, 44.07),
                    vector3(3340.86, -702.38, 44.27),
                    vector3(3332.82, -675.11, 45.53),
                    vector3(3351.17, -656.75, 45.36),
                    vector3(3367.39, -645.78, 46.27),
                    vector3(3381.01, -671.52, 46.25),
                    vector3(3349.86, -666.79, 45.63),
                },
            },
            ["Tumbleweed"] = {
                loc = vector3(-5495.16, -2958.5, -0.69),
                npc = { enabled = true, ped = vector4(-5495.16, -2958.5, -0.69, 14.07), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
                pickup = vector3(-5492.86, -2968.59, -1.98),
                workSpot = {
                    vector3(-5482.29, -2962.48, -1.66),
                    vector3(-5511.05, -2965.95, -1.57),
                    vector3(-5477.02, -2939.71, -1.08),
                    vector3(-5478.06, -2932.15, -1.25),
                    vector3(-5492.17, -2934.13, -1.13),
                },
            },
            ["Guarma"] = {
                loc = vector3(1298.52, -6831.73, 43.92),
                npc = { enabled = true, ped = vector4(1298.52, -6831.73, 43.92, 265.34), model = "a_m_m_bivworker_01" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Construction Job" },
                pickup = vector3(1289.83, -6841.93, 43.64),
                workSpot = {
                    vector3(1285.72, -6840.05, 43.64),
                    vector3(1304.74, -6838.28, 43.28),
                    vector3(1307.92, -6831.07, 43.3),
                    vector3(1290.81, -6846.96, 43.7),
                },
            },
        },
    },

    Sweeping = {
        label = "Sweeping",

        pedSpawning = function(ped) -- The manager holds a broom
            return { AttachProp(ped, "p_broom01x", "SKEL_R_Finger12", vec3(0.49, 0.0, 0.52), vec3(0.0, 225.0, 35.0), false) }
        end,

        pickup = {
            label = "Pick up broom",
            run = function(ped)
                local prop = AttachProp(ped, "p_broom01x", "SKEL_R_Finger12", vec3(0.49, 0.0, 0.52), vec3(0.0, 225.0, 35.0))
                return true, prop
            end,
        },

        workSpot = {
            label = "Sweep the floor",
            run = function(ped)
                TaskStartScenarioInPlace(ped, joaat("WORLD_HUMAN_BROOM_WORKING"), 30000, true, false, false, false)
                return PlaySkillbar({ 4000, 3400, 3000, 2700 }, 7)
            end,
        },

        pay = {
            [0] = 15,
            [10] = 20,
            [40] = 24,
            [70] = 32,
        },

        locations = {
            ["Saint Denis"] = {
                loc = vector3(2852.69, -1210.28, 47.69),
                npc = { enabled = true, ped = vector4(2852.69, -1210.28, 47.69, 91.42), model = "CS_PrincessIsabeau" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Sweeping Job" },
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
                npc = { enabled = true, ped = vector4(1346.38, -1319.18, 76.9, 319.78), model = "CS_PrincessIsabeau" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Sweeping Job" },
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
            ["Valentine"] = {
                loc = vector3(-320.94, 777.82, 118.01),
                npc = { enabled = true, ped = vector4(-320.94, 777.82, 118.01, 10.97), model = "CS_PrincessIsabeau" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Sweeping Job" },
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
                npc = { enabled = true, ped = vector4(-1749.88, -383.93, 156.42, 199.43), model = "CS_PrincessIsabeau" },
                blip = { enabled = true, style = 1664425300, scale = 0.2, sprite = "blip_proc_loanshark", name = "Sweeping Job" },
                pickup = vector3(-1761.47, -394.53, 156.26),
                workSpot = {
                    vector3(-1775.32, -402.05, 156.48),
                    vector3(-1781.9, -387.56, 159.26),
                    vector3(-1807.93, -368.28, 162.84),
                    vector3(-1790.85, -355.01, 165.02),
                    vector3(-1781.18, -373.39, 159.91),
                },
            },
        },
    },
}
