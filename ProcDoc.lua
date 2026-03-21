-- ProcDoc.lua

-- 1) SavedVariables initialization
--    Creates a frame to initialize persistent settings on VARIABLES_LOADED.
local initFrame = CreateFrame("Frame", "ProcDocDBInitFrame", UIParent)
initFrame:RegisterEvent("VARIABLES_LOADED")

initFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if not ProcDocDB then ProcDocDB = {} end
        if not ProcDocDB.globalVars then ProcDocDB.globalVars = {} end
        if not ProcDocDB.procsEnabled then ProcDocDB.procsEnabled = {} end
        if not ProcDocDB.actionProcDurations then ProcDocDB.actionProcDurations = {} end

        local gv = ProcDocDB.globalVars
        -- Only set defaults if not present
        if gv.minAlpha == nil then gv.minAlpha = 0.8 end
        if gv.maxAlpha == nil then gv.maxAlpha = 1.0 end
        if gv.minScale == nil then gv.minScale = 0.9 end
        if gv.maxScale == nil then gv.maxScale = 1.0 end  -- new default (old default was 1.25)
        if gv.alphaStep == nil then gv.alphaStep = 0.01 end
        if gv.pulseSpeed == nil then gv.pulseSpeed = 0.4 end
        if gv.topOffset == nil then gv.topOffset = 70 end
        if gv.sideOffset == nil then gv.sideOffset = 60 end
        if gv.timerTextAlpha == nil then gv.timerTextAlpha = 0.85 end
        if gv.isMuted == nil then gv.isMuted = false end
        if gv.soundVolume == nil then gv.soundVolume = 1.0 end
        if gv.disableTimers == nil then gv.disableTimers = false end


        minAlpha      = gv.minAlpha
        maxAlpha      = gv.maxAlpha
        minScale      = gv.minScale
        maxScale      = gv.maxScale
        alphaStep     = gv.alphaStep
        pulseSpeed    = gv.pulseSpeed
        topOffset     = gv.topOffset
        sideOffset    = gv.sideOffset
        timerTextAlpha= gv.timerTextAlpha

        initFrame:UnregisterEvent("VARIABLES_LOADED")
    end
end)

-- Debug helper to print current DB values
local function ProcDoc_DumpDB()
    if not ProcDocDB or not ProcDocDB.globalVars then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ProcDoc|r: DB not initialized yet.")
        return
    end
    local gv = ProcDocDB.globalVars
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ProcDoc DB Dump|r")
    DEFAULT_CHAT_FRAME:AddMessage("  minAlpha="..tostring(gv.minAlpha)
        .." maxAlpha="..tostring(gv.maxAlpha)
        .." minScale="..tostring(gv.minScale)
        .." maxScale="..tostring(gv.maxScale)
        .." pulseSpeed="..tostring(gv.pulseSpeed))
    DEFAULT_CHAT_FRAME:AddMessage("  topOffset="..tostring(gv.topOffset).." sideOffset="..tostring(gv.sideOffset)
        .." isMuted="..tostring(gv.isMuted)
        .." disableTimers="..tostring(gv.disableTimers))
end
    
-- 2) Main addon frame
local addonName = "ProcDoc"
local ProcDoc   = CreateFrame("Frame", "ProcDocAlertFrame", UIParent)

-- 3) Proc data tables
local PROC_DATA = {
    ["WARLOCK"] = {
        {
            buffName         = "Shadow Trance",
            texture          = "Interface\\Icons\\Spell_Shadow_Twilight",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\WarlockShadowTrance.tga",
            alertStyle       = "SIDES",
        },
    },
    ["MAGE"] = {
        {
            buffName         = "Clearcasting",
            texture          = "Interface\\Icons\\Spell_Shadow_ManaBurn",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidClearcasting.tga",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Netherwind Focus",
            texture          = "Interface\\Icons\\Spell_Shadow_Teleport",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\MageT2.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Temporal Convergence",
            texture          = "Interface\\Icons\\Spell_Nature_StormReach",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\MageTemporalConvergence.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Flash Freeze",
            texture          = "Interface\\Icons\\Spell_Fire_FrostResistanceTotem",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\MageFlashFreeze.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Arcane Rupture",
            texture          = "Interface\\Icons\\Spell_Arcane_Blast",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\MageArcaneRupture.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Hot Streak",
            texture          = "Interface\\Icons\\Spell_Fire_Firestarter", -- generic fire icon (may differ on server)
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\WarriorRevenge.tga", -- sample texture for test button preview
            alertStyle       = "LEFT", -- preview only; live logic spawns LEFT/RIGHT/TOP2 as tiers advance
        },
    },
    ["DRUID"] = {
        {
            buffName         = "Clearcasting",
            texture          = "Interface\\Icons\\Spell_Shadow_ManaBurn",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidClearcasting.tga",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Nature's Grace",
            texture          = "Interface\\Icons\\Spell_Nature_NaturesBlessing",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidNaturesGrace.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Tiger's Fury",
            texture          = "Interface\\Icons\\Ability_Mount_JungleTiger",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\HunterMongooseBite.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Astral Boon",
            texture          = "Interface\\Icons\\Spell_Arcane_StarFire",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidAstralBoon.tga",
            alertStyle       = "TOP2",
        },
        {
            buffName         = "Natural Boon",
            texture          = "Interface\\Icons\\Spell_Nature_AbolishMagic",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidNaturalBoon.tga",
            alertStyle       = "TOP2",
        },
        {
            buffName         = "Arcane Eclipse",
            texture          = "Interface\\Icons\\Spell_Nature_WispSplode",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidArcaneEclipse.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Nature Eclipse",
            texture          = "Interface\\Icons\\Spell_Nature_AbolishMagic",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidNatureEclipse.tga",
            alertStyle       = "SIDES2",
        },
    },
    ["SHAMAN"] = {
        {
            buffName         = "Clearcasting",
            texture          = "Interface\\Icons\\Spell_Shadow_ManaBurn",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidClearcasting.tga",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Nature's Swiftness",
            texture          = "Interface\\Icons\\Spell_Nature_RavenForm",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidNaturesGrace.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Stormstrike",
            texture          = "Interface\\Icons\\Ability_Shaman_StormStrike",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\ShamanStormstrike.tga",
            alertStyle       = "TOP2",
        },
        {
            buffName         = "Flurry",
            texture          = "Interface\\Icons\\Ability_GhoulFrenzy",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\HunterMongooseBite.tga",
            alertStyle       = "SIDES2",
        },
    },
    ["HUNTER"] = {
        {
            buffName         = "Quick Shots",
            texture          = "Interface\\Icons\\Ability_Warrior_InnerRage",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\HunterQuickShots.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Lock and Load",
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\Lock_and_Load.blp",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Explosive Ammunition",
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\impact.blp",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Poisonous Ammunition",
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\DruidNaturesGrace.tga",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Enchanted Ammunition",
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\serendipity.blp",
            alertStyle       = "TOP",
        },
    },
    ["WARRIOR"] = {
        {
            buffName         = "Enrage",
            texture          = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\WarriorEnrage.tga",
            alertStyle       = "SIDES",
        },
    },
    ["PRIEST"] = {
        {
            buffName         = "Resurgence",
            texture          = "Interface\\Icons\\Spell_Holy_MindVision",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PriestResurgence.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Enlightened",
            texture          = "Interface\\Icons\\Spell_Holy_PowerInfusion",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PriestEnlightened.tga",
            alertStyle       = "TOP",
        },
        {
            buffName         = "Searing Light",
            texture          = "Interface\\Icons\\Spell_Holy_SearingLightPriest",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PriestSearingLight.tga",
            alertStyle       = "SIDES2",
        },
        {
            buffName         = "Shadow Veil",
            texture          = "Interface\\Icons\\Spell_Shadow_GatherShadows",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PriestShadowVeil.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Spell Blasting",
            texture          = "Interface\\Icons\\Spell_Lightning_LightningBolt01",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PriestSpellBlasting.tga",
            alertStyle       = "TOP2",
        },
    },
    ["PALADIN"] = {
        {
            buffName         = "Daybreak",
            texture          = "Interface\\Icons\\Spell_Holy_AuraMastery",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PaladinDaybreak.tga",
            alertStyle       = "TOP",
        },
        {
            -- Triggered by Crusader Strike. Reduces damage of the next blocked attack.
            -- Lasts 10 seconds.
            buffName         = "Zealous Defence",
            texture          = "Interface\\Icons\\Ability_Warrior_ShieldReflection",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\Grand_Crusader.tga",
            alertStyle       = "SIDES",
        },
    },
    ["ROGUE"] = {
        {
            buffName         = "Remorseless",
            texture          = "Interface\\Icons\\Ability_FiegnDead",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\RogueRemorseless.tga",
            alertStyle       = "SIDES",
        },
        {
            buffName         = "Tricks of the Trade",
            texture          = "Interface\\Icons\\INV_Misc_Key_03",
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\RogueTricksoftheTrade.tga",
            alertStyle       = "TOP",
        },
    },
}

