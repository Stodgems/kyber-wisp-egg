-- XLServerUtils Plugin
-- Features:
--   1. Bot difficulty fix - sets AimNoiseScale on Level:Loaded (BF2+ compatible)
--   2. Auto-start game once minimum player count is reached
--   3. 16v16 bot balancing via AutoPlayers settings

local Timer = require "common/timer".Timer

-- -------------------------------------------------------
-- Configuration
-- -------------------------------------------------------

-- Bot difficulty via AimNoiseScale:
-- 0 = Master, 3 = Knight, 6 = Hard, 9 = Medium, 12 = Easy
local desiredDifficulty <const> = 9

local minPlayersToStart <const> = 4
local checkIntervalSeconds <const> = 5
local maxBotsPerTeam <const> = 16
local botApplyDelaySeconds <const> = 5

-- -------------------------------------------------------
-- State
-- -------------------------------------------------------

local hasAutoStarted = false
local isLevelLoaded = false
local hasServerInitialized = false

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------

local function getHumanCountPerTeam()
    local counts = {0, 0}
    local players = PlayerManager.GetPlayers()
    for _, player in ipairs(players) do
        if player.isBot then
            goto continue
        end
        local team = player.team
        if team == 1 or team == 2 then
            counts[team] = counts[team] + 1
        end
        ::continue::
    end
    return counts
end

local function getHumanPlayerCount()
    local counts = getHumanCountPerTeam()
    return counts[1] + counts[2]
end

-- -------------------------------------------------------
-- Feature 3: 16v16 Bot Balancing
-- -------------------------------------------------------

local function applyBotCounts()
    if not hasServerInitialized or not isLevelLoaded then
        return
    end

    local settings = Console.GetSettings("AutoPlayers")
    if settings == nil then
        print("[XLServerUtils] AutoPlayers settings not found.")
        return
    end

    local humanCounts = getHumanCountPerTeam()
    local botsTeam1 = math.max(0, maxBotsPerTeam - humanCounts[1])
    local botsTeam2 = math.max(0, maxBotsPerTeam - humanCounts[2])

    settings.forceFillGameplayBotsTeam1 = botsTeam1
    settings.forceFillGameplayBotsTeam2 = botsTeam2

    print(string.format("[XLServerUtils] Bots: Team1=%d (humans=%d), Team2=%d (humans=%d)",
        botsTeam1, humanCounts[1], botsTeam2, humanCounts[2]))
end

-- -------------------------------------------------------
-- Feature 2: Auto-Start
-- -------------------------------------------------------

function tryAutoStart()
    if hasAutoStarted or not isLevelLoaded or not hasServerInitialized then
        return
    end

    local humanCount = getHumanPlayerCount()
    if humanCount >= minPlayersToStart then
        print(string.format("[XLServerUtils] %d players present, auto-starting.", humanCount))
        -- Set flag immediately so the countdown cannot be triggered again
        hasAutoStarted = true
        Console.Execute("Kyber.Broadcast **KYBER:** Game starting in 10 seconds! Choose your class!")

        -- 10 second countdown before starting
        Timer.new(5, function(t1)
            Console.Execute("Kyber.Broadcast **KYBER:** Starting in 5 seconds!")
            t1:cancel()

            Timer.new(5, function(t2)
                local wsSettings = Console.GetSettings("Whiteshark")
                if wsSettings ~= nil then
                    wsSettings.minNumberOfPlayers = 1
                end

                Console.Execute("Kyber.startgame")
                t2:cancel()

                -- Apply bots 5 seconds after the game starts
                Timer.new(botApplyDelaySeconds, function(t3)
                    print("[XLServerUtils] Applying bot counts after auto-start delay.")
                    applyBotCounts()
                    t3:cancel()
                end)
            end)
        end)
    end
end

-- -------------------------------------------------------
-- Events
-- -------------------------------------------------------

EventManager.Listen("Server:Init", function()
    hasServerInitialized = true
    print("[XLServerUtils] Plugin initialized.")
    print(string.format("[XLServerUtils] difficulty=%d, minPlayers=%d, maxBotsPerTeam=%d",
        desiredDifficulty, minPlayersToStart, maxBotsPerTeam))
end)

EventManager.Listen("Level:Loaded", function(levelName, gameModeId)
    print(string.format("[XLServerUtils] Level loaded: %s (%s).", levelName, gameModeId))
    hasAutoStarted = false
    isLevelLoaded = true

    -- Set bot difficulty on every level load (BF2+ compatible approach)
    Console.Execute("AutoPlayers.AimNoiseScale " .. desiredDifficulty)
    print("[XLServerUtils] Bot difficulty set to: " .. desiredDifficulty)
end)

EventManager.Listen("ServerPlayer:Joined", function(player)
    if player == nil or player.isBot then
        return
    end
    if hasAutoStarted then
        applyBotCounts()
    end
    tryAutoStart()
end)

EventManager.Listen("ServerPlayer:Disconnect", function(player)
    if player == nil or player.isBot then
        return
    end
    if hasAutoStarted then
        applyBotCounts()
    end
end)

-- Periodic auto-start check
local AutoStartService = {
    elapsed = 0,
    update = function(self, deltaSecs)
        if hasAutoStarted then return end
        self.elapsed = self.elapsed + deltaSecs
        if self.elapsed >= checkIntervalSeconds then
            self.elapsed = self.elapsed - checkIntervalSeconds
            tryAutoStart()
        end
    end,
}

EventManager.Listen("Server:UpdatePre", AutoStartService.update, AutoStartService)