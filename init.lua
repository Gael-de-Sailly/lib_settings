libsettings = {}

local settings = Settings(minetest.get_worldpath() .. "/world.conf")

libsettings.settings = settings

-- Convert a noise params table into a string...
local function noise_to_string(n)
	return n.offset ..
		", " .. n.scale ..
		", " .. minetest.pos_to_string(n.spread) ..
		", " .. n.seed ..
		", " .. n.octaves ..
		", " .. n.persist ..
		", " .. (n.lacunarity or 2)
end

-- ... and the contrary!
local function string_to_noise(str)
	local t = {}
	for line in str:gmatch("[%d%.%-e]+") do -- All numeric characters: digits (%d), point (%.), minus(%-) and exponents (e).
		table.insert(t, tonumber(line))
	end
	return {
		offset = t[1],
		scale = t[2],
		spread = {x=t[3], y=t[4], z=t[5]},
		seed = t[6],
		octaves = t[7],
		persist = t[8],
		lacunarity = t[9] or 2,
	}
end

local function define_str(flag, default, read_config)
	local value = settings:get(flag)
	if value then -- This flag exists in world.conf, return its value
		return value, true
	elseif read_config then
		local on_config = minetest.setting_get(flag) -- get this flag in minetest.conf
		if on_config then -- This flag exists in minetest.conf, so return its value
			settings:set(flag, on_config)
			return on_config, false
		end
	end
	 -- Flag don't exist anywhere, so the default value will be written in settings and returned
	settings:set(flag, default) -- write to world.conf
	return default, false -- return default value
end

local function define_num(flag, default, read_config)
	local value = settings:get(flag)
	if value then -- This flag exists in world.conf, return its value
		return tonumber(value), true
	elseif read_config then
		local on_config = minetest.setting_get(flag) -- get this flag in minetest.conf
		if on_config then -- This flag exists in minetest.conf, so return its value
			settings:set(flag, on_config)
			return tonumber(on_config), false
		end
	end
	 -- Flag don't exist anywhere, so the default value will be written in settings and returned
	settings:set(flag, default) -- write to world.conf
	return default, false -- return default value
end

local function define_bool(flag, default, read_config)
	local value = settings:get_bool(flag)
	if value ~= nil then -- This flag exists in world.conf, return its value
		return value, true
	elseif read_config then
		local on_config = minetest.setting_getbool(flag) -- get this flag in minetest.conf
		if on_config ~= nil then -- This flag exists in minetest.conf, so return its value
			settings:set(flag, tostring(on_config))
			return on_config, false
		end
	end
	 -- Flag don't exist anywhere, so the default value will be written in settings and returned
	settings:set(flag, tostring(default)) -- write to world.conf
	return default, false -- return default value
end

local function define_noise(flag, default, read_config)
	local value = settings:get(flag)
	if value then -- This flag exists in world.conf, return its value
		return string_to_noise(value), true
	elseif read_config then
		local on_config = minetest.setting_get(flag) -- get this flag in minetest.conf
		if on_config then -- This flag exists in minetest.conf, so return its value
			settings:set(flag, on_config)
			return string_to_noise(on_config), false
		end
	end
	 -- Flag don't exist anywhere, so the default value will be written in settings and returned
	settings:set(flag, noise_to_string(default)) -- write to world.conf
	return default, false -- return default value
end

local settings_interface = {
	define = function(self, flag, value, read_config)
		if read_config == nil then
			read_config = true
		end
		flag = self.name .. "_" .. flag
		local typeval = type(value)
		if typeval == "string" then
			return define_str(flag, value, read_config)
		elseif typeval == "number" then
			return define_num(flag, value, read_config)
		elseif typeval == "boolean" then
			return define_bool(flag, value, read_config)
		elseif typeval == "table" then
			return define_noise(flag, value, read_config)
		end
	end,

	get_number = function(self, flag)
		flag = self.name .. "_" .. flag
		local value = settings:get(flag)
		if value then
			return tonumber(value)
		end
	end,

	get_string = function(self, flag)
		flag = self.name .. "_" .. flag
		return settings:get(flag)
	end,

	get_bool = function(self, flag)
		flag = self.name .. "_" .. flag
		return settings:get_bool(flag)
	end,

	get_noise = function(self, flag)
		flag = self.name .. "_" .. flag
		return string_to_noise(settings:get(flag))
	end,

	set = function(self, flag, value)
		flag = self.name .. "_" .. flag
		if type(value) == "table" then
			settings:set(flag, noise_to_string(value))
		else
			settings:set(flag, tostring(value))
		end
	end,

	write = function()
		settings:write()
	end,
}

-- Index metamethod
settings_interface.__index = settings_interface

function libsettings.get_object(name)
	local name = name or minetest.get_current_modname()
	return setmetatable({name = name}, settings_interface)
end

-- Save settings just after loading, and on shutdown.
minetest.after(0, settings_interface.write)
minetest.register_on_shutdown(settings_interface.write)