local ACTION_PROCS = {
    ["ROGUE"] = {
        {
            buffName        = "Riposte",  
            texture         = "Interface\\Icons\\Ability_Warrior_Challange",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\RogueRiposte.tga",
            alertStyle      = "SIDES",
            spellName       = "Riposte"
        },
        {
            buffName        = "Surprise Attack",  
            texture         = "Interface\\Icons\\Ability_Rogue_SurpriseAttack",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\RogueSuddenDeath.tga",
            alertStyle      = "SIDES2",
            spellName       = "Surprise Attack"
        },
    },
    ["WARRIOR"] = {
        {
            buffName        = "Overpower", 
            texture         = "Interface\\Icons\\Ability_MeleeDamage",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\WarriorOverpower.tga",
            alertStyle      = "TOP",
            spellName       = "Overpower"
        },
        {
            buffName        = "Execute", 
            texture         = "Interface\\Icons\\inv_sword_48",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\WarriorExecute.tga",
            alertStyle      = "TOP2",
            spellName       = "Execute"
        },
        {
            buffName        = "Counterattack",
            texture         = "Interface\\Icons\\Ability_Warrior_Riposte",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\WarriorCounterattack.tga",
            alertStyle      = "LEFT",
            spellName       = "Counterattack"
        },
        {
            buffName       = "Revenge",
            texture         = "Interface\\Icons\\Ability_Warrior_Revenge",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\WarriorRevenge.tga",
            alertStyle      = "RIGHT",
            spellName       = "Revenge"
        }
    },
    ["MAGE"] = {
        {
            buffName        = "Arcane Surge", 
            texture         = "Interface\\Icons\\INV_Enchant_EssenceMysticalLarge",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\MageArcaneSurge.tga",
            alertStyle      = "TOP2",
            spellName       = "Arcane Surge"
        },
    },
    ["HUNTER"] = {
        {
            buffName        = "Lacerate",
            texture         = "Interface\\Icons\\Spell_Lacerate_1c",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\HunterMongooseBite.tga",
            alertStyle      = "SIDES",
            spellName       = "Lacerate"
        },
        {
            buffName        = "Baited Shot",
            texture         = "Interface\\Icons\\Inv_Misc_Food_66",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\HunterBaitedShot.tga",
            alertStyle      = "TOP",
            spellName       = "Baited Shot"
        }
    },
    ["PALADIN"] = {
        {
            buffName        = "Hammer of Wrath", 
            texture         = "Interface\\Icons\\Ability_Thunderclap",
            alertTexturePath= "Interface\\AddOns\\ProcDoc\\img\\PaladinHammer.tga",
            alertStyle      = "SIDES",
            spellName       = "Hammer of Wrath"
        },
        -- New: Spellbook-based cooldown procs (no action bar slot required)
        {
            buffName         = "Judgement",
            -- No action button texture lookup (use spellbook cooldown), so leave texture empty
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PaladinJudgement.tga",
            alertStyle       = "RIGHT",
            spellName        = "Judgement",
            useSpellbook     = true,
        },
        {
            buffName         = "Hammer of Justice",
            texture          = nil,
            alertTexturePath = "Interface\\AddOns\\ProcDoc\\img\\PaladinJustice.tga",
            alertStyle       = "LEFT",
            spellName        = "Hammer of Justice",
            useSpellbook     = true,
        },    

    },
}
local DEFAULT_ALERT_TEXTURE = "Interface\\AddOns\\ProcDoc\\img\\ProcDocAlert.tga"

-- Optional fixed durations (seconds) for action-based proc windows.
-- These emulate a timeout so the alert auto-clears even if the action remains usable.
local ACTION_PROC_DEFAULT_DURATIONS = {
    ["Overpower"]       = 5,  
    ["Riposte"]         = 5,  
    ["Counterattack"]   = 5,  
    ["Revenge"]         = 5,  
    ["Surprise Attack"] = 5,  
    ["Arcane Surge"]    = 4,
    ["Lacerate"]        = 4,
    ["Baited Shot"]     = 4,
}

-- Hot Streak (Turtle WoW custom, stack-based visual) constants (Vanilla 1.12 compatible logic)
local HOT_STREAK_BUFF_NAME = "Hot Streak"
-- Re-use existing textures in the addon: WarriorEnrage for side build-up, MageArcaneRupture for final top burst.
local HOT_STREAK_SIDE_TEXTURE = "Interface\\AddOns\\ProcDoc\\img\\WarriorRevenge.tga"
local HOT_STREAK_TOP_TEXTURE  = "Interface\\AddOns\\ProcDoc\\img\\MageHotStreak.tga"
local hotStreakLastTier = 0  -- 0,3,4,5 (we only care about tiers 3/4/5)


-- Ensure DB tables exist and load saved globals
local function ProcDoc_EnsureDB()
    if not ProcDocDB then ProcDocDB = {} end
    if not ProcDocDB.globalVars then ProcDocDB.globalVars = {} end
    if not ProcDocDB.procsEnabled then ProcDocDB.procsEnabled = {} end
    if not ProcDocDB.actionProcDurations then ProcDocDB.actionProcDurations = {} end
end

local function ProcDoc_LoadGlobalsFromDB()
    ProcDoc_EnsureDB()
    local gv = ProcDocDB.globalVars
    -- Migrate any legacy fields
    if gv.maxSize and not gv.maxScale then gv.maxScale = gv.maxSize; gv.maxSize = nil end

    if gv.minAlpha   ~= nil then minAlpha   = gv.minAlpha   end
    if gv.maxAlpha   ~= nil then maxAlpha   = gv.maxAlpha   end
    if gv.minScale   ~= nil then minScale   = gv.minScale   end
    if gv.maxScale   ~= nil then maxScale   = gv.maxScale   end
    if gv.pulseSpeed ~= nil then pulseSpeed = gv.pulseSpeed end
    if gv.topOffset  ~= nil then topOffset  = gv.topOffset  end
    if gv.sideOffset ~= nil then sideOffset = gv.sideOffset end
end

-- Initialize once SavedVariables are available in vanilla (VARIABLES_LOADED) 
local ProcDocInitFrame = CreateFrame("Frame", "ProcDocInitFrame", UIParent)
ProcDocInitFrame:RegisterEvent("VARIABLES_LOADED")
ProcDocInitFrame:SetScript("OnEvent", function()
    ProcDoc_LoadGlobalsFromDB()
end)

local function GetActionProcDuration(spellName)
    if not spellName then return nil end
    local overrides = ProcDocDB.actionProcDurations
    if overrides and overrides[spellName] and overrides[spellName] > 0 then
        return overrides[spellName]
    end
    return ACTION_PROC_DEFAULT_DURATIONS[spellName]
end

-- 4) Alert frame pool

local alertFrames = {}

local function CreateAlertFrame(style)
    local alertObj = {}
    alertObj.isActive      = false
    alertObj.isActionBased = false    
    alertObj.style         = style
    alertObj.textures      = {}
    -- Timer related fields
    alertObj.sliceGroups   = {}   -- (legacy; unused after reverting wipe)
    alertObj.timerTexts    = {}   -- per base texture index -> fontstring
    alertObj.hasTimer      = false
    alertObj.procStartTime = nil
    alertObj.procDuration  = nil
    alertObj.zeroShown     = false
    alertObj.pulseAlpha    = minAlpha
    alertObj.pulseDir      = alphaStep

    -- Decide frame size and positions based on style
    if style == "TOP" or style == "TOP2" or style == "TOP_ROTATED" then
        alertObj.baseWidth  = 256
        alertObj.baseHeight = 128

        local tex = ProcDoc:CreateTexture(nil, "OVERLAY")
        local offsetY = (style == "TOP2") and (topOffset + 50) or topOffset
        tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
        tex:SetWidth(alertObj.baseWidth)
        tex:SetHeight(alertObj.baseHeight)
        tex:SetAlpha(0)
        if style == "TOP_ROTATED" then
            tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
        end
        tex:Hide()
        table.insert(alertObj.textures, tex)
    elseif style == "SIDES" or style == "SIDES2" then
        alertObj.baseWidth  = 128
        alertObj.baseHeight = 256

        local left = ProcDoc:CreateTexture(nil, "OVERLAY")
        local right = ProcDoc:CreateTexture(nil, "OVERLAY")

        local offsetX = (style == "SIDES2") and (sideOffset + 50) or sideOffset
        left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
        right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)

        left:SetWidth(alertObj.baseWidth)
        left:SetHeight(alertObj.baseHeight)
        left:SetAlpha(0)
        left:Hide()

        right:SetWidth(alertObj.baseWidth)
        right:SetHeight(alertObj.baseHeight)
        right:SetTexCoord(1, 0, 0, 1)
        right:SetAlpha(0)
        right:Hide()

        table.insert(alertObj.textures, left)
        table.insert(alertObj.textures, right)
    elseif style == "LEFT" then
        -- Single left-side vertical texture (same positioning as the LEFT half of SIDES2, no mirrored partner)
        alertObj.baseWidth  = 128
        alertObj.baseHeight = 256

        local tex = ProcDoc:CreateTexture(nil, "OVERLAY")
        local offsetX = sideOffset + 50 -- mimic SIDES2 left offset spacing
        tex:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
        tex:SetWidth(alertObj.baseWidth)
        tex:SetHeight(alertObj.baseHeight)
        tex:SetAlpha(0)
        tex:Hide()
        table.insert(alertObj.textures, tex)
    elseif style == "RIGHT" then
        -- Single right-side vertical texture (same positioning as the RIGHT half of SIDES2, mirrored)
        alertObj.baseWidth  = 128
        alertObj.baseHeight = 256

        local tex = ProcDoc:CreateTexture(nil, "OVERLAY")
        local offsetX = sideOffset + 50 -- mimic SIDES2 right offset spacing
        tex:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
        tex:SetWidth(alertObj.baseWidth)
        tex:SetHeight(alertObj.baseHeight)
        tex:SetTexCoord(1, 0, 0, 1) -- mirror horizontally
        tex:SetAlpha(0)
        tex:Hide()
        table.insert(alertObj.textures, tex)
    end

    return alertObj
end


-- Acquire a frame for either buff-based OR action-based usage
local function AcquireAlertFrame(style, isActionBased)
    for _, alertObj in ipairs(alertFrames) do
        if (not alertObj.isActive)
           and (alertObj.style == style)
           and (alertObj.isActionBased == isActionBased)
        then
            return alertObj
        end
    end
    local newAlert = CreateAlertFrame(style)
    newAlert.isActionBased = isActionBased
    table.insert(alertFrames, newAlert)
    return newAlert
end

