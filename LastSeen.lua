
-- LastSeen.lua

-- Implements the main plugin entrypoint, as well as the command handlers






--- The prefix used for all console messages in the plugin
PLUGIN_PREFIX = "LastSeen: "





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
local function FormatLastSeenMsg(a_LastSeen)
	-- Check params:
	assert(type(a_LastSeen) == "table")
	assert(a_LastSeen.Cfg)
	
	-- Format the message based on the player's config:
	local cfg = a_LastSeen.Cfg
	if (cfg == "all") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here on " .. os.date("%Y-%m-%dT%H:%M:%S", a_LastSeen.LastInDate) .. " at ")
			:AddSuggestCommandPart(FormatPos(a_LastSeen), FormatTpCmd(a_LastSeen))
	elseif (cfg == "pos") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here at ")
			:AddSuggestCommandPart(FormatPos(a_LastSeen), FormatTpCmd(a_LastSeen))
	elseif (cfg == "time") then
		return cCompositeChat(a_LastSeen.PlayerName .. " was last seen here on " .. os.date("%Y-%m-%dT%H:%M:%S", a_LastSeen.LastInDate))
	end
	return a_LastSeen.PlayerName .. " wishes to remain anonymous here."
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
			:AddSuggestCommandPart("/lastseencfg", "/lastseencfg")
			:AddTextPart(" command.")
		)
	end
	
	-- Retrieve the data from the DB:
	local LastSeen = g_DB:GetLastSeen(a_Split[2])
	if not(LastSeen) then
		a_Player:SendMessage(a_Split[2] .. " has never been to this server.")
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





function Initialize(a_Plugin)
	InitStorage()

	-- Register the commands:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")
	RegisterPluginInfoCommands()

	return true
end




