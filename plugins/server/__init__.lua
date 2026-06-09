-- XLServerUtils Plugin
-- Features:
--   1. Bot difficulty fix - sets aimNoiseScale on bot spawn (IOI V7 Fix)
--   2. Auto-start game once minimum player count is reached

-- -------------------------------------------------------
-- Configuration
-- -------------------------------------------------------

local aimNoiseScale <const> = 9

-- Minimum number of human players required to auto-start the game.
local minPlayersToStart <const> = 4

-- How often (in seconds) to check if we should auto-start.
local checkIntervalSeconds <const> = 5

-- -------------------------------------------------------
-- State
-- -------------------------------------------------------

local hasAutoStarted = false
local isLevelLoaded = false

-- -------------------------------------------------------
-- Feature 1: Bot Difficulty Fix (IOI V7)
-- Sets aimNoiseScale each time a bot spawns so the
-- difficulty setting actually takes effect.
-- -------------------------------------------------------

EventManager.Listen("ServerPlayer:Spawned", function(player)
    if player == nil then
        return
    end

    if player.isBot then
        local settings = Console.GetSettings("AutoPlayers")
        if settings ~= nil then
            settings.aimNoiseScale = aimNoiseScale
        end
    end
end)

-- -------------------------------------------------------
-- Feature 2: Auto-Start
-- Counts human players and forces the game to start once
-- minPlayersToStart is reached. This is needed for XL
-- CO-OP servers where the default 4-player start threshold
-- causes the game to never start with larger player counts.
-- -------------------------------------------------------

local function getHumanPlayerCount()
    local count = 0
    local players = PlayerManager.GetPlayers()
    for _, player in ipairs(players) do
        if not player.isBot then
            count = count + 1
        end
    end
    return count
end

local function tryAutoStart()
    -- Only attempt once per level load
    if hasAutoStarted then
        return
    end

    -- Don't run before a level is loaded
    if not isLevelLoaded then
        return
    end

    local humanCount = getHumanPlayerCount()

    if humanCount >= minPlayersToStart then
        print(string.format("[XLServerUtils] %d human players present, auto-starting game.", humanCount))
        Console.Execute("Kyber.Broadcast **KYBER:** Auto-starting game with " .. humanCount .. " players.")

        -- Force the game to start by setting the minimum player count to 1
        -- and triggering a start check
        local wsSettings = Console.GetSettings("Whiteshark")
        if wsSettings ~= nil then
            wsSettings.minNumberOfPlayers = 1
        end

        -- Also execute the start command directly
        Console.Execute("wS.minNumberOfPlayers 1")
        Console.Execute("Kyber.startgame")

        hasAutoStarted = true
    end
end

-- Periodic check service
local AutoStartService = {
    elapsed = 0,

    update = function(self, deltaSecs)
        if hasAutoStarted then
            return
        end

        self.elapsed = self.elapsed + deltaSecs
        if self.elapsed >= checkIntervalSeconds then
            self.elapsed = self.elapsed - checkIntervalSeconds
            tryAutoStart()
        end
    end,
}

EventManager.Listen("Server:UpdatePre", AutoStartService.update, AutoStartService)

-- Reset auto-start flag when a new level loads
EventManager.Listen("Level:Loaded", function(levelName, gameModeId)
    print(string.format("[XLServerUtils] Level loaded: %s (%s). Resetting auto-start.", levelName, gameModeId))
    hasAutoStarted = false
    isLevelLoaded = true
end)

-- Also try to start immediately when a player joins
-- in case the periodic check hasn't fired yet
EventManager.Listen("ServerPlayer:Joined", function(player)
    if player == nil or player.isBot then
        return
    end

    tryAutoStart()
end)

EventManager.Listen("Server:Init", function()
    print("[XLServerUtils] Plugin initialized.")
    print(string.format("[XLServerUtils] Bot aimNoiseScale: %.2f", aimNoiseScale))
    print(string.format("[XLServerUtils] Auto-start threshold: %d players", minPlayersToStart))
end)
