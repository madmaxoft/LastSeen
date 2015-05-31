
-- Config.lua

-- Implements the configuration for the plugin





--- The configuration object
g_Config = {}

--- Name of the config file
local CONFIG_FILE = "LastSeen.cfg"





--- Checks if a_Config has all the keys it needs, adds defaults for the missing ones
-- Returns the corrected configuration (but changes the one in the parameter as well)
local function VerifyConfig(a_Config)
	-- Insert defaults:
	a_Config.DefaultCfg = a_Config.DefaultCfg or "all"
	
	return a_Config
end





--- Initializes the g_Config from the config file, if available
function InitConfig()
	-- Check if the file exists
	if not(cFile:Exists(CONFIG_FILE)) then
		-- Copy our example config file to the folder, to let the admin know the format:
		local PluginFolder = cPluginManager:Get():GetCurrentPlugin():GetLocalFolder()
		local ExampleFile = CONFIG_FILE:gsub(".cfg", ".example.cfg")
		cFile:Copy(PluginFolder .. "/example.cfg", ExampleFile)
		LOGWARNING(PLUGIN_PREFIX .. "The config file '" .. CONFIG_FILE .. "' doesn't exist. An example configuration file '"
			.. ExampleFile .. "' has been created for you. Rename this file to " .. CONFIG_FILE .. " and edit it to your liking."
		)
		g_Config = VerifyConfig({})
		return
	end

	-- Load and compile the config file:
	local cfg, err = loadfile(CONFIG_FILE)
	if not(cfg) then
		LOGWARNING(PLUGIN_PREFIX .. "Cannot load config file '" .. CONFIG_FILE .. "': " .. err)
		g_Config = VerifyConfig({})
		return
	end
	
	-- Execute the loaded file in a sandbox:
	-- This is Lua-5.1-specific and won't work in Lua 5.2!
	local Sandbox = {}
	setfenv(cfg, Sandbox)
	cfg()
	
	-- Retrieve the values we want from the sandbox:
	local Config = Sandbox.Config
	if not(Config) then
		LOGWARNING(PLUGIN_PREFIX .. "Config not found in the config file '" .. CONFIG_FILE .. "'. Using defaults.")
		Config = {}  -- Defaults will be inserted by VerifyConfig()
	end
	g_Config = VerifyConfig(Config)
end




