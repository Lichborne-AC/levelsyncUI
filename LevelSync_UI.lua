-- LevelSync_UI.lua
-- Standalone LevelSync panel — layout mirrors PBM_Tab_LevelSync exactly.

local LS = _G["LevelSync"]
if not LS then return end

-- ─── Style constants ─────────────────────────────────────────────────────────

local GOLD_R, GOLD_G, GOLD_B = 0.78, 0.61, 0.23
local GOLD       = "|cffd4af37"
local ENDC       = "|r"
local FONT       = "Fonts\\FRIZQT__.TTF"

local BG_R,  BG_G,  BG_B  = 0.04, 0.06, 0.12
local BDR_R, BDR_G, BDR_B, BDR_A = 0.78, 0.61, 0.23, 1.00

local BD_MAIN = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left=2, right=2, top=2, bottom=2 },
}
local BD_CELL = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 6,
    insets = { left=1, right=1, top=1, bottom=1 },
}

-- ─── Layout constants (matching PBM_Tab_LevelSync) ───────────────────────────

local PANEL_W    = 1090
local PANEL_H    = 684
local MARGIN     = 15
local CELL_W     = 348
local CELL_H     = 169
local CELL_GAP   = 6
local GRID_COLS  = 3
local GRID_ROWS  = 2
local GRID_TOP   = -52
local SLOT_COUNT = 10
local ROW_H      = 12

-- Cell column offsets (within each cell)
local LVL_X  = 2;   local LVL_W  = 20
local NAM_X  = 26;  local NAM_W  = 110
local TIR_X  = 140; local TIR_W  = 180
local REM_X  = 326; local REM_W  = 16

local GRID_END = GRID_TOP - GRID_ROWS * (CELL_H + CELL_GAP) + CELL_GAP  -- -396

-- Commands section
local CMD_Y    = GRID_END - 42   -- -438
local CMD_STEP = 26
local CMD_COL2 = 375
local CMD_COL3 = 735
local CMD_W    = 330
local cmdStart = CMD_Y - 36      -- -474

-- Notes sub-columns (inside CMD_COL3)
local NOTE_STEP  = 36
local NOTE_W     = 155
local NOTE_COL_A = CMD_COL3 + 4
local NOTE_COL_B = CMD_COL3 + 169

-- ─── Tier short display strings (matches PBM TIER_SHORT) ────────────────────

local TIER_SHORT = {
    [0]  = "None",
    [1]  = "T1 - Molten Core",
    [2]  = "T2 - Blackwing Lair",
    [3]  = "T3 - Ahn'Qiraj War Effort",
    [4]  = "T4 - AQ War",
    [5]  = "T5 - Ahn'Qiraj",
    [6]  = "T6 - Naxxramas 40",
    [7]  = "T7 - Pre-TBC",
    [8]  = "T8 - Karazhan, Gruul's, Mag's",
    [9]  = "T9 - Serpentshrine / TK",
    [10] = "T10 - Hyjal / Black Temple",
    [11] = "T11 - Zul'Aman (Optional)",
    [12] = "T12 - Sunwell Plateau",
    [13] = "T13 - Naxx/EoE/OS",
    [14] = "T14 - Ulduar",
    [15] = "T15 - Trial of the Crusader",
    [16] = "T16 - Icecrown Citadel",
    [17] = "T17 - Ruby Sanctum",
    [18] = "T18 - Complete",
}

-- ─── Tier colors (matches PBM IPTiersColor.lua exactly) ─────────────────────

local TIER_COLORS = {
    [0]  = {r=0.20, g=0.60, b=0.80},
    [1]  = {r=0.70, g=0.36, b=0.00},
    [2]  = {r=0.62, g=0.15, b=0.75},
    [3]  = {r=0.80, g=0.12, b=0.12},
    [4]  = {r=0.18, g=0.49, b=0.20},
    [5]  = {r=0.08, g=0.40, b=0.75},
    [6]  = {r=0.85, g=0.55, b=0.20},
    [7]  = {r=0.65, g=0.22, b=0.78},
    [8]  = {r=0.00, g=0.51, b=0.56},
    [9]  = {r=0.52, g=0.42, b=0.00},
    [10] = {r=0.68, g=0.08, b=0.34},
    [11] = {r=0.33, g=0.43, b=0.48},
    [12] = {r=0.90, g=0.29, b=0.00},
    [13] = {r=0.00, g=0.41, b=0.36},
    [14] = {r=0.28, g=0.38, b=0.85},
    [15] = {r=0.34, g=0.55, b=0.18},
    [16] = {r=0.55, g=0.18, b=0.82},
    [17] = {r=0.00, g=0.38, b=0.39},
    [18] = {r=0.53, g=0.06, b=0.31},
}

