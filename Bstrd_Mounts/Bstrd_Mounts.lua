local GUI = LibStub("AceGUI-3.0")
local Reg = LibStub("AceConfigRegistry-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

local BM = LibStub("AceAddon-3.0"):NewAddon("Bstrd_Mounts")

-- Mixin library functionality into this object
LibStub("AceConsole-3.0"):Embed(BM)
LibStub("AceComm-3.0"):Embed(BM)
LibStub("AceEvent-3.0"):Embed(BM)

local playerName = UnitName("player")
local playerFaction,playerFactionName = UnitFactionGroup("player")
local playerLevel = UnitLevel("player")

local defaults = {
    profile = {
    }
}

-- Called when the addon is initialized
function BM:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("BstrdMountsDB", defaults)
    
    -- Register /mountup slash command
    BM:RegisterChatCommand("mountup", "Handle_MountUp")
    BM:RegisterChatCommand("setmount", "Handle_SetMount")
    BM:RegisterChatCommand("setgroundmount", "Handle_SetGroundMount")
    BM:RegisterChatCommand("setswimmingmount", "Handle_SetSwimmingMount")
    BM:RegisterChatCommand("setflyingmount", "Handle_SetFlyingMount")
    BM:RegisterChatCommand("setcontinentmount", "Handle_SetContinentMount")

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
    
        if playerLevel < 20 then
            
            mountName = "Summon Chauffeur"
            
        else

            if IsSwimming() then mountName = mountDB["Swimming"] end
            if IsFalling() then mountName = mountDB["Falling"] end

            if mountDB[continent] then
                if not mountName then mountName = mountDB[continent][zoneText] end
                if not mountName then
                    if IsFlyableArea() then
                        mountName = mountDB[continent]["Flying"]
                    else
                        mountName = mountDB[continent]["Ground"]
                    end
                end
                if not mountName then mountName = mountDB[continent]["Default"] end
            end

            if not mountName then
                if IsFlyableArea() then
                    mountName = mountDB["Flying"]
                else
                    mountName = mountDB["Ground"]
                end
            end
            
            if not mountName then mountName = nil end

        end

    end

    if mountName then

        BM:Printf("In Continent : %s", continent)
        BM:Printf("In Zone : %s", zoneText)
        BM:Printf("Will Use : %s", mountName)

        CastSpellByName(mountName)
        
    end

end

-- Called when /setflyingmount slash command is used
function BM:Handle_SetFlyingMount(mountName) 
    BM:SetMount(nil, "Flying", mountName)
end

-- Called when /setgroundmount slash command is used
function BM:Handle_SetGroundMount(mountName) 
    BM:SetMount(nil, "Ground", mountName)
end

-- Called when /setswimmingmount slash command is used
function BM:Handle_SetSwimmingMount(mountName) 
    BM:SetMount(nil, "Swimming", mountName)
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

--[[    -- make sure there's a table for the continent
    -- otherwise create a new one
    if not self.db.profile[continent] then
        self.db.profile[continent] = {}
    end

    if mountName and mountName:len() > 0 then
        
        -- make sure we can use the mount
        local spellName, spellRank, spellIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(mountName)
        if spellName then
            -- set up new zone mount mapping
            self.db.profile[continent][zoneText] = spellName
        else
            BM:Printf("Unknown mount: [%i] %s", spellID, mountName)
        end

    else
        -- clears out an existing mount mapping
        mountName = self.db.profile[continent][zoneText]
        if mountName and string.len(mountName) then
            BM:Printf("Clearing zone mount: %s", mountName)
            self.db.profile[continent][zoneText] = nil
        end
    end
]]
end

function BM:SetMount(continent, zoneOrScenario, mountName) 

    local mountDB = self.db.profile

    -- If a continent was specified, we will use that continent as the mountDB.
    -- First make sure a table exists for the given continent. If not, create one.
    if continent then
        if not mountDB[continent] then
            mountDB[continent] = {}
        end
        mountDB = mountDB[continent]
    end

    if not (zoneOrScenario and zoneOrScenario:len()) then
        zoneOrScenario = "Default"
    end

    if mountName and mountName:len() > 0 then

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
        mountName = mountDB[zoneOrScenario]
        if mountName and mountName:len() then
            BM:Printf("Clearing zone mount: %s", mountName)
            mountDB[zoneOrScenario] = nil
        end
    end

end

function BM:IsUsableMount(mountName)

    -- trim leading and trailing spaces
    if mountName then mountName = mountName:gsub("^%s*(.-)%s*$", "%1") end

    if mountName and mountName:len() then
        -- make sure we can use the mount
        local spellName, spellRank, spellIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(mountName)
        if spellName then
            return true
        end
    end
    
    return false

end

-- Export global addon object which can be referenced by
-- other Lua scripts in the addon.
Bstrd_Mounts = BM