-- Re-anchor an alert object's textures according to its style and current saved offsets
local function ProcDoc_ReanchorAlert(alertObj)
    if not alertObj or not alertObj.textures then return end
    local style = alertObj.style
    if style == "TOP" or style == "TOP2" or style == "TOP_ROTATED" then
        local tex = alertObj.textures[1]
        if tex then
            tex:ClearAllPoints()
            local offsetY = (style == "TOP2") and (topOffset + 50) or topOffset
            tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
        end
    elseif style == "SIDES" or style == "SIDES2" then
        local left  = alertObj.textures[1]
        local right = alertObj.textures[2]
        local offsetX = (style == "SIDES2") and (sideOffset + 50) or sideOffset
        if left then
            left:ClearAllPoints()
            left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
        end
        if right then
            right:ClearAllPoints()
            right:SetPoint("CENTER", UIParent, "CENTER",  offsetX, topOffset - 150)
        end
    elseif style == "LEFT" then
        local tex = alertObj.textures[1]
        if tex then
            tex:ClearAllPoints()
            tex:SetPoint("CENTER", UIParent, "CENTER", -(sideOffset + 50), topOffset - 150)
        end
    elseif style == "RIGHT" then
        local tex = alertObj.textures[1]
        if tex then
            tex:ClearAllPoints()
            tex:SetPoint("CENTER", UIParent, "CENTER",  (sideOffset + 50), topOffset - 150)
        end
    end
end

--------------------------------------------
-- HELPER: Play proc sound with user volume
--------------------------------------------
local function ProcDoc_PlayAlertSound()
    if ProcDocDB.globalVars.isMuted then
        return
    end

    local desiredVolume = ProcDocDB.globalVars.soundVolume or 1.0
    if desiredVolume < 0 then desiredVolume = 0 end
    if desiredVolume > 1 then desiredVolume = 1 end

    local oldVolume = GetCVar("SoundVolume")
    SetCVar("SoundVolume", tostring(desiredVolume))

    PlaySoundFile("Interface\\AddOns\\ProcDoc\\img\\SpellAlert.ogg", "SFX")

    -- Immediately restore
    SetCVar("SoundVolume", oldVolume)
end


-- 5) OnUpdate pulse logic (handles alpha/scale pulsing and optional timer text)
-- NOTE: Frequent use of the live GameTooltip for buff scanning will instantly hide
-- any tooltip the player is viewing (items, NPCs, etc.). To avoid this we create
-- our own hidden tooltip and never call GameTooltip:Hide() during scans.
if not ProcDocScanTooltip then
    ProcDocScanTooltip = CreateFrame("GameTooltip","ProcDocScanTooltip",UIParent,"GameTooltipTemplate")
    ProcDocScanTooltip:Hide()
end

local function OnUpdateHandler()
    if maxAlpha <= minAlpha then maxAlpha = minAlpha + 0.01 end
    if maxScale <= minScale then maxScale = minScale + 0.01 end

    local now = GetTime()
    -- Periodic capture of current buff remaining times so we can detect mid-duration refreshes
    if not ProcDoc._lastBuffTimeScan then ProcDoc._lastBuffTimeScan = 0 end
    if not ProcDoc.currentBuffTimes then ProcDoc.currentBuffTimes = {} end
    if (now - ProcDoc._lastBuffTimeScan) > 0.30 then -- throttle ~3 times per second
        local snapshot = {}
        if GetPlayerBuffTimeLeft then
            for i = 0, 31 do
                local tex = GetPlayerBuffTexture(i)
                if tex then
                    ProcDocScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    ProcDocScanTooltip:SetPlayerBuff(i)
                    local bName = (ProcDocScanTooltipTextLeft1 and ProcDocScanTooltipTextLeft1:GetText()) or ""
                    ProcDocScanTooltip:Hide()
                    if bName ~= "" then
                        local tl = GetPlayerBuffTimeLeft(i)
                        if tl and tl > 0 then
                            -- keep the largest remaining (some servers may duplicate icons)
                            if (not snapshot[bName]) or (tl > snapshot[bName]) then
                                snapshot[bName] = tl
                            end
                        end
                    end
                end
            end
        end
        ProcDoc.currentBuffTimes = snapshot
        ProcDoc._lastBuffTimeScan = now
    end
    for _, alertObj in ipairs(alertFrames) do
        if alertObj.isActive then
            -- Pulse update
            alertObj.pulseAlpha = alertObj.pulseAlpha + (alertObj.pulseDir * pulseSpeed)
            if alertObj.pulseAlpha < minAlpha then
                alertObj.pulseAlpha = minAlpha
                alertObj.pulseDir   = alphaStep
            elseif alertObj.pulseAlpha > maxAlpha then
                alertObj.pulseAlpha = maxAlpha
                alertObj.pulseDir   = -alphaStep
            end

            local scale = 1.0
            local aRange = maxAlpha - minAlpha
            if aRange > 0 then
                local frac = (alertObj.pulseAlpha - minAlpha) / aRange
                scale = minScale + frac * (maxScale - minScale)
            end

            -- Apply pulse to textures
            for _, tex in ipairs(alertObj.textures) do
                tex:SetAlpha(alertObj.pulseAlpha)
                tex:SetWidth(alertObj.baseWidth * scale)
                tex:SetHeight(alertObj.baseHeight * scale)
                tex:Show()
            end

            -- Timer countdown text
            if alertObj.hasTimer and alertObj.procDuration and alertObj.procStartTime then
                -- Refresh detection: if the buff was re-applied (remaining time jumped up), reset timer
                if (not alertObj.isActionBased) and alertObj.buffName and ProcDoc.currentBuffTimes then
                    local observedTL = ProcDoc.currentBuffTimes[alertObj.buffName]
                    if observedTL and observedTL > 0 then
                        local elapsedSoFar = now - alertObj.procStartTime
                        local remainingPrev = alertObj.procDuration - elapsedSoFar
                        if remainingPrev < 0 then remainingPrev = 0 end
                        -- If the newly observed time left exceeds previous remaining by >0.5s treat as refresh
                        if (observedTL - remainingPrev) > 0.5 then
                            alertObj.procStartTime = now
                            alertObj.procDuration  = observedTL
                            alertObj.zeroShown     = false
                        end
                    end
                end
                local elapsed   = now - alertObj.procStartTime
                local remaining = alertObj.procDuration - elapsed
                local secs
                if remaining <= 0 then
                    secs = 0
                    if alertObj.zeroShown then
                        -- Now hide after showing 0 previously
                        alertObj.isActive      = false
                        alertObj.hasTimer      = false
                        alertObj.procStartTime = nil
                        alertObj.procDuration  = nil
                        alertObj.forceHide     = true
                        for _, tex in ipairs(alertObj.textures) do tex:Hide() end
                        if alertObj.timerTexts then
                            for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
                        end
                    else
                        alertObj.zeroShown = true
                    end
                else
                    -- Display remaining seconds (use floor so we reach 0)
                    secs = math.floor(remaining + 0.0001)
                    if secs < 0 then secs = 0 end
                end
                if alertObj.isActive and secs ~= nil then
                    for _, fs in ipairs(alertObj.timerTexts) do
                        if fs then
                            fs:SetText(secs)
                            if timerTextAlpha then fs:SetAlpha(timerTextAlpha) end
                            fs:Show()
                        end
                    end
                end
            else
                -- No timer -> hide any stray timer texts
                if alertObj.timerTexts then
                    for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
                end
            end
        end
        -- If frame is inactive but leftover timer text somehow visible, hide it
        if (not alertObj.isActive) and alertObj.timerTexts then
            for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
        end
    end
end

ProcDoc:SetScript("OnUpdate", OnUpdateHandler)
ProcDoc:SetWidth(1)
ProcDoc:SetHeight(1)
ProcDoc:SetPoint("CENTER", UIParent, "CENTER")

-- 6) Merge buff & action proc definitions for the player's class
local _, playerClass = UnitClass("player")

local normalProcs  = PROC_DATA[playerClass] or {}
local actionProcs  = ACTION_PROCS[playerClass] or {}  -- e.g. Overpower

-- Merge them into one big “classProcs” table
local classProcs = {}
for _, p in ipairs(normalProcs) do
    table.insert(classProcs, p)
end
for _, q in ipairs(actionProcs) do
    table.insert(classProcs, q)
end

-- 7) Buff-based detection

-- Holds which buff names we’ve already played a sound for.
local knownBuffProcs = {}
local buffStackCounts = {}

