
-- LastSeen.lua

-- Implements the main plugin entrypoint, as well as the command handlers






--- The prefix used for all console messages in the plugin
PLUGIN_PREFIX = "LastSeen: "

--- Map of online players
-- Maps PlayerName to true (player online) or nil (player offline).
-- TODO: Use this for reporting - if a player is online, make a specific message for /lastseen
local g_IsPlayerOnline = {}





--- Returns the player's position as a user-visible string
-- a_LastSeen is the LastSeen table loaded from the DB
local function FormatPos(a_LastSeen)
	-- Check params:
	assert(type(a_LastSeen) == "table")
	
	-- Format the position:
	return string.format("{%i, %i, %i}", a_LastSeen.LastPosX, a_LastSeen.LastPosY, a_LastSeen.LastPosZ)
end





--- Returns the "/tp" command to teleport to the specified LastSeen coords
local function FormatTpCmd(a_LastSeen)
	-- Check params:
	assert(type(a_LastSeen) == "table")
	
	-- Format the command:
	return "/tp " .. a_LastSeen.LastPosX .. " " .. a_LastSeen.LastPosY .. " " .. a_LastSeen.LastPosZ
end





--- Formats the LastSeen information retrieved from DB into a message sent to a player
-- Returns a cCompositeChat instance
local function FormatLastSeenMsg(a_LastSeen)
	-- Check params:
	assert(type(a_LastSeen) == "table")
	assert(a_LastSeen.Cfg)
	
	-- Format the message based on the player's config:
	local cfg = a_LastSeen.Cfg
	if (cfg == "all") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here on " .. os.date("%Y-%m-%d %H:%M:%S", a_LastSeen.LastInDate) .. " at ")
			:AddSuggestCommandPart(FormatPos(a_LastSeen), FormatTpCmd(a_LastSeen), "u")
	elseif (cfg == "pos") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here at ")
			:AddSuggestCommandPart(FormatPos(a_LastSeen), FormatTpCmd(a_LastSeen), "u")
	elseif (cfg == "time") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here on " .. os.date("%Y-%m-%d %H:%M:%S", a_LastSeen.LastInDate))
	end
	return cCompositeChat(a_LastSeen.PlayerName .. " wishes to remain anonymous here.")
end





function HandleCmdLastSeen(a_Split, a_Player, a_EntireCmd)
	-- Check params, display usage if PlayerName missing:
	if not(a_Split[2]) then
		a_Player:SendMessage(
			cCompositeChat("Usage: ")
			:AddSuggestCommandPart(a_Split[1], a_Split[1])
			:AddTextPart(" <PlayerName>", "@2")
		)
		a_Player:SendMessage(
			cCompositeChat("Displays the last seen place and time of the specified player, unless they disallowed that in their settings. You can edit your own preference using the ")
			:AddSuggestCommandPart("/lastseencfg", "/lastseencfg", "u")
			:AddTextPart(" command.")
		)
		return true
	end
	
	-- Retrieve the data from the DB:
	local LastSeen = g_DB:GetLastSeen(a_Split[2])
	if not(LastSeen) then
		a_Player:SendMessage(a_Split[2] .. " has never been to this server.")
		return true
	end
	
	-- If the player has the rights, display the LastSeen info even if the user opted out:
	if ((LastSeen.Cfg ~= "all") and a_Player:HasPermission("lastseen.admin.seeall")) then
		LastSeen.Cfg = "all"
		a_Player:SendMessage("(You're using your admin override to view the player's LastSeen status)")
	end
	
	-- Send the info to the player:
	a_Player:SendMessage(FormatLastSeenMsg(LastSeen))
	return true
end





function HandleConsoleCmdLastSeen(a_Split, a_EntireCmd)
	-- Check params:
	if not(a_Split[2]) then
		return true, "Usage: " .. a_Split[1] .. " <PlayerName>"
	end
	
	-- Retrieve the data from the DB:
	local LastSeen = g_DB:GetLastSeen(a_Split[2])
	if not(LastSeen) then
		return true, a_Split[2] .. " has never been to this server."
	end
	
	-- Console user always has admin rights:
	LastSeen.Cfg = "all"
	
	-- Format the message and return its text only:
	local msg = FormatLastSeenMsg(LastSeen)
	return true, msg:ExtractText()
end





--- Handler for the HOOK_PLAYER_SPAWNED hook
-- Updates the LastSeen info in the DB
local function OnPlayerSpawned(a_Player)
	g_IsPlayerOnline[a_Player:GetName()] = true
	g_DB:UpdateLastSeen(a_Player, "LastInDate")
	return false
end





--- Handler for the HOOK_PLAYER_DESTROYED hook
-- Updates the LastSeen info in the DB
local function OnPlayerDestroyed(a_Player)
	g_IsPlayerOnline[a_Player:GetName()] = nil
	g_DB:UpdateLastSeen(a_Player, "LastOutDate")
	return false
end





function Initialize(a_Plugin)
	InitStorage()

	-- Register the commands:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")
	RegisterPluginInfoCommands()
	RegisterPluginInfoConsoleCommands()
	
	-- Register the hooks that store the LastSeen info:
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED,   OnPlayerSpawned)
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)

	return true
end




