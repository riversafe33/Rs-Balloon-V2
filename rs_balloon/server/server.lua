local VORPcore = exports.vorp_core:GetCore()
local T = Translation.Langs[Config.Lang]

RegisterServerEvent('rs_balloon:checkOwned')
AddEventHandler('rs_balloon:checkOwned', function()
    local src = source
    local User = VORPcore.getUser(src).getUsedCharacter
    local u_identifier = User.identifier
    local u_charid = User.charIdentifier

    exports.oxmysql:execute('SELECT * FROM balloon_buy WHERE identifier = @identifier AND charid = @charid LIMIT 1', {
        ['@identifier'] = u_identifier,
        ['@charid'] = u_charid
    }, function(result)
        if result and result[1] then
            TriggerClientEvent('rs_balloon:openMenu', src, true)
        else
            TriggerClientEvent('rs_balloon:openMenu', src, false)
        end
    end)
end)

RegisterNetEvent('rs_balloon:RentBalloon')
AddEventHandler('rs_balloon:RentBalloon', function(locationIndex)
    local src = source
    local Character = VORPcore.getUser(src).getUsedCharacter
    local money = Character.money
    local cost = Config.BallonPrice
    local duration = Config.BallonUseTime * 60

    if not Character or not Character.identifier then
        return
    end

    if money < cost then
        VORPcore.NotifyLeft(src, T.Tittle, T.NeedMoney .. "  " .. cost .. "$ " .. T.ToRentBalloon,  "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    exports.oxmysql:execute("SELECT * FROM balloon_rentals WHERE user_id = ? AND character_id = ?", {
        Character.identifier,
        Character.charIdentifier
    }, function(result)
        if result[1] then
            VORPcore.NotifyLeft(src, T.Tittle, T.AlreadyHasBalloon, "menu_textures", "cross", 4000, "COLOR_RED")
            return
        end

        Character.removeCurrency(0, cost)
        VORPcore.NotifyLeft(src, T.Tittle, T.BalloonRented .. " " .. Config.BallonUseTime .. " " .. T.Minutes, "generic_textures", "tick", 4000, "COLOR_GREEN")

        exports.oxmysql:execute("INSERT INTO balloon_rentals (user_id, character_id, duration) VALUES (?, ?, ?)", {
            Character.identifier,
            Character.charIdentifier,
            duration
        }, function()
            exports.oxmysql:execute("SELECT LAST_INSERT_ID() AS id", {}, function(idResult)
                if idResult and idResult[1] and idResult[1].id then
                    local balloonId = idResult[1].id
                    TriggerClientEvent("rs_balloon:spawnBalloon1", src, balloonId, locationIndex)
                    startBalloonCountdown(Character.identifier, Character.charIdentifier, src, balloonId)
                end
            end)
        end)
    end)
end)

function startBalloonCountdown(user_id, character_id, src, balloonId)
    local interval = 30
    local interval_ms = interval * 1000
    local shouldStop = false
    local warned_90 = false
    local warned_60 = false
    local warned_30 = false

    Citizen.CreateThread(function()
        while not shouldStop do
            Citizen.Wait(interval_ms)

            exports.oxmysql:execute("UPDATE balloon_rentals SET duration = duration - ? WHERE user_id = ? AND character_id = ?", {
                interval,
                user_id,
                character_id
            })

            exports.oxmysql:execute("SELECT duration FROM balloon_rentals WHERE user_id = ? AND character_id = ?", {
                user_id,
                character_id
            }, function(result)
                if result[1] then
                    local remaining = tonumber(result[1].duration)

                    if remaining == 90 and not warned_90 then
                        TriggerClientEvent("rs_balloon:balloonWarning", src, remaining)
                        warned_90 = true
                    end

                    if remaining == 60 and not warned_60 then
                        TriggerClientEvent("rs_balloon:balloonWarning", src, remaining)
                        warned_60 = true
                    end

                    if remaining == 30 and not warned_30 then
                        TriggerClientEvent("rs_balloon:balloonWarning", src, remaining)
                        warned_30 = true
                    end

                    if remaining <= 0 then
                        TriggerClientEvent("rs_balloon:balloonWarning", src, 0)
                        exports.oxmysql:execute("DELETE FROM balloon_rentals WHERE user_id = ? AND character_id = ?", {
                            user_id,
                            character_id
                        })
                        TriggerClientEvent("rs_balloon:deleteTemporaryBalloon", src, balloonId)
                        shouldStop = true
                    end
                else
                    shouldStop = true
                end
            end)
        end
    end)
end

RegisterNetEvent("rs_balloon:removeBalloonFromSQL")
AddEventHandler("rs_balloon:removeBalloonFromSQL", function()
    local src = source
    local Character = VORPcore.getUser(src).getUsedCharacter

    if not Character or not Character.identifier then
        return
    end

    exports.oxmysql:execute("DELETE FROM balloon_rentals WHERE user_id = ? AND character_id = ?", {
        Character.identifier,
        Character.charIdentifier
    })
end)