local function CheckProcs()
    -- Ensure we are using the latest saved globals each time we show/update alerts
    if ProcDoc_LoadGlobalsFromDB then ProcDoc_LoadGlobalsFromDB() end
    -- 1) Hide any old (buff-based) frames first
    for _, alertObj in ipairs(alertFrames) do
        if (not alertObj.isActionBased) then
            alertObj.isActive = false
            for _, tex in ipairs(alertObj.textures) do tex:Hide() end
            if alertObj.timerTexts then
                for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
            end
            if alertObj.stackText then alertObj.stackText:Hide() end
            alertObj.hasTimer      = false
            alertObj.procStartTime = nil
            alertObj.procDuration  = nil
            alertObj.buffName      = nil
        end
    end

    -- 2) Gather a list of all currently active buff-based procs
    local activeBuffProcs = {}
    local activeBuffNames = {}  -- just the names, for quick “did it fall off?” checks

    local hotStreakStacks = 0
    buffStackCounts = {}
    for i = 0, 31 do
        local buffTexture = GetPlayerBuffTexture(i)
        if buffTexture then
            ProcDocScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            ProcDocScanTooltip:SetPlayerBuff(i)
            local buffName = (ProcDocScanTooltipTextLeft1 and ProcDocScanTooltipTextLeft1:GetText()) or ""
            local stackGuess = 0
            -- Vanilla 1.12: stacks often appear as right text or in second left line; attempt simple numeric parse
            if ProcDocScanTooltipTextRight1 and ProcDocScanTooltipTextRight1:GetText() then
                local rn = tonumber(ProcDocScanTooltipTextRight1:GetText())
                if rn then stackGuess = rn end
            end
            if stackGuess == 0 and ProcDocScanTooltipTextLeft2 and ProcDocScanTooltipTextLeft2:GetText() then
                local ln2 = ProcDocScanTooltipTextLeft2:GetText()
                local ln2n = tonumber(ln2)
                if ln2n then stackGuess = ln2n end
            end
            -- Prefer GetPlayerBuffApplications for Astral Boon / Natural Boon (reliable charges)
            if GetPlayerBuffApplications and (buffName == "Astral Boon" or buffName == "Natural Boon") then
                local apiStacks = GetPlayerBuffApplications(i)
                if apiStacks and apiStacks > 0 then
                    stackGuess = apiStacks
                end
            end
            ProcDocScanTooltip:Hide()

            for _, procInfo in ipairs(normalProcs) do
                if ProcDocDB.procsEnabled[procInfo.buffName] ~= false then
                    if (procInfo.texture == nil or buffTexture == procInfo.texture) and (buffName == procInfo.buffName) then
                        table.insert(activeBuffProcs, procInfo)
                        activeBuffNames[procInfo.buffName] = true
                        -- Store stack count if any (>=1 valid)
                        if stackGuess and stackGuess >= 1 then
                            buffStackCounts[buffName] = stackGuess
                        end
                    end
                end
            end
            -- Hot Streak detection (fuzzy, allow lowercase compare, handle possible rank suffixes)
            if buffName ~= "" then
                local lowerName = string.lower(buffName)
                if lowerName == string.lower(HOT_STREAK_BUFF_NAME) or string.find(lowerName, "hot streak") then
                    local apiStacks
                    if GetPlayerBuffApplications then
                        apiStacks = GetPlayerBuffApplications(i)
                    end
                    local stacks = apiStacks or stackGuess
                    if not stacks or stacks < 1 then stacks = 1 end
                    if stacks > hotStreakStacks then hotStreakStacks = stacks end
                end
            end
        end
    end

    -- 3) Show frames for each active buff
    for _, procInfo in ipairs(activeBuffProcs) do
        local style   = procInfo.alertStyle or "SIDES"
    local alertObj = AcquireAlertFrame(style, false)
        alertObj.isActive   = true
        alertObj.pulseAlpha = minAlpha
        alertObj.pulseDir   = alphaStep
        alertObj.hasTimer      = false
        alertObj.procStartTime = nil
        alertObj.procDuration  = nil
    alertObj.buffName      = procInfo.buffName

        local path = procInfo.alertTexturePath or DEFAULT_ALERT_TEXTURE
        for _, tex in ipairs(alertObj.textures) do
            tex:SetTexture(path)
            tex:SetAlpha(minAlpha)
            tex:SetWidth(alertObj.baseWidth * minScale)
            tex:SetHeight(alertObj.baseHeight * minScale)
            tex:Show()
        end
    ProcDoc_ReanchorAlert(alertObj)
        ProcDoc_ReanchorAlert(alertObj)

    -- Timer numeric countdown (replaces prior vertical wipe implementation)
        local timeLeft
        if GetPlayerBuffTimeLeft then
            for i = 0, 31 do
                local bTex = GetPlayerBuffTexture(i)
                if bTex then
                    ProcDocScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    ProcDocScanTooltip:SetPlayerBuff(i)
                    local bName = (ProcDocScanTooltipTextLeft1 and ProcDocScanTooltipTextLeft1:GetText()) or ""
                    ProcDocScanTooltip:Hide()
                    if bName == procInfo.buffName then
                        local tl = GetPlayerBuffTimeLeft(i)
                        if tl and tl > 0 then
                            timeLeft = tl
                        end
                        break
                    end
                end
            end
        end
        if (not ProcDocDB.globalVars.disableTimers) and timeLeft and timeLeft > 0 then
            alertObj.hasTimer      = true
            alertObj.procStartTime = GetTime()
            alertObj.procDuration  = timeLeft
            alertObj.zeroShown     = false
            -- Create/ensure timer font strings (one per base texture)
            for idx, baseTex in ipairs(alertObj.textures) do
                if not alertObj.timerTexts[idx] then
                    local parentFrame = baseTex:GetParent() or ProcDoc or UIParent
                    local fs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    local xShift = 0
                    if procInfo.buffName == "Astral Boon" then
                        xShift = -45 -- left side
                    elseif procInfo.buffName == "Natural Boon" then
                        xShift = 45  -- right side
                    end
                    fs:SetPoint("CENTER", baseTex, "CENTER", xShift, 0)
                    fs:SetTextColor(1, 1, 0, 1)
                    if timerTextAlpha then fs:SetAlpha(timerTextAlpha) end
                    fs:SetText("")
                    alertObj.timerTexts[idx] = fs
                else
                    if procInfo.buffName == "Astral Boon" then
                        local fs = alertObj.timerTexts[idx]; fs:ClearAllPoints(); fs:SetPoint("CENTER", alertObj.textures[idx], "CENTER", -45, 0)
                    elseif procInfo.buffName == "Natural Boon" then
                        local fs = alertObj.timerTexts[idx]; fs:ClearAllPoints(); fs:SetPoint("CENTER", alertObj.textures[idx], "CENTER", 45, 0)
                    end
                end
            end
            -- Stack displays (Astral Boon left, Natural Boon right; stacks above respective shifted timers)
            if procInfo.buffName == "Astral Boon" or procInfo.buffName == "Natural Boon" then
                local stacks = buffStackCounts[procInfo.buffName]
                if stacks and stacks >= 1 then
                    local anchorFS = alertObj.timerTexts[1]
                    if anchorFS then
                        if not alertObj.stackText then
                            local parentFrame = anchorFS:GetParent() or ProcDoc or UIParent
                            local sfs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                            sfs:SetTextColor(1,1,1,1)
                            if timerTextAlpha then sfs:SetAlpha(timerTextAlpha) end
                            alertObj.stackText = sfs
                        end
                        alertObj.stackText:ClearAllPoints()
                        -- Center directly above the timer (no horizontal offset)
                        alertObj.stackText:SetPoint("BOTTOM", anchorFS, "TOP", 0, 2)
                        alertObj.stackText:SetText(stacks)
                        alertObj.stackText:Show()
                    end
                else
                    if alertObj.stackText then alertObj.stackText:Hide() end
                end
            elseif alertObj.stackText then
                alertObj.stackText:Hide()
            end
        else
            -- Ensure timer texts hidden if no duration
            if alertObj.timerTexts then
                for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
            end
            if alertObj.stackText then alertObj.stackText:Hide() end
        end

        -- 4) If this is a newly gained buff, play the sound (if not muted).
        local bName = procInfo.buffName
        if not knownBuffProcs[bName] then
            if not ProcDocDB.globalVars.isMuted then
                ProcDoc_PlayAlertSound()
            end
            knownBuffProcs[bName] = true
        end
    end

    -- 5) Remove any old buff from knownBuffProcs that has fallen off
    for bName in pairs(knownBuffProcs) do
        if not activeBuffNames[bName] then
            knownBuffProcs[bName] = nil
        end
    end

    -- 6) Hot Streak tier visuals (3=LEFT, 4=LEFT+RIGHT, 5=LEFT+RIGHT+TOP)
    if playerClass == "MAGE" and ProcDocDB.procsEnabled[HOT_STREAK_BUFF_NAME] ~= false then
        local tier = 0
        if hotStreakStacks >= 5 then tier = 5 elseif hotStreakStacks == 4 then tier = 4 elseif hotStreakStacks == 3 then tier = 3 end

        -- Hide previous tier frames if tier dropped or returned to 0
        if tier == 0 and hotStreakLastTier ~= 0 then
            for _, alertObj in ipairs(alertFrames) do
                if alertObj.isActive and (alertObj.style == "LEFT" or alertObj.style == "RIGHT" or alertObj.style == "TOP" or alertObj.style == "TOP2") then
                    -- Only hide those using our Hot Streak textures
                    local hide = false
                    for _, tex in ipairs(alertObj.textures) do
                        local tPath = tex:GetTexture()
                        if tPath == HOT_STREAK_SIDE_TEXTURE or tPath == HOT_STREAK_TOP_TEXTURE then hide = true break end
                    end
                    if hide then
                        alertObj.isActive = false
                        for _, tex in ipairs(alertObj.textures) do tex:Hide() end
                    end
                end
            end
        end

        if tier >= 3 then
            -- LEFT
            local leftObj = AcquireAlertFrame("LEFT", false)
            leftObj.isActive = true
            leftObj.pulseAlpha = minAlpha
            leftObj.pulseDir = alphaStep
            for _, tex in ipairs(leftObj.textures) do
                tex:SetTexture(HOT_STREAK_SIDE_TEXTURE)
                tex:SetAlpha(minAlpha)
                tex:SetWidth(leftObj.baseWidth * minScale)
                tex:SetHeight(leftObj.baseHeight * minScale)
                tex:Show()
            end
            ProcDoc_ReanchorAlert(leftObj)
        end
        if tier >= 4 then
            -- RIGHT
            local rightObj = AcquireAlertFrame("RIGHT", false)
            rightObj.isActive = true
            rightObj.pulseAlpha = minAlpha
            rightObj.pulseDir = alphaStep
            for _, tex in ipairs(rightObj.textures) do
                tex:SetTexture(HOT_STREAK_SIDE_TEXTURE)
                tex:SetAlpha(minAlpha)
                tex:SetWidth(rightObj.baseWidth * minScale)
                tex:SetHeight(rightObj.baseHeight * minScale)
                tex:Show()
            end
            ProcDoc_ReanchorAlert(rightObj)
        end
        if tier >= 5 then
            -- TOP (use TOP2 for spacing consistency with existing top visuals)
            local topObj = AcquireAlertFrame("TOP2", false)
            topObj.isActive = true
            topObj.pulseAlpha = minAlpha
            topObj.pulseDir = alphaStep
            for _, tex in ipairs(topObj.textures) do
                tex:SetTexture(HOT_STREAK_TOP_TEXTURE)
                tex:SetAlpha(minAlpha)
                tex:SetWidth(topObj.baseWidth * minScale)
                tex:SetHeight(topObj.baseHeight * minScale)
                tex:Show()
            end
            ProcDoc_ReanchorAlert(topObj)
        end

        -- Play sound only on entering a new tier (avoid spam every scan)
        if tier ~= 0 and tier ~= hotStreakLastTier then
            if not ProcDocDB.globalVars.isMuted then ProcDoc_PlayAlertSound() end
        end
        hotStreakLastTier = tier
    end
end




-- 8) Action-based detection (per-ability usability checks)
--    Track states per ability
local actionProcStates = {}

