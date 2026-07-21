

local Notification = nil
pcall(function()
    local notifModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/lepoco/notification/main/init.lua"))
    if notifModule then
        Notification = notifModule()
    end
end)

local function ShowNotification(Title, Text, Duration)
    if not Notification then return end
    pcall(function()
        Notification:Notify({
            Title = Title,
            Text = Text,
            Duration = Duration or 5,
        })
    end)
end

local PARTS = {
    "Head","UpperTorso","HumanoidRootPart","LowerTorso",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm",
    "LeftUpperArm","RightUpperArm","LeftFoot","RightFoot",
    "LeftLowerLeg","RightLowerLeg","LeftUpperLeg","RightUpperLeg"
}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local hitboxCache = {}
local CACHE_LIFETIME = 0.05
local MAX_CACHE_ENTRIES = 10
local frameCounter = 0

local state = {
    connections = {},
    silentactive = false,
    silentTarget = nil,
    silentLastPart = nil,
    uninjectSent = false,
    cleanupActive = false,
    lastValidTarget = nil,
    triggerLastValidTarget = nil,
    lastShootTime = 0,
    visualsEnabled = true,
    triggerFOVActive = false,
    lastTriggerTarget = nil,
    lastAttackTime = 0,
    shootDetectionEnabled = false,
    lockedTarget = nil,
    triggerKeyHeld = false,
    lastWeaponName = nil,
    lastWeaponSwitchTime = 0,
    sharedTargetLocked = false,
    sharedTarget = nil,
    namesVisible = true,
    panelVisible = true,
    weaponLastAttackTime = {},
    preciseSkipCounter = 0,
    cameraTargetLocked = false,
    cameraTarget = nil,
    cameraLastValidTarget = nil,
    cameraFOVActive = false,
    cameraEasingProgress = 0,
    cameraLastTarget = nil,
    cameraShakeTime = 0,
    silentOnly = false,
    triggerOnly = false,
    cameraOnly = false,
    heartbeatConnection = nil,
    renderSteppedConnection = nil,
    preRenderConnection = nil,
    modDetectionConnection = nil,
    modDetectionSpawn = nil,
    safetyVisualsConnection = nil,
    targetingInputConnection = nil,
    inputEndedConnection = nil,
    deathHandlerPlayerAdded = nil,
    playerRemovingConnection = nil,
    forcefieldTimers = {},
    SpeedModEnabled = false,
    antiFallCharacterConnection = nil,
    acLogServiceLoop = nil,
    acCheckerLoop = nil,
    acGripLoop = nil,
    acAccuracyLoop = nil,
    acShotTotalLoop = nil,
    acShotTotalConnection = nil,
    acShotTotalChildConnection = nil,
    daHoodCheckerConnection = nil,
    daHoodGripConnection = nil,
    daHoodCharacterConnection = nil,
    skinChangerCharacterConnection = nil,
    skinChangerBackpackConnection = nil,
    skinChangerToolConnection = nil,
}

local State = {
    Targets = {
        Silent = nil,
        Trigger = nil,
        Camera = nil
    },
    SilentTargetLocked = false,
    TriggerTargetLocked = false,
    CameraTargetLocked = false
}

local LastFrame = {
    FOVVisible = false,
    ESPVisible = false,
    PanelVisible = false,
    TriggerFOVVisible = false,
    CameraFOVVisible = false,
}

local player = LocalPlayer
local userId = player.UserId

local requestFunc = http_request or request or (syn and syn.request) or (http and http.request)

local INJECT_WEBHOOK = "https://discord.com/api/webhooks/1524951959235330140/QpiKtg-IAJAUgKh8FVn7hJBUPeGQuDVULUuhwzsFGM5Gl--Z644Y-DTkpdHRg1VeChIb"
local UNINJECT_WEBHOOK = "https://discord.com/api/webhooks/1524951241518616596/XRtkUBovM9S8p5d84yJ2p6bsNnnMONRh6cN1jy8WZVUtmualCgmm3UpPuZ2s0-6K734z"
local injectTime = tick()
local injectTimeFormatted = os.date("%Y-%m-%d %H:%M:%S")
local HttpService = game:GetService("HttpService")

local function getExecutorName()
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name then return name end
    end
    return "Unknown"
end

local function getPlatform()
    if game:GetService("GuiService"):IsTenFootInterface() then return "Console" end
    return "PC"
end

local function getOSType()
    local ok, result = pcall(function() return identifyexecutor and identifyexecutor() or "" end)
    if ok and result and result ~= "" then return "Windows" end
    return "Windows"
end

local function getMemoryUsage()
    local ok, mem = pcall(function()
        local stats = game:GetService("Stats")
        return stats and stats:GetTotalMemoryUsageMb() or 0
    end)
    return ok and mem or 0
end

local function getPing()
    local ok, result = pcall(function()
        local stats = game:GetService("Stats")
        if not stats then return 0 end
        local network = stats.Network
        if not network then return 0 end
        local serverStats = network.ServerStatsItem
        if not serverStats then return 0 end
        local ping = serverStats["Data Ping"]
        return ping and math.floor(ping:GetValue() * 1000) / 1000 or 0
    end)
    return ok and result or 0
end

local function getServerPlayerCount()
    return #Players:GetPlayers()
end

local function isPrivateServer()
    return game.PrivateServerId ~= "" and game.PrivateServerId ~= nil
end

local function getServerOwner()
    if game.PrivateServerOwnerId and game.PrivateServerOwnerId ~= 0 then
        return game.PrivateServerOwnerId
    end
    return 0
end

local function getAccountAge()
    return "Unknown"
end

local function getGameCreatorId()
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if ok and info then return info.Creator and info.Creator.CreatorTargetId or "Unknown" end
    return "Unknown"
end

local function getEnabledFeaturesCount(cfg)
    local count = 0
    if cfg["Silent Aimbot"] and cfg["Silent Aimbot"]["Enabled"] then count = count + 1 end
    if cfg["Trigger Bot"] and cfg["Trigger Bot"]["Enabled"] then count = count + 1 end
    if cfg["Camera Aimbot"] and cfg["Camera Aimbot"]["Enabled"] then count = count + 1 end
    if cfg["Visuals"] and cfg["Visuals"]["Enabled"] then count = count + 1 end
    if cfg["Skin Changer"] and cfg["Skin Changer"]["Enabled"] then count = count + 1 end
    return count
end

