# COPYMAP_HUB - SaveInstance Script

A Roblox executor saveinstance script. Saves games/places to `.rbxlx`/`.rbxmx` files.

## How to Use

```lua
local Params = {
    RepoURL = "https://raw.githubusercontent.com/mystry112000/copymap-hub/main/",
    SSI = "saveinstance",
}

local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".lua", true), Params.SSI)()

local CustomOptions = { SafeMode = true, DecompileTimeout = 15, SaveBytecode = true }

synsaveinstance(CustomOptions)
```

## Join our Discord

[https://discord.gg/a8ru9NveN](https://discord.gg/a8ru9NveN)