RegisterServerEvent('rs_balloon:buyballoon')
AddEventHandler('rs_balloon:buyballoon', function(args)
    local _price = args['Price']
    local _name = args['Name']
    local User = VORPcore.getUser(source).getUsedCharacter

    local u_identifier = User.identifier
    local u_charid = User.charIdentifier
    local u_money = User.money

    if u_money < _price then
        VORPcore.NotifyLeft(source, T.Tittle, T.Noti,  "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    User.removeCurrency(0, _price)

    local Parameters = {
        ['identifier'] = u_identifier,
        ['charid'] = u_charid,
        ['name'] = _name
    }

    exports.oxmysql:execute("INSERT INTO balloon_buy (`identifier`, `charid`, `name`) VALUES (@identifier, @charid, @name)", Parameters)
    VORPcore.NotifyLeft(source, T.Tittle, T.Noti1, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)

RegisterServerEvent('rs_balloon:loadownedBallons')
AddEventHandler('rs_balloon:loadownedBallons', function()
    local _source = source
    local User = VORPcore.getUser(_source).getUsedCharacter
    local u_identifier = User.identifier
    local u_charid = User.charIdentifier

    local Parameters = {
        ['@identifier'] = u_identifier,
        ['@charid'] = u_charid
    }

    exports.oxmysql:execute('SELECT * FROM balloon_buy WHERE identifier = @identifier AND charid = @charid', Parameters, function(HasBalloons)
        if HasBalloons[1] then
            TriggerClientEvent("rs_balloon:loadBallonMenu", _source, HasBalloons)
        end
    end)
end)

RegisterServerEvent('rs_balloon:transferBalloon')
AddEventHandler('rs_balloon:transferBalloon', function(targetId)
    local src = source
    local sender = VORPcore.getUser(src).getUsedCharacter
    local target = VORPcore.getUser(tonumber(targetId))
    if not target then
        return
    end

    local sender_identifier = sender.identifier
    local sender_charid = sender.charIdentifier
    local target_identifier = target.getUsedCharacter.identifier
    local target_charid = target.getUsedCharacter.charIdentifier

    -- Verificar si el receptor ya tiene un globo
    exports.oxmysql:execute('SELECT * FROM balloon_buy WHERE identifier = @identifier AND charid = @charid LIMIT 1', {
        ['@identifier'] = target_identifier,
        ['@charid'] = target_charid
    }, function(existing)
        if existing and existing[1] then
            VORPcore.NotifyLeft(src, T.Tittle, T.has, "menu_textures", "cross", 4000, "COLOR_RED")
        else
            -- Transferir el globo al nuevo jugador
            exports.oxmysql:execute('UPDATE balloon_buy SET identifier = @newIdentifier, charid = @newCharId WHERE identifier = @oldIdentifier AND charid = @oldCharId LIMIT 1', {
                ['@newIdentifier'] = target_identifier,
                ['@newCharId'] = target_charid,
                ['@oldIdentifier'] = sender_identifier,
                ['@oldCharId'] = sender_charid
            }, function()
                VORPcore.NotifyLeft(src, T.Tittle, T.Tranfer, "generic_textures", "tick", 4000, "COLOR_GREEN")
                VORPcore.NotifyLeft(tonumber(targetId), T.Tittle, T.Received, "generic_textures", "tick", 4000, "COLOR_GREEN")
            end)
        end
    end)
end)

RegisterServerEvent('rs_balloon:sellballoon')
AddEventHandler('rs_balloon:sellballoon', function(args)
    if not args then
        VORPcore.NotifyLeft(source, T.Tittle, T.Error, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local User = VORPcore.getUser(source).getUsedCharacter

    local u_identifier = User.identifier
    local u_charid = User.charIdentifier
    local original_price = nil

    for _, globo in pairs(Config.Globo) do
        original_price = globo.Param.Price
        break
    end

    if original_price then
        local sell_price = original_price * Config.Sellprice

        User.addCurrency(0, sell_price)

        exports.oxmysql:execute("DELETE FROM balloon_buy WHERE identifier = @identifier AND charid = @charid", {
            ['@identifier'] = u_identifier,
            ['@charid'] = u_charid,
        })
        VORPcore.NotifyLeft(source, T.Tittle, T.Buy .. " " .. sell_price .. "$",  "generic_textures", "tick", 4000, "COLOR_GREEN")
    else
        VORPcore.NotifyLeft(source, T.Tittle, T.Dont, "menu_textures", "cross", 4000, "COLOR_RED")
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    exports.oxmysql:execute("DELETE FROM balloon_rentals", {}, function()
    end)
end)