local function sendWebhook(url, payload)
    if not requestFunc or url == "" then return end
    task.spawn(function()
        pcall(function()
            requestFunc({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function SendInjectLog()
    local Config = shared.Illusion
    if not Config then return end

    local execName = getExecutorName()
    local platform = getPlatform()
    local gameNameOk, gameInfo = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    local gameNameStr = gameNameOk and gameInfo.Name or "Unknown"

    local avatarImageUrl = nil
    if requestFunc then
        local avatarApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=420x420&format=Png"
        pcall(function()
            local thumbRes = requestFunc({Url = avatarApiUrl, Method = "GET"})
            local thumbData = HttpService:JSONDecode(thumbRes.Body)
            if thumbData and thumbData.data and thumbData.data[1] and thumbData.data[1].imageUrl then
                avatarImageUrl = thumbData.data[1].imageUrl
            end
        end)
    end

    local silentCfg = Config["Silent Aimbot"] or {}
    local triggerCfg = Config["Trigger Bot"] or {}
    local cameraCfg = Config["Camera Aimbot"] or {}
    local visualsCfg = Config["Visuals"] or {}
    local keybindCfg = Config['Keybind Operating Systems']['Universal Keybind'] or {}
    local skinCfg = Config["Skin Changer"] or {}

    local namesCfg = visualsCfg["Names"] or {}
    local boxCfg = visualsCfg["Box"] or {}
    local fovOps = Config["Field Of View Operations"] or {}
    local fovTrigger = fovOps["Trigger Bot"] or {}
    local fovSilent = Config["Silent Aimbot"] or {}
    local fovCamera = Config["Camera Aimbot"] or {}
    local silkFov = fovSilent["Field Of View Method"] or "2D"
    local trigFov = fovTrigger["Field Of View Method"] or "2D"
    local camFov = fovCamera["Field Of View Method"] or "3D"

    local triggerKey = keybindCfg["Separate"] and keybindCfg["Separate"]["Trigger Bot"] or keybindCfg["Keybind"] or "N/A"

    local message = {
        ["username"] = "Illusion Logs",
        ["embeds"] = {{
            ["title"] = "Session Started",
            ["color"] = 9031664,
            ["thumbnail"] = { ["url"] = avatarImageUrl or "" },
            ["fields"] = {
                {["name"] = "User Info", ["value"] = string.format("**%s** (%s)\nUser ID: %s\nDisplay: %s",
                    player.Name, getAccountAge(), tostring(userId), player.DisplayName), ["inline"] = false},
                {["name"] = "Game Info", ["value"] = string.format("%s\nPlace: %s | Job: %s | Creator: %s",
                    gameNameStr, tostring(game.PlaceId), game.JobId, tostring(getGameCreatorId())), ["inline"] = false},
                {["name"] = "System", ["value"] = string.format("Exec: %s | %s | OS: %s\nMem: %.2f MB | Ping: %.0f ms",
                    execName, platform, getOSType(), getMemoryUsage(), getPing()), ["inline"] = false},
                {["name"] = "Server", ["value"] = string.format("Players: %d/%d",
                    getServerPlayerCount(), game.Players.MaxPlayers or 0), ["inline"] = true},
                {["name"] = "Inject Time", ["value"] = injectTimeFormatted, ["inline"] = true},
                {["name"] = "Silent Aimbot", ["value"] = string.format("%s | FOV: %s | Mode: %s",
                    silentCfg["Enabled"] and "On" or "Off", silkFov,
                    Config['Selecting A Player']['Silent Aimbot'] or "Toggle"), ["inline"] = false},
                {["name"] = "Trigger Bot", ["value"] = string.format("%s | FOV: %s | Key: %s | Mode: %s",
                    triggerCfg["Enabled"] and "On" or "Off", trigFov, triggerKey,
                    Config['Selecting A Player']['Trigger Bot'] or "Toggle"), ["inline"] = false},
                {["name"] = "Camera Aimbot", ["value"] = string.format("%s | FOV: %s | Mode: %s",
                    cameraCfg["Enabled"] and "On" or "Off", camFov,
                    Config['Selecting A Player']['Aim Assist'] or "Toggle"), ["inline"] = false},
                {["name"] = "Visuals", ["value"] = string.format("%s | Key: %s | Names: %s | Box: %s",
                    visualsCfg["Enabled"] and "On" or "Off", Config['Keybind Operating Systems']['Utility Operations']['Visuals'] or "N/A",
                    namesCfg["Enabled"] and "On" or "Off",
                    boxCfg["Enabled"] and "On" or "Off"), ["inline"] = false},
                {["name"] = "Skin Changer", ["value"] = string.format("%s | Knife: %s | Revolver: %s | DB: %s | Tac: %s",
                    skinCfg["Enabled"] and "On" or "Off",
                    skinCfg["[Knife]"] or "None",
                    skinCfg["[Revolver]"] or "None",
                    skinCfg["[Double-Barrel SG]"] or "None",
                    skinCfg["[TacticalShotgun]"] or "None"), ["inline"] = false},
                {["name"] = "Keybinds", ["value"] = string.format("Global: %s | Separate: %s | Uninject: %s",
                    keybindCfg["Keybind"] or "N/A", keybindCfg["Separate"]["Enabled"] and "Yes" or "No",
                    Config['Keybind Operating Systems']['Safety Operations']['Uninject'] or "N/A"), ["inline"] = false},
                {["name"] = "Features Enabled", ["value"] = tostring(getEnabledFeaturesCount(Config)), ["inline"] = true},
            },
            ["footer"] = {["text"] = "Illusion Script | Session started at " .. injectTimeFormatted}
        }}
    }

    sendWebhook(INJECT_WEBHOOK, message)
end

local function SendUninjectLog()
    local execName = getExecutorName()
    local platform = getPlatform()
    local gameNameOk, gameInfo = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    local gameNameStr = gameNameOk and gameInfo.Name or "Unknown"
    local uninjectTime = tick()
    local uninjectTimeFormatted = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local sessionDuration = math.floor(uninjectTime - injectTime)

    local avatarImageUrl = nil
    if requestFunc then
        local avatarApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=420x420&format=Png"
        pcall(function()
            local thumbRes = requestFunc({Url = avatarApiUrl, Method = "GET"})
            local thumbData = HttpService:JSONDecode(thumbRes.Body)
            if thumbData and thumbData.data and thumbData.data[1] and thumbData.data[1].imageUrl then
                avatarImageUrl = thumbData.data[1].imageUrl
            end
        end)
    end

    local message = {
        ["username"] = "Illusion Logs",
        ["embeds"] = {{
            ["title"] = "Session Ended",
            ["color"] = 9031664,
            ["thumbnail"] = { ["url"] = avatarImageUrl or "" },
            ["fields"] = {
                {["name"] = "Username", ["value"] = player.Name, ["inline"] = true},
                {["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true},
                {["name"] = "Display Name", ["value"] = player.DisplayName, ["inline"] = true},
                {["name"] = "Game Name", ["value"] = gameNameStr, ["inline"] = true},
                {["name"] = "Game Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true},
                {["name"] = "Job ID", ["value"] = game.JobId, ["inline"] = true},
                {["name"] = "Inject Time", ["value"] = injectTimeFormatted, ["inline"] = true},
                {["name"] = "Uninject Time", ["value"] = uninjectTimeFormatted, ["inline"] = true},
                {["name"] = "Session Duration", ["value"] = string.format("%d seconds", sessionDuration), ["inline"] = true},
                {["name"] = "Executor", ["value"] = execName, ["inline"] = true},
                {["name"] = "Platform", ["value"] = platform, ["inline"] = true},
                {["name"] = "Total Players", ["value"] = tostring(getServerPlayerCount()), ["inline"] = true},
            },
            ["footer"] = {["text"] = "Illusion Script | Session ended at " .. uninjectTimeFormatted}
        }}
    }

    pcall(function()
        sendWebhook(UNINJECT_WEBHOOK, message)
    end)
end

local function IsGameSupported()
    local placeId = game.PlaceId
    local supportedIds = {
        [2788229376] = true,
        [9825515356] = true,
        [80567999110374] = true,
        [138995385694035] = true,
        [123974602339071] = true,
        [86767910702812] = true,
    }
    if supportedIds[placeId] then return true end
    
    local success, productInfo = pcall(function() return MarketplaceService:GetProductInfo(placeId) end)
    if success then
        local name = productInfo.Name or ""
        if name:find("Da Hood") or name:find("Hood Customs") or name:find("D4S H00DZ") then
            return true
        end
    end
    
    local gameNameStr = tostring(game)
    if gameNameStr:find("Hood") or gameNameStr:find("Customs") or gameNameStr:find("Da Hood") then return true end
    
    return false
end

if not IsGameSupported() then
    LocalPlayer:Kick("this game is not supported, if you think this is a mistake please contact support.")
    return
end

task.spawn(function()
    pcall(SendInjectLog)
end)

if game.PlaceId == 2788229376 then
    local a, b, c, d = cloneref(game:GetService'Players'), cloneref(game:GetService'RunService'), cloneref(game:GetService'LogService'), cloneref(game:GetService'ReplicatedStorage')
    local e, f = d:WaitForChild('MainEvent', 10), a.LocalPlayer

    if not e then return end

    local g = {}
    local function nuke_logservice_ac()
        for h, i in getconnections(c.MessageOut)do
            if not g[i] then
                g[i] = true
                pcall(function()
                    i:Disable()
                end)
            end
        end
    end
    nuke_logservice_ac()
    state.acLogServiceLoop = task.spawn(function()
        while not state.cleanupActive and task.wait(5) do
            pcall(nuke_logservice_ac)
        end
    end)
    
    local h, i = {
        CHECKER_1 = true, CHECKER_4 = true,
        CHECKER = true, TeleportDetect = true,
        OneMoreTime = true, GUI_CHECK = true,
        checkingSPEED = true, BANREMOTE = true,
        KICKREMOTE = true, BR_KICKPC = true,
        BR_KICKMOBILE = true, PERMAIDBAN = true,
        INVISHIT = true,
    }

    i = hookmetamethod(game, '__namecall', newcclosure(function(j, ...)
        local k, l = getnamecallmethod(), {...}
        if k == 'FireServer' and j == e then
            if type(l[1]) == 'string' and h[l[1]] then
                return
            end
        end
        if k == 'Kick' and j == f then
            if not checkcaller() then
                return
            end
        end
        if not checkcaller() then
            local m = getfenv(2)
            if m and rawget(m, 'crash') then
                rawset(m, 'crash', newcclosure(function() end))
            end
        end
        return i(j, ...)
    end))

    state.acCheckerLoop = task.spawn(function()
        local j = f.Character or f.CharacterAdded:Wait()
        local k, l = j:WaitForChild('HumanoidRootPart', 10), j:FindFirstChild'UpperTorso'
        local function kill_checker1_connections(m)
            if not m then return end
            for n, o in getconnections(m.ChildAdded)do
                pcall(function()
                    o:Disable()
                end)
            end
        end
        kill_checker1_connections(k)
        kill_checker1_connections(l)
        state.daHoodCheckerConnection = f.CharacterAdded:Connect(function(m)
            task.wait()
            local n, o = m:WaitForChild('HumanoidRootPart', 10), m:FindFirstChild'UpperTorso'
            kill_checker1_connections(n)
            kill_checker1_connections(o)
        end)
    end)
    
    state.acGripLoop = task.spawn(function()
        local j = f.Character or f.CharacterAdded:Wait()

        local function kill_grip_watchers(k)
            if not k:IsA'Tool' then return end
            local l = k:GetPropertyChangedSignal'Grip'
            for m, n in getconnections(l)do
                pcall(function()
                    n:Disable()
                end)
            end
        end

        for k, l in j:GetChildren()do
            if l:IsA'Tool' then
                kill_grip_watchers(l)
            end
        end

        j.ChildAdded:Connect(function(k)
            if k:IsA'Tool' then
                kill_grip_watchers(k)
            end
        end)
        state.daHoodGripConnection = f.CharacterAdded:Connect(function(k)
            task.wait()
            for l, m in k:GetChildren()do
                if m:IsA'Tool' then
                    kill_grip_watchers(m)
                end
            end
            k.ChildAdded:Connect(function(l)
                if l:IsA'Tool' then
                    kill_grip_watchers(l)
                end
            end)
        end)
    end)
    
    state.acAccuracyLoop = task.spawn(function()
        local j = d:FindFirstChild'Modules'
        if not j then return end

        local k = {}

        local function hook_accuracy_module(l)
            if k[l] then return end
            k[l] = true

            local m, n = pcall(require, l)

            if m and type(n) == 'table' then
                if n.setAccuracy then
                    pcall(hookfunction, n.setAccuracy, newcclosure(function() end))
                end
                if n.accuracy then
                    n.accuracy = 1
                end
                if n.enums and n.enums.Accuracy then
                    local o = n.enums.Accuracy
                    if o.getProperty then
                        pcall(hookfunction, o.getProperty, newcclosure(function()
                            return 0
                        end))
                    end
                end

                for o, p in pairs(n)do
                    if type(p) == 'function' then
                        if string.find(o, 'find', 1, true) or string.find(o, 'get', 1, true) then
                            pcall(hookfunction, p, newcclosure(function(...)
                                return true
                            end))
                        end
                    end
                end
            end
        end

        for l, m in j:GetDescendants()do
            if m:IsA'ModuleScript' then
                local n = m.Name
                if string.find(n, 'Zone', 1, true) or string.find(n, 'Accuracy', 1, true) then
                    hook_accuracy_module(m)
                end
            end
        end

        while not state.cleanupActive and task.wait(10) do
            pcall(function()
                for l, m in workspace:GetDescendants()do
                    if m:IsA'ModuleScript' and string.find(m.Name, 'Zone', 1, true) then
                        local n, o = pcall(require, m)
                        if n and o and o.setAccuracy then
                            pcall(function()
                                o:setAccuracy(1)
                            end)
                            pcall(function()
                                o.accuracy = 1
                            end)
                        end
                    end
                end
            end)
        end
    end)

    local function ResetShotTotal()
        local DataFolder = game.Players.LocalPlayer:FindFirstChild("DataFolder")
        if DataFolder then
            local ShotTotal = DataFolder:FindFirstChild("ShotTotal")
            if ShotTotal and ShotTotal:IsA("IntValue") and ShotTotal.Value ~= 0 then
                ShotTotal.Value = 0
            end
        end
    end
    
    state.acShotTotalLoop = task.spawn(function()
        while not state.cleanupActive do
            task.wait()
            ResetShotTotal()
        end
    end)
    
    local function SetupListener()
        local DataFolder = game.Players.LocalPlayer:FindFirstChild("DataFolder")
        if DataFolder then
            local ShotTotal = DataFolder:FindFirstChild("ShotTotal")
            if ShotTotal and ShotTotal:IsA("IntValue") then
                state.acShotTotalConnection = ShotTotal:GetPropertyChangedSignal("Value"):Connect(function()
                    if ShotTotal.Value ~= 0 then
                        ShotTotal.Value = 0
                    end
                end)
            end
            
            state.acShotTotalChildConnection = DataFolder.ChildAdded:Connect(function(child)
                if child.Name == "ShotTotal" and child:IsA("IntValue") then
                    child:GetPropertyChangedSignal("Value"):Connect(function()
                        if child.Value ~= 0 then
                            child.Value = 0
                        end
                    end)
                end
            end)
        end
    end
    
    SetupListener()
    
    state.daHoodCharacterConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait()
        SetupListener()
    end)
end

local DaHoodPlaceId = {
    [2788229376] = true,
}

if DaHoodPlaceId[game.PlaceId] then
    local function GetSkinChangerCfg()
        if not shared.Illusion or not shared.Illusion['Skin Changer'] then
            return { Enabled = false, Skins = {} }
        end
        local cfg = shared.Illusion['Skin Changer']
        local skins = {}
        for k, v in pairs(cfg) do
            if k ~= 'Enabled' and k ~= 'Beam Color' then
                skins[k] = v
            end
        end
        return {
            Enabled = cfg['Enabled'] or false,
            Skins = skins
        }
    end
    
    local AppliedSkins = { }
    local KnifeData = { }
    local ToolRegistry = { }
    local SkinAssets = ReplicatedStorage:FindFirstChild('SkinAssets')
    local SkinModules = ReplicatedStorage:FindFirstChild('SkinModules')
    local SkinData = nil

    local function IsKnifeSkin(Name)
        local N = Name:lower():gsub(' ', '')
        return N == 'goldenagetanto' or N == 'gpo-knife' or N == 'gpo-knifeprestige' or N == 'heaven'
            or N == 'lovekukri' or N == 'purpledagger' or N == 'bluedagger' or N == 'greendagger' or N == 'reddagger'
            or N == 'portal' or N == 'rgbdual' or N == 'rgbdualbayonets' or N == 'galactic' or N == 'world'
            or N == 'ribbon' or N == 'emeraldbutterfly' or N == 'boy' or N == 'girl' or N == 'dragon'
            or N == 'void' or N == 'wildwest' or N == 'icedout' or N == 'reptile'
    end

    local function HideKnifeDefaults(Tool, SkinRoot)
        local Hidden = { }
        for _, Desc in next, Tool:GetDescendants() do
            if not Desc:IsA('BasePart') then continue end
            if Desc.Name == 'Handle.R' or (Desc.Parent == Tool and Desc.Name == 'Handle') then continue end
            if Desc:GetAttribute('_skinclone') or (SkinRoot and (Desc == SkinRoot or Desc:IsDescendantOf(SkinRoot))) then continue end
            Hidden[Desc] = {
                Transparency = Desc.Transparency,
                LocalTransparencyModifier = Desc.LocalTransparencyModifier,
            }
            Desc.Transparency = 1
            Desc.LocalTransparencyModifier = 1
        end
        return Hidden
    end

    local function RestoreKnifeDefaults(Hidden)
        if not Hidden then return end
        for Part, State in next, Hidden do
            if Part and Part.Parent and type(State) == 'table' then
                Part.Transparency = State.Transparency
                Part.LocalTransparencyModifier = State.LocalTransparencyModifier
            end
        end
    end

    local function CleanKnife(Tool, SkipRestore)
        local Data = KnifeData[Tool]
        local KeptHidden = SkipRestore and Data and Data.hiddenParts or nil
        if Data then
            if Data.track then
                Data.track:Stop()
                Data.track:Destroy()
                Data.track = nil
            end
            if Data.welds then
                for _, W in next, Data.welds do
                    if W then W:Destroy() end
                end
            end
            if Data.sounds then
                for _, S in next, Data.sounds do
                    if S and S.Parent then S:Destroy() end
                end
            end
            if not SkipRestore then
                RestoreKnifeDefaults(Data.hiddenParts)
                KeptHidden = nil
            end
        end
        local Mesh = Tool:FindFirstChild('Default')
        if Mesh then
            for _, V in next, Mesh:GetChildren() do
                if V.Name == 'Handle.R' or V:GetAttribute('_skinclone') then
                    V:Destroy()
                end
            end
        end
        KnifeData[Tool] = nil
        return KeptHidden
    end

    local function ApplyKnife(Character, Tool, SkinName)
        if not IsKnifeSkin(SkinName) then return end
        if Tool.Parent ~= Character then return end
        local Humanoid = Character:FindFirstChild('Humanoid')
        local RHand = Character:FindFirstChild('RightHand')
        if not Humanoid or not RHand then return end

        local Existing = KnifeData[Tool]
        if Existing and Existing.welds and #Existing.welds > 0 then
            local HandleR = Tool:FindFirstChild('Default') and Tool:FindFirstChild('Default'):FindFirstChild('Handle.R')
            if HandleR and HandleR.Parent then
                local M6D = HandleR:FindFirstChildOfClass('Motor6D')
                if M6D then
                    M6D.Part0 = RHand
                end
                if not Existing.hiddenParts then
                    local SkinRoot = nil
                    for _, Child in next, Tool:FindFirstChild('Default'):GetChildren() do
                        if Child:GetAttribute('_skinclone') then
                            SkinRoot = Child
                            break
                        end
                    end
                    Existing.hiddenParts = HideKnifeDefaults(Tool, SkinRoot)
                end
                local Animator = Humanoid:FindFirstChildOfClass('Animator')
                if Animator then
                    local N = SkinName:lower():gsub(' ', '')
                    local AnimId, SndId
                    if N == 'goldenagetanto' then AnimId = 'rbxassetid://13473404819'; SndId = 'rbxassetid://5917819099'
                    elseif N == 'gpo-knife' or N == 'gpo-knifeprestige' then AnimId = 'rbxassetid://14014278925'; SndId = 'rbxassetid://4604390759'
                    elseif N == 'heaven' then AnimId = 'rbxassetid://14500266726'; SndId = 'rbxassetid://14489860007'
                    elseif N == 'purpledagger' then AnimId = 'rbxassetid://17824999722'; SndId = 'rbxassetid://17822743153'
                    elseif N == 'bluedagger' then AnimId = 'rbxassetid://17824995184'; SndId = 'rbxassetid://17822737046'
                    elseif N == 'greendagger' then AnimId = 'rbxassetid://17825004320'; SndId = 'rbxassetid://17822741762'
                    elseif N == 'reddagger' then AnimId = 'rbxassetid://17825008844'; SndId = 'rbxassetid://17822952417'
                    elseif N == 'portal' then AnimId = 'rbxassetid://16058633881'; SndId = 'rbxassetid://16058846352'
                    elseif N == 'rgbdual' or N == 'rgbdualbayonets' then AnimId = 'rbxassetid://16769784949'; SndId = nil
                    elseif N == 'galactic' then AnimId = 'rbxassetid://8254762807'; SndId = nil
                    elseif N == 'world' then AnimId = 'rbxassetid://8254762807'; SndId = nil
                    elseif N == 'ribbon' then AnimId = 'rbxassetid://124102609796063'; SndId = 'rbxassetid://130974579277249'
                    elseif N == 'emeraldbutterfly' then AnimId = 'rbxassetid://14918231706'; SndId = 'rbxassetid://14931902491'
                    elseif N == 'boy' then AnimId = 'rbxassetid://18789158908'; SndId = 'rbxassetid://18765078331'
                    elseif N == 'girl' then AnimId = 'rbxassetid://18789162944'; SndId = 'rbxassetid://18765078331'
                    elseif N == 'dragon' then AnimId = 'rbxassetid://14217804400'; SndId = 'rbxassetid://14217789230'
                    elseif N == 'void' then AnimId = 'rbxassetid://14774699952'; SndId = 'rbxassetid://14756591763'
                    elseif N == 'wildwest' then AnimId = 'rbxassetid://16058148839'; SndId = 'rbxassetid://16058689026'
                    elseif N == 'icedout' then AnimId = 'rbxassetid://18465353361'; SndId = 'rbxassetid://14924261405'
                    elseif N == 'reptile' then AnimId = 'rbxassetid://18788955930'; SndId = 'rbxassetid://18765103349'
                    end
                    if AnimId then
                        if Existing.track then
                            Existing.track:Stop()
                            Existing.track:Destroy()
                            Existing.track = nil
                        end
                        local Anim = Instance.new('Animation')
                        Anim.AnimationId = AnimId
                        local Track = Animator:LoadAnimation(Anim)
                        Track.Looped = false
                        Track:Play()
                        Existing.track = Track
                        Anim:Destroy()
                        Track.Ended:Once(function()
                            if Existing.track == Track then Existing.track = nil end
                            Track:Destroy()
                        end)
                    end
                    if SndId then
                        local Snd = Instance.new('Sound')
                        Snd.SoundId = SndId
                        Snd.Parent = Workspace
                        Snd:Play()
                        table.insert(Existing.sounds, Snd)
                        Snd.Ended:Connect(function()
                            Snd:Destroy()
                        end)
                    end
                end
                return
            end
        end

        local KeptHidden = CleanKnife(Tool, true)
        KnifeData[Tool] = { track = nil, welds = { }, sounds = { }, hiddenParts = KeptHidden }
        local Data = KnifeData[Tool]
        local Mesh = Tool:FindFirstChild('Default')
        if not Mesh then return end
        if not Data.hiddenParts then
            Data.hiddenParts = HideKnifeDefaults(Tool, nil)
        end
        local Knives = SkinModules and SkinModules:FindFirstChild('Knives')
        if not Knives then return end
        local SkinModel = Knives:FindFirstChild(SkinName)
        if not SkinModel then
            local N = SkinName:lower():gsub(' ', '')
            for _, Child in next, Knives:GetChildren() do
                if Child.Name:lower():gsub(' ', '') == N then
                    SkinModel = Child
                    break
                end
            end
        end
        if not SkinModel then return end
        local Clone = SkinModel:Clone()
        Clone.Name = SkinName
        Clone:SetAttribute('_skinclone', true)
        local HandleR = Instance.new('Part')
        HandleR.Name = 'Handle.R'
        HandleR.Transparency = 1
        HandleR.CanCollide = false
        HandleR.Anchored = false
        HandleR.Size = Vector3.new(0.001, 0.001, 0.001)
        HandleR.Massless = true
        HandleR.Parent = Mesh
        local M6D = Instance.new('Motor6D')
        M6D.Name = 'Handle.R'
        M6D.Part0 = RHand
        M6D.Part1 = HandleR
        M6D.Parent = HandleR

        local Offset, AnimId, SndId
        local N = SkinName:lower():gsub(' ', '')

        if N == 'goldenagetanto' then
            Offset = CFrame.new(0, -0.20, -1.2) * CFrame.Angles(math.rad(90), math.rad(263.7), math.rad(180))
            AnimId = 'rbxassetid://13473404819'
            SndId = 'rbxassetid://5917819099'
        elseif N == 'gpo-knife' or N == 'gpo-knifeprestige' then
            Offset = CFrame.new(0, -0.32, -1.07) * CFrame.Angles(math.rad(90), math.rad(-97.4), math.rad(90))
            AnimId = 'rbxassetid://14014278925'
            SndId = 'rbxassetid://4604390759'
        elseif N == 'heaven' then
            Offset = CFrame.new(-0.02, -0.82, 0.20) * CFrame.Angles(math.rad(64.42), math.rad(3.79), math.rad(0))
            AnimId = 'rbxassetid://14500266726'
            SndId = 'rbxassetid://14489860007'
        elseif N == 'lovekukri' then
            Offset = CFrame.new(-0.14, 0.14, -1.62) * CFrame.Angles(math.rad(-90), math.rad(180), math.rad(-4.97))
        elseif N == 'purpledagger' then
            Offset = CFrame.new(-0.13, -0.24, -1.80) * CFrame.Angles(math.rad(89.05), math.rad(96.63), math.rad(180))
            AnimId = 'rbxassetid://17824999722'
            SndId = 'rbxassetid://17822743153'
        elseif N == 'bluedagger' then
            Offset = CFrame.new(-0.13, -0.24, -1.80) * CFrame.Angles(math.rad(89.05), math.rad(96.63), math.rad(180))
            AnimId = 'rbxassetid://17824995184'
            SndId = 'rbxassetid://17822737046'
        elseif N == 'greendagger' then
            Offset = CFrame.new(-0.13, -0.24, -1.07) * CFrame.Angles(math.rad(89.05), math.rad(96.63), math.rad(180))
            AnimId = 'rbxassetid://17825004320'
            SndId = 'rbxassetid://17822741762'
        elseif N == 'reddagger' then
            Offset = CFrame.new(-0.13, -0.24, -1.07) * CFrame.Angles(math.rad(89.05), math.rad(96.63), math.rad(180))
            AnimId = 'rbxassetid://17825008844'
            SndId = 'rbxassetid://17822952417'
        elseif N == 'portal' then
            Offset = CFrame.new(0, -0.20, -1.2) * CFrame.Angles(math.rad(90), math.rad(263.7), math.rad(180))
            AnimId = 'rbxassetid://16058633881'
            SndId = 'rbxassetid://16058846352'
        elseif N == 'rgbdual' or N == 'rgbdualbayonets' then
            Offset = CFrame.new(0, -0.20, -1.2) * CFrame.Angles(math.rad(90), math.rad(263.7), math.rad(180))
            AnimId = 'rbxassetid://16769784949'
            SndId = nil
        elseif N == 'galactic' then
            Offset = CFrame.new(0, -0.20, -1.2) * CFrame.Angles(math.rad(90), math.rad(263.7), math.rad(180))
            AnimId = 'rbxassetid://8254762807'
            SndId = nil
        elseif N == 'world' then
            Offset = CFrame.new(0, -0.20, -1.2) * CFrame.Angles(math.rad(90), math.rad(263.7), math.rad(180))
            AnimId = 'rbxassetid://8254762807'
            SndId = nil
        elseif N == 'ribbon' then
            Offset = CFrame.new(0.02, -0.25, -0.05) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(180))
            AnimId = 'rbxassetid://124102609796063'
            SndId = 'rbxassetid://130974579277249'
        elseif N == 'emeraldbutterfly' then
            Offset = CFrame.new(-0.02, -0.30, -0.65) * CFrame.Angles(math.rad(180), math.rad(90.95), math.rad(180))
            AnimId = 'rbxassetid://14918231706'
            SndId = 'rbxassetid://14931902491'
        elseif N == 'boy' then
            Offset = CFrame.new(-0.02, -0.09, -0.73) * CFrame.Angles(math.rad(89.05), math.rad(-88.11), math.rad(180))
            AnimId = 'rbxassetid://18789158908'
            SndId = 'rbxassetid://18765078331'
        elseif N == 'girl' then
            Offset = CFrame.new(-0.02, -0.16, -0.73) * CFrame.Angles(math.rad(89.05), math.rad(-88.11), math.rad(180))
            AnimId = 'rbxassetid://18789162944'
            SndId = 'rbxassetid://18765078331'
        elseif N == 'dragon' then
            Offset = CFrame.new(-0.02, -0.32, -0.98) * CFrame.Angles(math.rad(89.05), math.rad(90.95), math.rad(180))
            AnimId = 'rbxassetid://14217804400'
            SndId = 'rbxassetid://14217789230'
        elseif N == 'void' then
            Offset = CFrame.new(-0.02, -0.22, -0.85) * CFrame.Angles(math.rad(180), math.rad(90.95), math.rad(180))
            AnimId = 'rbxassetid://14774699952'
            SndId = 'rbxassetid://14756591763'
        elseif N == 'wildwest' then
            Offset = CFrame.new(-0.02, -0.24, -1.15) * CFrame.Angles(math.rad(-91.89), math.rad(90.95), math.rad(180))
            AnimId = 'rbxassetid://16058148839'
            SndId = 'rbxassetid://16058689026'
        elseif N == 'icedout' then
            Offset = CFrame.new(0.02, -0.08, 0.99) * CFrame.Angles(math.rad(180), math.rad(-90.95), math.rad(-180))
            AnimId = 'rbxassetid://18465353361'
            SndId = 'rbxassetid://14924261405'
        elseif N == 'reptile' then
            Offset = CFrame.new(-0.03, -0.06, -0.92) * CFrame.Angles(math.rad(168.63), math.rad(90), math.rad(-180))
            AnimId = 'rbxassetid://18788955930'
            SndId = 'rbxassetid://18765103349'
        end

        if not Offset then return end

        if Clone:IsA('Model') then
            if not Clone.PrimaryPart then
                for _, C in next, Clone:GetChildren() do
                    if C:IsA('BasePart') then
                        Clone.PrimaryPart = C
                        break
                    end
                end
            end
            if Clone.PrimaryPart then
                for _, P in next, Clone:GetDescendants() do
                    if P:IsA('BasePart') then
                        P.CanCollide = false
                        P.Massless = true
                        P.Anchored = false
                        local W = Instance.new('Weld')
                        W.Part0 = HandleR
                        W.Part1 = P
                        W.C0 = Offset
                        W.C1 = P.CFrame:ToObjectSpace(Clone.PrimaryPart.CFrame)
                        W.Parent = P
                        table.insert(Data.welds, W)
                    end
                end
            end
            Clone.Parent = Mesh
        elseif Clone:IsA('BasePart') then
            Clone.CanCollide = false
            Clone.Massless = true
            Clone.Anchored = false
            Clone.Parent = Mesh
            local W = Instance.new('Weld')
            W.Part0 = HandleR
            W.Part1 = Clone
            W.C0 = Offset
            W.Parent = Clone
            table.insert(Data.welds, W)
        end

        Data.hiddenParts = HideKnifeDefaults(Tool, Clone)

        local Animator = Humanoid:FindFirstChildOfClass('Animator')
        if not Animator then
            Animator = Instance.new('Animator')
            Animator.Parent = Humanoid
        end
        if AnimId then
            local Anim = Instance.new('Animation')
            Anim.AnimationId = AnimId
            local Track = Animator:LoadAnimation(Anim)
            Track.Looped = false
            Track:Play()
            Data.track = Track
            Anim:Destroy()
            Track.Ended:Once(function()
                if Data.track == Track then
                    Data.track = nil
                end
                Track:Destroy()
            end)
        end
        if SndId then
            local Snd = Instance.new('Sound')
            Snd.SoundId = SndId
            Snd.Parent = Workspace
            Snd:Play()
            table.insert(Data.sounds, Snd)
            Snd.Ended:Connect(function()
                Snd:Destroy()
            end)
        end
    end

    local SkinModulesClone = nil
    local function LoadSkinData()
        if SkinData then return SkinData end
        if SkinModules and SkinModules:IsA('ModuleScript') then
            SkinModulesClone = SkinModules:Clone()
            local Success, Result = pcall(require, SkinModulesClone)
            if Success then SkinData = Result end
        end
        return SkinData
    end

    local function GetSkinInfo(WeaponName, SkinName)
        local Data = LoadSkinData()
        if not Data then return nil end
        local WeaponSkins = Data[WeaponName]
        if not WeaponSkins then
            local BracketName = '[' .. WeaponName:gsub('%[', ''):gsub('%]', '') .. ']'
            WeaponSkins = Data[BracketName]
        end
        if not WeaponSkins then return nil end
        local Info = WeaponSkins[SkinName]
        if not Info then
            Info = WeaponSkins[SkinName:gsub('-', ' ')]
        end
        if not Info then
            Info = WeaponSkins[SkinName:gsub('-', '')]
        end
        return Info
    end

    local function FindSourceMesh(SkinName, MeshRef, IsKnife)
        if not SkinModules then return nil end
        if IsKnife then
            local CleanSkin = SkinName:lower():gsub(' ', '')
            local KnivesFolder = SkinModules:FindFirstChild('Knives')
            if KnivesFolder then
                for _, Child in next, KnivesFolder:GetChildren() do
                    if Child:IsA('MeshPart') then
                        local CleanName = Child.Name:lower():gsub(' ', '')
                        if Child.Name == SkinName or CleanName == CleanSkin then
                            return Child
                        end
                    elseif Child:IsA('Folder') or Child:IsA('Model') then
                        local CleanName = Child.Name:lower():gsub(' ', '')
                        if Child.Name == SkinName or CleanName == CleanSkin then
                            for _, Sub in next, Child:GetChildren() do
                                if Sub:IsA('MeshPart') then
                                    return Sub
                                end
                            end
                        end
                    end
                end
            end
            if SkinAssets then
                local KnifeFolder = SkinAssets:FindFirstChild('KnifeMeshes') or SkinAssets:FindFirstChild('Knives')
                if KnifeFolder then
                    for _, Child in next, KnifeFolder:GetChildren() do
                        if Child:IsA('MeshPart') then
                            local CleanName = Child.Name:lower():gsub(' ', '')
                            if Child.Name == SkinName or CleanName == CleanSkin then
                                return Child
                            end
                        elseif Child:IsA('Folder') or Child:IsA('Model') then
                            local CleanName = Child.Name:lower():gsub(' ', '')
                            if Child.Name == SkinName or CleanName == CleanSkin then
                                for _, Sub in next, Child:GetChildren() do
                                    if Sub:IsA('MeshPart') then
                                        return Sub
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return nil
        end
        local MeshesFolder = SkinModules:FindFirstChild('Meshes')
        if not MeshesFolder then return nil end
        local FolderNames = { SkinName, SkinName:gsub(' ', ''), SkinName:gsub(' ', '_') }
        for _, FolderName in next, FolderNames do
            local SkinFolder = MeshesFolder:FindFirstChild(FolderName)
            if SkinFolder then
                if MeshRef then
                    local MeshAliases = {
                        ['[Silencer]'] = { electric = 'ElectricGlock', glock = 'ElectricGlock' },
                        ['[SilencerAR]'] = { electric = 'ElectricAR' },
                    }
                    local AliasKey = SkinName:lower():gsub('[^%w]', '')
                    local AliasName = MeshAliases[MeshRef] and MeshAliases[MeshRef][AliasKey]
                    if AliasName then
                        local AliasMesh = SkinFolder:FindFirstChild(AliasName)
                        if AliasMesh and AliasMesh:IsA('MeshPart') then
                            return AliasMesh
                        end
                    end
                    for _, Child in next, SkinFolder:GetChildren() do
                        if Child:IsA('MeshPart') then
                            local CleanChild = Child.Name:lower():gsub(' ', ''):gsub('-', '')
                            local CleanRef = MeshRef:lower():gsub(' ', ''):gsub('-', '')
                            if Child.Name == MeshRef or CleanChild == CleanRef then
                                return Child
                            end
                        end
                    end
                    return nil
                end
                for _, Child in next, SkinFolder:GetChildren() do
                    if Child:IsA('MeshPart') then
                        return Child
                    end
                end
            end
        end
        if SkinAssets then
            local GunMeshes = SkinAssets:FindFirstChild('GunMeshes')
            if GunMeshes then
                for _, FolderName in next, FolderNames do
                    local SkinFolder = GunMeshes:FindFirstChild(FolderName)
                    if SkinFolder then
                        for _, Child in next, SkinFolder:GetChildren() do
                            if Child:IsA('MeshPart') then
                                return Child
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local SkinCFrameFallbacks = {
        ['[Silencer]:Electric'] = CFrame.new(-0.00207519531, 0.0318723917, 0.0401077271, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        ['[Glock]:Electric'] = CFrame.new(-0.00207519531, 0.0318723917, 0.0401077271, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    }

    local function GetSkinCFrame(Tool, SkinName, SkinInfo)
        if SkinInfo and SkinInfo.CFrame and typeof(SkinInfo.CFrame) == 'CFrame' then
            return SkinInfo.CFrame
        end
        return SkinCFrameFallbacks[Tool.Name .. ':' .. SkinName] or CFrame.new()
    end

    local function HideOriginalGunMeshes(Tool, Default, SkinClone)
        local HiddenParts = { }
        local KeepVisible = { Muzzle = true, Aim = true }
        for _, Desc in next, Tool:GetDescendants() do
            if Desc:IsA('BasePart') then
                if SkinClone and (Desc == SkinClone or Desc:IsDescendantOf(SkinClone)) then
                    continue
                end
                if KeepVisible[Desc.Name] then
                    continue
                end
                if Desc == Default or Desc:IsDescendantOf(Default) then
                    HiddenParts[Desc] = Desc.Transparency
                    Desc.Transparency = 1
                end
            end
        end
        return HiddenParts
    end

    local function ApplyGunSkinMesh(Default, SkinMesh, SkinCFrame)
        local Clone = SkinMesh:Clone()
        Clone.Anchored = false
        Clone.CanCollide = false
        Clone.Name = '\0'
        Clone.CFrame = Default.CFrame
        local Weld = Instance.new('Weld')
        Weld.Part0 = Clone
        Weld.Part1 = Default
        Weld.C0 = SkinCFrame:Inverse()
        Weld.Name = '\0'
        Weld.Parent = Clone
        Default.Transparency = 1
        Clone.Parent = Default
        return Clone
    end

    local function ResolveSkinTextureMesh(SkinInfo, SkinName)
        if not SkinInfo or SkinInfo.TextureID == nil then
            return nil
        end
        local TextureValue = SkinInfo.TextureID
        if typeof(TextureValue) == 'Instance' and TextureValue:IsA('MeshPart') then
            return TextureValue
        end
        if not SkinModules then
            return nil
        end
        local MeshesFolder = SkinModules:FindFirstChild('Meshes')
        if not MeshesFolder then
            return nil
        end
        local SkinFolder = MeshesFolder:FindFirstChild(SkinName)
            or MeshesFolder:FindFirstChild(SkinName:gsub(' ', ''))
            or MeshesFolder:FindFirstChild(SkinName:gsub(' ', '_'))
            or MeshesFolder:FindFirstChild(SkinName:gsub('-', ' '))
            or MeshesFolder:FindFirstChild(SkinName:gsub('-', ''))
        if not SkinFolder then
            return nil
        end
        local MeshName = type(TextureValue) == 'string' and TextureValue or TextureValue.Name
        if MeshName and MeshName ~= '' then
            local NamedMesh = SkinFolder:FindFirstChild(MeshName)
            if NamedMesh and NamedMesh:IsA('MeshPart') then
                return NamedMesh
            end
        end
        return nil
    end

    local function GetShootSound(WeaponName, SkinName)
        if not SkinAssets then return nil end
        local GunShootSounds = SkinAssets:FindFirstChild('GunShootSounds')
        if not GunShootSounds then return nil end
        local WeaponFolder = GunShootSounds:FindFirstChild(WeaponName)
        if not WeaponFolder then return nil end
        local SoundValue = WeaponFolder:FindFirstChild(SkinName)
            or WeaponFolder:FindFirstChild(SkinName:gsub('-', ' '))
            or WeaponFolder:FindFirstChild(SkinName:gsub('-', ''))
        if SoundValue and SoundValue:IsA('StringValue') then
            return SoundValue.Value
        end
        return nil
    end

    local function ApplyGunHandleParticle(Tool, Handle, SkinName)
        if not SkinAssets or not Tool or not Handle then return end
        local Data = AppliedSkins[Tool]
        if not Data then return end
        local GunHandleParticle = SkinAssets:FindFirstChild('GunHandleParticle')
        if not GunHandleParticle then return end
        local ParticleFolder = GunHandleParticle:FindFirstChild(SkinName)
            or GunHandleParticle:FindFirstChild(SkinName:gsub('-', ' '))
            or GunHandleParticle:FindFirstChild(SkinName:gsub('-', ''))
        if not ParticleFolder then return end
        local Emitter = ParticleFolder:FindFirstChildOfClass('ParticleEmitter')
        if not Emitter then return end
        local ClonedParticle = Emitter:Clone()
        ClonedParticle.Parent = Handle
        ClonedParticle.Name = '\0'
        table.insert(Data.ClonedChildren, ClonedParticle)
    end

    local function RemoveSkinFromTool(Tool)
        if not Tool or not AppliedSkins[Tool] then return end
        CleanKnife(Tool)
        local Original = AppliedSkins[Tool]
        if Original.Connections then
            for _, Connection in next, Original.Connections do
                if Connection and Connection.Connected then
                    Connection:Disconnect()
                end
            end
        end
        for _, Child in next, Original.ClonedChildren or { } do
            if Child and Child.Parent then
                Child:Destroy()
            end
        end

        if Original.HiddenParts then
            for Part, Transparency in next, Original.HiddenParts do
                if Part and Part.Parent then
                    Part.Transparency = Transparency
                end
            end
        end
        if Original.Default and Original.Default.Parent then
            for _, Child in next, Original.Default:GetChildren() do
                if Child.Name == '\0' then
                    Child:Destroy()
                end
            end
            Original.Default.Transparency = Original.OriginalTransparency or 0
            Original.Default.LocalTransparencyModifier = Original.OriginalLTM or 0
            Original.Default.TextureID = Original.OriginalTextureID or ''
        end
        for _, Child in next, Tool:GetChildren() do
            if Child.Name == '\0' then
                Child:Destroy()
            end
        end
        if Original.OriginalGripCFrame then
            pcall(function() Tool.GripCFrame = Original.OriginalGripCFrame end)
        end
        if Original.ShootSound and Original.OriginalShootSoundId then
            Original.ShootSound.SoundId = Original.OriginalShootSoundId
        end
        local Handle = Tool:FindFirstChild('Handle')
        if Handle then
            Handle:SetAttribute('SkinName', Original.OriginalSkinName or '')
            for _, Child in next, Handle:GetChildren() do
                if Child.Name == '\0' then
                    Child:Destroy()
                end
            end
        end
        AppliedSkins[Tool] = nil
    end

    local function ApplySkinToTool(Tool, SkinName)
        if not Tool then return end
        if AppliedSkins[Tool] and AppliedSkins[Tool].SkinName == SkinName then return end
        local Handle = Tool:FindFirstChild('Handle')
        if not Handle then return end
        local Default = Tool:FindFirstChild('Default')
        if not Default or not Default:IsA('MeshPart') then
            Default = Handle:FindFirstChildOfClass('MeshPart')
            if not Default then
                for _, Child in next, Tool:GetDescendants() do
                    if Child:IsA('MeshPart') then
                        Default = Child
                        break
                    end
                end
            end
        end
        if not Default then
            local IsKnifeCheck = Tool.Name:lower():find('knife') ~= nil or Tool.Name == '[Knife]'
            if IsKnifeCheck then
                if AppliedSkins[Tool] then RemoveSkinFromTool(Tool) end
                local KnifeInfo = GetSkinInfo(Tool.Name, SkinName)
                local GcfOk, OrigGcf = pcall(function() return Tool.GripCFrame end)
                AppliedSkins[Tool] = {
                    SkinName = SkinName,
                    OriginalSkinName = Handle:GetAttribute('SkinName') or '',
                    OriginalGripCFrame = GcfOk and OrigGcf or CFrame.new(),
                    ClonedChildren = { },
                    Connections = { },
                }
                Handle:SetAttribute('SkinName', SkinName)
                local AttrConn = Handle:GetAttributeChangedSignal('SkinName'):Connect(function()
                    if Handle:GetAttribute('SkinName') ~= SkinName then
                        Handle:SetAttribute('SkinName', SkinName)
                    end
                end)
                table.insert(AppliedSkins[Tool].Connections, AttrConn)
                if KnifeInfo and KnifeInfo.CFrame and typeof(KnifeInfo.CFrame) == 'CFrame' then
                    pcall(function() Tool.GripCFrame = KnifeInfo.CFrame end)
                end
                return
            end
            return
        end
        local ShootSound = nil
        for _, Child in next, Tool:GetDescendants() do
            if Child:IsA('Sound') and (Child.Name == 'Shoot' or Child.Name == 'ShootSound') then
                ShootSound = Child
                break
            end
        end
        if AppliedSkins[Tool] then
            RemoveSkinFromTool(Tool)
        end
        AppliedSkins[Tool] = {
            SkinName = SkinName,
            OriginalTextureID = Default.TextureID,
            OriginalTransparency = Default.Transparency,
            OriginalSkinName = Handle:GetAttribute('SkinName') or '',
            Default = Default,
            ShootSound = ShootSound,
            OriginalShootSoundId = ShootSound and ShootSound.SoundId or nil,
            ClonedChildren = { },
            Connections = { },
            HiddenParts = { },
        }
        Handle:SetAttribute('SkinName', SkinName)
        local AttrConn = Handle:GetAttributeChangedSignal('SkinName'):Connect(function()
            if Handle:GetAttribute('SkinName') ~= SkinName then
                Handle:SetAttribute('SkinName', SkinName)
            end
        end)
        table.insert(AppliedSkins[Tool].Connections, AttrConn)
        local IsKnife = Tool.Name:lower():find('knife') ~= nil or Tool.Name == '[Knife]'
        local WeaponName = Tool.Name:lower():sub(2, -2)
        local SkinInfo = GetSkinInfo(Tool.Name, SkinName)
        local NewMesh = (not IsKnife) and ResolveSkinTextureMesh(SkinInfo, SkinName) or nil
        local Mesh = nil
        if IsKnife then
            if not IsKnifeSkin(SkinName) then
                Mesh = FindSourceMesh(SkinName, nil, true)
            end
        else
            if SkinModules then
                local MeshesFolder = SkinModules:FindFirstChild('Meshes')
                if MeshesFolder then
                    local SkinFolder = MeshesFolder:FindFirstChild(SkinName)
                        or MeshesFolder:FindFirstChild(SkinName:gsub(' ', ''))
                        or MeshesFolder:FindFirstChild(SkinName:gsub(' ', '_'))
                        or MeshesFolder:FindFirstChild(SkinName:gsub('-', ' '))
                        or MeshesFolder:FindFirstChild(SkinName:gsub('-', ''))
                    if SkinFolder then
                        if SkinFolder:IsA('MeshPart') then
                            Mesh = SkinFolder
                        else
                            Mesh = SkinFolder:GetChildren()
                        end
                    end
                end
                if not Mesh then
                    local GunModels = SkinModules:FindFirstChild('GunModels')
                    if GunModels then
                        local Model = GunModels:FindFirstChild(SkinName)
                        or GunModels:FindFirstChild('[' .. SkinName .. ']')
                        or GunModels:FindFirstChild(SkinName:gsub('-', ' '))
                        or GunModels:FindFirstChild(SkinName:gsub('-', ''))
                        if Model then
                            if Model:IsA('MeshPart') then
                                Mesh = Model
                            elseif Model:IsA('Model') then
                                Mesh = Model:FindFirstChildOfClass('MeshPart')
                            end
                        end
                    end
                end
            end
        end
        if not NewMesh and Mesh then
            if typeof(Mesh) == 'Instance' and Mesh:IsA('MeshPart') then
                NewMesh = Mesh
            elseif type(Mesh) == 'table' then
                for _, Child in next, Mesh do
                    if typeof(Child) == 'Instance' and Child:IsA('MeshPart') then
                        if Child.Name == Tool.Name then
                            NewMesh = Child
                            break
                        end
                        local Lowered = Child.Name:lower()
                        if Lowered:find('rpg') and WeaponName == 'rpg' then
                            NewMesh = Child; break
                        elseif Lowered:find('aug') and WeaponName == 'aug' then
                            NewMesh = Child; break
                        elseif Lowered:find('tac') and WeaponName == 'tacticalshotgun' then
                            NewMesh = Child; break
                        elseif Lowered:find('rev') and WeaponName == 'revolver' then
                            NewMesh = Child; break
                        elseif (Lowered:find('db') or Lowered:find('double')) and (WeaponName == 'double-barrel sg' or WeaponName == 'double-barrelsg') then
                            NewMesh = Child; break
                        elseif Lowered:find('knife') and IsKnife then
                            NewMesh = Child; break
                        elseif Lowered:find('rifle') and WeaponName == 'rifle' then
                            NewMesh = Child; break
                        elseif Lowered:find('flame') and WeaponName == 'flamethrower' then
                            NewMesh = Child; break
                        elseif Lowered:find('drum') and WeaponName == 'drumgun' then
                            NewMesh = Child; break
                        elseif Lowered:find('ak') and WeaponName == 'ak47' then
                            NewMesh = Child; break
                        elseif Lowered:find('smg') and WeaponName == 'smg' then
                            NewMesh = Child; break
                        elseif Lowered:find('lmg') and WeaponName == 'lmg' then
                            NewMesh = Child; break
                        elseif Lowered:find('p90') and WeaponName == 'p90' then
                            NewMesh = Child; break
                        elseif Lowered == 'ar' and WeaponName == 'ar' then
                            NewMesh = Child; break
                        elseif WeaponName == 'silencerar' and (Lowered:find('silencerar') or Lowered:find('silencedar')) then
                            NewMesh = Child; break
                        elseif WeaponName == 'silencer' and Lowered:find('silencer') and not Lowered:find('silencerar') and not Lowered:find('silencedar') then
                            NewMesh = Child; break
                        elseif WeaponName == 'silencer' and (Lowered:find('supp') or Lowered == 'sil') then
                            NewMesh = Child; break
                        elseif WeaponName == 'silencer' and Lowered:find('glock') then
                            NewMesh = Child; break
                        elseif Lowered:find('glock') and WeaponName == 'glock' then
                            NewMesh = Child; break
                        elseif Lowered:find('deagle') and WeaponName == 'deagle' then
                            NewMesh = Child; break
                        end
                    end
                end
                if not NewMesh then
                    NewMesh = FindSourceMesh(SkinName, Tool.Name, false)
                        or FindSourceMesh(SkinName, WeaponName, false)
                        or FindSourceMesh(SkinName, '[' .. WeaponName .. ']', false)
                end
                if not NewMesh then
                    local CleanWeapon = WeaponName:gsub('[^%w]', '')
                    local Matched = { }
                    for _, Child in next, Mesh do
                        if typeof(Child) == 'Instance' and Child:IsA('MeshPart') then
                            local CleanChild = Child.Name:lower():gsub('[^%w]', '')
                            if CleanChild == CleanWeapon or CleanChild:find(CleanWeapon, 1, true) then
                                table.insert(Matched, Child)
                            end
                        end
                    end
                    if #Matched == 1 then
                        NewMesh = Matched[1]
                    elseif #Matched > 1 then
                        NewMesh = Matched[1]
                    end
                end
            end
        end
        if not NewMesh and not IsKnife then
            NewMesh = FindSourceMesh(SkinName, Tool.Name, false)
                or FindSourceMesh(SkinName, WeaponName, false)
                or FindSourceMesh(SkinName, '[' .. WeaponName .. ']', false)
        end
        if NewMesh then
            local SkinCFrame = GetSkinCFrame(Tool, SkinName, SkinInfo)
            local NewFake = ApplyGunSkinMesh(Default, NewMesh, SkinCFrame)
            AppliedSkins[Tool].HiddenParts = HideOriginalGunMeshes(Tool, Default, NewFake)
            table.insert(AppliedSkins[Tool].ClonedChildren, NewFake)
        elseif SkinInfo and SkinInfo.TextureID then
            local TextureValue = SkinInfo.TextureID
            if typeof(TextureValue) == 'Instance' and TextureValue:IsA('MeshPart') then
                local SkinCFrame = GetSkinCFrame(Tool, SkinName, SkinInfo)
                local Clone = ApplyGunSkinMesh(Default, TextureValue, SkinCFrame)
                AppliedSkins[Tool].HiddenParts = HideOriginalGunMeshes(Tool, Default, Clone)
                table.insert(AppliedSkins[Tool].ClonedChildren, Clone)
            elseif type(TextureValue) == 'string' then
                AppliedSkins[Tool].HiddenParts = HideOriginalGunMeshes(Tool, Default, nil)
                Default.TextureID = TextureValue
                Default.Transparency = 0
            end
        else
            if not IsKnife then
                RemoveSkinFromTool(Tool)
                return
            end
            if IsKnifeSkin(SkinName) then
                return
            end
            AppliedSkins[Tool].OriginalLTM = Default.LocalTransparencyModifier
            Default.LocalTransparencyModifier = 1
            if SkinInfo and SkinInfo.CFrame and typeof(SkinInfo.CFrame) == 'CFrame' then
                local GcfOk, OrigGcf = pcall(function() return Tool.GripCFrame end)
                AppliedSkins[Tool].OriginalGripCFrame = GcfOk and OrigGcf or CFrame.new()
                pcall(function() Tool.GripCFrame = SkinInfo.CFrame end)
            end
        end
        for _, Child in next, Handle:GetChildren() do
            if #Child.Name == 0 then
                Child:Destroy()
            end
        end
        ApplyGunHandleParticle(Tool, Handle, SkinName)
        if IsKnife and SkinAssets then
            local SkinScripts = SkinAssets:FindFirstChild('SkinScripts')
            if SkinScripts then
                for _, Folder in next, SkinScripts:GetChildren() do
                    if Folder.Name:lower():gsub(' ', '') == SkinName:lower():gsub(' ', '') then
                        local Sound = Folder:FindFirstChildOfClass('Sound')
                        if Sound then
                            local Cloned = Sound:Clone()
                            Cloned.Name = '\0'
                            Cloned.Parent = Handle
                            Cloned:Play()
                            game.Debris:AddItem(Cloned, 3)
                        end
                        for _, Obj in next, Folder:GetDescendants() do
                            if Obj:IsA('Sound') or Obj:IsA('StringValue') then
                                local ObjLower = Obj.Name:lower():gsub(' ', '')
                                local Val = Obj:IsA('Sound') and Obj.SoundId or Obj.Value
                                if not Val or Val == '' then continue end
                                if ObjLower == 'equipsfx' or ObjLower == 'sfx' or ObjLower == 'equip' or ObjLower == 'tantoequip' then
                                    AppliedSkins[Tool].KnifeEquipSound = Val
                                elseif ObjLower == 'attacksfx' or ObjLower == 'attack' then
                                    AppliedSkins[Tool].KnifeAttackSound = Val
                                end
                            end
                        end
                        break
                    end
                end
            end
            local SkinScriptsStorage = SkinAssets:FindFirstChild('SkinScriptsStorage')
            if SkinScriptsStorage then
                for _, Folder in next, SkinScriptsStorage:GetChildren() do
                    if Folder.Name:lower():gsub(' ', '') == SkinName:lower():gsub(' ', '') then
                        for _, Anim in next, Folder:GetDescendants() do
                            if Anim:IsA('Animation') then
                                local AnimLower = Anim.Name:lower():gsub(' ', '')
                                if AnimLower == 'knife' or AnimLower == 'equipknife' or AnimLower == 'knifeequip' or AnimLower == 'tantoequip' then
                                    AppliedSkins[Tool].KnifeEquipAnim = Anim
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
            local KnifeSkinAnimation = SkinAssets:FindFirstChild('KnifeSkinAnimation')
            if KnifeSkinAnimation then
                for _, Folder in next, KnifeSkinAnimation:GetChildren() do
                    if Folder.Name:lower():gsub(' ', '') == SkinName:lower():gsub(' ', '') then
                        for _, Anim in next, Folder:GetDescendants() do
                            if Anim:IsA('Animation') then
                                AppliedSkins[Tool].KnifeAttackAnim = Anim
                                break
                            end
                        end
                        break
                    end
                end
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'goldenagetanto' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://13473404819'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://13473404819'
            end
        end
        if IsKnife and (SkinName:lower():gsub(' ', '') == 'gpoknife' or SkinName:lower():gsub(' ', '') == 'gpoknifeprestige') then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://102007904524177'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://102007904524177'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'portal' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://16058633881'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://16058633881'
            end
        end
        if IsKnife and (SkinName:lower():gsub(' ', '') == 'rgbdual' or SkinName:lower():gsub(' ', '') == 'rgbdualbayonets') then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://16769825152'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://16769825152'
            end
        end
        if IsKnife and (SkinName:lower():gsub(' ', '') == 'galactic' or SkinName:lower():gsub(' ', '') == 'world') then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://8254762807'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://8254762807'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'ribbon' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://124102609796063'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://124102609796063'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'emeraldbutterfly' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://14918231706'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://14918231706'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'boy' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://18789158908'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://18789158908'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'girl' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://18789162944'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://18789162944'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'dragon' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://14217804400'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://14217804400'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'void' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://14774699952'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://14774699952'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'wildwest' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://16058148839'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://16058148839'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'icedout' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://18465353361'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://18465353361'
            end
        end
        if IsKnife and SkinName:lower():gsub(' ', '') == 'reptile' then
            if not AppliedSkins[Tool].KnifeEquipAnim then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = 'rbxassetid://18788955930'
                AppliedSkins[Tool].KnifeEquipAnim = Anim
            else
                AppliedSkins[Tool].KnifeEquipAnim.AnimationId = 'rbxassetid://18788955930'
            end
        end
        local SoundId = GetShootSound(Tool.Name, SkinName)
        if SoundId and AppliedSkins[Tool].ShootSound then
            AppliedSkins[Tool].ShootSound.SoundId = SoundId
        end
    end

    local function GetDesiredSkin(Tool)
        local SkinChangerCfg = GetSkinChangerCfg()
        if not SkinChangerCfg or not SkinChangerCfg['Enabled'] then return nil end
        local Skins = SkinChangerCfg['Skins']
        if not Skins then return nil end
        local ConfiguredSkin = Skins[Tool.Name]
        if not ConfiguredSkin then
            local Stripped = Tool.Name:gsub('%[', ''):gsub('%]', '')
            ConfiguredSkin = Skins['[' .. Stripped .. ']']
        end
        if not ConfiguredSkin or ConfiguredSkin == '' or ConfiguredSkin == 'None' or ConfiguredSkin == 'Default' then return nil end
        return ConfiguredSkin
    end

    local function ProcessTool(Tool)
        local DesiredSkin = GetDesiredSkin(Tool)
        local CurrentApplied = AppliedSkins[Tool]
        local CurrentSkin = CurrentApplied and CurrentApplied.SkinName or nil

        if CurrentSkin == DesiredSkin then return end

        if CurrentApplied then
            RemoveSkinFromTool(Tool)
        end

        if not DesiredSkin then
            ToolRegistry[Tool] = nil
            return
        end

        ToolRegistry[Tool] = DesiredSkin
        local IsKnife = Tool.Name:lower():find('knife') ~= nil or Tool.Name == '[Knife]'
        if IsKnife and IsKnifeSkin(DesiredSkin) then
            if AppliedSkins[Tool] then
                RemoveSkinFromTool(Tool)
            end
            local Handle = Tool:FindFirstChild('Handle')
            if not Handle then return end
            AppliedSkins[Tool] = {
                SkinName = DesiredSkin,
                OriginalSkinName = Handle:GetAttribute('SkinName') or '',
                ClonedChildren = { },
                Connections = { },
            }
            Handle:SetAttribute('SkinName', DesiredSkin)
            local AttrConn = Handle:GetAttributeChangedSignal('SkinName'):Connect(function()
                if Handle:GetAttribute('SkinName') ~= DesiredSkin then
                    Handle:SetAttribute('SkinName', DesiredSkin)
                end
            end)
            table.insert(AppliedSkins[Tool].Connections, AttrConn)
            ApplyGunHandleParticle(Tool, Handle, DesiredSkin)
            if not KnifeData[Tool] or not KnifeData[Tool].hiddenParts then
                KnifeData[Tool] = KnifeData[Tool] or { }
                KnifeData[Tool].hiddenParts = HideKnifeDefaults(Tool, nil)
            end
            local EquipConn
            EquipConn = Tool.Equipped:Connect(function()
                if not AppliedSkins[Tool] then
                    if EquipConn then EquipConn:Disconnect() end
                    return
                end
                local Char = Tool.Parent
                if Char ~= LocalPlayer.Character then return end
                ApplyKnife(Char, Tool, DesiredSkin)
            end)
            if not AppliedSkins[Tool].Connections then
                AppliedSkins[Tool].Connections = { }
            end
            table.insert(AppliedSkins[Tool].Connections, EquipConn)
            if LocalPlayer.Character and Tool.Parent == LocalPlayer.Character then
                ApplyKnife(LocalPlayer.Character, Tool, DesiredSkin)
            end
            if AppliedSkins[Tool] and (AppliedSkins[Tool].KnifeAttackAnim or AppliedSkins[Tool].KnifeAttackSound) then
                local AttackConn
                AttackConn = Tool.Activated:Connect(function()
                    local SkinData = AppliedSkins[Tool]
                    if not SkinData then
                        if AttackConn then AttackConn:Disconnect() end
                        return
                    end
                    if SkinData.KnifeAttackSound then
                        local Sound = Instance.new('Sound')
                        Sound.SoundId = SkinData.KnifeAttackSound
                        Sound.Volume = 1
                        Sound.Parent = Tool:FindFirstChild('Handle') or Tool
                        Sound:Play()
                        game.Debris:AddItem(Sound, 3)
                    end
                    if SkinData.KnifeAttackAnim then
                        local Character = LocalPlayer.Character
                        if Character then
                            local Humanoid = Character:FindFirstChildOfClass('Humanoid')
                            if Humanoid then
                                local Animator = Humanoid:FindFirstChildOfClass('Animator')
                                if not Animator then
                                    Animator = Instance.new('Animator')
                                    Animator.Parent = Humanoid
                                end
                                local Anim = Instance.new('Animation')
                                Anim.AnimationId = SkinData.KnifeAttackAnim.AnimationId
                                local Track = Animator:LoadAnimation(Anim)
                                Track.Priority = Enum.AnimationPriority.Action
                                Track:Play()
                                Anim:Destroy()
                            end
                        end
                    end
                end)
                table.insert(AppliedSkins[Tool].Connections, AttackConn)
            end
        else
            ApplySkinToTool(Tool, DesiredSkin)
            if not AppliedSkins[Tool] then return end
            local EquipConn
            EquipConn = Tool.Equipped:Connect(function()
                if not AppliedSkins[Tool] then
                    if EquipConn then EquipConn:Disconnect() end
                    return
                end
                local Char = Tool.Parent
                if Char ~= LocalPlayer.Character then return end
                ApplySkinToTool(Tool, DesiredSkin)
            end)
            if not AppliedSkins[Tool].Connections then
                AppliedSkins[Tool].Connections = { }
            end
            table.insert(AppliedSkins[Tool].Connections, EquipConn)
            if LocalPlayer.Character and Tool.Parent == LocalPlayer.Character then
                ApplySkinToTool(Tool, DesiredSkin)
            end
        end
    end

    local function ProcessCharacter(Character)
        if not Character then return end
        for _, Child in next, Character:GetChildren() do
            if Child:IsA('Tool') then
                ProcessTool(Child)
            end
        end
        state.skinChangerToolConnection = Character.ChildAdded:Connect(function(Child)
            if Child:IsA('Tool') then
                ProcessTool(Child)
            end
        end)
    end

    local function ProcessBackpack(Backpack)
        if not Backpack then return end
        for _, Tool in next, Backpack:GetChildren() do
            if Tool:IsA('Tool') then
                ProcessTool(Tool)
            end
        end
        state.skinChangerBackpackConnection = Backpack.ChildAdded:Connect(function(Tool)
            if Tool:IsA('Tool') then
                ProcessTool(Tool)
            end
        end)
    end

    LoadSkinData()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Backpack = LocalPlayer:WaitForChild('Backpack', 5)
    ProcessCharacter(Character)
    if Backpack then ProcessBackpack(Backpack) end
    state.skinChangerCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
        ProcessCharacter(NewCharacter)
        local NewBackpack = LocalPlayer:WaitForChild('Backpack', 5)
        if NewBackpack then ProcessBackpack(NewBackpack) end
    end)

    local function RescanAllTools()
        local Char = LocalPlayer.Character
        if Char then
            for _, Child in next, Char:GetChildren() do
                if Child:IsA('Tool') then ProcessTool(Child) end
            end
        end
        local Bp = LocalPlayer:FindFirstChildOfClass('Backpack')
        if Bp then
            for _, Child in next, Bp:GetChildren() do
                if Child:IsA('Tool') then ProcessTool(Child) end
            end
        end
        for Tool in next, ToolRegistry do
            if not Tool.Parent then
                ToolRegistry[Tool] = nil
            end
        end
    end

    local LastSkinCfgSnapshot = ''
    local skinCheckCounter = 0
    state.heartbeatConnection = RunService.Heartbeat:Connect(function()
        if state.cleanupActive then return end
        skinCheckCounter = skinCheckCounter + 1
        if skinCheckCounter % 60 ~= 0 then return end
        local SkinCfg = GetSkinChangerCfg()
        local Snapshot = tostring(SkinCfg['Enabled'])
        local Skins = SkinCfg['Skins']
        if Skins then
            for K, V in next, Skins do
                Snapshot = Snapshot .. K .. tostring(V)
            end
        end
        if Snapshot ~= LastSkinCfgSnapshot then
            LastSkinCfgSnapshot = Snapshot
            RescanAllTools()
        end
    end)
end

local function getFOVValue(style, methodData)
    if style == "Basic" then
        return methodData["Basic"]
    elseif style == "Advanced" then
        return methodData["Advanced"]
    end
    return nil
end

local function parseFOVConfig(mode, fovType)
    local Settings = shared.Illusion
    if not Settings then return nil end
    
    local fovOps = Settings["Field Of View Operations"]
    if not fovOps then return nil end
    
    local fovData = fovOps[fovType]
    if not fovData then return nil end
    
    local modeCfg = nil
    if mode == "Trigger" or mode == "Trigger Bot" then
        modeCfg = fovOps["Trigger Bot"]
    elseif mode == "Silent" or mode == "Silent Aimbot" then
        modeCfg = Settings["Silent Aimbot"]
    elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
        modeCfg = Settings["Camera Aimbot"]
    end
    
    if not modeCfg then return nil end
    
    local style = modeCfg["Field Of View Style"] or "Basic"
    local method = modeCfg["Field Of View Method"] or "2D"
    
    if method ~= fovType then return nil end
    
    local fovValues = getFOVValue(style, fovData)
    if not fovValues then return nil end
    
    return {
        values = fovValues,
        style = style,
        method = method
    }
end

local function getScaledFOV(mode, fovType, screenPos, rootPart)
    local config = parseFOVConfig(mode, fovType)
    if not config then return nil end
    
    local values = config.values
    if not values then return nil end
    
    if fovType == "2D" then
        local fovData = values
        local left, right, upper, lower
        
        if config.style == "Basic" then
            local basic = values[1]
            if basic and #basic >= 2 then
                left = basic[2] or 236
                right = basic[2] or 236
                upper = basic[2] or 236
                lower = basic[2] or 236
                local scale = basic[1] or 0.124
                local ViewportY = Camera.ViewportSize.Y
                local CamFOV = Camera.FieldOfView
                local sizeScale = (rootPart.Size.Y * ViewportY) / (screenPos.Z * 2) * 100 / CamFOV
                left = left * sizeScale * scale
                right = right * sizeScale * scale
                upper = upper * sizeScale * scale
                lower = lower * sizeScale * scale
            else
                return nil
            end
        elseif config.style == "Advanced" then
            local xData = values["X"]
            local yData = values["Y"]
            if xData and yData and xData[1] and yData[1] then
                left = xData[1][2] or 0.3
                right = xData[1][2] or 0.3
                upper = yData[1][2] or 0.3
                lower = yData[1][2] or 0.3
                local xScale = xData[1][1] or 0.2
                local yScale = yData[1][1] or 0.2
                local ViewportY = Camera.ViewportSize.Y
                local CamFOV = Camera.FieldOfView
                local sizeScale = (rootPart.Size.Y * ViewportY) / (screenPos.Z * 2) * 100 / CamFOV
                left = left * sizeScale * xScale
                right = right * sizeScale * xScale
                upper = upper * sizeScale * yScale
                lower = lower * sizeScale * yScale
            else
                return nil
            end
        else
            return nil
        end
        
        return { left = left, right = right, upper = upper, lower = lower }
    elseif fovType == "3D" then
        if config.style == "Basic" then
            local basic = values[1]
            if basic and #basic >= 3 then
                return { x = basic[2] or 236, y = basic[2] or 236, z = basic[3] or 0.5 }
            end
        elseif config.style == "Advanced" then
            local xData = values["X"]
            local yData = values["Y"]
            local zData = values["Z"]
            if xData and yData and zData and xData[1] and yData[1] and zData[1] then
                return { x = xData[1][2] or 0.3, y = yData[1][2] or 0.3, z = zData[1][2] or 0.4 }
            end
        end
        return nil
    end
    
    return nil
end

local function isIn2DFOV(screenPos, mousePos, fovConfig)
    if not fovConfig then return true end
    local deltaX = screenPos.X - mousePos.X
    local deltaY = screenPos.Y - mousePos.Y
    return math.abs(deltaX) <= fovConfig.left and math.abs(deltaY) <= fovConfig.upper
end

local function partInFOV3D(part, fovConfig)
    if not fovConfig then return true end
    if not part or not part.Parent then return false end

    local char = part.Parent
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local fovSize = hrp.Size + Vector3.new(fovConfig.x * 2, fovConfig.y * 2, fovConfig.z * 2)
    local fovCF = hrp.CFrame

    local mousePos = UserInputService:GetMouseLocation()
    if not mousePos then return false end
    
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    if not ray then return false end

    local cf = fovCF
    local size = fovSize / 2

    local localOrigin = cf:PointToObjectSpace(ray.Origin)
    local localDir = cf:VectorToObjectSpace(ray.Direction * 1000)

    local tmin, tmax = -math.huge, math.huge

    for _, axis in ipairs({"X", "Y", "Z"}) do
        local o = localOrigin[axis]
        local d = localDir[axis]
        local s = size[axis]

        if math.abs(d) < 1e-8 then
            if o < -s or o > s then return false end
        else
            local t1 = (-s - o) / d
            local t2 = ( s - o) / d
            if t1 > t2 then t1, t2 = t2, t1 end
            tmin = math.max(tmin, t1)
            tmax = math.min(tmax, t2)
            if tmin > tmax then return false end
        end
    end

    return tmax > 0
end

local function isInPreciseFOV(targetChar)
    if not targetChar then return false end
    
    local mousePos = UserInputService:GetMouseLocation()
    if not mousePos then return false end
    
    local cam = Camera
    local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
    if not ray then return false end
    
    local parts = {}
    for _, name in pairs(PARTS) do
        local part = targetChar:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    
    if #parts == 0 then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Whitelist
    rayParams.FilterDescendantsInstances = parts
    rayParams.IgnoreWater = true
    
    local range = 1000
    local result = Workspace:Raycast(ray.Origin, ray.Direction * range, rayParams)
    
    if result then
        local hitPart = result.Instance
        if hitPart and hitPart:IsDescendantOf(targetChar) then
            return true
        end
    end
    
    return false
end

local function getDynamicDensity(distance)
    if distance < 15 then return 8
    elseif distance < 30 then return 7
    elseif distance < 50 then return 6
    elseif distance < 80 then return 5
    elseif distance < 120 then return 4
    elseif distance < 200 then return 3
    else return 2 end
end

local function getCachedHitboxPoints(character)
    if not character then return nil end
    local key = tostring(character)
    local currentTime = tick()
    
    local cacheEntry = hitboxCache[key]
    if cacheEntry and currentTime - cacheEntry.timestamp < CACHE_LIFETIME then
        return cacheEntry.points, cacheEntry.density
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local density = getDynamicDensity(distance)
    
    local points = {}
    local partList = {}
    
    for _, name in pairs(PARTS) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(partList, part)
        end
    end
    
    if #partList == 0 then return nil end
    
    local step = 1 / (density - 1)
    local pointLimit = 3000
    local totalPoints = #partList * density * density * density
    
    if totalPoints > pointLimit then
        density = math.max(2, math.floor((pointLimit / #partList) ^ (1/3)))
        step = 1 / (density - 1)
    end
    
    for _, part in pairs(partList) do
        local size = part.Size
        local half = size * 0.5
        local cframe = part.CFrame
        
        for z = 0, density - 1 do
            local zOff = -half.Z + z * step * size.Z
            for y = 0, density - 1 do
                local yOff = -half.Y + y * step * size.Y
                for x = 0, density - 1 do
                    local xOff = -half.X + x * step * size.X
                    local worldPos = cframe:PointToWorldSpace(Vector3.new(xOff, yOff, zOff))
                    table.insert(points, worldPos)
                end
            end
        end
    end
    
    if #points > pointLimit then
        local sampled = {}
        local stride = math.max(1, math.floor(#points / pointLimit))
        for i = 1, #points, stride do
            table.insert(sampled, points[i])
        end
        points = sampled
    end
    
    if #hitboxCache > MAX_CACHE_ENTRIES then
        local oldest = nil
        local oldestTime = currentTime
        for k, v in pairs(hitboxCache) do
            if v.timestamp < oldestTime then
                oldestTime = v.timestamp
                oldest = k
            end
        end
        if oldest then hitboxCache[oldest] = nil end
    end
    
    hitboxCache[key] = {
        points = points,
        timestamp = currentTime,
        density = density,
        distance = distance
    }
    
    return points, density
end

local function clearHitboxCache()
    local currentTime = tick()
    for key, data in pairs(hitboxCache) do
        if currentTime - data.timestamp > CACHE_LIFETIME * 4 then
            hitboxCache[key] = nil
        end
    end
end

if LRM_INIT_SCRIPT then
    LRM_INIT_SCRIPT(function()
        script_key = shared.Saved.Auth.Key
    end)
end

local function IsSameCrew(Player)
    local LocalCrew = LocalPlayer:GetAttribute("CrewName")
    local TargetCrew = Player:GetAttribute("CrewName")
    return LocalCrew and TargetCrew and LocalCrew == TargetCrew
end

local function IsTargetDead(Player)
    if not Player then return true end
    local Character = Player.Character
    if not Character then return true end
    if not Character.Parent then return true end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return true end
    if Humanoid.Health <= 0 then return true end
    local Head = Character:FindFirstChild("Head")
    if not Head then return true end
    if not Head.Parent then return true end
    return false
end

local function IsPlayerKnocked(Player)
    if not Player.Character then return false end
    local BodyEffects = Player.Character:FindFirstChild("BodyEffects")
    if BodyEffects then
        local KO = BodyEffects:FindFirstChild("K.O")
        local Knocked = BodyEffects:FindFirstChild("Knocked")
        return (KO and KO.Value == true) or (Knocked and Knocked.Value == true)
    end
    return false
end

local function IsLocalPlayerKnocked()
    if not LocalPlayer.Character then return false end
    local BodyEffects = LocalPlayer.Character:FindFirstChild("BodyEffects")
    if BodyEffects then
        local KO = BodyEffects:FindFirstChild("K.O")
        local Knocked = BodyEffects:FindFirstChild("Knocked")
        return (KO and KO.Value == true) or (Knocked and Knocked.Value == true)
    end
    return false
end

local function HasForcefieldOrInvis(Player)
    if not Player.Character then return false end
    local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid:GetAttribute("Invisibility") == true then
        return true
    end
    if Player.Character:FindFirstChild("ForceField") then
        return true
    end
    return false
end

local function HasForceField(Player)
    if not Player or not Player.Character then return false end
    if Player.Character:FindFirstChild("ForceField") or Player.Character:FindFirstChildOfClass("ForceField") then
        return true
    end
    return false
end

local function IsInVehicle(Player)
    local Character = Player and Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    return Humanoid and Humanoid.Sit or false
end

local function IsTargetVisible(TargetPart)
    if not TargetPart or not TargetPart.Parent then return false end
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Blacklist
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, TargetPart.Parent}
    RayParams.IgnoreWater = true
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Hit = Workspace:Raycast(Origin, Direction, RayParams)
    if Hit then
        if Hit.Instance:IsDescendantOf(TargetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

local function getChecksForMode(mode)
    local Config = shared.Illusion
    if not Config then return nil end
    
    local checks = Config["Aimbot Condition Checks"]
    if not checks then return nil end
    
    local modeKey = mode
    if mode == "Silent" or mode == "Silent Aimbot" then
        modeKey = "Silent Aimbot"
    elseif mode == "Trigger" or mode == "Trigger Bot" then
        modeKey = "Trigger Bot"
    elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
        modeKey = "Camera Aimbot"
    elseif mode == "Hitbox Expander" then
        modeKey = "Hitbox Expander"
    end
    
    local checkList = checks[modeKey]
    if not checkList then return {} end
    
    local result = {}
    if #checkList > 0 and type(checkList[1]) == "table" then
        for _, item in ipairs(checkList[1]) do
            if type(item) == "string" then
                local clean = item:gsub("%[", ""):gsub("%]", "")
                result[clean] = true
            end
        end
    end
    
    return result
end

local function CheckChecks(Player, mode)
    local checks = getChecksForMode(mode)
    if not checks then return true end
    
    if IsTargetDead(Player) then return false end
    
    if checks["Knocked"] and IsPlayerKnocked(Player) then return false end
    if checks["Self Knocked"] and IsLocalPlayerKnocked() then return false end
    if checks["Crew Check"] and IsSameCrew(Player) then return false end
    if checks["Grabbed"] then
        local char = Player.Character
        if char and char:FindFirstChild("Grabbed") then return false end
    end
    if checks["Visible"] then
        local Head = Player.Character and Player.Character:FindFirstChild("Head")
        if Head then
            if not IsTargetVisible(Head) then return false end
        else
            return false
        end
    end
    
    return true
end

local function CheckChecksNoVisible(Player, mode)
    local checks = getChecksForMode(mode)
    if not checks then return true end
    
    if IsTargetDead(Player) then return false end
    
    if checks["Knocked"] and IsPlayerKnocked(Player) then return false end
    if checks["Self Knocked"] and IsLocalPlayerKnocked() then return false end
    if checks["Crew Check"] and IsSameCrew(Player) then return false end
    if checks["Grabbed"] then
        local char = Player.Character
        if char and char:FindFirstChild("Grabbed") then return false end
    end
    
    return true
end

local function IsPlayerValid(Player, mode)
    if not Player or Player == LocalPlayer then return false end
    if not Player.Character then return false end
    local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end
    if not Player.Character:FindFirstChild("Head") then return false end
    return CheckChecksNoVisible(Player, mode)
end

local function GetKeybind(mode)
    local Config = shared.Illusion
    if not Config then return nil end
    
    local keybindOS = Config["Keybind Operating Systems"]
    if not keybindOS then return nil end
    
    local universal = keybindOS["Universal Keybind"]
    if not universal then return nil end
    
    if mode then
        local separate = universal["Separate"]
        if separate and separate["Enabled"] then
            if mode == "Trigger" or mode == "Trigger Bot" then
                return separate["Trigger Bot"]
            elseif mode == "Silent" or mode == "Silent Aimbot" then
                return separate["Silent Aimbot"]
            elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
                return separate["Camera Aimbot"]
            elseif mode == "Hitbox Expander" then
                return separate["Hitbox Expander"]
            end
        end
    end
    
    return universal["Keybind"]
end

local function GetSelectingDistance(mode)
    local Config = shared.Illusion
    if not Config then return 0 end
    
    local distCfg = Config["Aimbot Selecting Distance"]
    if not distCfg then return 0 end
    
    local modeKey = mode
    if mode == "Trigger" or mode == "Trigger Bot" then
        modeKey = "Trigger Bot"
    elseif mode == "Silent" or mode == "Silent Aimbot" then
        modeKey = "Silent Aimbot"
    elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
        modeKey = "Camera Aimbot"
    end
    
    return distCfg[modeKey] or 1000
end

local function GetTriggerCooldownForWeapon(weaponName)
    local Config = shared.Illusion
    if not Config then return 0.001 end
    local CooldownCfg = Config["Click Cooldown"] or {}
    
    for Key, Value in pairs(CooldownCfg) do
        if Key == weaponName then return Value end
    end
    
    return 0.001
end

local function IsSilentHitpartClosestPoint()
    local Config = shared.Illusion
    if not Config then return false end
    local silentCfg = Config["Silent Aimbot"]
    if not silentCfg then return false end
    local targetZone = silentCfg["Silent Aimbot Target Zone"] or "Closest"
    local closestMode = silentCfg["Closest Configuration"] and silentCfg["Closest Configuration"]["Closest Mode"] or "Point"
    return targetZone == "Closest" or closestMode == "Point"
end

local function getClosestPoint(character)
    if not (character and character.Parent) then return nil end
    
    local mousePos = UserInputService:GetMouseLocation()
    local mouseX, mouseY = mousePos.X, mousePos.Y
    local cam = Camera
    
    local ray = cam:ViewportPointToRay(mouseX, mouseY)
    if not ray then return nil end

    local Config = shared.Illusion
    local silentCfg = Config and Config["Silent Aimbot"]
    local cfg = silentCfg and silentCfg["Closest Configuration"]
    if not cfg then return nil end

    local scale = cfg["Point Scale"] or 0.3
    local density = math.clamp(math.floor(scale * 20), 2, 12)

    local allParts = {}
    for _, name in pairs(PARTS) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(allParts, part)
        end
    end

    if #allParts == 0 then return nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Whitelist
    rayParams.FilterDescendantsInstances = allParts
    rayParams.IgnoreWater = true
    
    local directHit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
    if directHit then
        return { Part = directHit.Instance, Position = directHit.Position }
    end

    local bestDist = 1e9
    local bestResult = nil
    local STEP = 1 / (density - 1)
    local STEP_OFFSETS = {}
    for j = 0, density - 1 do STEP_OFFSETS[j + 1] = j * STEP end

    for _, part in pairs(allParts) do
        local size = part.Size
        local half = size * 0.5
        local cframe = part.CFrame

        for z = 1, density do
            local clampedZ = -half.Z + STEP_OFFSETS[z] * size.Z
            for y = 1, density do
                local clampedY = -half.Y + STEP_OFFSETS[y] * size.Y
                for x = 1, density do
                    local clampedX = -half.X + STEP_OFFSETS[x] * size.X
                    local worldPos = cframe:PointToWorldSpace(Vector3.new(clampedX, clampedY, clampedZ))
                    
                    local s = cam:WorldToViewportPoint(worldPos)
                    if s.Z > 0 then
                        local dist = (s.X - mouseX) * (s.X - mouseX) + (s.Y - mouseY) * (s.Y - mouseY)
                        if dist < bestDist then
                            bestDist = dist
                            bestResult = { Part = part, Position = worldPos }
                        end
                    end
                end
            end
        end
    end
    
    if bestResult then return bestResult end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root then return { Part = root, Position = root.Position } end
    
    return nil
end

local function IsLeftControlHeld()
    return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
end

local function ClearTargetsForPlayer(Player)
    if State.Targets.Silent == Player then
        State.Targets.Silent = nil
        State.SilentTargetLocked = false
        state.lastValidTarget = nil
    end
    if State.Targets.Trigger == Player then
        State.Targets.Trigger = nil
        State.TriggerTargetLocked = false
        state.triggerLastValidTarget = nil
        state.triggerFOVActive = false
        if TriggerFOVBox then
            TriggerFOVBox.Visible = false
        end
        if Trigger3DFOVPart then
            Trigger3DFOVPart.Transparency = 1
        end
    end
    if State.Targets.Camera == Player then
        State.Targets.Camera = nil
        State.CameraTargetLocked = false
        state.cameraLastValidTarget = nil
        state.cameraFOVActive = false
        state.cameraEasingProgress = 0
        state.cameraLastTarget = nil
        state.cameraShakeTime = 0
        if CameraFOVBox then
            CameraFOVBox.Visible = false
        end
        if Camera3DFOVPart then
            Camera3DFOVPart.Transparency = 1
        end
    end
    if state.sharedTarget == Player then
        state.sharedTarget = nil
        state.sharedTargetLocked = false
    end
end

local function SetupPlayerDeathHandler(Player)
    if not Player then return end
    
    local Character = Player.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid.Died:Connect(function()
            ClearTargetsForPlayer(Player)
        end)
    end
    
    local BodyEffects = Character:FindFirstChild("BodyEffects")
    if BodyEffects then
        local KO = BodyEffects:FindFirstChild("K.O")
        if KO then
            KO:GetPropertyChangedSignal("Value"):Connect(function()
                if KO.Value == true then
                    ClearTargetsForPlayer(Player)
                end
            end)
        end
    end
end

state.deathHandlerPlayerAdded = Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        Player.CharacterAdded:Connect(function(Char)
            SetupPlayerDeathHandler(Player)
        end)
        if Player.Character then
            SetupPlayerDeathHandler(Player)
        end
    end
end)

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        if Player.Character then
            SetupPlayerDeathHandler(Player)
        end
    end
end

local function ValidateTarget(mode)
    if mode == "Silent" or mode == "Silent Aimbot" then
        if not State.SilentTargetLocked then return end
        
        local Target = State.Targets.Silent
        
        if Target then
            if not CheckChecksNoVisible(Target, "Silent") then
                State.Targets.Silent = nil
                State.SilentTargetLocked = false
                state.lastValidTarget = nil
                return
            end
            if CheckChecks(Target, "Silent") then
                state.lastValidTarget = nil
                return
            else
                state.lastValidTarget = Target
                State.Targets.Silent = nil
                return
            end
        end
        
        if state.lastValidTarget then
            if CheckChecksNoVisible(state.lastValidTarget, "Silent") and CheckChecks(state.lastValidTarget, "Silent") then
                State.Targets.Silent = state.lastValidTarget
                state.lastValidTarget = nil
            elseif not CheckChecksNoVisible(state.lastValidTarget, "Silent") then
                state.lastValidTarget = nil
            end
        end
    elseif mode == "Trigger" or mode == "Trigger Bot" then
        if not State.TriggerTargetLocked then return end
        
        local Target = State.Targets.Trigger
        
        if Target then
            if not CheckChecksNoVisible(Target, "Trigger") then
                State.Targets.Trigger = nil
                State.TriggerTargetLocked = false
                state.triggerLastValidTarget = nil
                state.triggerFOVActive = false
                if TriggerFOVBox then TriggerFOVBox.Visible = false end
                if Trigger3DFOVPart then Trigger3DFOVPart.Transparency = 1 end
                return
            end
            if CheckChecks(Target, "Trigger") then
                state.triggerLastValidTarget = nil
                return
            else
                state.triggerLastValidTarget = Target
                State.Targets.Trigger = nil
                return
            end
        end
        
        if state.triggerLastValidTarget then
            if CheckChecksNoVisible(state.triggerLastValidTarget, "Trigger") and CheckChecks(state.triggerLastValidTarget, "Trigger") then
                State.Targets.Trigger = state.triggerLastValidTarget
                state.triggerLastValidTarget = nil
                state.triggerFOVActive = true
            elseif not CheckChecksNoVisible(state.triggerLastValidTarget, "Trigger") then
                state.triggerLastValidTarget = nil
                state.triggerFOVActive = false
                if TriggerFOVBox then TriggerFOVBox.Visible = false end
                if Trigger3DFOVPart then Trigger3DFOVPart.Transparency = 1 end
            end
        end
    elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
        if not State.CameraTargetLocked then return end
        
        local Target = State.Targets.Camera
        
        if Target then
            if not CheckChecksNoVisible(Target, "Camera") then
                State.Targets.Camera = nil
                State.CameraTargetLocked = false
                state.cameraLastValidTarget = nil
                state.cameraFOVActive = false
                state.cameraEasingProgress = 0
                state.cameraLastTarget = nil
                state.cameraShakeTime = 0
                if CameraFOVBox then CameraFOVBox.Visible = false end
                if Camera3DFOVPart then Camera3DFOVPart.Transparency = 1 end
                return
            end
            if CheckChecks(Target, "Camera") then
                state.cameraLastValidTarget = nil
                return
            else
                state.cameraLastValidTarget = Target
                State.Targets.Camera = nil
                return
            end
        end
        
        if state.cameraLastValidTarget then
            if CheckChecksNoVisible(state.cameraLastValidTarget, "Camera") and CheckChecks(state.cameraLastValidTarget, "Camera") then
                State.Targets.Camera = state.cameraLastValidTarget
                state.cameraLastValidTarget = nil
                state.cameraFOVActive = true
            elseif not CheckChecksNoVisible(state.cameraLastValidTarget, "Camera") then
                state.cameraLastValidTarget = nil
                state.cameraFOVActive = false
                state.cameraEasingProgress = 0
                state.cameraLastTarget = nil
                state.cameraShakeTime = 0
                if CameraFOVBox then CameraFOVBox.Visible = false end
                if Camera3DFOVPart then Camera3DFOVPart.Transparency = 1 end
            end
        end
    end
end

local GunHandler = nil
pcall(function()
    GunHandler = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("GunHandler")
    if not GunHandler then
        GunHandler = ReplicatedStorage:FindFirstChild("GunHandler")
    end
    if GunHandler then
        GunHandler = require(GunHandler)
    end
end)

local OriginalGetAim = nil
if GunHandler then
    OriginalGetAim = GunHandler.getAim
end

if GunHandler and OriginalGetAim then
    GunHandler.getAim = function(origin, range)
        local Config = shared.Illusion
        local SilentCfg = Config and Config["Silent Aimbot"]
        if not SilentCfg or not SilentCfg["Enabled"] then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        if not State.SilentTargetLocked then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        ValidateTarget("Silent Aimbot")
        
        local Target = State.Targets.Silent
        if not Target then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        local TargetChar = Target.Character
        local TargetPos = nil
        
        local isClosestPoint = IsSilentHitpartClosestPoint()
        
        if isClosestPoint then
            local result = getClosestPoint(TargetChar)
            if result and result.Position then
                TargetPos = result.Position
            end
        end
        
        if not TargetPos then
            local TargetHead = TargetChar:FindFirstChild("Head")
            if TargetHead then
                TargetPos = TargetHead.Position
            else
                local Root = TargetChar:FindFirstChild("HumanoidRootPart")
                if Root then
                    TargetPos = Root.Position
                else
                    if OriginalGetAim then return OriginalGetAim(origin, range) end
                    return
                end
            end
        end
        
        local predictionCfg = Config["Prediction"] or {}
        if predictionCfg["Enabled"] then
            local rootPart = TargetChar:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local velocity = rootPart.AssemblyLinearVelocity
                local predX = predictionCfg["X"] or 0
                local predY = predictionCfg["Y"] or 0
                local predZ = predictionCfg["Z"] or 0
                TargetPos = TargetPos + Vector3.new(velocity.X * predX, velocity.Y * predY, velocity.Z * predZ)
            end
        end
        
        local Distance = (TargetPos - origin).Magnitude
        local MaxRange = GetSelectingDistance("Silent")
        
        if MaxRange <= 0 then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        if Distance > MaxRange then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        local fovConfig = getScaledFOV("Silent", "2D", nil, TargetChar:FindFirstChild("HumanoidRootPart"))
        local inFOV = true
        
        local fovMethod = SilentCfg["Field Of View Method"] or "2D"
        if fovMethod == "2D" then
            local screenPos, onScreen = Camera:WorldToViewportPoint(TargetPos)
            if onScreen and screenPos.Z > 0 then
                local mousePos = UserInputService:GetMouseLocation()
                local Root = TargetChar:FindFirstChild("HumanoidRootPart")
                if Root then
                    local scaledFov = getScaledFOV("Silent", "2D", screenPos, Root)
                    if scaledFov then
                        inFOV = isIn2DFOV(screenPos, mousePos, scaledFov)
                    end
                end
            else
                inFOV = false
            end
        elseif fovMethod == "3D" then
            local targetPart = TargetChar:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local fov3d = getScaledFOV("Silent", "3D", nil, targetPart)
                if fov3d then
                    inFOV = partInFOV3D(targetPart, fov3d)
                end
            end
        end
        
        if not inFOV then
            if OriginalGetAim then return OriginalGetAim(origin, range) end
            return
        end
        
        local dir = (TargetPos - origin)
        return dir.Unit, math.min(dir.Magnitude, range or 200)
    end
end

local function GetClosestPlayerToCursor(MaxRange, mode)
    if MaxRange <= 0 then return nil end
    
    local MousePos = UserInputService:GetMouseLocation()
    local CamPos = Camera.CFrame.Position
    local Closest, BestDist = nil, math.huge
    for _, Plr in next, Players:GetPlayers() do
        if not IsPlayerValid(Plr, mode) then continue end
        local Root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
        if not Root then continue end
        local Dist = (CamPos - Root.Position).Magnitude
        if Dist > MaxRange then continue end
        
        local Head = Plr.Character:FindFirstChild("Head")
        local targetPos = Head and Head.Position or Root.Position
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(targetPos)
        if not OnScreen or ScreenPos.Z <= 0 then continue end
        local Mag = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
        
        if Mag < BestDist then
            BestDist = Mag
            Closest = Plr
        end
    end
    return Closest
end

local UtilityUI = Instance.new("ScreenGui")
UtilityUI.Name = "IllusionUI"
UtilityUI.IgnoreGuiInset = true
UtilityUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UtilityUI.Parent = CoreGui

local function CreateSquare()
    local Obj = { _Size = Vector2.new(0,0), _Position = Vector2.new(0,0), _Color = Color3.new(1,1,1), _Visible = false, _Filled = false, _Thickness = 1, _Transparency = 1 }
    local Frame = Instance.new("Frame")
    Frame.BorderSizePixel = 0
    Frame.BackgroundTransparency = 1
    Frame.BackgroundColor3 = Obj._Color
    Frame.Visible = false
    Frame.Parent = UtilityUI
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = Obj._Thickness
    Stroke.Enabled = true
    Stroke.LineJoinMode = Enum.LineJoinMode.Miter
    Stroke.Parent = Frame
    local Proxy = {}
    local Meta = {
        __newindex = function(_, K, V)
            if K == "Size" then Obj._Size = V; Frame.Size = UDim2.fromOffset(V.X, V.Y)
            elseif K == "Position" then Obj._Position = V; Frame.Position = UDim2.fromOffset(V.X, V.Y)
            elseif K == "Color" then Obj._Color = V; Frame.BackgroundColor3 = V; Stroke.Color = V
            elseif K == "Visible" then Obj._Visible = V; Frame.Visible = V
            elseif K == "Filled" then Obj._Filled = V; Frame.BackgroundTransparency = V and (1 - Obj._Transparency) or 1; Stroke.Enabled = not V
            elseif K == "Thickness" then Obj._Thickness = V; Stroke.Thickness = math.clamp(V, 0.6, 1e9)
            elseif K == "Transparency" then Obj._Transparency = V; local A = 1 - V; Frame.BackgroundTransparency = Obj._Filled and A or 1; Stroke.Transparency = A
            end
        end,
        __index = function(_, K)
            if K == "Remove" or K == "Destroy" then return function() Frame:Destroy() end end
            if K == "Size" then return Obj._Size end
            if K == "Position" then return Obj._Position end
            if K == "Color" then return Obj._Color end
            if K == "Visible" then return Obj._Visible end
            if K == "Filled" then return Obj._Filled end
            if K == "Thickness" then return Obj._Thickness end
            if K == "Transparency" then return Obj._Transparency end
            return nil
        end
    }
    return setmetatable(Proxy, Meta)
end

local function CreateTextLabel()
    local Obj = { _Text = "", _Size = 14, _Position = Vector2.new(0,0), _Color = Color3.new(1,1,1), _Visible = false, _Center = false, _Outline = true, _OutlineColor = Color3.new(0,0,0), _Transparency = 1 }
    local Label = Instance.new("TextLabel")
    Label.AnchorPoint = Vector2.new(0.5,0.5)
    Label.BorderSizePixel = 0
    Label.BackgroundTransparency = 1
    Label.RichText = true
    Label.Font = Enum.Font.SourceSansBold
    Label.TextSize = Obj._Size
    Label.TextColor3 = Obj._Color
    Label.Visible = false
    Label.Text = ""
    Label.Parent = UtilityUI
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Obj._OutlineColor
    Stroke.Enabled = Obj._Outline
    Stroke.Parent = Label
    local function UpdatePos()
        local Bounds = Label.TextBounds
        local Ox = Obj._Center and 0 or (Bounds.X / 2)
        Label.Position = UDim2.fromOffset(Obj._Position.X + Ox, Obj._Position.Y + Bounds.Y / 2)
    end
    Label:GetPropertyChangedSignal("TextBounds"):Connect(UpdatePos)
    local Proxy = {}
    local Meta = {
        __newindex = function(_, K, V)
            if K == "Text" then Obj._Text = V; Label.Text = V
            elseif K == "Size" then Obj._Size = V; Label.TextSize = V
            elseif K == "Position" then Obj._Position = V; UpdatePos()
            elseif K == "Color" then Obj._Color = V; Label.TextColor3 = V
            elseif K == "Visible" then Obj._Visible = V; Label.Visible = V
            elseif K == "Center" then Obj._Center = V; UpdatePos()
            elseif K == "Outline" then Obj._Outline = V; Stroke.Enabled = V
            elseif K == "OutlineColor" then Obj._OutlineColor = V; Stroke.Color = V
            elseif K == "Transparency" then Obj._Transparency = V; local A = 1 - V; Label.TextTransparency = A; Stroke.Transparency = A
            end
        end,
        __index = function(_, K)
            if K == "TextBounds" then return Label.TextBounds end
            if K == "Remove" or K == "Destroy" then return function() Label:Destroy() end end
            if K == "Text" then return Obj._Text end
            if K == "Size" then return Obj._Size end
            if K == "Position" then return Obj._Position end
            if K == "Color" then return Obj._Color end
            if K == "Visible" then return Obj._Visible end
            if K == "Center" then return Obj._Center end
            if K == "Outline" then return Obj._Outline end
            if K == "Transparency" then return Obj._Transparency end
            return nil
        end
    }
    return setmetatable(Proxy, Meta)
end

local SilentFOVBox = CreateSquare()
SilentFOVBox.Visible = false
SilentFOVBox.Filled = false
SilentFOVBox.Thickness = 0.2
SilentFOVBox.Transparency = 1

local TriggerFOVBox = CreateSquare()
TriggerFOVBox.Visible = false
TriggerFOVBox.Filled = false
TriggerFOVBox.Thickness = 0.2
TriggerFOVBox.Transparency = 1

local CameraFOVBox = CreateSquare()
CameraFOVBox.Visible = false
CameraFOVBox.Filled = false
CameraFOVBox.Thickness = 0.2
CameraFOVBox.Transparency = 1

local Silent3DFOVPart = Instance.new("Part")
Silent3DFOVPart.Anchored = true
Silent3DFOVPart.CanCollide = false
Silent3DFOVPart.CanQuery = false
Silent3DFOVPart.CanTouch = false
Silent3DFOVPart.CastShadow = false
Silent3DFOVPart.Transparency = 0.92
Silent3DFOVPart.Material = Enum.Material.Neon
Silent3DFOVPart.Parent = Workspace

local Trigger3DFOVPart = Instance.new("Part")
Trigger3DFOVPart.Anchored = true
Trigger3DFOVPart.CanCollide = false
Trigger3DFOVPart.CanQuery = false
Trigger3DFOVPart.CanTouch = false
Trigger3DFOVPart.CastShadow = false
Trigger3DFOVPart.Transparency = 0.92
Trigger3DFOVPart.Material = Enum.Material.Neon
Trigger3DFOVPart.Parent = Workspace

local Camera3DFOVPart = Instance.new("Part")
Camera3DFOVPart.Anchored = true
Camera3DFOVPart.CanCollide = false
Camera3DFOVPart.CanQuery = false
Camera3DFOVPart.CanTouch = false
Camera3DFOVPart.CastShadow = false
Camera3DFOVPart.Transparency = 0.92
Camera3DFOVPart.Material = Enum.Material.Neon
Camera3DFOVPart.Parent = Workspace

local NameESPDrawings = {}

local PanelTitle = CreateTextLabel()
PanelTitle.Visible = false
PanelTitle.Size = 16
PanelTitle.Outline = true
PanelTitle.Center = true

local PanelLabels = {}
for i = 1, 12 do
    local L = CreateTextLabel()
    L.Visible = false
    L.Size = 14
    L.Outline = true
    L.Center = true
    PanelLabels[i] = L
end

local function IsInFOV(Player, mode)
    if not Player or not Player.Character then return false end
    
    local Config = shared.Illusion
    local fovOps = Config and Config["Field Of View Operations"]
    if not fovOps then return true end
    
    local modeCfg = nil
    if mode == "Trigger" or mode == "Trigger Bot" then
        modeCfg = fovOps["Trigger Bot"]
    elseif mode == "Silent" or mode == "Silent Aimbot" then
        modeCfg = Config["Silent Aimbot"]
    elseif mode == "Camera" or mode == "Aim Assist" or mode == "Camera Aimbot" then
        modeCfg = Config["Camera Aimbot"]
    end
    
    if not modeCfg then return true end
    
    local fovMethod = modeCfg["Field Of View Method"] or "2D"
    local TargetChar = Player.Character
    
    if fovMethod == "Precise" then
        return isInPreciseFOV(TargetChar)
    end
    
    local Root = TargetChar:FindFirstChild("HumanoidRootPart")
    if not Root then return false end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(Root.Position)
    if not onScreen or screenPos.Z <= 0 then return false end
    
    if fovMethod == "2D" then
        local mousePos = UserInputService:GetMouseLocation()
        local scaledFov = getScaledFOV(mode, "2D", screenPos, Root)
        if scaledFov then
            return isIn2DFOV(screenPos, mousePos, scaledFov)
        end
        return true
    elseif fovMethod == "3D" then
        local fov3d = getScaledFOV(mode, "3D", nil, Root)
        if fov3d then
            return partInFOV3D(Root, fov3d)
        end
        return true
    end
    
    return true
end

local function IsSeparateKeybindsEnabled()
    local Config = shared.Illusion
    if not Config then return false end
    local universal = Config["Keybind Operating Systems"] and Config["Keybind Operating Systems"]["Universal Keybind"]
    if not universal then return false end
    local separate = universal["Separate"]
    return separate and separate["Enabled"] == true
end

local function HandleSharedKey(input, processed)
    if processed then return end
    
    if IsSeparateKeybindsEnabled() then return end
    
    local Config = shared.Illusion
    if not Config then return end
    
    local key = GetKeybind()
    if not key then return end
    
    local match = false
    pcall(function()
        if input.KeyCode == Enum.KeyCode[key:upper()] then
            match = true
        end
    end)
    if not match then
        pcall(function()
            if input.UserInputType == Enum.UserInputType[key] then
                match = true
            end
        end)
    end
    
    if not match then return end
    
    local SilentEnabled = Config["Silent Aimbot"] and Config["Silent Aimbot"]["Enabled"]
    local TriggerEnabled = Config["Trigger Bot"] and Config["Trigger Bot"]["Enabled"]
    local CameraEnabled = Config["Camera Aimbot"] and Config["Camera Aimbot"]["Enabled"]
    
    local activeModes = {}
    if SilentEnabled then table.insert(activeModes, "Silent Aimbot") end
    if TriggerEnabled then table.insert(activeModes, "Trigger Bot") end
    if CameraEnabled then table.insert(activeModes, "Camera Aimbot") end
    
    if #activeModes == 0 then return end
    
    if #activeModes == 1 then
        local mode = activeModes[1]
        if mode == "Silent Aimbot" then
            local SelMode = Config['Selecting A Player']['Silent Aimbot'] or "Toggle"
            local MaxR = GetSelectingDistance("Silent")
            if SelMode == "Toggle" then
                State.SilentTargetLocked = not State.SilentTargetLocked
                if State.SilentTargetLocked then
                    State.Targets.Silent = GetClosestPlayerToCursor(MaxR, "Silent")
                    state.lastValidTarget = nil
                else
                    State.Targets.Silent = nil
                    state.lastValidTarget = nil
                end
            elseif SelMode == "Hold" then
                State.SilentTargetLocked = true
                State.Targets.Silent = GetClosestPlayerToCursor(MaxR, "Silent")
                state.lastValidTarget = nil
            end
        elseif mode == "Trigger Bot" then
            local SelMode = Config['Selecting A Player']['Trigger Bot'] or "Toggle"
            local MaxR = GetSelectingDistance("Trigger")
            if SelMode == "Toggle" then
                State.TriggerTargetLocked = not State.TriggerTargetLocked
                if State.TriggerTargetLocked then
                    State.Targets.Trigger = GetClosestPlayerToCursor(MaxR, "Trigger")
                    state.triggerLastValidTarget = nil
                    state.triggerFOVActive = true
                else
                    State.Targets.Trigger = nil
                    state.triggerLastValidTarget = nil
                    state.triggerFOVActive = false
                    TriggerFOVBox.Visible = false
                    Trigger3DFOVPart.Transparency = 1
                end
            elseif SelMode == "Hold" then
                State.TriggerTargetLocked = true
                State.Targets.Trigger = GetClosestPlayerToCursor(MaxR, "Trigger")
                state.triggerLastValidTarget = nil
                state.triggerFOVActive = true
            end
        elseif mode == "Camera Aimbot" then
            local SelMode = Config['Selecting A Player']['Aim Assist'] or "Toggle"
            local MaxR = GetSelectingDistance("Camera")
            if SelMode == "Toggle" then
                State.CameraTargetLocked = not State.CameraTargetLocked
                if State.CameraTargetLocked then
                    State.Targets.Camera = GetClosestPlayerToCursor(MaxR, "Camera")
                    state.cameraLastValidTarget = nil
                    state.cameraFOVActive = true
                    state.cameraEasingProgress = 0
                    state.cameraLastTarget = nil
                else
                    State.Targets.Camera = nil
                    state.cameraLastValidTarget = nil
                    state.cameraFOVActive = false
                    state.cameraEasingProgress = 0
                    state.cameraLastTarget = nil
                    CameraFOVBox.Visible = false
                    Camera3DFOVPart.Transparency = 1
                end
            elseif SelMode == "Hold" then
                State.CameraTargetLocked = true
                State.Targets.Camera = GetClosestPlayerToCursor(MaxR, "Camera")
                state.cameraLastValidTarget = nil
                state.cameraFOVActive = true
                state.cameraEasingProgress = 0
                state.cameraLastTarget = nil
            end
        end
        return
    end
    
    local allLocked = State.SilentTargetLocked or State.TriggerTargetLocked or State.CameraTargetLocked
    
    if allLocked then
        State.SilentTargetLocked = false
        State.TriggerTargetLocked = false
        State.CameraTargetLocked = false
        State.Targets.Silent = nil
        State.Targets.Trigger = nil
        State.Targets.Camera = nil
        state.lastValidTarget = nil
        state.triggerLastValidTarget = nil
        state.cameraLastValidTarget = nil
        state.triggerFOVActive = false
        state.cameraFOVActive = false
        state.cameraEasingProgress = 0
        state.cameraLastTarget = nil
        TriggerFOVBox.Visible = false
        Trigger3DFOVPart.Transparency = 1
        CameraFOVBox.Visible = false
        Camera3DFOVPart.Transparency = 1
        state.sharedTargetLocked = false
        state.sharedTarget = nil
        state.silentOnly = false
        state.triggerOnly = false
        state.cameraOnly = false
    else
        if not state.silentOnly and not state.triggerOnly and not state.cameraOnly then
            if SilentEnabled then state.silentOnly = true end
            if TriggerEnabled then state.triggerOnly = true end
            if CameraEnabled then state.cameraOnly = true end
            
            if SilentEnabled then
                local MaxR = GetSelectingDistance("Silent")
                local Target = GetClosestPlayerToCursor(MaxR, "Silent")
                if Target then
                    State.SilentTargetLocked = true
                    State.Targets.Silent = Target
                    state.lastValidTarget = nil
                    state.sharedTargetLocked = true
                    state.sharedTarget = Target
                end
            end
            
            if TriggerEnabled then
                local MaxR = GetSelectingDistance("Trigger")
                local Target = state.sharedTarget or GetClosestPlayerToCursor(MaxR, "Trigger")
                if Target then
                    State.TriggerTargetLocked = true
                    State.Targets.Trigger = Target
                    state.triggerLastValidTarget = nil
                    state.triggerFOVActive = true
                end
            end
            
            if CameraEnabled then
                local MaxR = GetSelectingDistance("Camera")
                local Target = state.sharedTarget or GetClosestPlayerToCursor(MaxR, "Camera")
                if Target then
                    State.CameraTargetLocked = true
                    State.Targets.Camera = Target
                    state.cameraLastValidTarget = nil
                    state.cameraFOVActive = true
                    state.cameraEasingProgress = 0
                    state.cameraLastTarget = nil
                end
            end
        end
    end
end

local function HandleTriggerKey(input, processed)
    if processed then return end
    
    if not IsSeparateKeybindsEnabled() then return end
    
    local Config = shared.Illusion
    local TriggerCfg = Config and Config["Trigger Bot"]
    if not TriggerCfg or not TriggerCfg["Enabled"] then return end
    
    local MaxR = GetSelectingDistance("Trigger")
    local key = GetKeybind("Trigger")
    
    if not key then return end
    
    local match = false
    pcall(function()
        if input.KeyCode == Enum.KeyCode[key:upper()] then
            match = true
        end
    end)
    if not match then
        pcall(function()
            if input.UserInputType == Enum.UserInputType[key] then
                match = true
            end
        end)
    end
    
    if not match then return end
    
    local SelMode = Config['Selecting A Player']['Trigger Bot'] or "Toggle"
    
    if SelMode == "Toggle" then
        State.TriggerTargetLocked = not State.TriggerTargetLocked
        if State.TriggerTargetLocked then
            State.Targets.Trigger = GetClosestPlayerToCursor(MaxR, "Trigger")
            state.triggerLastValidTarget = nil
            state.triggerFOVActive = true
        else
            State.Targets.Trigger = nil
            state.triggerLastValidTarget = nil
            state.triggerFOVActive = false
            TriggerFOVBox.Visible = false
            Trigger3DFOVPart.Transparency = 1
        end
    elseif SelMode == "Hold" then
        State.TriggerTargetLocked = true
        State.Targets.Trigger = GetClosestPlayerToCursor(MaxR, "Trigger")
        state.triggerLastValidTarget = nil
        state.triggerFOVActive = true
    end
end

local function HandleSilentKey(input, processed)
    if processed then return end
    
    if not IsSeparateKeybindsEnabled() then return end
    
    local Config = shared.Illusion
    local SilentCfg = Config and Config["Silent Aimbot"]
    if not SilentCfg or not SilentCfg["Enabled"] then return end
    
    local MaxR = GetSelectingDistance("Silent")
    local Key = GetKeybind("Silent")
    
    if not Key then return end
    
    local Match = false
    pcall(function()
        if input.KeyCode == Enum.KeyCode[Key:upper()] then
            Match = true
        end
    end)
    if not Match then
        pcall(function()
            if input.UserInputType == Enum.UserInputType[Key] then
                Match = true
            end
        end)
    end
    
    if not Match then return end
    
    local SelMode = Config['Selecting A Player']['Silent Aimbot'] or "Toggle"
    
    if SelMode == "Toggle" then
        State.SilentTargetLocked = not State.SilentTargetLocked
        if State.SilentTargetLocked then
            State.Targets.Silent = GetClosestPlayerToCursor(MaxR, "Silent")
            state.lastValidTarget = nil
        else
            State.Targets.Silent = nil
            state.lastValidTarget = nil
        end
    elseif SelMode == "Hold" then
        State.SilentTargetLocked = true
        State.Targets.Silent = GetClosestPlayerToCursor(MaxR, "Silent")
        state.lastValidTarget = nil
    end
end

local function HandleCameraKey(input, processed)
    if processed then return end
    
    if not IsSeparateKeybindsEnabled() then return end
    
    local Config = shared.Illusion
    local CameraCfg = Config and Config["Camera Aimbot"]
    if not CameraCfg or not CameraCfg["Enabled"] then return end
    
    local MaxR = GetSelectingDistance("Camera")
    local Key = GetKeybind("Camera")
    
    if not Key then return end
    
    local Match = false
    pcall(function()
        if input.KeyCode == Enum.KeyCode[Key:upper()] then
            Match = true
        end
    end)
    if not Match then
        pcall(function()
            if input.UserInputType == Enum.UserInputType[Key] then
                Match = true
            end
        end)
    end
    
    if not Match then return end
    
    local SelMode = Config['Selecting A Player']['Aim Assist'] or "Toggle"
    
    if SelMode == "Toggle" then
        State.CameraTargetLocked = not State.CameraTargetLocked
        if State.CameraTargetLocked then
            State.Targets.Camera = GetClosestPlayerToCursor(MaxR, "Camera")
            state.cameraLastValidTarget = nil
            state.cameraFOVActive = true
            state.cameraEasingProgress = 0
            state.cameraLastTarget = nil
        else
            State.Targets.Camera = nil
            state.cameraLastValidTarget = nil
            state.cameraFOVActive = false
            state.cameraEasingProgress = 0
            state.cameraLastTarget = nil
            CameraFOVBox.Visible = false
            Camera3DFOVPart.Transparency = 1
        end
    elseif SelMode == "Hold" then
        State.CameraTargetLocked = true
        State.Targets.Camera = GetClosestPlayerToCursor(MaxR, "Camera")
        state.cameraLastValidTarget = nil
        state.cameraFOVActive = true
        state.cameraEasingProgress = 0
        state.cameraLastTarget = nil
    end
end

state.targetingInputConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    HandleSharedKey(input, processed)
    HandleSilentKey(input, processed)
    HandleTriggerKey(input, processed)
    HandleCameraKey(input, processed)
end)

state.inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
    if not IsSeparateKeybindsEnabled() then
        local Key = GetKeybind()
        if Key then
            local Match = false
            pcall(function()
                if input.KeyCode == Enum.KeyCode[Key:upper()] then
                    Match = true
                end
            end)
            if not Match then
                pcall(function()
                    if input.UserInputType == Enum.UserInputType[Key] then
                        Match = true
                    end
                end)
            end
            if Match then
                local Config = shared.Illusion
                if Config then
                    local SilentCfg = Config["Silent Aimbot"]
                    if SilentCfg and Config['Selecting A Player']['Silent Aimbot'] == "Hold" then
                        State.SilentTargetLocked = false
                        State.Targets.Silent = nil
                        state.lastValidTarget = nil
                    end
                    local TriggerCfg = Config["Trigger Bot"]
                    if TriggerCfg and Config['Selecting A Player']['Trigger Bot'] == "Hold" then
                        State.TriggerTargetLocked = false
                        State.Targets.Trigger = nil
                        state.triggerLastValidTarget = nil
                        state.triggerFOVActive = false
                        TriggerFOVBox.Visible = false
                        Trigger3DFOVPart.Transparency = 1
                    end
                    local CameraCfg = Config["Camera Aimbot"]
                    if CameraCfg and Config['Selecting A Player']['Aim Assist'] == "Hold" then
                        State.CameraTargetLocked = false
                        State.Targets.Camera = nil
                        state.cameraLastValidTarget = nil
                        state.cameraFOVActive = false
                        state.cameraEasingProgress = 0
                        state.cameraLastTarget = nil
                        CameraFOVBox.Visible = false
                        Camera3DFOVPart.Transparency = 1
                    end
                end
                state.sharedTargetLocked = false
                state.sharedTarget = nil
                state.silentOnly = false
                state.triggerOnly = false
                state.cameraOnly = false
            end
        end
    else
        local Config = shared.Illusion
        if Config then
            local SilentCfg = Config["Silent Aimbot"]
            if SilentCfg and SilentCfg["Enabled"] and Config['Selecting A Player']['Silent Aimbot'] == "Hold" then
                local Key = GetKeybind("Silent")
                if Key then
                    local Match = false
                    pcall(function()
                        if input.KeyCode == Enum.KeyCode[Key:upper()] then
                            Match = true
                        end
                    end)
                    if not Match then
                        pcall(function()
                            if input.UserInputType == Enum.UserInputType[Key] then
                                Match = true
                            end
                        end)
                    end
                    if Match then
                        State.SilentTargetLocked = false
                        State.Targets.Silent = nil
                        state.lastValidTarget = nil
                    end
                end
            end
            local TriggerCfg = Config["Trigger Bot"]
            if TriggerCfg and TriggerCfg["Enabled"] and Config['Selecting A Player']['Trigger Bot'] == "Hold" then
                local Key = GetKeybind("Trigger")
                if Key then
                    local Match = false
                    pcall(function()
                        if input.KeyCode == Enum.KeyCode[Key:upper()] then
                            Match = true
                        end
                    end)
                    if not Match then
                        pcall(function()
                            if input.UserInputType == Enum.UserInputType[Key] then
                                Match = true
                            end
                        end)
                    end
                    if Match then
                        State.TriggerTargetLocked = false
                        State.Targets.Trigger = nil
                        state.triggerLastValidTarget = nil
                        state.triggerFOVActive = false
                        TriggerFOVBox.Visible = false
                        Trigger3DFOVPart.Transparency = 1
                    end
                end
            end
            local CameraCfg = Config["Camera Aimbot"]
            if CameraCfg and CameraCfg["Enabled"] and Config['Selecting A Player']['Aim Assist'] == "Hold" then
                local Key = GetKeybind("Camera")
                if Key then
                    local Match = false
                    pcall(function()
                        if input.KeyCode == Enum.KeyCode[Key:upper()] then
                            Match = true
                        end
                    end)
                    if not Match then
                        pcall(function()
                            if input.UserInputType == Enum.UserInputType[Key] then
                                Match = true
                            end
                        end)
                    end
                    if Match then
                        State.CameraTargetLocked = false
                        State.Targets.Camera = nil
                        state.cameraLastValidTarget = nil
                        state.cameraFOVActive = false
                        state.cameraEasingProgress = 0
                        state.cameraLastTarget = nil
                        CameraFOVBox.Visible = false
                        Camera3DFOVPart.Transparency = 1
                    end
                end
            end
        end
    end
end)

local function UpdateCameraFOV()
    local Config = shared.Illusion
    local CameraCfg = Config and Config["Camera Aimbot"]
    if not CameraCfg then
        if LastFrame.CameraFOVVisible then
            CameraFOVBox.Visible = false
            Camera3DFOVPart.Transparency = 1
            LastFrame.CameraFOVVisible = false
        end
        return
    end

    ValidateTarget("Camera Aimbot")
    local CameraTarget = State.Targets.Camera
    local fovMethod = CameraCfg["Field Of View Method"] or "2D"
    local visualize = CameraCfg["Visualize Field Of View"]

    if not CameraTarget or not State.CameraTargetLocked then
        if LastFrame.CameraFOVVisible then
            CameraFOVBox.Visible = false
            Camera3DFOVPart.Transparency = 1
            LastFrame.CameraFOVVisible = false
        end
        return
    end

    if fovMethod == "2D" then
        Camera3DFOVPart.Transparency = 1
        
        local FOVVis = false
        if visualize then
            local Char = CameraTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                if OnScreen and ScreenPos.Z > 1 then
                    local scaledFov = getScaledFOV("Camera", "2D", ScreenPos, Root)
                    if scaledFov then
                        local W = scaledFov.left + scaledFov.right
                        local H = scaledFov.upper + scaledFov.lower
                        
                        local MousePos = UserInputService:GetMouseLocation()
                        local InBox = isIn2DFOV(ScreenPos, MousePos, scaledFov)
                        local color = InBox and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                        
                        CameraFOVBox.Size = Vector2.new(math.floor(W + 0.5), math.floor(H + 0.5))
                        CameraFOVBox.Position = Vector2.new(math.floor(ScreenPos.X - scaledFov.left + 0.5), math.floor(ScreenPos.Y - scaledFov.upper + 0.5))
                        CameraFOVBox.Color = color
                        CameraFOVBox.Thickness = 0.2
                        FOVVis = true
                    end
                end
            end
        end
        if FOVVis ~= LastFrame.CameraFOVVisible then
            CameraFOVBox.Visible = FOVVis
            LastFrame.CameraFOVVisible = FOVVis
        end
    elseif fovMethod == "3D" then
        if LastFrame.CameraFOVVisible then
            CameraFOVBox.Visible = false
            LastFrame.CameraFOVVisible = false
        end
        
        if visualize then
            local Char = CameraTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local fovConfig = getScaledFOV("Camera", "3D", nil, Root)
                if fovConfig then
                    local totalSize = Root.Size + Vector3.new(fovConfig.x * 2, fovConfig.y * 2, fovConfig.z * 2)
                    Camera3DFOVPart.Size = totalSize
                    Camera3DFOVPart.CFrame = Root.CFrame
                    local inFOV = partInFOV3D(Root, fovConfig)
                    Camera3DFOVPart.Color = inFOV and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                    Camera3DFOVPart.Transparency = 0.92
                end
            end
        else
            Camera3DFOVPart.Transparency = 1
        end
    end
end

local function UpdateTriggerFOV()
    local Config = shared.Illusion
    local fovOps = Config and Config["Field Of View Operations"]
    local TriggerCfg = fovOps and fovOps["Trigger Bot"]
    if not TriggerCfg then
        if LastFrame.TriggerFOVVisible then
            TriggerFOVBox.Visible = false
            Trigger3DFOVPart.Transparency = 1
            LastFrame.TriggerFOVVisible = false
        end
        return
    end

    ValidateTarget("Trigger Bot")
    local TriggerTarget = State.Targets.Trigger
    local fovMethod = TriggerCfg["Field Of View Method"] or "2D"
    local visualize = TriggerCfg["Visualize Field Of View"]

    if not TriggerTarget or not State.TriggerTargetLocked then
        if LastFrame.TriggerFOVVisible then
            TriggerFOVBox.Visible = false
            Trigger3DFOVPart.Transparency = 1
            LastFrame.TriggerFOVVisible = false
        end
        return
    end

    if fovMethod == "Precise" then
        Trigger3DFOVPart.Transparency = 1
        TriggerFOVBox.Visible = false
        LastFrame.TriggerFOVVisible = false
        return
    end

    if fovMethod == "2D" then
        Trigger3DFOVPart.Transparency = 1
        
        local FOVVis = false
        if visualize then
            local Char = TriggerTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                if OnScreen and ScreenPos.Z > 1 then
                    local scaledFov = getScaledFOV("Trigger", "2D", ScreenPos, Root)
                    if scaledFov then
                        local W = scaledFov.left + scaledFov.right
                        local H = scaledFov.upper + scaledFov.lower
                        
                        local MousePos = UserInputService:GetMouseLocation()
                        local InBox = isIn2DFOV(ScreenPos, MousePos, scaledFov)
                        local color = InBox and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                        
                        TriggerFOVBox.Size = Vector2.new(math.floor(W + 0.5), math.floor(H + 0.5))
                        TriggerFOVBox.Position = Vector2.new(math.floor(ScreenPos.X - scaledFov.left + 0.5), math.floor(ScreenPos.Y - scaledFov.upper + 0.5))
                        TriggerFOVBox.Color = color
                        TriggerFOVBox.Thickness = 0.2
                        FOVVis = true
                    end
                end
            end
        end
        if FOVVis ~= LastFrame.TriggerFOVVisible then
            TriggerFOVBox.Visible = FOVVis
            LastFrame.TriggerFOVVisible = FOVVis
        end
    elseif fovMethod == "3D" then
        if LastFrame.TriggerFOVVisible then
            TriggerFOVBox.Visible = false
            LastFrame.TriggerFOVVisible = false
        end
        
        if visualize then
            local Char = TriggerTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local fovConfig = getScaledFOV("Trigger", "3D", nil, Root)
                if fovConfig then
                    local totalSize = Root.Size + Vector3.new(fovConfig.x * 2, fovConfig.y * 2, fovConfig.z * 2)
                    Trigger3DFOVPart.Size = totalSize
                    Trigger3DFOVPart.CFrame = Root.CFrame
                    local inFOV = partInFOV3D(Root, fovConfig)
                    Trigger3DFOVPart.Color = inFOV and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                    Trigger3DFOVPart.Transparency = 0.92
                end
            end
        else
            Trigger3DFOVPart.Transparency = 1
        end
    end
end

local function UpdateSilentFOV()
    local Config = shared.Illusion
    local SilentCfg = Config and Config["Silent Aimbot"]
    local SilentEnabled = SilentCfg and SilentCfg["Enabled"]
    
    if not SilentEnabled then
        if LastFrame.FOVVisible then
            SilentFOVBox.Visible = false
            LastFrame.FOVVisible = false
        end
        Silent3DFOVPart.Transparency = 1
        return
    end

    ValidateTarget("Silent Aimbot")
    local SilentTarget = State.Targets.Silent
    local fovMethod = SilentCfg["Field Of View Method"] or "2D"
    local visualize = SilentCfg["Visualize Field Of View"]

    if not SilentTarget or not State.SilentTargetLocked then
        if LastFrame.FOVVisible then
            SilentFOVBox.Visible = false
            Silent3DFOVPart.Transparency = 1
            LastFrame.FOVVisible = false
        end
        return
    end

    if fovMethod == "2D" then
        Silent3DFOVPart.Transparency = 1
        
        local FOVVis = false
        if visualize then
            local Char = SilentTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                if OnScreen and ScreenPos.Z > 1 then
                    local scaledFov = getScaledFOV("Silent", "2D", ScreenPos, Root)
                    if scaledFov then
                        local W = scaledFov.left + scaledFov.right
                        local H = scaledFov.upper + scaledFov.lower
                        
                        local MousePos = UserInputService:GetMouseLocation()
                        local InBox = isIn2DFOV(ScreenPos, MousePos, scaledFov)
                        local color = InBox and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                        
                        SilentFOVBox.Size = Vector2.new(math.floor(W + 0.5), math.floor(H + 0.5))
                        SilentFOVBox.Position = Vector2.new(math.floor(ScreenPos.X - scaledFov.left + 0.5), math.floor(ScreenPos.Y - scaledFov.upper + 0.5))
                        SilentFOVBox.Color = color
                        SilentFOVBox.Thickness = 0.2
                        FOVVis = true
                    end
                end
            end
        end
        if FOVVis ~= LastFrame.FOVVisible then
            SilentFOVBox.Visible = FOVVis
            LastFrame.FOVVisible = FOVVis
        end
    elseif fovMethod == "3D" then
        if LastFrame.FOVVisible then
            SilentFOVBox.Visible = false
            LastFrame.FOVVisible = false
        end
        
        if visualize then
            local Char = SilentTarget.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if Root then
                local fovConfig = getScaledFOV("Silent", "3D", nil, Root)
                if fovConfig then
                    local totalSize = Root.Size + Vector3.new(fovConfig.x * 2, fovConfig.y * 2, fovConfig.z * 2)
                    Silent3DFOVPart.Size = totalSize
                    Silent3DFOVPart.CFrame = Root.CFrame
                    local inFOV = partInFOV3D(Root, fovConfig)
                    Silent3DFOVPart.Color = inFOV and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                    Silent3DFOVPart.Transparency = 0.92
                end
            end
        else
            Silent3DFOVPart.Transparency = 1
        end
    end
end

local function UpdateESP()
    if not state.visualsEnabled or not state.namesVisible then
        if LastFrame.ESPVisible then
            for _, Draw in next, NameESPDrawings do
                if Draw then Draw.Visible = false end
            end
            LastFrame.ESPVisible = false
        end
        return
    end
    
    local Config = shared.Illusion
    local VisualsCfg = Config and Config["Visuals"] or {}
    local NamesCfg = VisualsCfg["Names"] or {}
    local ESPEnabled = VisualsCfg["Enabled"] and NamesCfg["Enabled"]
    local ESPVis = false
    if ESPEnabled then
        local ColorsCfg = VisualsCfg["Colors"] or {}
        local NameColor = ColorsCfg["Names"] or Color3.new(1,1,1)
        local AimedColor = ColorsCfg["Aimed"] or Color3.new(1,0,0)
        local Size = VisualsCfg["Size"] and VisualsCfg["Size"]["Names"] or 12
        local Placement = NamesCfg["Placement"] or "Bottom"
        local OffsetVec = Vector3.new(0, -2.5, 0)
        if Placement == "Above" then
            OffsetVec = Vector3.new(0, 2.5, 0)
        end
        local Method = NamesCfg["Method"] or "Display"
        for _, Plr in next, Players:GetPlayers() do
            if Plr == LocalPlayer then continue end
            if IsTargetDead(Plr) then
                local Draw = NameESPDrawings[Plr]
                if Draw and Draw.Visible then Draw.Visible = false end
                continue
            end
            local Char = Plr.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then
                local Draw = NameESPDrawings[Plr]
                if Draw and Draw.Visible then Draw.Visible = false end
                continue
            end
            local Pos = Root.Position + OffsetVec
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Pos)
            if not OnScreen then
                local Draw = NameESPDrawings[Plr]
                if Draw and Draw.Visible then Draw.Visible = false end
                continue
            end
            if not NameESPDrawings[Plr] then
                local Draw = CreateTextLabel()
                Draw.Outline = true
                Draw.Center = true
                NameESPDrawings[Plr] = Draw
            end
            local Draw = NameESPDrawings[Plr]
            
            local isLocked = false
            if Plr == State.Targets.Silent and CheckChecks(Plr, "Silent") then
                isLocked = true
            elseif Plr == State.Targets.Trigger and CheckChecks(Plr, "Trigger") then
                isLocked = true
            elseif Plr == State.Targets.Camera and CheckChecks(Plr, "Camera") then
                isLocked = true
            end
            
            Draw.Text = (Method == "Name") and Plr.Name or Plr.DisplayName
            Draw.Size = Size
            Draw.Color = isLocked and AimedColor or NameColor
            Draw.Position = Vector2.new(math.floor(ScreenPos.X + 0.5), math.floor(ScreenPos.Y + 0.5))
            Draw.Visible = true
            ESPVis = true
        end
    end
    if ESPVis ~= LastFrame.ESPVisible then
        if not ESPVis then
            for _, Draw in next, NameESPDrawings do
                if Draw then Draw.Visible = false end
            end
        end
        LastFrame.ESPVisible = ESPVis
    end
end

local function UpdatePanel()
    if not state.visualsEnabled or not state.panelVisible then
        if LastFrame.PanelVisible then
            PanelTitle.Visible = false
            for _, L in next, PanelLabels do
                if L then L.Visible = false end
            end
            LastFrame.PanelVisible = false
        end
        return
    end
    
    local Config = shared.Illusion
    local VisualsCfg = Config and Config["Visuals"] or {}
    local PanelEnabled = VisualsCfg["Enabled"]
    local PanelVis = false
    
    if PanelEnabled then
        local ViewportX, ViewportY = Camera.ViewportSize.X, Camera.ViewportSize.Y
        local ColorsCfg = VisualsCfg["Colors"] or {}
        local NameColor = ColorsCfg["Names"] or Color3.new(0.7,0.7,0.7)
        local AimedColor = ColorsCfg["Aimed"] or Color3.new(0, 0, 255)
        local BoxColor = ColorsCfg["Box"] or Color3.new(1,1,1)
        local FillColor = ColorsCfg["Fill"] or Color3.new(1,0,0)
        
        local silentTarget = State.Targets.Silent
        local triggerTarget = State.Targets.Trigger
        local cameraTarget = State.Targets.Camera
        
        local function getTargetName(target, mode)
            if target and target.Parent then
                if CheckChecksNoVisible(target, mode) then
                    return target.DisplayName or target.Name or "Player"
                end
            end
            return "N/A"
        end
        
        local silentName = getTargetName(silentTarget, "Silent")
        local triggerName = getTargetName(triggerTarget, "Trigger")
        local cameraName = getTargetName(cameraTarget, "Camera")
        
        local primaryTarget = nil
        local primaryMode = nil
        if silentTarget and State.SilentTargetLocked then
            primaryTarget = silentTarget
            primaryMode = "Silent"
        elseif triggerTarget and State.TriggerTargetLocked then
            primaryTarget = triggerTarget
            primaryMode = "Trigger"
        elseif cameraTarget and State.CameraTargetLocked then
            primaryTarget = cameraTarget
            primaryMode = "Camera"
        end
        
        local targetDisplayName = "N/A"
        local healthValue = "N/A"
        local armorValue = "N/A"
        
        if primaryTarget and primaryTarget.Parent then
            if CheckChecksNoVisible(primaryTarget, primaryMode) then
                targetDisplayName = primaryTarget.DisplayName or primaryTarget.Name or "Player"
                
                local char = primaryTarget.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local health = math.floor(humanoid.Health)
                        healthValue = tostring(health)
                        
                        local armorVal = 0
                        local armor = humanoid:FindFirstChild("Armor")
                        if armor then
                            armorVal = math.floor(armor.Value or 0)
                        end
                        if armorVal == 0 then
                            local armorAttribute = humanoid:GetAttribute("Armor")
                            if armorAttribute then
                                armorVal = math.floor(armorAttribute)
                            end
                        end
                        if armorVal == 0 then
                            local bodyEffects = char:FindFirstChild("BodyEffects")
                            if bodyEffects then
                                local armorObj = bodyEffects:FindFirstChild("Armor")
                                if armorObj then
                                    armorVal = math.floor(armorObj.Value or 0)
                                end
                            end
                        end
                        armorValue = tostring(armorVal)
                    end
                end
            end
        end
        
        local walkSpeedStatus = state.SpeedModEnabled and "on" or "off"
        
        local BaseX = math.floor(ViewportX / 2 + 0.6)
        local BaseY = math.floor(ViewportY - 190 + 0.5)
        
        PanelTitle.Text = string.format('illlusion')
        PanelTitle.Size = 16
        PanelTitle.Color = NameColor
        PanelTitle.Position = Vector2.new(BaseX, BaseY)
        PanelTitle.Visible = true

        local OffsetY = BaseY + 20
        local LabelIdx = 0

        LabelIdx = LabelIdx + 1
        local L = PanelLabels[LabelIdx]
        if L then
            local silentStatus = State.SilentTargetLocked and "on" or "off"
            local statusColor = (silentStatus == "on") and AimedColor or NameColor
            L.Text = string.format('silent : %s', silentStatus)
            L.Color = statusColor
            L.Size = 14
            L.Position = Vector2.new(BaseX, OffsetY)
            L.Visible = true
            OffsetY = OffsetY + 18
        end

        LabelIdx = LabelIdx + 1
        local L2 = PanelLabels[LabelIdx]
        if L2 then
            local triggerStatus = State.TriggerTargetLocked and "on" or "off"
            local statusColor = (triggerStatus == "on") and AimedColor or NameColor
            L2.Text = string.format('trigger : %s', triggerStatus)
            L2.Color = statusColor
            L2.Size = 14
            L2.Position = Vector2.new(BaseX, OffsetY)
            L2.Visible = true
            OffsetY = OffsetY + 18
        end

        LabelIdx = LabelIdx + 1
        local L3 = PanelLabels[LabelIdx]
        if L3 then
            local cameraStatus = State.CameraTargetLocked and "on" or "off"
            local statusColor = (cameraStatus == "on") and AimedColor or NameColor
            L3.Text = string.format('camera : %s', cameraStatus)
            L3.Color = statusColor
            L3.Size = 14
            L3.Position = Vector2.new(BaseX, OffsetY)
            L3.Visible = true
            OffsetY = OffsetY + 18
        end

        LabelIdx = LabelIdx + 1
        local L4 = PanelLabels[LabelIdx]
        if L4 then
            local speedColor = (walkSpeedStatus == "on") and AimedColor or NameColor
            L4.Text = string.format('speed : %s', walkSpeedStatus)
            L4.Color = speedColor
            L4.Size = 14
            L4.Position = Vector2.new(BaseX, OffsetY)
            L4.Visible = true
            OffsetY = OffsetY + 18
        end

        LabelIdx = LabelIdx + 1
        local L5 = PanelLabels[LabelIdx]
        if L5 then
            L5.Text = string.format('target : %s [%s]', targetDisplayName, healthValue)
            L5.Color = NameColor
            L5.Size = 14
            L5.Position = Vector2.new(BaseX, OffsetY)
            L5.Visible = true
            OffsetY = OffsetY + 18
        end

        for i = LabelIdx + 1, #PanelLabels do
            if PanelLabels[i].Visible then PanelLabels[i].Visible = false end
        end
        PanelVis = true
    end
    
    if PanelVis ~= LastFrame.PanelVisible then
        if not PanelVis then
            PanelTitle.Visible = false
            for _, L in next, PanelLabels do
                if L then L.Visible = false end
            end
        end
        LastFrame.PanelVisible = PanelVis
    end
end

local function UpdateTriggerBot()
    local Config = shared.Illusion
    local TriggerCfg = Config and Config["Trigger Bot"]
    if not TriggerCfg or not TriggerCfg["Enabled"] then return end
    
    if not State.TriggerTargetLocked then return end
    
    ValidateTarget("Trigger Bot")
    
    local Target = State.Targets.Trigger
    if not Target then return end
    
    local MaxRange = GetSelectingDistance("Trigger")
    local BlankPrevention = TriggerCfg["Blank Prevention"]
    
    if BlankPrevention == true then
        MaxRange = 204.2
    end
    
    if MaxRange > 0 and MaxRange ~= math.huge then
        local Character = LocalPlayer.Character
        if not Character then return end
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end
        local TargetRoot = Target.Character and Target.Character:FindFirstChild("HumanoidRootPart")
        if not TargetRoot then return end
        local Dist = (RootPart.Position - TargetRoot.Position).Magnitude
        if Dist > MaxRange then return end
    end
    
    local inFOV = IsInFOV(Target, "Trigger")
    if not inFOV then return end
    
    if not CheckChecks(Target, "Trigger") then return end
    
    if IsLeftControlHeld() then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Tool = Character:FindFirstChildOfClass("Tool")
    if not Tool then return end
    
    if Tool.Name == "[Knife]" or Tool.Name == "Knife" then return end
    
    local CurrentTime = tick()
    local CurrentWeapon = Tool.Name
    
    local Cooldown = GetTriggerCooldownForWeapon(CurrentWeapon)
    local LastAttackTime = state.weaponLastAttackTime[CurrentWeapon] or 0
    
    if CurrentTime - LastAttackTime >= Cooldown then
        local ShootSuccess = false
        
        local function AttemptShoot(Method)
            local Success = false
            pcall(function()
                if Method == "Activate" and Tool.Activate then
                    Tool:Activate()
                    Success = true
                elseif Method == "Fire" and Tool:FindFirstChild("Fire") then
                    local FireEvent = Tool:FindFirstChild("Fire")
                    if FireEvent:IsA("RemoteEvent") then
                        FireEvent:FireServer()
                        Success = true
                    elseif FireEvent:IsA("BindableEvent") then
                        FireEvent:Fire()
                        Success = true
                    end
                elseif Method == "Shoot" and Tool:FindFirstChild("Shoot") then
                    local ShootEvent = Tool:FindFirstChild("Shoot")
                    if ShootEvent:IsA("RemoteEvent") then
                        ShootEvent:FireServer()
                        Success = true
                    elseif ShootEvent:IsA("BindableEvent") then
                        ShootEvent:Fire()
                        Success = true
                    end
                elseif Method == "Click" then
                    local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
                    if Mouse then
                        Mouse.Button1Down:Fire()
                        task.wait(0.02)
                        Mouse.Button1Up:Fire()
                        Success = true
                    end
                elseif Method == "RemoteEvent" then
                    for _, Child in pairs(Tool:GetChildren()) do
                        if Child:IsA("RemoteEvent") and Child.Name ~= "Fire" and Child.Name ~= "Shoot" then
                            Child:FireServer()
                            Success = true
                            break
                        end
                    end
                elseif Method == "Attack" and Tool:FindFirstChild("Attack") then
                    local AttackEvent = Tool:FindFirstChild("Attack")
                    if AttackEvent:IsA("RemoteEvent") then
                        AttackEvent:FireServer()
                        Success = true
                    elseif AttackEvent:IsA("BindableEvent") then
                        AttackEvent:Fire()
                        Success = true
                    end
                end
            end)
            return Success
        end
        
        local ShootMethods = {"Activate", "Fire", "Shoot", "Click", "RemoteEvent", "Attack"}
        for _, Method in pairs(ShootMethods) do
            if AttemptShoot(Method) then
                ShootSuccess = true
                break
            end
        end
        
        if not ShootSuccess then
            pcall(function()
                local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
                if Mouse then
                    local Button1Down = Mouse.Button1Down
                    local Button1Up = Mouse.Button1Up
                    if Button1Down and Button1Up then
                        Button1Down:Fire()
                        task.wait(0.05)
                        Button1Up:Fire()
                        ShootSuccess = true
                    end
                end
            end)
        end
        
        if ShootSuccess then
            state.weaponLastAttackTime[CurrentWeapon] = CurrentTime
            state.lastAttackTime = CurrentTime
        end
    end
end

local function UpdateSharedTarget()
    if state.sharedTargetLocked and state.sharedTarget then
        if not CheckChecksNoVisible(state.sharedTarget, "Silent") then
            state.sharedTarget = nil
            state.sharedTargetLocked = false
            state.silentOnly = false
            state.triggerOnly = false
            state.cameraOnly = false
        end
    end
end

local function GetCameraTargetPart(Player)
    local Character = Player.Character
    if not Character then return nil end
    
    local Config = shared.Illusion
    if not Config then return nil end
    local CameraCfg = Config["Camera Aimbot"]
    if not CameraCfg then return nil end
    
    local TargetZone = CameraCfg["Silent Aimbot Target Zone"] or "Closest"
    
    if TargetZone == "Head" then
        return Character:FindFirstChild("Head")
    elseif TargetZone == "UpperTorso" then
        return Character:FindFirstChild("UpperTorso")
    elseif TargetZone == "Closest" then
        local MousePos = UserInputService:GetMouseLocation()
        local ClosestDist = math.huge
        local ClosestPart = nil
        
        for _, name in pairs(PARTS) do
            local Part = Character:FindFirstChild(name)
            if Part and Part:IsA("BasePart") then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                if OnScreen and ScreenPos.Z > 0 then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Dist < ClosestDist then
                        ClosestDist = Dist
                        ClosestPart = Part
                    end
                end
            end
        end
        return ClosestPart or Character:FindFirstChild("HumanoidRootPart")
    end
    
    return Character:FindFirstChild("HumanoidRootPart")
end

local function UpdateCameraAimbot()
    local Config = shared.Illusion
    local CameraCfg = Config and Config["Camera Aimbot"]
    if not CameraCfg or not CameraCfg["Enabled"] then return end
    
    if not State.CameraTargetLocked then
        return
    end
    
    ValidateTarget("Camera Aimbot")
    
    local Target = State.Targets.Camera
    if not Target then return end
    
    if not CheckChecks(Target, "Camera") then
        State.CameraTargetLocked = false
        State.Targets.Camera = nil
        state.cameraFOVActive = false
        state.cameraEasingProgress = 0
        state.cameraLastTarget = nil
        state.cameraShakeTime = 0
        CameraFOVBox.Visible = false
        Camera3DFOVPart.Transparency = 1
        return
    end
    
    local inFOV = IsInFOV(Target, "Camera")
    if not inFOV then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end
    
    local TargetChar = Target.Character
    if not TargetChar then return end
    
    local TargetPos = nil
    local TargetPart = GetCameraTargetPart(Target)
    if TargetPart then
        TargetPos = TargetPart.Position
    else
        local Head = TargetChar:FindFirstChild("Head")
        if Head then
            TargetPos = Head.Position
        else
            return
        end
    end
    
    local Prediction = Config["Prediction"] or {}
    if Prediction["Enabled"] then
        local RootPart = TargetChar:FindFirstChild("HumanoidRootPart")
        if RootPart then
            local Velocity = RootPart.AssemblyLinearVelocity
            TargetPos = TargetPos + Vector3.new(
                Velocity.X * (Prediction["X"] or 0),
                Velocity.Y * (Prediction["Y"] or 0),
                Velocity.Z * (Prediction["Z"] or 0)
            )
        end
    end
    
    local AimProps = Config["Aim Properties"] or {}
    local SmoothingCfg = AimProps["Smoothing"] or {}
    local SmoothingEnabled = SmoothingCfg["Enabled"]
    local xSmooth = SmoothingCfg["X Smoothing"] and SmoothingCfg["X Smoothing"][1] or 0.0123
    local ySmooth = SmoothingCfg["Y Smoothing"] and SmoothingCfg["Y Smoothing"][1] or 0.0123
    
    local MousePos = UserInputService:GetMouseLocation()
    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPos)
    
    if OnScreen and ScreenPos.Z > 0 then
        local DeltaX = ScreenPos.X - MousePos.X
        local DeltaY = ScreenPos.Y - MousePos.Y
        
        local progress = math.min((state.cameraEasingProgress or 0) + 0.05, 1)
        
        local function easeInOut(t)
            return t < 0.5 and 2 * t * t or 1 - math.pow(-2 * t + 2, 2) / 2
        end
        
        local easedProgress = progress
        easedProgress = easeInOut(progress)
        
        local smoothX = SmoothingEnabled and (xSmooth * easedProgress) or 1
        local smoothY = SmoothingEnabled and (ySmooth * easedProgress) or 1
        
        local AimDeltaX = DeltaX * smoothX
        local AimDeltaY = DeltaY * smoothY
        
        if math.abs(AimDeltaX) > 0.3 or math.abs(AimDeltaY) > 0.3 then
            mousemoverel(math.floor(AimDeltaX), math.floor(AimDeltaY))
        end
        state.cameraEasingProgress = progress
    end
end

local function SetupAntiFall()
    local Config = shared.Illusion
    if not Config then return end
    
    local SafetyUtils = Config["Safety And Utilities"]
    if not SafetyUtils then return end
    
    local AntiFall = SafetyUtils["Anti Fall"]
    if not AntiFall then return end
    
    local function HandleAntiFall(Character)
        if not Character then return end
        
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then return end
        
        Humanoid.StateChanged:Connect(function(_, NewState)
            if NewState == Enum.HumanoidStateType.FallingDown or NewState == Enum.HumanoidStateType.Ragdoll then
                task.wait(0.1)
                pcall(function()
                    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
        end)
    end
    
    if LocalPlayer.Character then
        HandleAntiFall(LocalPlayer.Character)
    end
    
    state.antiFallCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("Humanoid", 5)
        HandleAntiFall(Character)
    end)
end

SetupAntiFall()

local function CleanupFOVBoxes()
    pcall(function()
        if SilentFOVBox then
            SilentFOVBox.Visible = false
            SilentFOVBox:Remove()
        end
        if TriggerFOVBox then
            TriggerFOVBox.Visible = false
            TriggerFOVBox:Remove()
        end
        if CameraFOVBox then
            CameraFOVBox.Visible = false
            CameraFOVBox:Remove()
        end
    end)
    
    pcall(function()
        if Silent3DFOVPart then
            Silent3DFOVPart.Transparency = 1
            Silent3DFOVPart:Destroy()
        end
        if Trigger3DFOVPart then
            Trigger3DFOVPart.Transparency = 1
            Trigger3DFOVPart:Destroy()
        end
        if Camera3DFOVPart then
            Camera3DFOVPart.Transparency = 1
            Camera3DFOVPart:Destroy()
        end
    end)
    
    for _, v in pairs(Workspace:GetChildren()) do
        if v and v:IsA("Part") then
            local name = v.Name
            if name == "Silent3DFOVPart" or name == "Trigger3DFOVPart" or name == "Camera3DFOVPart" then
                pcall(function()
                    v.Transparency = 1
                    v:Destroy()
                end)
            end
        end
    end
    
    if LastFrame then
        LastFrame.FOVVisible = false
        LastFrame.TriggerFOVVisible = false
        LastFrame.CameraFOVVisible = false
    end
end

local function FullCleanup()
    state.cleanupActive = true
    state.uninjectSent = true

    pcall(SendUninjectLog)

    CleanupFOVBoxes()

    local function safeDisconnect(conn)
        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end

    local function safeDisable(conn)
        if conn then
            pcall(function() conn:Disable() end)
            pcall(function() conn:Disconnect() end)
        end
    end

    local connections = {
        state.heartbeatConnection,
        state.renderSteppedConnection,
        state.preRenderConnection,
        state.modDetectionConnection,
        state.safetyVisualsConnection,
        state.targetingInputConnection,
        state.inputEndedConnection,
        state.deathHandlerPlayerAdded,
        state.playerRemovingConnection,
        state.antiFallCharacterConnection,
        state.acLogServiceLoop,
        state.acCheckerLoop,
        state.acGripLoop,
        state.acAccuracyLoop,
        state.acShotTotalLoop,
        state.acShotTotalConnection,
        state.acShotTotalChildConnection,
        state.daHoodCheckerConnection,
        state.daHoodGripConnection,
        state.daHoodCharacterConnection,
        state.skinChangerCharacterConnection,
        state.skinChangerBackpackConnection,
        state.skinChangerToolConnection,
    }

    for _, conn in ipairs(connections) do
        safeDisconnect(conn)
    end

    local function killRemainingConnections()
        pcall(function()
            local services = { RunService, UserInputService, Players }
            for _, svc in ipairs(services) do
                local name = svc.ClassName
                local events = {
                    RunService = {"RenderStepped", "Heartbeat", "PreRender", "Stepped"},
                    UserInputService = {"InputBegan", "InputEnded", "JumpRequest"},
                    Players = {"PlayerAdded", "PlayerRemoving"},
                }
                for _, evt in ipairs(events[tostring(name)] or {}) do
                    local sig = svc[evt]
                    if sig then
                        for _, c in ipairs(getconnections and getconnections(sig) or {}) do
                            if c and c.Function then
                                local s = tostring(c.Function)
                                if s:find("Illusion") or s:find("Update") or s:find("Validate") or s:find("Handle") or s:find("checkMod") then
                                    safeDisable(c)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    killRemainingConnections()

    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui and gui:IsA("ScreenGui") then
            local guiName = gui.Name
            if guiName == "IllusionUI" or guiName == "Illusion" then
                pcall(function() gui:Destroy() end)
            end
        end
    end

    if NameESPDrawings then
        for _, Draw in next, NameESPDrawings do
            if Draw then pcall(function() Draw:Remove() end) end
        end
        NameESPDrawings = {}
    end

    pcall(function()
        if PanelTitle then PanelTitle:Remove() end
        if PanelLabels then
            for _, L in next, PanelLabels do
                if L then L:Remove() end
            end
            PanelLabels = {}
        end
    end)

    SilentFOVBox = nil
    TriggerFOVBox = nil
    CameraFOVBox = nil
    Silent3DFOVPart = nil
    Trigger3DFOVPart = nil
    Camera3DFOVPart = nil
    PanelTitle = nil
    PanelLabels = {}
    NameESPDrawings = {}

    LastFrame.FOVVisible = false
    LastFrame.ESPVisible = false
    LastFrame.PanelVisible = false
    LastFrame.TriggerFOVVisible = false
    LastFrame.CameraFOVVisible = false

    pcall(function()
        for _, v in next, (getgc and getgc() or {}) do
            if type(v) == "table" then
                if rawget(v, "Illusion") then rawset(v, "Illusion", nil) end
                if rawget(v, "State") and rawget(v, "Targets") then rawset(v, "State", nil) end
            end
        end
    end)

    pcall(function()
        local function cleanEnv(tbl)
            if type(tbl) ~= "table" then return end
            for k, v in pairs(tbl) do
                if type(v) == "table" then cleanEnv(v) end
                if type(k) == "string" and (k:find("Illusion") or k:find("State") or k:find("Target")) then
                    pcall(function() tbl[k] = nil end)
                end
            end
        end
        cleanEnv(getfenv and getfenv() or {})
    end)

    shared.Illusion = nil
    pcall(function() getgenv().Illusion = nil end)

    state.connections = {}
    state.silentactive = false
    state.silentTarget = nil
    state.silentLastPart = nil
    state.lastValidTarget = nil
    state.triggerLastValidTarget = nil
    state.triggerFOVActive = false
    state.lastTriggerTarget = nil
    state.lastAttackTime = 0
    state.sharedTargetLocked = false
    state.sharedTarget = nil
    state.weaponLastAttackTime = {}
    state.preciseSkipCounter = 0
    state.cameraTargetLocked = false
    state.cameraTarget = nil
    state.cameraLastValidTarget = nil
    state.cameraFOVActive = false
    state.cameraEasingProgress = 0
    state.cameraLastTarget = nil
    state.cameraShakeTime = 0
    state.silentOnly = false
    state.triggerOnly = false
    state.cameraOnly = false
    state.visualsEnabled = false
    state.namesVisible = false
    state.panelVisible = false
    state.forcefieldTimers = {}
    state.heartbeatConnection = nil
    state.renderSteppedConnection = nil
    state.preRenderConnection = nil
    state.modDetectionConnection = nil
    state.modDetectionSpawn = nil
    state.safetyVisualsConnection = nil
    state.targetingInputConnection = nil
    state.inputEndedConnection = nil
    state.deathHandlerPlayerAdded = nil
    state.playerRemovingConnection = nil
    state.antiFallCharacterConnection = nil

    State.Targets = { Silent = nil, Trigger = nil, Camera = nil }
    State.SilentTargetLocked = false
    State.TriggerTargetLocked = false
    State.CameraTargetLocked = false

    hitboxCache = {}
    frameCounter = 0
end

_G.IllusionFullCleanup = function()
    FullCleanup()
end

state.safetyVisualsConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local Settings = shared.Illusion
    if not Settings then return end

    pcall(function()
        local utilityOps = Settings['Keybind Operating Systems'] and Settings['Keybind Operating Systems']['Utility Operations']
        if utilityOps then
            local vk = utilityOps['Visuals']
            if vk and vk ~= '' and tostring(input.KeyCode) == "Enum.KeyCode." .. vk then
                state.visualsEnabled = not state.visualsEnabled
                state.namesVisible = state.visualsEnabled
                state.panelVisible = state.visualsEnabled
                if not state.visualsEnabled then
                    for _, Draw in next, NameESPDrawings do
                        if Draw then Draw.Visible = false end
                    end
                    PanelTitle.Visible = false
                    for _, L in next, PanelLabels do
                        if L then L.Visible = false end
                    end
                    LastFrame.ESPVisible = false
                    LastFrame.PanelVisible = false
                end
                return
            end
        end
    end)

    pcall(function()
        local safetyOps = Settings['Keybind Operating Systems'] and Settings['Keybind Operating Systems']['Safety Operations']
        local secOS = Settings['Security Operating System']
        if safetyOps and secOS then
            local sk = safetyOps['Uninject']
            local uninjectCfg = secOS['Uninject']
            if sk and sk ~= '' and uninjectCfg and uninjectCfg['Enabled'] then
                if tostring(input.KeyCode) == "Enum.KeyCode." .. sk then
                    state.uninjectSent = true
                    FullCleanup()
                end
            end
        end
    end)
end)

local preRenderConnection = nil
preRenderConnection = RunService.RenderStepped:Connect(function()
    state.preRenderConnection = preRenderConnection
    state.renderSteppedConnection = state.preRenderConnection
    if not shared.Illusion or state.cleanupActive then
        if preRenderConnection then
            preRenderConnection:Disconnect()
            preRenderConnection = nil
        end
        return
    end

    local cfg = shared.Illusion
    if not cfg then return end

    frameCounter = (frameCounter + 1) % 3600

    if frameCounter % 20 == 0 then
        clearHitboxCache()
    end

    UpdateSharedTarget()

    local silentCfg = cfg["Silent Aimbot"]
    if silentCfg and silentCfg["Enabled"] then
        UpdateSilentFOV()
    else
        if LastFrame.FOVVisible then
            SilentFOVBox.Visible = false
            Silent3DFOVPart.Transparency = 1
            LastFrame.FOVVisible = false
        end
    end

    local triggerCfg = cfg["Trigger Bot"]
    if triggerCfg and triggerCfg["Enabled"] then
        UpdateTriggerFOV()
    else
        if LastFrame.TriggerFOVVisible then
            TriggerFOVBox.Visible = false
            Trigger3DFOVPart.Transparency = 1
            LastFrame.TriggerFOVVisible = false
        end
    end

    local cameraCfg = cfg["Camera Aimbot"]
    if cameraCfg and cameraCfg["Enabled"] then
        UpdateCameraFOV()
    else
        if LastFrame.CameraFOVVisible then
            CameraFOVBox.Visible = false
            Camera3DFOVPart.Transparency = 1
            LastFrame.CameraFOVVisible = false
        end
    end

    local visualsCfg = cfg["Visuals"]
    if state.visualsEnabled and visualsCfg and visualsCfg["Enabled"] then
        UpdateESP()
        UpdatePanel()
    else
        if LastFrame.ESPVisible then
            for _, Draw in next, NameESPDrawings do
                if Draw then Draw.Visible = false end
            end
            LastFrame.ESPVisible = false
        end
        if LastFrame.PanelVisible then
            PanelTitle.Visible = false
            for _, L in next, PanelLabels do
                if L then L.Visible = false end
            end
            LastFrame.PanelVisible = false
        end
    end

    if triggerCfg and triggerCfg["Enabled"] then
        UpdateTriggerBot()
    end

    if cameraCfg and cameraCfg["Enabled"] then
        UpdateCameraAimbot()
    end
end)

state.playerRemovingConnection = Players.PlayerRemoving:Connect(function(Plr)
    local Draw = NameESPDrawings[Plr]
    if Draw then Draw:Remove(); NameESPDrawings[Plr] = nil end
    state.forcefieldTimers[Plr] = nil
    if state.lastValidTarget == Plr then state.lastValidTarget = nil end
    if state.triggerLastValidTarget == Plr then state.triggerLastValidTarget = nil end
    if state.cameraLastValidTarget == Plr then state.cameraLastValidTarget = nil end
    if state.sharedTarget == Plr then
        state.sharedTarget = nil
        state.sharedTargetLocked = false
        state.silentOnly = false
        state.triggerOnly = false
        state.cameraOnly = false
    end
    if State.Targets.Silent == Plr then
        State.Targets.Silent = nil
        State.SilentTargetLocked = false
    end
    if State.Targets.Trigger == Plr then
        State.Targets.Trigger = nil
        State.TriggerTargetLocked = false
        state.triggerFOVActive = false
    end
    if State.Targets.Camera == Plr then
        State.Targets.Camera = nil
        State.CameraTargetLocked = false
        state.cameraFOVActive = false
        state.cameraEasingProgress = 0
        state.cameraLastTarget = nil
        state.cameraShakeTime = 0
    end
end)

return {
    State = State,
    GetClosest = GetClosestPlayerToCursor,
}
