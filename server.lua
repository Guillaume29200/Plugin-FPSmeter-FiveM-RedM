local fps = 0
local ticks = 0
local lastSecond = GetGameTimer()
local startTime = os.time()

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        ticks = ticks + 1
        local now = GetGameTimer()
        if now - lastSecond >= 1000 then
            fps = ticks
            ticks = 0
            lastSecond = now
        end
    end
end)

RegisterCommand("fpsmeter", function(source, args, raw)
    local players = #GetPlayers()
    local uptime = os.time() - startTime
    local totalPing = 0

    for _, id in ipairs(GetPlayers()) do
        totalPing = totalPing + GetPlayerPing(id)
    end

    local avgPing = players > 0 and math.floor(totalPing / players) or 0

    local output = {
        fps = fps,
        players = players,
        avg_ping = avgPing,
        uptime = uptime
    }

    print(json.encode(output))
end, true)
