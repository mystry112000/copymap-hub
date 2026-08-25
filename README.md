# COPYMAP_HUB - SaveInstance Script

A self-contained Roblox executor saveinstance script. No external dependencies needed.
Saves games/places to `.rbxlx`/`.rbxmx` files.

## How to Use

```lua
local rawScript = game:HttpGet("https://raw.githubusercontent.com/mystry112000/copymap-hub/main/saveinstance.lua", true)
local synsaveinstance = loadstring(rawScript)()

synsaveinstance({
    mode = "custom",
    ExtraInstances = {
        workspace,
        game:GetService("Lighting"),
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerStorage"),
        game:GetService("ServerScriptService"),
        game:GetService("StarterGui"),
        game:GetService("StarterPlayer")
    },
    SafeMode = true,
    Decompile = true,
    FilePath = "Map_F2"
})
```

## Join our Discord

[https://discord.gg/a8ru9NveN](https://discord.gg/a8ru9NveN)