local function ShowActionProcAlert(actionProc)
    -- Sync from DB so we don't rely on options frame being opened first
    if ProcDoc_LoadGlobalsFromDB then ProcDoc_LoadGlobalsFromDB() end
    local spellName  = actionProc.spellName or "UnknownSpell"
    local state      = actionProcStates[spellName] or {}
    actionProcStates[spellName] = state

    local alertObj   = state.alertObj
    if alertObj and alertObj.isActive then
        -- Already showing, don't restart the animation - just ensure it stays active
        -- (Do nothing to pulseAlpha/pulseDir to keep animation smooth)
    else
        -- Acquire a new alert frame for isActionBased = true
        alertObj = AcquireAlertFrame(actionProc.alertStyle or "SIDES", true)
        alertObj.isActive   = true
        alertObj.pulseAlpha = minAlpha
        alertObj.pulseDir   = alphaStep

        local path = actionProc.alertTexturePath or actionProc.texture or DEFAULT_ALERT_TEXTURE
        for _, tex in ipairs(alertObj.textures) do
            tex:SetTexture(path)
            tex:SetAlpha(minAlpha)
            tex:SetWidth(alertObj.baseWidth * minScale)
            tex:SetHeight(alertObj.baseHeight * minScale)
            tex:Show()
        end

        if not ProcDocDB.globalVars.isMuted then
            ProcDoc_PlayAlertSound()
        end

        -- Initialize timer if duration configured and timers enabled
        alertObj.hasTimer      = false
        alertObj.procStartTime = nil
        alertObj.procDuration  = nil
        if (not ProcDocDB.globalVars.disableTimers) then
            local duration = GetActionProcDuration(spellName)
            if duration then
                alertObj.hasTimer      = true
                alertObj.procStartTime = GetTime()
                alertObj.procDuration  = duration
                alertObj.zeroShown     = false
                for idx, baseTex in ipairs(alertObj.textures) do
                    if not alertObj.timerTexts[idx] then
                        local parentFrame = baseTex:GetParent() or ProcDoc or UIParent
                        local fs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                        fs:SetPoint("CENTER", baseTex, "CENTER", 0, 0)
                        fs:SetTextColor(1,1,0,1)
                        fs:SetText("")
                        alertObj.timerTexts[idx] = fs
                    end
                end
            end
        end

        state.alertObj = alertObj
    end

    state.isActive = true
end

local function HideActionProcAlert(actionProc)
    local spellName = actionProc.spellName or "UnknownSpell"
    local state     = actionProcStates[spellName]
    if not state or not state.isActive then
        return
    end

    local alertObj = state.alertObj
    if alertObj and alertObj.isActive then
        alertObj.isActive = false
        for _, tex in ipairs(alertObj.textures) do tex:Hide() end
        if alertObj.timerTexts then
            for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
        end
    end
    state.isActive = false
end

-- Helper: find a spellbook index by exact name (vanilla 1.12 compatible)
local function FindSpellBookIndexByName(spellName)
    if not spellName then return nil end
    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    for t = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(t)
        if offset and numSpells then
            for i = offset + 1, offset + numSpells do
                local sName = GetSpellName(i, BOOKTYPE_SPELL or "spell")
                if sName == spellName then
                    return i
                end
            end
        end
    end
    return nil
end

-- Spellbook-driven action proc checks (for abilities that should show when off cooldown while in combat)
local function UpdateSpellbookActionProcs()
    if playerClass ~= "PALADIN" then return end
    for _, actionProc in ipairs(actionProcs) do
        if actionProc.useSpellbook and ProcDocDB.procsEnabled[actionProc.buffName] ~= false then
            local inCombat = (UnitAffectingCombat and UnitAffectingCombat("player")) or inCombatFlag
            if not inCombat then
                HideActionProcAlert(actionProc)
            else
                local idx = FindSpellBookIndexByName(actionProc.spellName)
                if idx then
                    local start, duration, enable = GetSpellCooldown(idx, BOOKTYPE_SPELL or "spell")
                    -- Ready if duration == 0 (ignore GCD as a cooldown requirement)
                    local ready = (duration == 0)
                    if ready then
                        ShowActionProcAlert(actionProc)
                    else
                        HideActionProcAlert(actionProc)
                    end
                else
                    -- Spell not found, ensure hidden
                    HideActionProcAlert(actionProc)
                end
            end
        elseif actionProc.useSpellbook == true and ProcDocDB.procsEnabled[actionProc.buffName] == false then
            -- Explicitly hidden by user
            HideActionProcAlert(actionProc)
        end
    end
end

local function FindActionSlotAndCheck(actionProc)
    local spellName = actionProc.spellName or "UnknownSpell"
    local texPath   = actionProc.texture or ""
    if texPath == "" then
        return
    end

    -- find slot
    local foundSlot = nil
    for slot = 1, 120 do
        local actionTex = GetActionTexture(slot)
        if actionTex then
            local lowerActionTex = string.lower(actionTex)
            local lowerWanted    = string.lower(texPath)
            if lowerActionTex == lowerWanted then
                foundSlot = slot
                break
            end
        end
    end

    local state = actionProcStates[spellName] or {}
    actionProcStates[spellName] = state

    state.slot = foundSlot
    if not foundSlot then
        -- if previously active, hide
        if state.isActive then
            HideActionProcAlert(actionProc)
        end
        return
    end

    local usable = IsUsableAction(foundSlot)
    if usable then
        if not state.isActive then
            ShowActionProcAlert(actionProc)
        end
    else
        if state.isActive then
            HideActionProcAlert(actionProc)
        end
    end
end

local function CheckAllActionProcs()
    for _, actionProc in ipairs(actionProcs) do
        -- skip if disabled
        if ProcDocDB.procsEnabled[actionProc.buffName] ~= false then
            -- If the underlying alertObj was force hidden (timer expiry), clear state to allow re-trigger
            local st = actionProcStates[actionProc.spellName or actionProc.buffName]
            if st and st.alertObj and st.alertObj.forceHide then
                st.isActive = false
                st.alertObj.forceHide = nil
            end
            FindActionSlotAndCheck(actionProc)
        else
            -- if it's currently active, hide it
            HideActionProcAlert(actionProc)
        end
    end
end



-- 9) Event frame for action-based procs

-- Fallback combat flag for clients without UnitAffectingCombat
local inCombatFlag = false

-- Periodic timer for spellbook cooldown checking
local spellbookCheckFrame = CreateFrame("Frame", "ProcDocSpellbookFrame", UIParent)
local lastSpellbookCheck = 0
local SPELLBOOK_CHECK_INTERVAL = 0.1  -- Check every 0.5 seconds

spellbookCheckFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if (now - lastSpellbookCheck) >= SPELLBOOK_CHECK_INTERVAL then
        -- Only check if in combat AND we have spellbook procs that are currently down
        local inCombat = (UnitAffectingCombat and UnitAffectingCombat("player")) or inCombatFlag
        if inCombat and playerClass == "PALADIN" then
            local needsCheck = false
            -- Check if any spellbook-based procs are currently down but enabled
            for _, actionProc in ipairs(actionProcs) do
                if actionProc.useSpellbook and ProcDocDB.procsEnabled[actionProc.buffName] ~= false then
                    local state = actionProcStates[actionProc.spellName or actionProc.buffName]
                    if not state or not state.isActive then
                        needsCheck = true
                        break
                    end
                end
            end
            
            if needsCheck then
                UpdateSpellbookActionProcs()
            end
        end
        lastSpellbookCheck = now
    end
end)

-- If your older client needs the old style event usage, do the "global event" trick:
local actionFrame = CreateFrame("Frame", "ProcDocActionFrame", UIParent)
actionFrame:RegisterEvent("PLAYER_LOGIN")
actionFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
actionFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
actionFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
actionFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
actionFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
actionFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
actionFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
actionFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
actionFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

actionFrame:SetScript("OnEvent", function()
    local e   = event
    local a1  = arg1
    local a2  = arg2
    local a3  = arg3

    if e == "PLAYER_LOGIN" then
        CheckAllActionProcs()
        CheckProcs()  -- run buff-based as well
    UpdateSpellbookActionProcs()
    elseif e == "ACTIONBAR_PAGE_CHANGED"
        or e == "UPDATE_BONUS_ACTIONBAR"
        or e == "UPDATE_SHAPESHIFT_FORM"
        or e == "PLAYER_TARGET_CHANGED"
    or e == "ACTIONBAR_UPDATE_USABLE"
    or e == "ACTIONBAR_UPDATE_COOLDOWN"
    or e == "PLAYER_REGEN_DISABLED"
    or e == "PLAYER_REGEN_ENABLED"
    then
    if e == "PLAYER_REGEN_DISABLED" then inCombatFlag = true end
    if e == "PLAYER_REGEN_ENABLED"  then inCombatFlag = false end
        CheckAllActionProcs()
    UpdateSpellbookActionProcs()
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        -- if we just cast Overpower / Riposte / Arcane Surge, hide them
        for _, actionProc in ipairs(actionProcs) do
            if a1 == "player" and (a2 == actionProc.spellName) then
                HideActionProcAlert(actionProc)
            end
        end
    CheckAllActionProcs()
    UpdateSpellbookActionProcs()
    end
end)


-- 10) Aura change event (buff-based proc refresh)
-- Also old-style event usage if needed:
local auraFrame = CreateFrame("Frame", "ProcDocAuraFrame", UIParent)
auraFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
auraFrame:SetScript("OnEvent", function()
    CheckProcs()

end)

-- Class colors for chat messages
local CLASS_COLORS = {
    ["WARRIOR"]     = "ffc79c6e",  -- Tan
    ["PALADIN"]     = "fff58cba",  -- Pink
    ["HUNTER"]      = "ffabd473",  -- Green
    ["ROGUE"]       = "fffff569",  -- Yellow
    ["PRIEST"]      = "ffffffff",  -- White
    ["SHAMAN"]      = "ff0070de",  -- Blue
    ["MAGE"]        = "ff69ccf0",  -- Light Blue
    ["WARLOCK"]     = "ff9482c9",  -- Purple
    ["DRUID"]       = "ffff7d0a",  -- Orange
}