-- ─── Helper ───────────────────────────────────────────────────────────────────

local function hexRGB(hex)
    if not hex then return 1, 1, 1 end
    return tonumber(hex:sub(1,2),16)/255,
           tonumber(hex:sub(3,4),16)/255,
           tonumber(hex:sub(5,6),16)/255
end

-- ─── Main Panel ──────────────────────────────────────────────────────────────

local panel = CreateFrame("Frame", "LevelSyncMainFrame", UIParent)
panel:SetSize(PANEL_W, PANEL_H)
panel:SetPoint("CENTER")
panel:SetFrameStrata("FULLSCREEN_DIALOG")
panel:SetMovable(true)
panel:SetClampedToScreen(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
panel:SetBackdrop(BD_MAIN)
panel:SetBackdropColor(BG_R, BG_G, BG_B, 1.0)
panel:SetBackdropBorderColor(BDR_R, BDR_G, BDR_B, BDR_A)

local panelBg = panel:CreateTexture(nil, "ARTWORK")
panelBg:SetAllPoints(panel)
panelBg:SetTexture(BG_R, BG_G, BG_B, 1.0)

-- Gold border lines
local bTop = panel:CreateTexture(nil, "OVERLAY")
bTop:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)
bTop:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, 0)
bTop:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
bTop:SetHeight(2)

local bBot = panel:CreateTexture(nil, "OVERLAY")
bBot:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)
bBot:SetPoint("BOTTOMLEFT",  panel, "BOTTOMLEFT",  0, 0)
bBot:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
bBot:SetHeight(2)

local bLeft = panel:CreateTexture(nil, "OVERLAY")
bLeft:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)
bLeft:SetPoint("TOPLEFT",    panel, "TOPLEFT",    0,  0)
bLeft:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0,  0)
bLeft:SetWidth(2)

local bRight = panel:CreateTexture(nil, "OVERLAY")
bRight:SetTexture(BDR_R, BDR_G, BDR_B, 0.55)
bRight:SetPoint("TOPRIGHT",    panel, "TOPRIGHT",    0, 0)
bRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
bRight:SetWidth(2)

panel:SetScript("OnShow", function()
    panel:SetBackdropColor(BG_R, BG_G, BG_B, 1.0)
    panel:SetBackdropBorderColor(BDR_R, BDR_G, BDR_B, BDR_A)
end)

panel:Hide()
tinsert(UISpecialFrames, "LevelSyncMainFrame")

-- ─── Title bar ───────────────────────────────────────────────────────────────

local titleFS = panel:CreateFontString(nil, "OVERLAY")
titleFS:SetFont(FONT, 13, "OUTLINE")
titleFS:SetPoint("TOP", panel, "TOP", 0, -12)
titleFS:SetText(GOLD.."LevelSync - v1.1"..ENDC)

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

-- ─── Gold separator helper ────────────────────────────────────────────────────

local function goldLine(yAbs)
    local t = panel:CreateTexture(nil, "OVERLAY")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  panel, "TOPLEFT",  MARGIN,  yAbs)
    t:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -MARGIN, yAbs)
    t:SetTexture(GOLD_R, GOLD_G, GOLD_B, 0.55)
    return t
end

goldLine(-38)

-- ─── 3×2 Account cell grid ───────────────────────────────────────────────────

local cells = {}

