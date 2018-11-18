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
    BM:RegisterChatCommand("debugmounts", "Handle_DebugMounts")                 -- lists the current situations and the mounts set for them
    BM:RegisterChatCommand("setmount", "Handle_SetMount")                       -- sets zone mount
    BM:RegisterChatCommand("setgroupmount", "Handle_SetGroupMount")				-- sets character's default mount when grouped
    BM:RegisterChatCommand("setgroundmount", "Handle_SetGroundMount")           -- sets character's default ground mount
    BM:RegisterChatCommand("setonwatermount", "Handle_SetOnWaterMount")         -- sets character's default on-water mount
    BM:RegisterChatCommand("setunderwatermount", "Handle_SetUnderwaterMount")   -- sets character's default under-water mount
    BM:RegisterChatCommand("setflyingmount", "Handle_SetFlyingMount")           -- sets character's default flying mount
    BM:RegisterChatCommand("setcontinentmount", "Handle_SetContinentMount")     -- sets a default mount for continent
    BM:RegisterChatCommand("setshiftmount", "Handle_SetShiftMount")             -- sets a default mount when shift is held

end

function BM:GetCurrentSituation()

    local continent = CurrentContinentName()
    local zone = CurrentZoneName()
    local situation = {}
    local playerLevel = UnitLevel("player")

    if IsOutdoors() then
    
        -- if player is under level 20, always attempt to use the heirloom mount
        if playerLevel < 20 then
            
            table.insert( situation, "Heirloom" )
            
        else

            -- if the shift key is being held while activating the
            -- mount command, then use the shift mount
            if IsShiftKeyDown() then
                table.insert( situation, "Shift" )
            end
            
            -- if player is grouped and a group mount is defined, that
            -- will take precedence over the others
            if IsInGroup() then
                table.insert( situation, "Group" )
            end

            -- if a swimming mount is defined and we are swimming, that
            -- will take priority over the other defined mounts
            if IsSubmerged() then
                if GetMirrorTimerInfo(2)=="BREATH" then
                    table.insert( situation, "Underwater" )
                elseif IsShiftKeyDown() then
                    -- special case for shift key
                    -- if in the water, shift will control whether we use the in/on
                    -- water mount, and not use the assigned shift mount
                    table.insert( situation, "Underwater" )
                    RemoveFromTable( situation, "Shift" )
                end
                table.insert( situation, "Swimming" )
            end

            -- Continent + Zone takes precedence over Continent + Default
            table.insert( situation, MakeZoneKey(continent, zone) )
            table.insert( situation, MakeZoneKey(continent) )

            -- if there is no zone or continent specific mount, use a
            -- default mounts for this character, ground or flying
            if (IsFlyableArea() and playerLevel >= 60) then
                table.insert( situation, "Flying" )
            end
            
            table.insert( situation, "Ground" )

        end

    else
        table.insert( situation, "Indoors" )
    end

    return situation

end

-- Called when /mountup slash command is used
function BM:Handle_MountUp() 

    local mountDB = self.db.profile
    
    if IsMounted() then
        
        Dismount()
        
    else
        
        local situation = BM:GetCurrentSituation()
        
        for i,s in ipairs(situation) do
            local mountName = mountDB[s]
            if mountName then
                BM:UseMount(s, mountName)
                return
            end
            
        end

        BM:Printf("No preferred mounts set.")
    
    end

end

function BM:UseMount(situation, mountName)
    BM:Printf("[%s] %s", situation, mountName)
    CastSpellByName(mountName)
end

-- Called when /debugmounts slash command is used
function BM:Handle_DebugMounts()

    local mountDB = self.db.profile
    local situation = BM:GetCurrentSituation()
    
    BM:Printf("---------MOUNT SCENARIOS--------")    
    
    for i,s in ipairs(situation) do
        local mountName = mountDB[s]
        if mountName then
            local spellName, spellRank, spellIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(mountName)
            if spellName then
                BM:Printf("When [%s] use [%i:%s]", s, spellID, spellName)
            else
                BM:Printf("When [%s] use [Unknown:%s]", s, mountName)
            end
        else
            BM:Printf("When [%s] use [Not Specified]", s)
        end
    end

    BM:Printf("-------------------------------")    
    
end

-- Called when /setgroupmount slash command is used
function BM:Handle_SetGroupMount(mountName) 
    BM:SetMount("Group", mountName)
end

-- Called when /setflyingmount slash command is used
function BM:Handle_SetFlyingMount(mountName) 
    BM:SetMount("Flying", mountName)
end

-- Called when /setgroundmount slash command is used
function BM:Handle_SetGroundMount(mountName) 
    BM:SetMount("Ground", mountName)
end

-- Called when /setonwatermount slash command is used
function BM:Handle_SetOnWaterMount(mountName) 
    BM:SetMount("Swimming", mountName)
end

-- Called when /setunderwatermount slash command is used
function BM:Handle_SetUnderwaterMount(mountName) 
    BM:SetMount("Underwater", mountName)
end

-- Called when /setcontinentmount slash command is used
function BM:Handle_SetContinentMount(mountName) 
    local continent = CurrentContinentName()
    BM:SetMount(MakeZoneKey(continent), mountName)
end

-- Called when /setshiftmount slash command is used
function BM:Handle_SetShiftMount(mountName) 
    BM:SetMount("Shift", mountName)
end

-- Called when /setmount slash command is used
function BM:Handle_SetMount(mountName) 

    local continent = CurrentContinentName()
    local zone = CurrentZoneName()

    BM:SetMount(MakeZoneKey(continent, zone), mountName)

end

function BM:SetMount(situation, mountName) 

    local mountDB = self.db.profile

    if not IsNullOrWhiteSpace(mountName) then

        -- make sure we can use the mount
        local spellName, spellRank, spellIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(mountName)
        if spellName then
            -- set up new mount mapping
            mountDB[situation] = spellName
            BM:Printf("When [%s] use [%i:%s].", situation, spellID, mountName)
        else
            BM:Printf("Unknown mount: %s", mountName)
        end

    else
        -- clears out an existing mount mapping
        mountName = mountDB[situation]
        if mountName then
            BM:Printf("Clearing [%s] mount preference. (Was [%s])", situation, mountName)
            mountDB[situation] = nil
        end
    end

end

function CurrentContinentName()

    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = C_Map.GetMapInfo(mapID)

    while (mapInfo.mapType > 2) do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end

    if (mapInfo.mapType == 2) then
        return mapInfo.name
    end

    return "World"

end

function CurrentZoneName()

    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = C_Map.GetMapInfo(mapID)

    return mapInfo.name

end

function MakeZoneKey(continent, zone)
    if continent and zone then
        return continent .. ":" .. zone
    elseif continent then
        return continent
    else
        return "Unknown"
    end
end

function IsNullOrWhiteSpace(str)
    if str and str:len() > 0 then str = str:gsub("^%s*(.-)%s*$", "%1") end
    if str and str:len() > 0 then
        return false
    else
        return true
    end
end

function RemoveFromTable(tbl, str)
    for i, v in ipairs(tbl) do
        if v == str then
            return table.remove(tbl, i)
        end
    end
end  

-- Export global addon object which can be referenced by
-- other Lua scripts in the addon.
Bstrd_Mounts = BM