local classColor = CLASS_COLORS[playerClass] or "ffffffff"
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ProcDoc|r Loaded. Tracking procs for |c"..classColor..(UnitClass("player")).."|r. Type |cff00ffff/procdoc|r for options.")
-- 11) Test proc + options frame helpers
local testProcActive = false
local testProcAlertObj = nil
local testProcAlerts = {}  

local function RefreshTestProc()
    for buffName, alertObj in pairs(testProcAlerts) do
        if alertObj.isActive then
            if alertObj.style == "TOP" or alertObj.style == "TOP2" or alertObj.style == "TOP_ROTATED" then
                local tex = alertObj.textures[1]
                tex:ClearAllPoints()
                local offsetY = (alertObj.style == "TOP2") and (topOffset + 50) or topOffset
                tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
            elseif alertObj.style == "SIDES" or alertObj.style == "SIDES2" then
                local left = alertObj.textures[1]
                local right = alertObj.textures[2]

                local offsetX = (alertObj.style == "SIDES2") and (sideOffset + 50) or sideOffset
                left:ClearAllPoints()
                left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)

                right:ClearAllPoints()
                right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
            elseif alertObj.style == "LEFT" then
                local tex = alertObj.textures[1]
                tex:ClearAllPoints()
                local offsetX = sideOffset + 50
                tex:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
            elseif alertObj.style == "RIGHT" then
                local tex = alertObj.textures[1]
                tex:ClearAllPoints()
                local offsetX = sideOffset + 50
                tex:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
            end
        end
    end

    if testProcActive and testProcAlertObj then
        -- Update base alpha/scale
        if not minAlpha then minAlpha = 0.6 end
        if not maxAlpha then maxAlpha = 1.0 end
        if not minScale then minScale = 0.8 end
        if not maxScale then maxScale = 1.0 end

        -- Re-anchor the test proc based on its style
        if testProcAlertObj.style == "TOP" or testProcAlertObj.style == "TOP2" or testProcAlertObj.style == "TOP_ROTATED" then
            local tex = testProcAlertObj.textures[1]
            tex:ClearAllPoints()
            local offsetY = (testProcAlertObj.style == "TOP2") and (topOffset + 50) or topOffset
            tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
        elseif testProcAlertObj.style == "SIDES" or testProcAlertObj.style == "SIDES2" then
            local left = testProcAlertObj.textures[1]
            local right = testProcAlertObj.textures[2]

            local offsetX = (testProcAlertObj.style == "SIDES2") and (sideOffset + 50) or sideOffset
            left:ClearAllPoints()
            left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)

            right:ClearAllPoints()
            right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
        elseif testProcAlertObj.style == "LEFT" then
            local tex = testProcAlertObj.textures[1]
            tex:ClearAllPoints()
            local offsetX = sideOffset + 50
            tex:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
        elseif testProcAlertObj.style == "RIGHT" then
            local tex = testProcAlertObj.textures[1]
            tex:ClearAllPoints()
            local offsetX = sideOffset + 50
            tex:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
        end

        -- Apply alpha & size
        for _, tex in ipairs(testProcAlertObj.textures) do
            tex:SetAlpha(minAlpha)
            tex:SetWidth(testProcAlertObj.baseWidth * minScale)
            tex:SetHeight(testProcAlertObj.baseHeight * minScale)
            tex:Show()
        end

        -- Reset the pulse animation
        testProcAlertObj.pulseAlpha = minAlpha
        testProcAlertObj.pulseDir = alphaStep

        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[ProcDoc]|r Test proc refreshed with updated offsets.")
    end
end



-- 12) Multi-test alerts (for previewing multiple proc visuals)

local function ShowTestBuffAlert(procInfo)
    local style = procInfo.alertStyle or "SIDES"

    -- Sync current globals from saved DB so test uses persisted values
    if ProcDocDB and ProcDocDB.globalVars then
        local gv = ProcDocDB.globalVars
        if gv.minAlpha then minAlpha = gv.minAlpha end
        if gv.maxAlpha then maxAlpha = gv.maxAlpha end
        if gv.minScale then minScale = gv.minScale end
        if gv.maxScale then maxScale = gv.maxScale end
        if gv.pulseSpeed then pulseSpeed = gv.pulseSpeed end
        if gv.topOffset then topOffset = gv.topOffset end
        if gv.sideOffset then sideOffset = gv.sideOffset end
    end

    -- If this buff's alert is already active, reuse it:
    local alertObj = testProcAlerts[procInfo.buffName]
    if alertObj and alertObj.isActive then
        alertObj.pulseAlpha = minAlpha
        alertObj.pulseDir   = alphaStep
    else
        -- Otherwise, acquire a new alert frame
    alertObj = AcquireAlertFrame(style, false)
        alertObj.isActive   = true
        alertObj.pulseAlpha = minAlpha
        alertObj.pulseDir   = alphaStep

        -- Assign textures
        local alertPath = procInfo.alertTexturePath or DEFAULT_ALERT_TEXTURE
        for _, tex in ipairs(alertObj.textures) do
            tex:SetTexture(alertPath)
            tex:SetAlpha(minAlpha)
            tex:SetWidth(alertObj.baseWidth * minScale)
            tex:SetHeight(alertObj.baseHeight * minScale)
            tex:Show()
        end

        -- Store it so we can hide/update later
        testProcAlerts[procInfo.buffName] = alertObj
    end

    -- Now re-anchor based on style
    if style == "TOP" or style == "TOP2" or style == "TOP_ROTATED" then
        local tex = alertObj.textures[1]
        local offsetY = (style == "TOP2") and (topOffset + 50) or topOffset
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
    elseif style == "SIDES" or style == "SIDES2" then
        local left  = alertObj.textures[1]
        local right = alertObj.textures[2]

        local offsetX = (style == "SIDES2") and (sideOffset + 50) or sideOffset
        left:ClearAllPoints()
        left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)

        right:ClearAllPoints()
        right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
    elseif style == "LEFT" then
        local tex = alertObj.textures[1]
        tex:ClearAllPoints()
        local offsetX = sideOffset + 50
        tex:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
    elseif style == "RIGHT" then
        local tex = alertObj.textures[1]
        tex:ClearAllPoints()
        local offsetX = sideOffset + 50
        tex:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
    end

    -- Apply final sizing to ensure any reused frame updates (important after reload)
    for _, tex in ipairs(alertObj.textures) do
        tex:SetAlpha(minAlpha)
        tex:SetWidth(alertObj.baseWidth * minScale)
        tex:SetHeight(alertObj.baseHeight * minScale)
    end
end



local function HideTestBuffAlert(procInfo)
    local alertObj = testProcAlerts[procInfo.buffName]
    if alertObj and alertObj.isActive then
        alertObj.isActive = false
        for _, tex in ipairs(alertObj.textures) do tex:Hide() end
        if alertObj.timerTexts then
            for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
        end
        testProcAlerts[procInfo.buffName] = nil
    end
end

