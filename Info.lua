
-- Info.lua

-- Implements the g_PluginInfo standard plugin description





g_PluginInfo =
{
	Name = "LastSeen",
	Date = "2015-05-29",
	
	Description = "This plugin allows players to view other players' last connection time and place",
	
	Commands =
	{
		["/lastseen"] =
		{
			HelpString = "Displays the last time and place a player has been seen on this server",
			Permission = "lastseen.lastseen",
			Handler = HandleCmdLastSeen,
			ParameterCombinations =
			{
				{
					Params = "<PlayerName>",
					Help = "Displays the last time and place the specified player has been seen on this server",
				},
			},
		},  -- /lastseen
		
		["/lastseencfg"] =
		{
			HelpString = "Configures the /lastseen command",
			Permission = "lastseen.lastseencfg",
			Handler = HandleCmdLastSeenCfg,
			ParameterCombinations =
			{
				{
					Params = "{all | pos | time | off}",
					Help = "Sets the amount of information displayed about you when using the /lastseen command",
				},
			},
		},  -- /lastseencfg
	},  -- Commands
	
	ConsoleCommands =
	{
		lastseen =
		{
			HelpString = "Displays the last time and place a player has been seen on this server",
			Handler = HandleConsoleCmdLastSeen,
			ParameterCombinations =
			{
				{
					Params = "<PlayerName>",
					Help = "Displays the last time and place the specified player has been seen on this server",
				},
			},
		},  -- lastseen
	},  -- ConsoleCommands
	
	Permissions =
	{
		["lastseen.admin.seeall"] =
		{
			Descriptions = "Allows admins to see the LastSeen info even for players that opted out of the LastSeen feature",
			RecommendedGroups = "admins",
		},
	},  -- Permissions
}




