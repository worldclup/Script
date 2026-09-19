if not game:IsLoaded() then game.Loaded:Wait() end

local base = "https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/final/"
local scripts = {
	[84556640895285] = "deagle-arena/main.lua",
	[133438949159785] = "endless-zombies/main.lua",
	[118805555015549] = "loot-to-forge/main.lua",
	[124216119978534] = "ride-a-pet/main.lua",
	[114204398207377] = "survive-zombie-arena/main.lua",
	[119214646022567] = "top-sniper/main.lua",
}

local path = scripts[game.PlaceId] or "all-game/main.lua"
loadstring(game:HttpGet(base .. path))()