-- 13) Options UI
local function CreateProcDocOptionsFrame()


    -- Safety: Make sure we have procsEnabled
    if not ProcDocDB then
        ProcDocDB = {}
    end
    if not ProcDocDB.procsEnabled then
        ProcDocDB.procsEnabled = {}
    end
    if not ProcDocDB.globalVars then
        ProcDocDB.globalVars = {}
    end

    -- Sync current tuning globals from saved DB BEFORE first-time slider creation
    do
        local gv = ProcDocDB.globalVars
        if gv.minAlpha      ~= nil then minAlpha    = gv.minAlpha end
        if gv.maxAlpha      ~= nil then maxAlpha    = gv.maxAlpha end
        if gv.minScale      ~= nil then minScale    = gv.minScale end
        if gv.maxScale      ~= nil then maxScale    = gv.maxScale end
        if gv.pulseSpeed    ~= nil then pulseSpeed  = gv.pulseSpeed end
        if gv.topOffset     ~= nil then topOffset   = gv.topOffset end
        if gv.sideOffset    ~= nil then sideOffset  = gv.sideOffset end
        -- Backwards compatibility: if old field names existed, migrate (example: maxSize->maxScale)
        if gv.maxSize and not gv.maxScale then
            maxScale = gv.maxSize
            gv.maxScale = gv.maxSize
            gv.maxSize = nil
        end
    end
    
    if not ProcDocOptionsFrame then
        local f = CreateFrame("Frame", "ProcDocOptionsFrame", UIParent)
        f:SetWidth(340)
        -- Height will be set dynamically later once we know proc count
        f:SetHeight(600)
        f:SetPoint("CENTER", UIParent, "CENTER", -360, 0)
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile     = true,
            tileSize = 16,
            edgeSize = 16,
            insets   = { left=4, right=4, top=4, bottom=4 },
        })
        f:SetBackdropColor(0, 0, 0, 0.8)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() f:StartMoving() end)
        f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
        
    -- Top (static) settings section (sliders / primary checkboxes)
        local TOP_SECTION_HEIGHT = 450  -- approximate space needed for all sliders & first row of checkboxes
        local sectionFrame = CreateFrame("Frame", nil, f)
        sectionFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -30)
        sectionFrame:SetWidth(f:GetWidth() - 30)
        sectionFrame:SetHeight(TOP_SECTION_HEIGHT)
        sectionFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        sectionFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
        sectionFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        table.insert(UISpecialFrames, "ProcDocOptionsFrame")



    -- Title
        local titleFrame = CreateFrame("Frame", nil, f)
        titleFrame:SetPoint("TOP", f, "TOP", 0, 12)
        titleFrame:SetWidth(256)
        titleFrame:SetHeight(64)

        local titleTex = titleFrame:CreateTexture(nil, "OVERLAY")
        titleTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
        titleTex:SetAllPoints()

        local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetText("|cff00ff00[ProcDoc]|r Options")
        title:SetPoint("TOP", 0, -14)

        -- Update live active proc frames (non-test) with new sizing/alpha values
        local function UpdateLiveProcs()
            for _, alertObj in ipairs(alertFrames) do
                if alertObj.isActive then
                    alertObj.pulseAlpha = minAlpha
                    alertObj.pulseDir = alphaStep
        
                    for _, tex in ipairs(alertObj.textures) do
                        tex:SetAlpha(minAlpha)
                        tex:SetWidth(alertObj.baseWidth * minScale)
                        tex:SetHeight(alertObj.baseHeight * minScale)
                    end
                end
            end
        end

        -- Update any active test proc preview frames immediately as sliders move
        local function UpdateTestAlertsPositions()
            for _, alertObj in pairs(testProcAlerts) do
                if alertObj.isActive then
                    -- Re-anchor
                    if alertObj.style == "TOP" or alertObj.style == "TOP2" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        local offsetY = (alertObj.style == "TOP2") and (topOffset + 50) or topOffset
                        tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
                    elseif alertObj.style == "SIDES" or alertObj.style == "SIDES2" then
                        local left = alertObj.textures[1]
                        local right = alertObj.textures[2]
                        local offsetX = (alertObj.style == "SIDES2") and (sideOffset + 50) or sideOffset
                        left:ClearAllPoints(); right:ClearAllPoints()
                        left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
                        right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
                    elseif alertObj.style == "LEFT" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        tex:SetPoint("CENTER", UIParent, "CENTER", -(sideOffset + 50), topOffset - 150)
                    elseif alertObj.style == "RIGHT" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        tex:SetPoint("CENTER", UIParent, "CENTER", (sideOffset + 50), topOffset - 150)
                    end
                    -- Apply size/alpha baseline
                    for _, tex in ipairs(alertObj.textures) do
                        tex:SetAlpha(minAlpha)
                        tex:SetWidth(alertObj.baseWidth * minScale)
                        tex:SetHeight(alertObj.baseHeight * minScale)
                    end
                end
            end
        end
        

    -- Min transparency slider
        local sliderLabel1 = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderLabel1:SetPoint("TOPLEFT", 10, -10)
        sliderLabel1:SetText("Min Transparency:")
        
        local minTransSlider = CreateFrame("Slider", "ProcDocMinTransSlider", f, "OptionsSliderTemplate")
        minTransSlider:SetPoint("TOPLEFT", 20, -60)
        minTransSlider:SetWidth(300)
        minTransSlider:SetMinMaxValues(0, 1)
        minTransSlider:SetValueStep(0.05)
    minTransSlider:SetValue(minAlpha)

        local low1  = getglobal(minTransSlider:GetName().."Low")
        local high1 = getglobal(minTransSlider:GetName().."High")
        local txt1  = getglobal(minTransSlider:GetName().."Text")

        if low1  then low1:SetText("0") end
        if high1 then high1:SetText("1") end
        if txt1  then txt1:SetText(string.format("%.2f", minAlpha)) end

        -- Using older style: no arguments, use `this`
        minTransSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()

            if not minAlpha then minAlpha = 0.6 end
            if not maxAlpha then maxAlpha = 1.0 end

            if value >= maxAlpha then
                value = maxAlpha - 0.01
                if value < 0 then value = 0 end
            end
            minAlpha = value

            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.minAlpha = minAlpha
            end

            local localText = getglobal(slider:GetName().."Text")
            if localText then
                localText:SetText(string.format("%.2f", value))
            end

            UpdateLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Max transparency slider
        local sliderLabel2 = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderLabel2:SetPoint("TOPLEFT", 10, -70)
        sliderLabel2:SetText("Max Transparency:")

        local maxTransSlider = CreateFrame("Slider", "ProcDocMaxTransSlider", f, "OptionsSliderTemplate")
        maxTransSlider:SetPoint("TOPLEFT", 20, -120)
        maxTransSlider:SetWidth(300)
        maxTransSlider:SetMinMaxValues(0, 1)
        maxTransSlider:SetValueStep(0.05)
    maxTransSlider:SetValue(maxAlpha)

        local low2  = getglobal(maxTransSlider:GetName().."Low")
        local high2 = getglobal(maxTransSlider:GetName().."High")
        local txt2  = getglobal(maxTransSlider:GetName().."Text")

        if low2  then low2:SetText("0") end
        if high2 then high2:SetText("1") end
        if txt2  then txt2:SetText(string.format("%.2f", maxAlpha)) end

        maxTransSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()

            if not minAlpha then minAlpha = 0.6 end

            if value <= minAlpha then
                value = minAlpha + 0.01
                if value > 1 then value = 1 end
            end
            maxAlpha = value
            
            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.maxAlpha = maxAlpha
            end

            local localText = getglobal(slider:GetName().."Text")
            if localText then
                localText:SetText(string.format("%.2f", value))
            end

            UpdateLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Min size slider
        local sizeLabel1 = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sizeLabel1:SetPoint("TOPLEFT", 10, -130)
        sizeLabel1:SetText("Min Size:")

        local minSizeSlider = CreateFrame("Slider", "ProcDocMinSizeSlider", f, "OptionsSliderTemplate")
        minSizeSlider:SetPoint("TOPLEFT", 20, -180)
        minSizeSlider:SetWidth(300)
        minSizeSlider:SetMinMaxValues(0.5, 2)
        minSizeSlider:SetValueStep(0.05)
    minSizeSlider:SetValue(minScale)

        local low3  = getglobal(minSizeSlider:GetName().."Low")
        local high3 = getglobal(minSizeSlider:GetName().."High")
        local txt3  = getglobal(minSizeSlider:GetName().."Text")

        if low3  then low3:SetText("0.5") end
        if high3 then high3:SetText("2.0") end
        if txt3  then txt3:SetText(string.format("%.2f", minScale)) end

        minSizeSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()

            if not maxScale then maxScale = 1.0 end

            if value >= maxScale then
                value = maxScale - 0.01
                if value < 0.5 then value = 0.5 end
            end
            minScale = value

            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.minScale = minScale
            end

            local localText = getglobal(slider:GetName().."Text")
            if localText then
                localText:SetText(string.format("%.2f", value))
            end

            UpdateLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Max size slider
        local sizeLabel2 = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sizeLabel2:SetPoint("TOPLEFT", 10, -190)
        sizeLabel2:SetText("Max Size:")

        local maxSizeSlider = CreateFrame("Slider", "ProcDocMaxSizeSlider", f, "OptionsSliderTemplate")
        maxSizeSlider:SetPoint("TOPLEFT", 20, -240)
        maxSizeSlider:SetWidth(300)
        maxSizeSlider:SetMinMaxValues(0.5, 2)
        maxSizeSlider:SetValueStep(0.05)
    maxSizeSlider:SetValue(maxScale)

        local low4  = getglobal(maxSizeSlider:GetName().."Low")
        local high4 = getglobal(maxSizeSlider:GetName().."High")
        local txt4  = getglobal(maxSizeSlider:GetName().."Text")

        if low4  then low4:SetText("0.5") end
        if high4 then high4:SetText("2.0") end
        if txt4  then txt4:SetText(string.format("%.2f", maxScale)) end

        maxSizeSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()

            if not minScale then minScale = 0.8 end

            if value <= minScale then
                value = minScale + 0.01
                if value > 2 then value = 2 end
            end
            maxScale = value

            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.maxScale = maxScale
            end

            local localText = getglobal(slider:GetName().."Text")
            if localText then
                localText:SetText(string.format("%.2f", value))
            end

            UpdateLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Pulse speed slider

        local speedLabel = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        speedLabel:SetPoint("TOPLEFT", 10, -250)
        speedLabel:SetText("Pulse Speed:")

        local pulseSpeedSlider = CreateFrame("Slider", "ProcDocPulseSpeedSlider", f, "OptionsSliderTemplate")
        pulseSpeedSlider:SetPoint("TOPLEFT", 20, -300)
        pulseSpeedSlider:SetWidth(300)
        pulseSpeedSlider:SetMinMaxValues(0.1, 5.0)
        pulseSpeedSlider:SetValueStep(0.1)
    pulseSpeedSlider:SetValue(pulseSpeed)

        local lowSpeed  = getglobal(pulseSpeedSlider:GetName().."Low")
        local highSpeed = getglobal(pulseSpeedSlider:GetName().."High")
        local txtSpeed  = getglobal(pulseSpeedSlider:GetName().."Text")
        if lowSpeed  then lowSpeed:SetText("0.1") end
        if highSpeed then highSpeed:SetText("5.0") end
        if txtSpeed  then txtSpeed:SetText(string.format("%.2f", pulseSpeed)) end

        pulseSpeedSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()

            pulseSpeed = value  -- store globally

            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.pulseSpeed = pulseSpeed
            end
        
            -- Update label
            local labelObj = getglobal(slider:GetName().."Text")
            if labelObj then
                labelObj:SetText(string.format("%.2f", value))
            end
    end)

        local function ReanchorAllLiveProcs()
            for _, alertObj in ipairs(alertFrames) do
                if alertObj.isActive then
                    -- Update position based on style
                    if alertObj.style == "TOP" or alertObj.style == "TOP2" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        local offsetY = (alertObj.style == "TOP2") and (topOffset + 50) or topOffset
                        tex:SetPoint("CENTER", UIParent, "CENTER", 0, offsetY)
                    elseif alertObj.style == "SIDES" or alertObj.style == "SIDES2" then
                        local left = alertObj.textures[1]
                        local right = alertObj.textures[2]
        
                        local offsetX = (alertObj.style == "SIDES2") and (sideOffset + 50) or sideOffset
                        left:ClearAllPoints()
                        left:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
        
                        right:ClearAllPoints()
                        right:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
                    elseif alertObj.style == "LEFT" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        local offsetX = sideOffset + 50
                        tex:SetPoint("CENTER", UIParent, "CENTER", -offsetX, topOffset - 150)
                    elseif alertObj.style == "RIGHT" then
                        local tex = alertObj.textures[1]
                        tex:ClearAllPoints()
                        local offsetX = sideOffset + 50
                        tex:SetPoint("CENTER", UIParent, "CENTER", offsetX, topOffset - 150)
                    end
                end
            end
        end

    -- Top offset slider
        local topLabel = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        topLabel:SetPoint("TOPLEFT", 10, -310)
        topLabel:SetText("Top Offset:")

        local topOffsetSlider = CreateFrame("Slider", "ProcDocTopOffsetSlider", f, "OptionsSliderTemplate")
        topOffsetSlider:SetPoint("TOPLEFT", 20, -360)
        topOffsetSlider:SetWidth(300)
        topOffsetSlider:SetMinMaxValues(0, 300)    -- e.g. range 0 -> 300
        topOffsetSlider:SetValueStep(10)
    topOffsetSlider:SetValue(topOffset)        -- current global

        local lowT  = getglobal(topOffsetSlider:GetName().."Low")
        local highT = getglobal(topOffsetSlider:GetName().."High")
        local txtT  = getglobal(topOffsetSlider:GetName().."Text")
        if lowT  then lowT:SetText("0")   end
        if highT then highT:SetText("300") end
        if txtT  then txtT:SetText(tostring(topOffset)) end

        topOffsetSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()
            topOffset = value
            if txtT then
                txtT:SetText(tostring(value))
            end

            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.topOffset = topOffset
            end

            ReanchorAllLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Side offset slider
        local sideLabel = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sideLabel:SetPoint("TOPLEFT", 10, -370)
        sideLabel:SetText("Side Offset:")

        local sideOffsetSlider = CreateFrame("Slider", "ProcDocSideOffsetSlider", f, "OptionsSliderTemplate")
        sideOffsetSlider:SetPoint("TOPLEFT", 20, -420)
        sideOffsetSlider:SetWidth(300)
        sideOffsetSlider:SetMinMaxValues(0, 300)    -- e.g. range 0 -> 300
        sideOffsetSlider:SetValueStep(10)
    sideOffsetSlider:SetValue(sideOffset)

        local lowS  = getglobal(sideOffsetSlider:GetName().."Low")
        local highS = getglobal(sideOffsetSlider:GetName().."High")
        local txtS  = getglobal(sideOffsetSlider:GetName().."Text")
        if lowS  then lowS:SetText("0")   end
        if highS then highS:SetText("300") end
        if txtS  then txtS:SetText(tostring(sideOffset)) end

        sideOffsetSlider:SetScript("OnValueChanged", function()
            local slider = this
            local value  = slider:GetValue()
            sideOffset = value
            if txtS then
                txtS:SetText(tostring(value))
            end
            
            -- SAVE to DB:
            if ProcDocDB and ProcDocDB.globalVars then
                ProcDocDB.globalVars.sideOffset = sideOffset
            end


            ReanchorAllLiveProcs(); UpdateTestAlertsPositions()
        end)

    -- Mute checkbox
    local muteCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    muteCheck:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 5, - (TOP_SECTION_HEIGHT - 30)) -- near bottom of top section
        muteCheck:SetWidth(24)
        muteCheck:SetHeight(24)

        local muteLabel = muteCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        muteLabel:SetPoint("LEFT", muteCheck, "RIGHT", 4, 0)
        muteLabel:SetText("Mute All Proc Sounds")

        -- Initialize check mark based on DB:
        muteCheck:SetChecked(ProcDocDB.globalVars.isMuted)

        muteCheck:SetScript("OnClick", function()
            if muteCheck:GetChecked() then
                ProcDocDB.globalVars.isMuted = true
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: Sounds are now muted.")
            else
                ProcDocDB.globalVars.isMuted = false
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: Sounds are now unmuted.")
            end
        end)

    -- Disable timers checkbox
    local timerCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    timerCheck:SetPoint("LEFT", muteCheck, "RIGHT", 140, 0) -- place to the right of mute
        timerCheck:SetWidth(24)
        timerCheck:SetHeight(24)
        local timerLabel = timerCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        timerLabel:SetPoint("LEFT", timerCheck, "RIGHT", 4, 0)
        timerLabel:SetText("Disable Timers")
        timerCheck:SetChecked(ProcDocDB.globalVars.disableTimers)
        timerCheck:SetScript("OnClick", function()
            if timerCheck:GetChecked() then
                ProcDocDB.globalVars.disableTimers = true
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: Timers disabled.")
                -- Hide any current timer texts immediately
                for _, aObj in ipairs(alertFrames) do
                    if aObj.timerTexts then
                        for _, fs in ipairs(aObj.timerTexts) do if fs then fs:Hide() end end
                    end
                    aObj.hasTimer = false
                end
            else
                ProcDocDB.globalVars.disableTimers = false
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: Timers enabled.")
            end
        end)

    -- Dynamic proc list section
        local testLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        testLabel:SetText("|cffffffffProc Animations to Show for " .. (UnitClass("player")) .. "|r")

        local sectionFrame2 = CreateFrame("Frame", nil, f)
        sectionFrame2:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        sectionFrame2:SetBackdropColor(0.2, 0.2, 0.2, 1)
        sectionFrame2:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        local numProcs = 0
        for _ in ipairs(classProcs) do numProcs = numProcs + 1 end
        local ROW_HEIGHT = 28
        local LIST_EXTRA_PADDING = 10 -- padding inside frame
        local listHeight = (numProcs * ROW_HEIGHT) + LIST_EXTRA_PADDING
        if listHeight < 60 then listHeight = 36 end

        -- Anchor the dynamic list directly below the top section
        sectionFrame2:ClearAllPoints()
        sectionFrame2:SetPoint("TOPLEFT", sectionFrame, "BOTTOMLEFT", 0, -20)
        sectionFrame2:SetWidth(sectionFrame:GetWidth())
        sectionFrame2:SetHeight(listHeight)

        -- Position label inside sectionFrame2
        testLabel:ClearAllPoints()
        testLabel:SetPoint("TOPLEFT", sectionFrame2, "TOPLEFT", 5, 13)

        local firstCheckY = -25  -- relative to sectionFrame2 top
    -- Table to hold references to each buff's checkbox
    local checkBoxes = {}

    -- Build checkbox list
        local idx = 0
        for _, procInfo in ipairs(classProcs) do
            idx = idx + 1
            local check = CreateFrame("CheckButton", nil, sectionFrame2, "UICheckButtonTemplate")
            check:SetHeight(24)
            check:SetWidth(24)
            check:ClearAllPoints()
            local yOff = firstCheckY - ((idx - 1) * ROW_HEIGHT - 19)
            check:SetPoint("TOPLEFT", sectionFrame2, "TOPLEFT", 5, yOff)

            local label = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", check, "RIGHT", 4, 0)
            label:SetText(procInfo.buffName)

            local localProcInfo = procInfo
            checkBoxes[localProcInfo.buffName] = check
            check:SetScript("OnClick", function()
                local bName = localProcInfo.buffName
                local isChecked = check:GetChecked()
                if not bName then return end
                if isChecked then
                    ProcDocDB.procsEnabled[bName] = true
                else
                    ProcDocDB.procsEnabled[bName] = false
                end
            end)
            local isEnabled = (ProcDocDB.procsEnabled[procInfo.buffName] ~= false)
            check:SetChecked(isEnabled)
        end

    -- Recompute full frame height now that we know list height
        local BUTTON_BLOCK_HEIGHT = 70 -- space for buttons + padding
        local totalHeight = 30 + TOP_SECTION_HEIGHT + 10 + listHeight + BUTTON_BLOCK_HEIGHT + 20
        if totalHeight < 520 then totalHeight = 520 end -- minimum so sliders area not cramped
        f:SetHeight(totalHeight)

    -- Test proc button (shows alerts for all checked procs)
    local testButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    testButton:ClearAllPoints()
    testButton:SetPoint("TOP", sectionFrame2, "BOTTOM", 0, -45)
        testButton:SetWidth(120)
        testButton:SetHeight(25)
        testButton:SetText("Test Proc")

        -- Replace old logic with:
        testButton:SetScript("OnClick", function()
            for _, procInfo in ipairs(classProcs) do
                local c = checkBoxes[procInfo.buffName]
                if c and c:GetChecked() then
                    ShowTestBuffAlert(procInfo)
                else
                    HideTestBuffAlert(procInfo)
                end
            end
        end)

    -- Hide all test alerts button
    local hideAllBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    hideAllBtn:ClearAllPoints()
    hideAllBtn:SetPoint("TOPLEFT", sectionFrame2, "BOTTOMLEFT", 5, -15)
        hideAllBtn:SetWidth(120)
        hideAllBtn:SetHeight(25)
        hideAllBtn:SetText("Hide All")
        hideAllBtn:SetScript("OnClick", function()
            -- Hide all the multi-buff test alerts
            for buffName, alertObj in pairs(testProcAlerts) do
                if alertObj.isActive then
                    alertObj.isActive = false
                    for _, tex in ipairs(alertObj.textures) do tex:Hide() end
                    if alertObj.timerTexts then
                        for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
                    end
                end
            end

            -- Also hide the single testProcAlertObj
            if testProcAlertObj and testProcAlertObj.isActive then
                testProcAlertObj.isActive = false
                for _, t in ipairs(testProcAlertObj.textures) do
                    t:Hide()
                end
                testProcAlertObj = nil
                testProcActive   = false
            end

            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[ProcDoc]|r All test buff alerts hidden.")
        end)

    -- Close button
    local closeButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeButton:ClearAllPoints()
    closeButton:SetPoint("TOPRIGHT", sectionFrame2, "BOTTOMRIGHT", -5, -15)
        closeButton:SetWidth(120)
        closeButton:SetHeight(25)
        closeButton:SetText("Close")
        closeButton:SetScript("OnClick", function()
            for buffName, alertObj in pairs(testProcAlerts) do
                if alertObj.isActive then
                    alertObj.isActive = false
                    for _, tex in ipairs(alertObj.textures) do tex:Hide() end
                    if alertObj.timerTexts then
                        for _, fs in ipairs(alertObj.timerTexts) do if fs then fs:Hide() end end
                    end
                end
            end
            f:Hide()

        end)
        
    end

    ProcDocOptionsFrame:Show()
    
end


-- 14) Slash command
SLASH_PROCDOC1 = "/procdoc"
SlashCmdList["PROCDOC"] = function(msg)
    CreateProcDocOptionsFrame()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffProcDoc|r Options opened")
end
