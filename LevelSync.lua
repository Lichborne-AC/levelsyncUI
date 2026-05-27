-- LevelSync.lua — core logic
-- Communicates with mod-levelsync via WoW chat commands and CHAT_MSG_SYSTEM events.

local ADDON_NAME = "LevelSync"

-- Shared namespace; LevelSync_UI.lua accesses this via _G["LevelSync"]
local LS = {}
_G["LevelSync"] = LS

-- ─── Class & tier lookup tables ──────────────────────────────────────────────

LS.CLASS_COLORS = {
    ["Warrior"]      = "C79C6E",
    ["Paladin"]      = "F58CBA",
    ["Hunter"]       = "ABD473",
    ["Rogue"]        = "FFF569",
    ["Priest"]       = "FFFFFF",
    ["Death Knight"] = "C41F3B",
    ["Shaman"]       = "0070DE",
    ["Mage"]         = "69CCF0",
    ["Warlock"]      = "9482C9",
    ["Druid"]        = "FF7D0A",
}

LS.TIER_NAMES = {
    [0]  = "T0 — Molten Core / Onyxia",
    [1]  = "T1 — Molten Core / Onyxia",
    [2]  = "T2 — Blackwing Lair",
    [3]  = "T3 — Ahn'Qiraj War Effort",
    [4]  = "T4 — AQ War",
    [5]  = "T5 — Ahn'Qiraj",
    [6]  = "T6 — Naxxramas 40",
    [7]  = "T7 — Pre-TBC",
    [8]  = "T8 — Karazhan / Gruul's Lair / Magtheridon's Lair",
    [9]  = "T9 — Serpentshrine Cavern / Tempest Keep",
    [10] = "T10 — Hyjal Summit / Black Temple",
    [11] = "T11 — Zul'Aman (Optional)",
    [12] = "T12 — Sunwell Plateau",
    [13] = "T13 — Naxx / Eye of Eternity / Obsidian Sanctum",
    [14] = "T14 — Ulduar",
    [15] = "T15 — Trial of the Crusader",
    [16] = "T16 — Icecrown Citadel",
    [17] = "T17 — Ruby Sanctum",
    [18] = "T18 — Tiers Complete",
}

-- ─── Parsed group data (written by CommitStatus, read by UI) ─────────────────

LS.data = {
    inGroup        = false,
    groupId        = nil,
    accountsCur    = 0,
    accountsMax    = 0,
    totalChars     = 0,
    levelSync      = false,
    ipSync         = false,
    ipSyncDisabled = false,
    members        = {},  -- {accountId, name, level, class, tierStr}
}

-- ─── Command sender ───────────────────────────────────────────────────────────

local function SendCmd(cmd)
    if InCombatLockdown() then
        print("|cffff4444[LevelSync]|r Cannot send commands while in combat.")
        return
    end
    local box = ChatFrame1EditBox
    if not box:IsVisible() then
        ChatFrame_OpenChat("", ChatFrame1)
    end
    box:SetText(".levelsync " .. cmd)
    ChatEdit_SendText(box, false)
    box:Hide()
end

LS.SendCmd = SendCmd


-- ─── Multi-line status state machine ─────────────────────────────────────────
-- Captures ALL CHAT_MSG_SYSTEM lines while sm.active is true, then commits
-- 300ms after the last line (reset on each new arrival via OnUpdate timer).

local COMMIT_DELAY = 0.3

local sm = {
    active = false,
    lines  = {},
}

local commitRemaining = 0
local commitFrame = CreateFrame("Frame")
commitFrame:Hide()

local function ArmCommitTimer()
    commitRemaining = COMMIT_DELAY
    commitFrame:Show()
end