for idx = 1, 6 do
    local col  = (idx - 1) % GRID_COLS
    local row  = math.floor((idx - 1) / GRID_COLS)
    local xOff = MARGIN + col * (CELL_W + CELL_GAP)
    local yTop = GRID_TOP - row * (CELL_H + CELL_GAP)

    local cell = CreateFrame("Frame", nil, panel)
    cell:SetSize(CELL_W, CELL_H)
    cell:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff, yTop)
    cell:SetBackdrop(BD_CELL)
    cell:SetBackdropColor(0.08, 0.10, 0.18, 1)
    cell:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.80)

    -- Account name header (inside cell, centered)
    local hdrFS = cell:CreateFontString(nil, "OVERLAY")
    hdrFS:SetFont(FONT, 10, "OUTLINE")
    hdrFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -3)
    hdrFS:SetWidth(CELL_W - 4)
    hdrFS:SetJustifyH("CENTER")
    hdrFS:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    hdrFS:SetText("— empty —")

    -- Separator under account name
    local acctSep = cell:CreateTexture(nil, "ARTWORK")
    acctSep:SetHeight(1)
    acctSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -16)
    acctSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -16)
    acctSep:SetTexture(GOLD_R, GOLD_G, GOLD_B, 0.55)

    -- Column headers: Character | Tier (no LvL header, matching PBM)
    local colCharFS = cell:CreateFontString(nil, "OVERLAY")
    colCharFS:SetFont(FONT, 9, "OUTLINE")
    colCharFS:SetPoint("TOPLEFT", cell, "TOPLEFT", NAM_X, -22)
    colCharFS:SetWidth(NAM_W)
    colCharFS:SetJustifyH("LEFT")
    colCharFS:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    colCharFS:SetText("Character")

    local colTierFS = cell:CreateFontString(nil, "OVERLAY")
    colTierFS:SetFont(FONT, 9, "OUTLINE")
    colTierFS:SetPoint("TOPLEFT", cell, "TOPLEFT", TIR_X, -22)
    colTierFS:SetWidth(TIR_W)
    colTierFS:SetJustifyH("LEFT")
    colTierFS:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    colTierFS:SetText("Tier")

    -- Separator under column headers
    local hdrSep = cell:CreateTexture(nil, "ARTWORK")
    hdrSep:SetHeight(1)
    hdrSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -37)
    hdrSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -37)
    hdrSep:SetTexture(0.25, 0.35, 0.55, 0.70)

    -- 10 character slots
    local rows = {}
    for r = 1, SLOT_COUNT do
        local yRow = -(39 + (r - 1) * ROW_H)

        local lvlFS = cell:CreateFontString(nil, "OVERLAY")
        lvlFS:SetFont(FONT, 9, "OUTLINE")
        lvlFS:SetPoint("TOPLEFT", cell, "TOPLEFT", LVL_X, yRow)
        lvlFS:SetWidth(LVL_W)
        lvlFS:SetJustifyH("CENTER")
        lvlFS:SetText("")

        local nameFS = cell:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont(FONT, 9, "OUTLINE")
        nameFS:SetPoint("TOPLEFT", cell, "TOPLEFT", NAM_X, yRow)
        nameFS:SetWidth(NAM_W)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetText("")

        local tierFS = cell:CreateFontString(nil, "OVERLAY")
        tierFS:SetFont(FONT, 9, "OUTLINE")
        tierFS:SetPoint("TOPLEFT", cell, "TOPLEFT", TIR_X, yRow)
        tierFS:SetWidth(TIR_W)
        tierFS:SetJustifyH("LEFT")
        tierFS:SetText("")

        -- Row highlight
        local highlight = cell:CreateTexture(nil, "ARTWORK")
        highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
        highlight:SetSize(CELL_W - 6, ROW_H - 1)
        highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        highlight:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 0.08)
        highlight:Hide()

        -- Transparent hover frame
        local rowBtn = CreateFrame("Button", nil, cell)
        rowBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
        rowBtn:SetSize(CELL_W - 6, ROW_H)
        rowBtn:SetFrameLevel(cell:GetFrameLevel() + 1)
        rowBtn.active = false
        rowBtn:SetScript("OnEnter", function(self)
            if self.active then highlight:Show() end
        end)
        rowBtn:SetScript("OnLeave", function() highlight:Hide() end)

        -- Remove button (×)
        local removeBtn = CreateFrame("Button", nil, cell)
        removeBtn:SetSize(REM_W, ROW_H)
        removeBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", REM_X, yRow)
        removeBtn:SetFrameLevel(cell:GetFrameLevel() + 2)
        removeBtn.charName = ""
        local removeLbl = removeBtn:CreateFontString(nil, "OVERLAY")
        removeLbl:SetFont(FONT, 9, "OUTLINE")
        removeLbl:SetAllPoints(removeBtn)
        removeLbl:SetJustifyH("CENTER")
        removeLbl:SetTextColor(0.70, 0.20, 0.20)
        removeLbl:SetText("×")
        removeBtn.lbl = removeLbl
        removeBtn:SetScript("OnClick", function(self)
            if self.charName ~= "" then
                LS.SendCmd("removechar " .. self.charName)
            end
        end)
        removeBtn:SetScript("OnEnter", function(self)
            self.lbl:SetTextColor(1.0, 0.4, 0.4)
            if rowBtn.active then highlight:Show() end
        end)
        removeBtn:SetScript("OnLeave", function(self)
            self.lbl:SetTextColor(0.70, 0.20, 0.20)
            highlight:Hide()
        end)
        removeBtn:Hide()

        rows[r] = {
            lvlFS     = lvlFS,
            nameFS    = nameFS,
            tierFS    = tierFS,
            removeBtn = removeBtn,
            rowBtn    = rowBtn,
            highlight = highlight,
        }
    end

    cells[idx] = { frame = cell, hdrFS = hdrFS, rows = rows }
