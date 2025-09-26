Config = {}

-- Change the language
Config.Lang = 'English' -- 'English' -- 'French' -- 'Portuguese_BR'  -- 'German'  -- 'Italian' -- 'Spanish'

------------------------------- Hot Air Balloon Rental ------------------------------
Config.KeyToBuyBalloon = 0xD9D0E1C0 -- [ SPACE ] Key to rent the balloon

-- Rental price settings
Config.EnableTax = true   -- If true, the balloon rental fee will be charged, if false, it will be free.
Config.BallonPrice = 5.00 -- Rental price

Config.EnableBalloonTimer = true -- If you set it to false, the balloon will not disappear automatically.
Config.BallonUseTime = 2 -- Rental duration time in minutes
Config.BalloonModel = "hotairballoon01x"

-- Hot Air Balloon Rental locations
Config.BalloonLocations = {
    [1] = {
        coords = vector3(-397.65, 715.95, 114.88), -- Blip and prompt
        spawn = vector3(-406.58, 714.25, 115.47),     -- Where the balloon appears
        name = "Hot Air Balloon Rental",
        sprite = -1595467349
    },
    -- you can continue adding more by continuing with [2]
}

------------------------------ Hot Air Balloon store ----------------------------------

Config.Marker = {
    ["valentine"]   = {
        name = "Hot Air Balloon Store", -- Blip name
        sprite = -780469251, -- Blip sprite
        x = -290.4917, y = 691.4873, z = 112.3616, -- Blip and prompt
        spawn = {x = -289.77, y = 699.64, z = 113.45} -- Where the balloon appears
    },
    ["saint_denis"] = {
        name = "Hot Air Balloon Store", 
        sprite = -780469251,
        x = 2477.2075, y = -1364.8922, z = 45.3138,
        spawn = {x = 2463.88, y = -1372.9, z = 45.31}
    },
    ["rhodes"]      = {
        name = "Hot Air Balloon Store", 
        sprite = -780469251,
        x = 1225.9724, y = -1271.1418, z = 74.9349,
        spawn = {x = 1225.82, y = -1255.61, z = 74.53}
    },
    ["strawberry"]  = {
        name = "Hot Air Balloon Store", 
        sprite = -780469251,
        x = -1843.94, y = -431.16, z = 159.55,
        spawn = {x = -1847.04, y = -440.17, z = 159.42}
    },
    ["blackwater"]  = {
        name = "Hot Air Balloon Store", 
        sprite = -780469251,
        x = -839.0341, y = -1218.6031, z = 42.3995,
        spawn = {x = -839.63, y = -1212.74, z = 43.33}
    }
}

Config.NPC = {
    model = "A_M_M_UniBoatCrew_01",
    coords = {
        vector4(-290.4917297363281, 691.4873657226562, 112.36164855957031, 309.47),     -- Valentine Npc
        vector4(2477.20751953125, -1364.8922119140625, 45.31382369995117, 103.17),      -- Saint Denis Npc
        vector4(1225.972412109375, -1271.141845703125, 74.93492889404297, 249.81),      -- Rhodes Npc
        vector4(-1843.4991455078125, -431.02191162109375, 158.57522583007812, 153.76),  -- Strawberry Npc
        vector4(-839.0341796875, -1218.6031494140625, 42.39957809448242, 12.37),        -- Blackwater Npc
        vector4(-397.655517578125, 715.9544677734375, 114.88623809814453, 109.31),      -- Valentine Rental Npc
    }
}

------------------------------ Sell % price ----------------------------------

Config.Sellprice = 0.6 -- 60% of the original value 1.0 returns you the same as the cost original

------------------------------ Sale price ----------------------------------

Config.Globo = {
    [1] = {
        ['Text'] = "Hot Air Balloon",   -- Change it to your language
        ['Param'] = {
           ['Name'] = "Hot Air Balloon", -- Change it to your language
           ['Price'] = 1250,               -- Sale price
        }
    },
}