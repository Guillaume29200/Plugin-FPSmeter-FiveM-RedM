local fps = 0
local ticks = 0
local lastSecond = GetGameTimer()
local startTime = os.time()

local fpsHistory = {}
local pingHistory = {}
local maxHistory = 120 -- 120 secondes d'historique (2 minutes)

local minFPS, maxFPS = nil, nil
local minPing, maxPing = nil, nil

local tickDurations = {}
local waitCounter = 0
local lastClock = os.clock()

-- Moyenne
local function average(t)
    if #t == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(t) do sum = sum + v end
    return sum / #t
end

-- Écart-type
local function standardDeviation(t)
    if #t == 0 then return 0 end
    local avg = average(t)
    local sum = 0
    for _, v in ipairs(t) do
        sum = sum + ((v - avg) ^ 2)
    end
    return math.sqrt(sum / #t)
end

CreateThread(function()
    while true do
        Wait(0) -- plus proche de la vraie cadence
        ticks = ticks + 1
        waitCounter = waitCounter + 1
        local now = GetGameTimer()

        if now - lastSecond >= 1000 then
            local currentFPS = ticks
            fps = currentFPS
            table.insert(fpsHistory, currentFPS)
            if #fpsHistory > maxHistory then table.remove(fpsHistory, 1) end

            minFPS = (minFPS == nil or currentFPS < minFPS) and currentFPS or minFPS
            maxFPS = (maxFPS == nil or currentFPS > maxFPS) and currentFPS or maxFPS

            -- Ping
            local pingSum = 0
            local pings = {}
            local players = GetPlayers()
            for _, id in ipairs(players) do
                local ping = GetPlayerPing(id)
                pingSum = pingSum + ping
                table.insert(pings, ping)
            end
            local avgPing = #pings > 0 and math.floor(pingSum / #pings) or 0
            table.insert(pingHistory, avgPing)
            if #pingHistory > maxHistory then table.remove(pingHistory, 1) end

            for _, v in ipairs(pings) do
                if minPing == nil or v < minPing then minPing = v end
                if maxPing == nil or v > maxPing then maxPing = v end
            end

            -- Tick duration (temps réel écoulé entre deux ticks par os.clock)
            local nowClock = os.clock()
            local duration = nowClock - lastClock
            lastClock = nowClock
            table.insert(tickDurations, duration)
            if #tickDurations > maxHistory then table.remove(tickDurations, 1) end

            ticks = 0
            lastSecond = now
        end
    end
end)

RegisterCommand("fpsmeter", function(source, args, raw)
    if source ~= 0 and not IsPlayerAceAllowed(source, "fpsmeter.use") then
        TriggerClientEvent("chat:addMessage", source, {
            args = {"[FPSMeter]", "Vous n’êtes pas autorisé à utiliser cette commande."}
        })
        return
    end

    local players = #GetPlayers()
    local uptime = os.time() - startTime
    local avgPing = average(pingHistory)
    local avgFPS = average(fpsHistory)
    local stddevFPS = standardDeviation(fpsHistory)
    local avgTickTime = average(tickDurations)

    local output = {
        fps_avg   = math.floor(avgFPS),
        fps_min   = minFPS or avgFPS,
        fps_max   = maxFPS or avgFPS,
        fps_std   = tonumber(string.format("%.2f", stddevFPS)),
        players   = players,
        avg_ping  = math.floor(avgPing),
        min_ping  = minPing or 0,
        max_ping  = maxPing or 0,
        uptime    = uptime,
        wait_calls = waitCounter,
        avg_tick_time = tonumber(string.format("%.4f", avgTickTime))
    }

    print(json.encode(output))
end, true)

print("[fpsmeter_server] Plugin FPSMeter amélioré chargé ✅ (historique, ping, ticks, stddev, uptime).")
