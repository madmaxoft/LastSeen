
-- Storage.lua

-- Implements the DB backend for the plugin





--- The DB object
g_DB = {}





--- Creates the table of the specified name and columns[]
-- If the table exists, any columns missing are added; existing data is kept
-- a_Columns is an array of {ColumnName, ColumnType}, it will receive a map of LowerCaseColumnName => {ColumnName, ColumnType}
function g_DB:CreateDBTable(a_TableName, a_Columns)
	-- Check params:
	assert(self)
	assert(a_TableName)
	assert(a_Columns)
	assert(a_Columns[1])
	assert(a_Columns[1][1])
	
	-- Try to create the table first
	local ColumnDefs = {}
	for _, col in ipairs(a_Columns) do
		table.insert(ColumnDefs, col[1] .. " " .. (col[2] or ""))
	end
	local sql = "CREATE TABLE IF NOT EXISTS '" .. a_TableName .. "' ("
	sql = sql .. table.concat(ColumnDefs, ", ");
	sql = sql .. ")";
	if (not(self:ExecuteStatement(sql))) then
		LOGWARNING(PLUGIN_PREFIX .. "Cannot create DB Table " .. a_TableName)
		return false
	end
	-- SQLite doesn't inform us if it created the table or not, so we have to continue anyway
	
	-- Add the map of LowerCaseColumnName => {ColumnName, ColumnType} to a_Columns:
	for _, col in ipairs(a_Columns) do
		a_Columns[string.lower(col[1])] = col
	end
	
	-- Check each column whether it exists
	local ExistingColumns = {}  -- map of lcColumnName => true for each column that exists in the DB
	local function ColumnExists(a_Values)
		ExistingColumns[string.lower(a_Values["name"])] = true
	end
	if (not(self:ExecuteStatement("PRAGMA table_info(" .. a_TableName .. ")", nil, ColumnExists))) then
		LOGWARNING(PLUGIN_PREFIX .. "Cannot query DB table structure")
		return false
	end
	
	-- Get the columns that need adding:
	local ColumnsToAdd = {}  -- Array of {ColumnName, ColumnType}
	for _, col in ipairs(a_Columns) do
		if not(ExistingColumns[string.lower(col[1])]) then
			table.insert(ColumnsToAdd, col)
		end
	end
	
	-- Create the missing columns
	if (ColumnsToAdd[1]) then
		LOGINFO(PLUGIN_PREFIX .. "Database table \"" .. a_TableName .. "\" is missing " .. #ColumnsToAdd .. " columns, fixing now.")
		for _, col in ipairs(ColumnsToAdd) do
			if (not(self:ExecuteStatement("ALTER TABLE '" .. a_TableName .. "' ADD COLUMN " .. col[1] .. " " .. (col[2] or "")))) then
				LOGWARNING(PLUGIN_PREFIX .. "Cannot add DB table \"" .. a_TableName .. "\" column \"" .. col[1] .. "\"")
				return false
			end
		end
		LOGINFO(PLUGIN_PREFIX .. "Database table \"" .. a_TableName .. "\" columns fixed.")
	end
	
	return true
end





--- Executes the SQL statement, substituting "?" in the SQL with the specified params
-- Calls a_Callback for each row
-- The callback receives a dictionary table containing the row values (stmt:nrows())
-- Returns false and error message on failure, or true on success
function g_DB:ExecuteStatement(a_SQL, a_Params, a_Callback)
	-- Check params:
	assert(self)
	assert(self.DB)
	assert(type(a_SQL) == "string")
	assert((a_Params == nil) or (type(a_Params) == "table"))
	assert((a_Callback == nil) or (type(a_Callback) == "function"))
	
	local Stmt, ErrCode, ErrMsg = self.DB:prepare(a_SQL)
	if (Stmt == nil) then
		LOGWARNING("Cannot prepare SQL \"" .. a_SQL .. "\": " .. (ErrCode or "<unknown>") .. " (" .. (ErrMsg or "<no message>") .. ")")
		LOGWARNING("  Params = {" .. table.concat(a_Params, ", ") .. "}")
		return nil, (ErrMsg or "<no message")
	end
	if (a_Params ~= nil) then
		Stmt:bind_values(unpack(a_Params))
	end
	if (a_Callback == nil) then
		Stmt:step()
	else
		for v in Stmt:nrows() do
			a_Callback(v)
		end
	end
	Stmt:finalize()
	return true;
end





--- Returns the LastSeen info for the specified player.
-- If the player is found, a table describing the LastSeen info is returned (same format as DB columns)
-- If the player is not found, nil is returned
function g_DB:GetLastSeen(a_PlayerName)
	-- Check params:
	assert(type(a_PlayerName) == "string")
	
	-- Query the DB:
	local res
	self:ExecuteStatement(
		"SELECT * FROM LastSeen WHERE PlayerName = ? COLLATE NOCASE",
		{
			string.lower(a_PlayerName),
		},
		function (a_Values)
			res = a_Values
		end
	)
	
	return res
end





function InitStorage()
	-- Open the DB:
	local DBFile = "LastSeen.sqlite"
	local ErrCode, ErrMsg
	g_DB.DB, ErrCode, ErrMsg = sqlite3.open(DBFile)
	if not(g_DB.DB) then
		LOGWARNING(PLUGIN_PREFIX .. "Cannot open database \"" .. DBFile .. "\": " .. ErrCode .. " / " .. ErrMsg)
		error(ErrCode .. " / " .. ErrMsg)  -- Abort the plugin
	end
	
	-- Create the DB structure, if not already present:
	local LastSeenColumns =
	{
		{ "PlayerName",   "TEXT" },
		{ "LastInDate",   "INTEGER" },
		{ "LastOutDate",  "INTEGER" },
		{ "LastPosX",     "INTEGER" },
		{ "LastPosY",     "INTEGER" },
		{ "LastPosZ",     "INTEGER" },
		{ "Cfg",          "TEXT" },
	}
	if (
		not(g_DB:CreateDBTable("LastSeen", LastSeenColumns))
	) then
		LOGWARNING(PLUGIN_PREFIX .. "Cannot create DB tables!");
		error("Cannot create DB tables!");
	end
end




