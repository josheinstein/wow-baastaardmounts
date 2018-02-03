local GUI = LibStub("AceGUI-3.0")
local Reg = LibStub("AceConfigRegistry-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

local BM = LibStub("AceAddon-3.0"):NewAddon("Bstrd_Mounts")

-- Mixin library functionality into this object
LibStub("AceConsole-3.0"):Embed(BM)
LibStub("AceComm-3.0"):Embed(BM)
LibStub("AceEvent-3.0"):Embed(BM)
LibStub("AceHook-3.0"):Embed(BM)

local playerName = UnitName("player")
local playerClass,playerClassName,playerClassID = UnitClass("player")
local playerFaction,playerFactionName = UnitFactionGroup("player")
local playerLevel = UnitLevel("player")

local defaults = {
    profile = { ["Heirloom"] = "Summon Chauffeur" }
}

-- Called when the addon is initialized
function BM:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("BstrdMountsDB", defaults)

    -- Register /mountup slash command
    BM:RegisterChatCommand("mountup", "Handle_MountUp")                         -- calls up a mount for this zone
    BM:RegisterChatCommand("setmount", "Handle_SetMount")                       -- sets zone mount
    BM:RegisterChatCommand("setgroupmount", "Handle_SetGroupMount")				-- sets character's default mount when grouped
    BM:RegisterChatCommand("setgroundmount", "Handle_SetGroundMount")           -- sets character's default ground mount
    BM:RegisterChatCommand("setonwatermount", "Handle_SetOnWaterMount")         -- sets character's default on-water mount
    BM:RegisterChatCommand("setunderwatermount", "Handle_SetUnderwaterMount")   -- sets character's default under-water mount
    BM:RegisterChatCommand("setflyingmount", "Handle_SetFlyingMount")           -- sets character's default flying mount
    BM:RegisterChatCommand("setcontinentmount", "Handle_SetContinentMount")     -- sets a default mount for continent

end

-- Called when /mountup slash command is used
function BM:Handle_MountUp() 

    local mountName = nil
    local continent = tostring(GetCurrentMapContinent()+0)
    local zoneText = GetZoneText()
    local mountDB = self.db.profile
    
    if IsMounted() then
        
        Dismount()
        
    elseif IsOutdoors() then
    
        -- if player is under level 20, always attempt to use the heirloom mount
        if playerLevel < 20 then
            
            mountName = "Summon Chauffeur"
            
        else

            -- if player is grouped and a group mount is defined, that
            -- will take precedence over the others
            if not mountName and IsInGroup() then mountName = s(mountDB["Group"]) end

            -- if a swimming mount is defined and we are swimming, that
            -- will take priority over the other defined mounts
            if not mountName and IsSubmerged() then
                if GetMirrorTimerInfo(2)=="BREATH" then
                    mountName = s(mountDB["Underwater"])
                else
                    mountName = s(mountDB["Swimming"])                    
                end
            end

            if mountDB[continent] then
                -- try to use a zone-specific mount if one is configured
                if not mountName then mountName = s(mountDB[continent][zoneText]) end
                -- if there is no zone-specific mount, try a continent-specific mount
                if not mountName then mountName = s(mountDB[continent]["Default"]) end
            end

            -- if there is no zone or continent specific mount, use a
            -- default mounts for this character, ground or flying
            if not mountName then
                if IsFlyableArea() then
                    mountName = s(mountDB["Flying"])
                else
                    mountName = s(mountDB["Ground"])
                end
            end
            
            if not mountName then
                if playerClassName == "DRUID" and playerLevel >= 18 then
                    mountName = "Travel Form"
                end
            end
            
        end

    end

    if mountName then

        BM:Printf("[%s] %s: %s", continent, zoneText, mountName)

        CastSpellByName(mountName)
        
    end

end

-- Called when /setgroupmount slash command is used
function BM:Handle_SetGroupMount(mountName) 
    BM:SetMount(nil, "Group", mountName)
end

-- Called when /setflyingmount slash command is used
function BM:Handle_SetFlyingMount(mountName) 
    BM:SetMount(nil, "Flying", mountName)
end

-- Called when /setgroundmount slash command is used
function BM:Handle_SetGroundMount(mountName) 
    BM:SetMount(nil, "Ground", mountName)
end

-- Called when /setonwatermount slash command is used
function BM:Handle_SetOnWaterMount(mountName) 
    BM:SetMount(nil, "Swimming", mountName)
end

-- Called when /setunderwatermount slash command is used
function BM:Handle_SetUnderwaterMount(mountName) 
    BM:SetMount(nil, "Underwater", mountName)
end

-- Called when /setcontinentmount slash command is used
function BM:Handle_SetContinentMount(mountName) 
    local continent = tostring(GetCurrentMapContinent()+0)
    BM:SetMount(continent, "Default", mountName)
end

-- Called when /setmount slash command is used
function BM:Handle_SetMount(mountName) 

    local continent = tostring(GetCurrentMapContinent()+0)
    local zoneText = GetZoneText()

    BM:SetMount(continent, zoneText, mountName)

end

function BM:SetMount(continent, zoneOrScenario, mountName) 

    local mountDB = self.db.profile

    continent = s(continent)
    zoneOrScenario = s(zoneOrScenario)
    mountName = s(mountName)

    -- If a continent was specified, we will use that continent as the mountDB.
    -- First make sure a table exists for the given continent. If not, create one.
    if continent then
        if not mountDB[continent] then
            mountDB[continent] = {}
        end
        mountDB = mountDB[continent]
    end

    if not zoneOrScenario then
        zoneOrScenario = "Default"
    end

    if mountName then

        -- make sure we can use the mount
        local spellName, spellRank, spellIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(mountName)
        if spellName then
            -- set up new mount mapping
            mountDB[zoneOrScenario] = spellName
            BM:Printf("Will use [%i] %s.", spellID, mountName)
        else
            BM:Printf("Unknown mount: [%i] %s", spellID, mountName)
        end

    else
        -- clears out an existing mount mapping
        mountName = s(mountDB[zoneOrScenario])
        if mountName then
            BM:Printf("Clearing zone mount: %s", mountName)
            mountDB[zoneOrScenario] = nil
        end
    end

end

-- cleans a string by trimming leading/trailing spaces and converting
-- empty strings to nil
function s(str)
    if str and str:len() > 0 then str = str:gsub("^%s*(.-)%s*$", "%1") end
    if str and str:len() > 0 then
        return str
    end
end


-- Export global addon object which can be referenced by
-- other Lua scripts in the addon.
Bstrd_Mounts = BM
