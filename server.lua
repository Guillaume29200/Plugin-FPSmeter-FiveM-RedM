-- ========================================
-- FPSMeter Plugin pour FiveM/RedM
-- Version 2.0 - Rewrite complet
-- Compatible avec api.php RCON
-- ========================================

local tickRate = 0
local tickCounter = 0
local lastCheck = GetGameTimer()
local startTime = os.time()

-- Historique des performances (2 minutes)
local tickHistory = {}
local cpuHistory = {}
local pingHistory = {}
local maxHistory = 120

-- Statistiques globales
local minTick, maxTick = nil, nil
local minPing, maxPing = nil, nil

-- Mesure CPU (tick time)
local lastTickTime = os.clock()
local tickDurations = {}

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================

local function average(t)
    if #t == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(t) do sum = sum + v end
    return sum / #t
end

local function standardDeviation(t)
    if #t == 0 then return 0 end
    local avg = average(t)
    local sum = 0
    for _, v in ipairs(t) do
        sum = sum + ((v - avg) ^ 2)
    end
    return math.sqrt(sum / #t)
end

local function addToHistory(tbl, value)
    table.insert(tbl, value)
    if #tbl > maxHistory then 
        table.remove(tbl, 1) 
    end
end

-- ========================================
-- THREAD DE MONITORING
-- ========================================

CreateThread(function()
    while true do
        Wait(0)
        tickCounter = tickCounter + 1
        
        local now = GetGameTimer()
        local elapsed = now - lastCheck

        -- Mesure du temps d'exécution du tick (CPU proxy)
        local nowClock = os.clock()
        local tickDuration = (nowClock - lastTickTime) * 1000 -- en ms
        lastTickTime = nowClock

        if elapsed >= 1000 then
            -- Calcul du tick rate (équivalent "FPS serveur")
            tickRate = tickCounter
            addToHistory(tickHistory, tickRate)

            -- Min/Max tick rate
            if not minTick or tickRate < minTick then minTick = tickRate end
            if not maxTick or tickRate > maxTick then maxTick = tickRate end

            -- Moyenne tick duration → proxy CPU (%)
            addToHistory(tickDurations, tickDuration)
            local avgTickDuration = average(tickDurations)
            -- Normalisation : 33ms = 30 tick/s = 0% / 100ms = overload = 100%
            local cpuPercent = math.min(100, math.max(0, (avgTickDuration / 33.33) * 100 - 100))
            addToHistory(cpuHistory, cpuPercent)

            -- Calcul ping moyen
            local players = GetPlayers()
            local pings = {}
            for _, id in ipairs(players) do
                local ping = GetPlayerPing(id)
                table.insert(pings, ping)
            end

            local avgPing = #pings > 0 and average(pings) or 0
            addToHistory(pingHistory, avgPing)

            -- Min/Max ping
            for _, v in ipairs(pings) do
                if not minPing or v < minPing then minPing = v end
                if not maxPing or v > maxPing then maxPing = v end
            end

            -- Reset compteurs
            tickCounter = 0
            lastCheck = now
        end
    end
end)

-- ========================================
-- COMMANDE RCON : fpsmeter
-- ========================================

RegisterCommand("fpsmeter", function(source, args, rawCommand)
    -- Récupération des infos serveur
    local hostname = GetConvar('sv_hostname', 'Serveur Inconnu')
    local maxPlayers = GetConvarInt('sv_maxclients', 32)
    local currentPlayers = #GetPlayers()
    local map = GetConvar('gamename', 'Inconnu') -- Pour RedM, sinon "fivem"
    
    -- Calculs des moyennes
    local avgTick = average(tickHistory)
    local stddevTick = standardDeviation(tickHistory)
    local avgCpu = average(cpuHistory)
    local avgPing = average(pingHistory)
    local uptime = os.time() - startTime

    -- Construction de la réponse JSON
    local response = {
        -- Données principales pour api.php
        fps_avg = math.floor(avgTick),
        cpu = tonumber(string.format("%.2f", avgCpu)),
        players = currentPlayers,
        max_players = maxPlayers,
        map = map,
        hostname = hostname,
        
        -- Statistiques avancées
        fps_min = minTick or avgTick,
        fps_max = maxTick or avgTick,
        fps_std = tonumber(string.format("%.2f", stddevTick)),
        
        avg_ping = math.floor(avgPing),
        min_ping = minPing or 0,
        max_ping = maxPing or 0,
        
        uptime = uptime,
        tick_avg_ms = tonumber(string.format("%.2f", average(tickDurations)))
    }

    -- IMPORTANT : Utilisation de print() pour réponse RCON
    -- FiveM capture automatiquement le print() et le renvoie via RCON
    print(json.encode(response))
end, true) -- true = commande restreinte (RCON only)

-- ========================================
-- COMMANDE CHAT (pour debug in-game)
-- ========================================

RegisterCommand("fpsmeter_stats", function(source, args, rawCommand)
    if source == 0 then return end -- Console only pour RCON
    
    if not IsPlayerAceAllowed(source, "fpsmeter.view") then
        TriggerClientEvent("chat:addMessage", source, {
            color = {255, 0, 0},
            args = {"[FPSMeter]", "Vous n'avez pas la permission."}
        })
        return
    end

    local avgTick = math.floor(average(tickHistory))
    local avgCpu = tonumber(string.format("%.1f", average(cpuHistory)))
    local avgPing = math.floor(average(pingHistory))
    local players = #GetPlayers()

    TriggerClientEvent("chat:addMessage", source, {
        color = {0, 255, 0},
        multiline = true,
        args = {
            "[FPSMeter Stats]",
            string.format(
                "Tick Rate: %d/s | CPU: %.1f%% | Joueurs: %d | Ping: %dms",
                avgTick, avgCpu, players, avgPing
            )
        }
    })
end, false)

-- ========================================
-- LOGS DE DÉMARRAGE
-- ========================================

CreateThread(function()
    Wait(1000)
    print("^2========================================^0")
    print("^2[FPSMeter] Plugin v2.0 chargé avec succès^0")
    print("^3Commandes disponibles :^0")
    print("  ^5- fpsmeter^0 (RCON) : Récupère les stats JSON")
    print("  ^5- fpsmeter_stats^0 (in-game) : Affiche les stats")
    print("^3Compatible :^0 FiveM & RedM")
    print("^2========================================^0")
end)