end

-- ─── Status bar ──────────────────────────────────────────────────────────────

goldLine(GRID_END - 8)

local statY = GRID_END - 18

local refreshBtn = CreateFrame("Button", nil, panel)
refreshBtn:SetSize(90, 22)
refreshBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", MARGIN, GRID_END - 14)
refreshBtn:SetBackdrop(BD_CELL)
refreshBtn:SetBackdropColor(0.10, 0.08, 0.02, 1)
refreshBtn:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1.0)
refreshBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

local refreshLbl = refreshBtn:CreateFontString(nil, "OVERLAY")
refreshLbl:SetFont(FONT, 10, "OUTLINE")
refreshLbl:SetAllPoints(refreshBtn)
refreshLbl:SetJustifyH("CENTER")
refreshLbl:SetText(GOLD.."Refresh"..ENDC)

refreshBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(1, 0.95, 0.5, 1)
end)
refreshBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(GOLD_R, GOLD_G, GOLD_B, 1.0)
end)
refreshBtn:SetScript("OnClick", function()
    LS.SendCmd("status")
end)

local accountsFS = panel:CreateFontString(nil, "OVERLAY")
accountsFS:SetFont(FONT, 10, "OUTLINE")
accountsFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 192, statY)
accountsFS:SetWidth(130)
accountsFS:SetJustifyH("CENTER")
accountsFS:SetTextColor(0.70, 0.75, 0.85)
accountsFS:SetText("Accounts: —")

local totalCharsFS = panel:CreateFontString(nil, "OVERLAY")
totalCharsFS:SetFont(FONT, 10, "OUTLINE")
totalCharsFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 409, statY)
totalCharsFS:SetWidth(130)
totalCharsFS:SetJustifyH("CENTER")
totalCharsFS:SetTextColor(0.70, 0.75, 0.85)
totalCharsFS:SetText("Characters: —")

local levelSyncFS = panel:CreateFontString(nil, "OVERLAY")
levelSyncFS:SetFont(FONT, 10, "OUTLINE")
levelSyncFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 626, statY)
levelSyncFS:SetWidth(130)
levelSyncFS:SetJustifyH("CENTER")
levelSyncFS:SetTextColor(0.70, 0.75, 0.85)
levelSyncFS:SetText("Level Sync: —")

local ipSyncFS = panel:CreateFontString(nil, "OVERLAY")
ipSyncFS:SetFont(FONT, 10, "OUTLINE")
ipSyncFS:SetPoint("TOPLEFT", panel, "TOPLEFT", 843, statY)
ipSyncFS:SetWidth(130)
ipSyncFS:SetJustifyH("CENTER")
ipSyncFS:SetTextColor(0.70, 0.75, 0.85)
ipSyncFS:SetText("IP Sync: —")