local function CommitStatus()
    sm.active = false
    local d = LS.data

    d.inGroup     = false
    d.groupId     = nil
    d.accountsCur = 0
    d.accountsMax = 0
    d.totalChars  = 0
    d.levelSync   = false
    d.ipSync      = false
    d.members     = {}

    local curAccount = nil

    for _, line in ipairs(sm.lines) do
        -- Group header: "[LevelSync] Sync Group #N"
        local gid = line:match("Sync Group #(%d+)")
        if gid then
            d.inGroup = true
            d.groupId = tonumber(gid)
        end

        -- "  Accounts: X/Y"
        local cur, max = line:match("Accounts: (%d+)/(%d+)")
        if cur then
            d.accountsCur = tonumber(cur)
            d.accountsMax = tonumber(max)
        end

        -- "  Total Characters: N"
        local tc = line:match("Total Characters: (%d+)")
        if tc then d.totalChars = tonumber(tc) end

        -- "  Level sync: Available|Disabled"
        local ls = line:match("Level sync: (%a+)")
        if ls then d.levelSync = (ls == "Available") end

        -- "  Progression sync: Available|Disabled"
        local ps = line:match("Progression sync: (%a+)")
        if ps then d.ipSync = (ps == "Available") end

        -- "  Account N: Characters: X" — extract account ID
        local accId = line:match("Account (%d+):")
        if accId then curAccount = tonumber(accId) end

        -- "    Name (lvl X) (Class) IP Tier: ..."
        -- After color stripping, 4-space indent
        local name, lvl, cls, tierStr =
            line:match("^%s+(.-)%s+%(lvl (%d+)%)%s+%((.-)%)%s+IP Tier: (.+)$")
        if name and curAccount then
            local tierNum = 0
            if tierStr and tierStr ~= "None" then
                tierNum = tonumber(tierStr:match("^(%d+)")) or 0
            end
            table.insert(d.members, {
                accountId = curAccount,
                name      = name,
                level     = tonumber(lvl),
                class     = cls,
                tierStr   = tierStr,
                tierNum   = tierNum,
            })
        end
    end

    sm.lines = {}

    if LS.UI_OnDataRefresh then LS.UI_OnDataRefresh() end
end

-- OnUpdate script set here so CommitStatus is in scope for the closure
commitFrame:SetScript("OnUpdate", function(self, elapsed)
    commitRemaining = commitRemaining - elapsed
    if commitRemaining <= 0 then
        self:Hide()
        if sm.active then CommitStatus() end
    end
end)

-- ─── CHAT_MSG_SYSTEM listener ─────────────────────────────────────────────────

local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_SYSTEM")
listener:SetScript("OnEvent", function(self, event, msg)
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    -- ── While collecting status block, capture ALL system messages ──
    if sm.active then
        table.insert(sm.lines, clean)
        ArmCommitTimer()
        return
    end

    -- Outside a status block, only act on [LevelSync] messages
    if not clean:find("%[LevelSync%]") then return end

    -- ── No group — wipe all data ──
    if clean:find("Sync group disbanded") or clean:find("You are not in a sync group") then
        LS.data.inGroup     = false
        LS.data.groupId     = nil
        LS.data.accountsCur = 0
        LS.data.accountsMax = 0
        LS.data.totalChars  = 0
        LS.data.levelSync   = false
        LS.data.ipSync      = false
        LS.data.members     = {}
        if LS.UI_OnDataRefresh then LS.UI_OnDataRefresh() end
        return
    end

    -- ── Status block start ──
    if clean:find("Sync Group #") then
        sm.active = true
        sm.lines  = { clean }
        ArmCommitTimer()
        return
    end

end)

-- ─── Status output filter ────────────────────────────────────────────────────
-- Suppresses the status block from appearing in the chat frame.

local function LevelSyncStatusFilter(_, _, msg)
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    if sm.active then
        if not clean:find("%[LevelSync%]") then return true end
        if clean:find("Sync Group #") or clean:find("Group members") or clean:find("graphical interface") then return true end
        return
    end

    if clean:find("%[LevelSync%]") and clean:find("Sync Group #") then
        return true
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LevelSyncStatusFilter)

-- ─── Slash commands ───────────────────────────────────────────────────────────

SLASH_LEVELSYNC1 = "/lsync"
SLASH_LEVELSYNC2 = "/levelsync"
SlashCmdList["LEVELSYNC"] = function(msg)
    msg = msg:match("^%s*(.-)%s*$")
    if msg == "" then
        if LS.TogglePanel then LS.TogglePanel() end
    else
        SendCmd(msg)
    end
end

-- ─── Minimap icon (LibDBIcon) — registered on ADDON_LOADED ───────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    LevelSyncDB = LevelSyncDB or {}
    LevelSyncDB.minimap = LevelSyncDB.minimap or { hide = false }

    local LDB  = LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub("LibDBIcon-1.0", true)

    if LDB and Icon then
        local ldb = LDB:NewDataObject("LevelSync", {
            type  = "launcher",
            icon  = "Interface\\Icons\\inv_misc_groupneedmore",
            label = "LevelSync",
            OnClick = function(_, btn)
                if btn == "LeftButton" then
                    if LS.TogglePanel then LS.TogglePanel() end
                end
            end,
            OnTooltipShow = function(tip)
                tip:AddLine("|cffd4af37LevelSync|r")
                tip:AddLine("|cffaaaaaaLeft-click|r to open/close", 1, 1, 1)
                tip:AddLine("|cffaaaaaaRight-drag|r to reposition", 1, 1, 1)
            end,
        })
        Icon:Register("LevelSync", ldb, LevelSyncDB.minimap)
    else
        print("|cffff4444[LevelSync]|r Warning: minimap libraries not loaded.")
    end
end)