-- Setup label and icon (top-right of status bar, matching PBM)
local setupHdr = panel:CreateFontString(nil, "OVERLAY")
setupHdr:SetFont(FONT, 13, "OUTLINE")
setupHdr:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -(MARGIN + 26), statY)
setupHdr:SetWidth(90)
setupHdr:SetJustifyH("RIGHT")
setupHdr:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
setupHdr:SetText("Setup:")

local setupIcon = CreateFrame("Button", nil, panel)
setupIcon:SetSize(20, 20)
setupIcon:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -MARGIN, GRID_END - 14)
local siTex = setupIcon:CreateTexture(nil, "ARTWORK")
siTex:SetAllPoints(setupIcon)
siTex:SetTexture("Interface\\Icons\\Inv_misc_groupneedmore")
setupIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffd4af37HOW TO USE LEVELSYNC|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("1. Set a |cffFF8C00security key|r for your account:", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync setkey <yourkey>|r", 1, 1, 1)
    GameTooltip:AddLine("   You need this key to add your accounts to the sync group.", 1, 1, 1)
    GameTooltip:AddLine("   |cffff4444Keep it private \226\128\148 it's the \"password\" for linking.|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("2. Link other accounts or characters into your |cff66ccffsync|r group:", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync addaccount <accountname> <key>|r", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync addchar <charname> <key>|r", 1, 1, 1)
    GameTooltip:AddLine("   The key is |cffff4444NOT|r required if you're adding your own account.", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("3. |cff66ccffLevel Sync|r and |cff66ccffIP Sync|r are |cffFF8C00toggle only|r. To toggle:", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync level on|r", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync IP on|r", 1, 1, 1)
    GameTooltip:AddLine("   |cff44dd44Available|r indicates syncs are available.", 1, 1, 1)
    GameTooltip:AddLine("   |cffdd4444Disabled|r indicates syncs are disabled.", 1, 1, 1)
    GameTooltip:AddLine("   A |cffFF8C0010 second cooldown|r is applied after each sync.", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("4. Use |cff66ccffpool gold|r to drain your level sync group members'", 1, 1, 1)
    GameTooltip:AddLine("   wallets into yours:", 1, 1, 1)
    GameTooltip:AddLine("   |cffd4af37.levelsync money|r", 1, 1, 1)
    GameTooltip:Show()
end)
setupIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ─── Commands + Notes section ─────────────────────────────────────────────────

goldLine(CMD_Y)

local cmdHdr = panel:CreateFontString(nil, "OVERLAY")
cmdHdr:SetFont(FONT, 13, "OUTLINE")
cmdHdr:SetPoint("TOPLEFT", panel, "TOPLEFT", MARGIN, CMD_Y - 8)
cmdHdr:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
cmdHdr:SetText("Commands")

local notesHdr = panel:CreateFontString(nil, "OVERLAY")
notesHdr:SetFont(FONT, 13, "OUTLINE")
notesHdr:SetPoint("TOPLEFT", panel, "TOPLEFT", CMD_COL3, CMD_Y - 8)
notesHdr:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
notesHdr:SetText("Notes")

goldLine(CMD_Y - 28)

-- Command entry builder
local function CmdEntry(x, y, cmd, desc)
    local fc = panel:CreateFontString(nil, "OVERLAY")
    fc:SetFont(FONT, 10, "OUTLINE")
    fc:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    fc:SetWidth(CMD_W)
    fc:SetJustifyH("LEFT")
    fc:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    fc:SetText(cmd)

    local fd = panel:CreateFontString(nil, "OVERLAY")
    fd:SetFont(FONT, 9, "OUTLINE")
    fd:SetPoint("TOPLEFT", panel, "TOPLEFT", x + 4, y - 12)
    fd:SetWidth(CMD_W)
    fd:SetJustifyH("LEFT")
    fd:SetTextColor(0.75, 0.75, 0.75)
    fd:SetText(desc)
end

local function BuildCmdColumn(x, entries)
    local cy = cmdStart
    for _, e in ipairs(entries) do
        CmdEntry(x, cy, e[1], e[2])
        cy = cy - CMD_STEP
    end
end

BuildCmdColumn(MARGIN, {
    { ".levelsync setkey <key>",            "Set your account security key"            },
    { ".levelsync addaccount <acct> [key]", "Link all characters from another account" },
    { ".levelsync addchar <name> [key]",    "Link a single character into your group"  },
    { ".levelsync removechar <name>",       "Remove one character from your group"     },
    { ".levelsync removeaccount <acct>",    "Remove all characters of an account"      },
    { ".levelsync removeaccount # <acct#>", "Remove an account by its account number"  },
    { ".levelsync money",                   "Pool all group money to the caller"       },
})

BuildCmdColumn(CMD_COL2, {
    { ".levelsync removeall",                "Disband your sync group"                              },
    { ".levelsync disbandaccount",           "Disband all groups tied to your account"              },
    { ".levelsync listaccount <acct> [key]", "List all characters on an account"                    },
    { ".levelsync status",                   "Show full group summary and all members"              },
    { ".levelsync level on|off",             "Toggle level synchronization for the group"           },
    { ".levelsync IP on|off",                "Toggle progression (IP tier) sync for the group"     },
    { ".levelsync unbindall",                "Resets all instances for target (requires server auth)" },
})

-- Notes builder
local function MakeNote(colX, offsetY, text)
    local n = panel:CreateFontString(nil, "OVERLAY")
    n:SetFont(FONT, 9, "OUTLINE")
    n:SetPoint("TOPLEFT", panel, "TOPLEFT", colX, cmdStart + offsetY)
    n:SetWidth(NOTE_W)
    n:SetJustifyH("LEFT")
    n:SetTextColor(0.75, 0.75, 0.75)
    n:SetText(text)
end

MakeNote(NOTE_COL_A, 0,              "|cffd4af37UPWARD ONLY|r \226\128\148 Levels, XP, and IP tier are never lowered. Sub-max members get pulled up.")
MakeNote(NOTE_COL_A, -NOTE_STEP,     "|cffd4af37SESSION SYNC|r \226\128\148 Syncs must be explicitly triggered via toggle \226\128\148 they do not fire automatically.")
MakeNote(NOTE_COL_A, -NOTE_STEP * 2, "|cffd4af37IP TIER|r \226\128\148 Tier syncs must be triggered manually via the IP toggle.")
MakeNote(NOTE_COL_A, -NOTE_STEP * 3, "|cffd4af37COOLDOWN|r \226\128\148 10-sec shared cooldown covers level, IP, and money commands.")
MakeNote(NOTE_COL_A, -NOTE_STEP * 4, "|cffd4af37SECURITY KEY|r \226\128\148 Controls who can link to your account. Keep it private.")

MakeNote(NOTE_COL_B, 0,              "|cffd4af37DEATH KNIGHTS|r \226\128\148 DK's can't pull up sub-55 levels/IP. Configurable server-side.")
MakeNote(NOTE_COL_B, -NOTE_STEP,     "|cffd4af37MONEY POOL|r \226\128\148 Toggle money pooling on/off. Pools group gold onto the caller.")
MakeNote(NOTE_COL_B, -NOTE_STEP * 2, "|cffd4af37GROUP LIMIT|r \226\128\148 Default cap is 6 accounts per group (up to 10 server-side).")
MakeNote(NOTE_COL_B, -NOTE_STEP * 3, "|cffd4af37UNBIND ALL|r \226\128\148 Uses the GM command to reset target instances.")

-- ─── Footer ──────────────────────────────────────────────────────────────────

local footer = panel:CreateFontString(nil, "OVERLAY")
footer:SetFont(FONT, 10, "OUTLINE")
footer:SetPoint("BOTTOMLEFT",  panel, "BOTTOMLEFT",  MARGIN, 8)
footer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -MARGIN, 8)
footer:SetJustifyH("CENTER")
footer:SetTextColor(0.75, 0.75, 0.75)
footer:SetText("** This tab requires |cffd4af37mod-levelsync|r on your server. Latest release at |cff66ccffgithub.com/Lichborne-AC/mod-levelsync|r")

-- ─── RebuildGrid ─────────────────────────────────────────────────────────────

local function RebuildGrid()
    local d = LS.data

    if d.inGroup then
        accountsFS:SetText("Accounts: |cffd4af37"..d.accountsCur.."/"..d.accountsMax.."|r")
        totalCharsFS:SetText("Characters: |cffd4af37"..d.totalChars.."|r")
        levelSyncFS:SetText("Level Sync: "..(d.levelSync and "|cff44dd44Available|r" or "|cffdd4444Disabled|r"))
        ipSyncFS:SetText("IP Sync: "    ..(d.ipSync    and "|cff44dd44Available|r" or "|cffdd4444Disabled|r"))
    else
        accountsFS:SetText("Accounts: —")
        totalCharsFS:SetText("Characters: —")
        levelSyncFS:SetText("Level Sync: —")
        ipSyncFS:SetText("IP Sync: —")
    end

    local accountOrder = {}
    local accountMap   = {}
    for _, m in ipairs(d.members) do
        if not accountMap[m.accountId] then
            table.insert(accountOrder, m.accountId)
            accountMap[m.accountId] = {}
        end
        table.insert(accountMap[m.accountId], m)
    end

    for cellIdx = 1, 6 do
        local cell  = cells[cellIdx]
        local accId = accountOrder[cellIdx]

        if not accId then
            cell.hdrFS:SetTextColor(0.35, 0.35, 0.50)
            cell.hdrFS:SetText("— empty —")
            cell.frame:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.80)
            for r = 1, SLOT_COUNT do
                cell.rows[r].nameFS:SetText("")
                cell.rows[r].lvlFS:SetText("")
                cell.rows[r].tierFS:SetText("")
                cell.rows[r].removeBtn.charName = ""
                cell.rows[r].removeBtn:Hide()
                cell.rows[r].rowBtn.active = false
                cell.rows[r].highlight:Hide()
            end
        else
            cell.hdrFS:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
            cell.hdrFS:SetText("Account " .. accId)
            cell.frame:SetBackdropBorderColor(GOLD_R*0.7, GOLD_G*0.7, GOLD_B*0.7, 0.9)

            local members = accountMap[accId]
            for r = 1, SLOT_COUNT do
                local m = members[r]
                if m then
                    local cr, cg, cb = hexRGB(LS.CLASS_COLORS[m.class])
                    cell.rows[r].nameFS:SetTextColor(cr, cg, cb)
                    cell.rows[r].nameFS:SetText(m.name)
                    cell.rows[r].lvlFS:SetTextColor(0.83, 0.69, 0.22)
                    cell.rows[r].lvlFS:SetText(tostring(m.level))
                    local tc = TIER_COLORS[m.tierNum] or TIER_COLORS[0]
                    cell.rows[r].tierFS:SetTextColor(tc.r, tc.g, tc.b)
                    cell.rows[r].tierFS:SetText(TIER_SHORT[m.tierNum] or "None")
                    cell.rows[r].removeBtn.charName = m.name
                    cell.rows[r].removeBtn:Show()
                    cell.rows[r].rowBtn.active = true
                else
                    cell.rows[r].nameFS:SetText("")
                    cell.rows[r].lvlFS:SetText("")
                    cell.rows[r].tierFS:SetText("")
                    cell.rows[r].removeBtn.charName = ""
                    cell.rows[r].removeBtn:Hide()
                    cell.rows[r].rowBtn.active = false
                    cell.rows[r].highlight:Hide()
                end
            end
        end
    end
end

-- ─── Public callbacks ────────────────────────────────────────────────────────

function LS.UI_OnDataRefresh()
    RebuildGrid()
end

function LS.UI_OnIPSyncDisabled()
    LS.data.ipSyncDisabled = true
    RebuildGrid()
end

function LS.UI_OnNotification(msg)
    local text = msg:match("%[LevelSync%]%s*(.+)") or msg
    print("|cffd4af37[LevelSync]|r " .. text)
end

-- ─── Toggle ──────────────────────────────────────────────────────────────────

function LS.TogglePanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
        RebuildGrid()
        LS.SendCmd("status")
    end
end
