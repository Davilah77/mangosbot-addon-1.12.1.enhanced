local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_RAID")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_GUILD")
Mangosbot_EventFrame:RegisterEvent("UPDATE")
Mangosbot_EventFrame:Hide()

local VERSION=0

function print(s)
    if (s ~= nil) then DEFAULT_CHAT_FRAME:AddMessage(s); else DEFAULT_CHAT_FRAME:AddMessage("nil"); end
end

local ToolBars = {}
local GroupToolBars = {}
local CommandSeparator = "\\\\"
local DropDownMenu = {}

function SanitizeBotCommand(text)
    if (text == nil) then return text end
    -- Playerbot may decorate talent-list replies with WoW colour/link escape
    -- sequences. Those sequences are valid in received chat but WoW 1.12
    -- rejects them when the same text is sent back as a command.
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "|H.-|h(.-)|h", "%1")
    text = string.gsub(text, "|h", "")
    text = string.gsub(text, "|", "")
    return text
end

function SendBotCommand(text, chat, lang, channel)
    if (chat == "PARTY" and partySize() == 0) then return end
    if (chat == "PARTY") then
        if (GetNumRaidMembers() > 0) then chat = "RAID" end
    end
    -- CMaNGOS Playerbot reads ordinary party/raid chat and whispers.  The
    -- original addon used SendAddonMessage for group commands, a private
    -- protocol used by ike3's aiPlayerbot but ignored by classic Playerbot.
    SendChatMessage(SanitizeBotCommand(text), chat, lang, channel)
end
function SendBotAddonCommand(text, chat, lang, channel)
    SendBotCommand("#a "..text, chat, lang, channel)
end

function GetCurrentBotName()
    if (CurrentBot ~= nil) then return CurrentBot end
    local name = GetUnitName("target")
    if (name ~= nil and botTable ~= nil and botTable[name] ~= nil) then return name end
    return nil
end

function BotRepliesEnabled()
    return frameopts ~= nil and frameopts.replyMessages == true
end

function UpdateReplyButton()
    if (SelectedBotPanels == nil) then return end
    for _, panel in pairs(SelectedBotPanels) do
        if (panel.maintenance ~= nil and panel.maintenance.replyButton ~= nil) then
            if (BotRepliesEnabled()) then
                panel.maintenance.replyButton.tooltip = "Bot command replies: ON"
                panel.maintenance.replyButton:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
            else
                panel.maintenance.replyButton.tooltip = "Bot command replies: OFF"
                panel.maintenance.replyButton:SetBackdropBorderColor(0, 0, 0, 0.0)
            end
        end
    end
end

function ToggleBotReplies()
    if (frameopts == nil) then frameopts = {} end
    frameopts.replyMessages = not BotRepliesEnabled()
    UpdateReplyButton()
end

function SendBotAdminCommand(command)
    local bot = GetCurrentBotName()
    if (bot == nil) then return end
    SendBotCommand(command .. " " .. bot, "SAY")
end

function InitializeCurrentBot()
    SendBotAdminCommand(".bot init")
end

function GearCurrentBot()
    SendBotAdminCommand(".bot gear")
end

function RequestBotTalentList(bot, openWhenReady)
    if (bot == nil) then return end
    if (botTable[bot] == nil) then botTable[bot] = {} end
    botTable[bot].talentBuilds = {}
    botTable[bot].talentBuildCommands = {}
    botTable[bot].talentListBuffer = ""
    botTable[bot].openTalentMenuWhenReady = openWhenReady == true
    botTable[bot].talentListRevision = (botTable[bot].talentListRevision or 0) + 1
    PendingTalentListBots[bot] = true
    SendBotCommand("talents list", "WHISPER", nil, bot)
    local revision = botTable[bot].talentListRevision
    wait(15.0, function(name, expectedRevision)
        if (PendingTalentListBots[name] and botTable[name] ~= nil and botTable[name].talentListRevision == expectedRevision) then
            FinalizeTalentList(name)
        end
    end, bot, revision)
end

function ListCurrentBotTalents()
    RequestBotTalentList(GetCurrentBotName(), false)
end

function ResetCurrentBotTalents()
    local bot = GetCurrentBotName()
    if (bot == nil) then return end
    SendBotCommand(".reset talents " .. bot, "SAY")
    wait(0.3, function(name) SendBotCommand(".reset stats " .. name, "SAY") end, bot)
end

function ApplyTalentBuild(buildName)
    local bot = TalentMenuForBot
    if (bot == nil or buildName == nil) then return end
    local buildCommand = buildName
    if (botTable[bot] ~= nil and botTable[bot].talentBuildCommands ~= nil and botTable[bot].talentBuildCommands[buildName] ~= nil) then
        buildCommand = botTable[bot].talentBuildCommands[buildName]
    end
    SendBotCommand("talents " .. buildCommand, "WHISPER", nil, bot)
    wait(0.3, function(name) SendBotCommand(".reset stats " .. name, "SAY") end, bot)
    PendingTalentListBots[bot] = nil
end

function CreateToolBar(frame, y, name, buttons, x, spacing, register)
    if (x == nil) then x = 5 end
    if (spacing == nil) then spacing = 5 end
    if (register == nil) then register = true end

    if (frame.toolbar == nil) then
        frame.toolbar = {}
    end

    local tb = CreateFrame("Frame", nil, frame)
    tb:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    tb:SetWidth(frame:GetWidth() - x - 5)
    tb:SetHeight(22)
    tb:SetBackdropColor(0,0,0,1.0)
    tb:SetBackdrop({
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    tb:SetBackdropBorderColor(0,0,0,1.0)

    tb.buttons = {}
    for key, button in pairs(buttons) do
        local btn = CreateFrame("Button", nil, tb)
        btn:SetPoint("TOPLEFT", tb, "TOPLEFT", button["index"] * (22 + spacing), 0)
        btn:SetWidth(20)
        btn:SetHeight(20)
        btn:SetBackdrop({
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = false, tileSize = 16, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonDown")
        btn["tooltip"] = button["tooltip"]
        btn:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT", 0, -frame:GetHeight() - 40)
          GameTooltip:SetText(btn["tooltip"])
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        btn["command"] = button["command"]
        btn["emote"] = button["emote"]
        btn["group"] = button["group"]
        btn["handler"] = button["handler"]
        btn["strategy"] = button["strategy"]
        btn["formation"] = button["formation"]
        btn["oneShot"] = button["oneShot"] == true
        btn["stateful"] = button["strategy"] ~= nil and button["strategy"] ~= "" and not btn["oneShot"]
        btn["isActive"] = false
        btn["toolbarFrame"] = tb
        btn["ToolBarButtonOnClick"] = ToolBarButtonOnClick;
        btn:SetScript("OnClick", function()
            if (frame.botName ~= nil) then
                CurrentBot = frame.botName
                SelectedBotPanel = frame
            end
            btn["ToolBarButtonOnClick"](btn, true)
        end)

        local image = CreateFrame("Frame", nil, btn)
        image:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        image:SetWidth(16)
        image:SetHeight(16)
        image.texture = image:CreateTexture(nil, "BACKGROUND")
        local filename = "Interface\\Addons\\Mangosbot\\Images\\" .. button["icon"] .. ".tga"
        image.texture:SetTexture(filename)
        image.texture:SetAllPoints()
        btn.image = image

        tb.buttons[key] = btn
    end

    frame.toolbar[name] = tb
    if (register) then
        ToolBars[name] = buttons
    end
    return buttons
end

function ClickToolBarButton(toolbar, button)
    local btn = ToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
    local btn = GroupToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function OnKeyBindingDown(button)
    local name = GetUnitName("target")
    local self = GetUnitName("player")
    if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target") or name == self)) then
        ClickGroupToolBarButton("group_movement", button)
    else
        ClickToolBarButton("movement", button)
    end
end

function ToolBarButtonOnClick(btn, visual)
    if (btn["handler"] ~= nil) then
        btn["handler"]()
        return
    end

    if (visual and btn["formation"] ~= nil) then
        for _, formationButton in pairs(btn["toolbarFrame"].buttons) do
            formationButton["isActive"] = false
            formationButton:SetBackdropBorderColor(0, 0, 0, 0.0)
        end
        btn["isActive"] = true
        btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
    elseif (visual and btn["stateful"]) then
        btn["isActive"] = not btn["isActive"]
        if (btn["isActive"]) then
            btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
        else
            btn:SetBackdropBorderColor(0, 0, 0, 0.0)
        end
    elseif (visual) then
        btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
        btn["flashToken"] = (btn["flashToken"] or 0) + 1
        local flashToken = btn["flashToken"]
        wait(1.5, function(button, expectedToken)
            if (button["flashToken"] == expectedToken and not button["isActive"]) then
                button:SetBackdropBorderColor(0, 0, 0, 0.0)
            end
        end, btn, flashToken)
    end

    if (btn["emote"] ~= nil) then
        DoEmote(btn["emote"])
    end

    if (btn["group"]) then
        local delay = 0
        for key, command in orderedPairs(btn["command"]) do
            if (command ~= nil and string.len(command) > 0) then
                wait(delay, function(command) SendBotCommand(command, "PARTY") end, command)
                delay = delay + 0.2
            end
        end
    else
        -- A bot chosen in the roster must take precedence over whatever the
        -- player happens to have targeted in the world.
        local bot = CurrentBot
        if (bot == nil) then bot = GetUnitName("target") end
        if (bot == nil) then return end
        local delay = 0
        for key, command in orderedPairs(btn["command"]) do
            if (command ~= nil and string.len(command) > 0) then
                wait(delay, function(command, bot) SendBotCommand(command, "WHISPER", nil, bot) end, command, bot)
                delay = delay + 0.2
            end
        end
    end
end

function ToggleButton(frame, toolbar, button, toggle, mixed)
    local btn = frame.toolbar[toolbar].buttons[button]
    btn["isActive"] = toggle
    if (toggle and mixed) then
        btn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1.0)
    elseif (toggle) then
        btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
    else
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
    end
end

function EnablePositionSaving(frame, frameName)
    frame:SetScript("OnMouseDown", function() this:StartMoving() end)
	frame:SetScript("OnMouseUp", function()
            local button = arg1
            local self = frame
            self:StopMovingOrSizing()

            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end

            local opts = frameopts[frameName]
            local from, _, to, x, y = self:GetPoint()

            opts.anchorFrom = from
            opts.anchorTo = to

            if self.is_expanded then
                if opts.anchorFrom == "TOPLEFT" or opts.anchorFrom == "LEFT" or opts.anchorFrom == "BOTTOMLEFT" then
                    opts.offsetx = x
                elseif opts.anchorFrom == "TOP" or opts.anchorFrom == "CENTER" or opts.anchorFrom == "BOTTOM" then
                    opts.offsetx = x - 151/2
                elseif opts.anchorFrom == "TOPRIGHT" or opts.anchorFrom == "RIGHT" or opts.anchorFrom == "BOTTOMRIGHT" then
                    opts.offsetx = x - 151
                end
            else
                opts.offsetx = x
            end
            opts.offsety = y
        end)

	do
		-------------------------------------------------------------------------------
		-- Restore the panel's position on the screen.
		-------------------------------------------------------------------------------
		local function Reset_Position()
            local self = frame
            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end
			local opts = frameopts[frameName]
			local FixedOffsetX = opts.offsetx

			self:ClearAllPoints()

			if opts.anchorTo == nil then
                self:SetPoint("CENTER", UIParent, "CENTER", self.defaultOffsetX or 0, self.defaultOffsetY or 0)
			else
				self:SetPoint(opts.anchorFrom, UIParent, opts.anchorTo, opts.offsetx, opts.offsety)
			end
		end

		frame:SetScript("OnShow", Reset_Position)
	end	-- do-block
end

function ResizeBotPanel(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame.header:SetWidth(frame:GetWidth())
    frame.header.text:SetWidth(frame.header:GetWidth())
    for toolbarName,toolbar in pairs(ToolBars) do
        frame.toolbar[toolbarName]:SetWidth(frame:GetWidth() - 10)
    end
end

function CreateBotRoster()
    local frame = CreateFrame("Frame", "BotRoster", UIParent)
    frame:Hide()
    frame:SetWidth(186)
    frame:SetHeight(175)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:RegisterForDrag("LeftButton")

    EnablePositionSaving(frame, "BotRoster")

    frame.items = {}
    for i = 1,10 do
        local item = CreateFrame("Frame", "BotRoster_Item" .. i, frame)
        item:SetPoint("TOPLEFT", frame, "TOPLEFT", i * 100, 0)
        item:SetWidth(112)
        item:SetHeight(40)
        item:SetBackdropColor(0,0,0,1)
        item:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = true, tileSize = 16, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 0 }
        })
        item:SetBackdropBorderColor(0.8,0.8,0.8,1)

        item.text = item:CreateFontString("BotRoster_ItemHeader" .. i)
        item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 20, 1)
        item.text:SetWidth(item:GetWidth())
        item.text:SetHeight(22)
        item.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
        item.text:SetJustifyH("LEFT")
        item.text:SetText("Click!")

        local cls = CreateFrame("Button", "BotRoster_ItemHeader" .. i .. "Image", item)
        cls:SetPoint("TOPLEFT", item, "TOPLEFT", 3, -3)
        cls:SetWidth(16)
        cls:SetHeight(16)
        cls:EnableMouse(true)
        cls:RegisterForClicks("LeftButtonDown")
        cls.texture = cls:CreateTexture(nil, "BACKGROUND")
        cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
        cls.texture:SetAllPoints()
        cls:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(item, "ANCHOR_TOPLEFT", 0, -item:GetHeight() - 40)
          GameTooltip:SetText("Bot Control Panel")
          GameTooltip:Show()
        end)
        cls:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        item.cls = cls

        CreateToolBar(item, -18, "quickbar"..i, {
            ["login"] = {
                icon = "login",
                command = {[0] = ""},
                strategy = "",
                tooltip = "Bring bot online",
                index = 0
            },
            ["logout"] = {
                icon = "logout",
                command = {[0] = ""},
                tooltip = "Logout bot",
                strategy = "",
                index = 0
            },
            ["invite"] = {
                icon = "invite",
                command = {[0] = ""},
                tooltip = "Invite to your group",
                strategy = "",
                index = 1
            },
            ["leave"] = {
                icon = "leave",
                command = {[0] = ""},
                tooltip = "Remove from group",
                strategy = "",
                index = 1
            },
            ["whisper"] = {
                icon = "whisper",
                command = {[0] = ""},
                tooltip = "Start whisper chat",
                strategy = "",
                index = 2
            },
            ["summon"] = {
                icon = "summon",
                command = {[0] = ""},
                tooltip = "Summon at meeting stone",
                strategy = "",
                index = 3
            },
            ["menu"] = {
                icon = "menu",
                command = {[0] = ""},
                tooltip = "More...",
                strategy = "",
                index = 4
            }			
        }, 20, 0, false)
        local tb = item.toolbar["quickbar"..i]
        tb:SetBackdropBorderColor(0,0,0,0.0)
        tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 48, 0)
        tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 32, 0)
        tb.buttons["menu"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 64, 0)

        item:Hide()
        frame.items[i] = item
        frame.ShowRequest = false
    end

    CreateToolBar(frame, 0, "quickbar", {
        ["login_all"] = {
            icon = "login",
            command = {[0] = ""},
            strategy = "",
            tooltip = "Bring all bots online",
            index = 0
        },
        ["logout_all"] = {
            icon = "logout",
            command = {[0] = ""},
            tooltip = "Logout all bots",
            strategy = "",
            index = 1
        },
        ["invite_all"] = {
            icon = "invite",
            command = {[0] = ""},
            tooltip = "Invite all bots to your group",
            strategy = "",
            index = 2
        },
        ["leave_all"] = {
            icon = "leave",
            command = {[0] = ""},
            tooltip = "Remove all bots from group",
            strategy = "",
            index = 3
        }
    }, 5, 0, false)
    frame.toolbar["quickbar"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_movement"] = CreateMovementToolBar(frame, 0, "group_movement", true, 5, 0, false)
    frame.toolbar["group_movement"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_formation"] = CreateFormationToolBar(frame, 0, "group_formation", true, 5, 0, false)
    frame.toolbar["group_formation"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_savemana"] = CreateSaveManaToolBar(frame, 0, "group_savemana", true, 5, 0, false)
    frame.toolbar["group_savemana"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic"] = CreateGenericNonCombatToolBar(frame, 0, "group_generic", true, 5, 0, false)
    frame.toolbar["group_generic"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic_combat"] = CreateGenericCombatToolBar(frame, 0, "group_generic_combat", true, 5, 0, false)
    frame.toolbar["group_generic_combat"]:SetBackdropBorderColor(0,0,0,0.0)

    return frame
end

function CreateRtiToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "rti_skull",
            command = {[0] = "rti skull"},
            rti = "skull",
            tooltip = "Attack skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "rti_cross",
            command = {[0] = "rti cross"},
            rti = "cross",
            tooltip = "Attack cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "rti_circle",
            command = {[0] = "rti circle"},
            rti = "circle",
            tooltip = "Attack circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "rti_star",
            command = {[0] = "rti star"},
            rti = "star",
            tooltip = "Attack star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "rti_square",
            command = {[0] = "rti square"},
            rti = "square",
            tooltip = "Attack square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "rti_triangle",
            command = {[0] = "rti triangle"},
            rti = "triangle",
            tooltip = "Attack triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "rti_diamond",
            command = {[0] = "rti diamond"},
            rti = "diamond",
            tooltip = "Attack diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "rti_moon",
            command = {[0] = "rti moon"},
            rti = "moon",
            tooltip = "Attack moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateRtiCcToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "cc_skull",
            command = {[0] = "rti cc skull"},
            rti_cc = "skull",
            tooltip = "CC skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "cc_cross",
            command = {[0] = "rti cc cross"},
            rti_cc = "cross",
            tooltip = "CC cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "cc_circle",
            command = {[0] = "rti cc circle"},
            rti_cc = "circle",
            tooltip = "CC circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "cc_star",
            command = {[0] = "rti cc star"},
            rti_cc = "star",
            tooltip = "CC star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "cc_square",
            command = {[0] = "rti cc square"},
            rti_cc = "square",
            tooltip = "CC square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "cc_triangle",
            command = {[0] = "rti cc triangle"},
            rti_cc = "triangle",
            tooltip = "CC triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "cc_diamond",
            command = {[0] = "rti cc diamond"},
            rti_cc = "diamond",
            tooltip = "CC diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "cc_moon",
            command = {[0] = "rti cc moon"},
            rti_cc = "moon",
            tooltip = "CC moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateMovementToolBar(frame, y, name, group, x, spacing, register)
    local tb = {
        ["follow_master"] = {
            icon = "follow_master",
            command = group and {[0] = "follow", [1] = "pet passive", [2] = "pet follow"} or {[0] = "follow"},
            strategy = "follow",
            tooltip = "Follow me",
            index = 0,
            group = group,
            oneShot = group,
            emote = "follow"
        },
        ["stay"] = {
            icon = "stay",
            command = group and {[0] = "stay", [1] = "pet passive", [2] = "pet stay"} or {[0] = "stay"},
            strategy = "stay",
            tooltip = "Stay in place",
            index = 1,
            group = group,
            oneShot = group,
            emote = "wait"
        }
    }
    local index = 2
    if (not group) then
        tb["runaway"] = {
            icon = "flee",
            command = {[0] = "orders combat passive", [1] = "follow"},
            strategy = "runaway",
            tooltip = "Run away from mobs",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["flee_passive"] = {
        icon = "flee_passive",
        command = group and {[0] = "orders combat passive", [1] = "pet passive", [2] = "pet follow", [3] = "follow"} or {[0] = "orders combat passive", [1] = "follow"},
        strategy = "",
        tooltip = "Ignore everything and follow master",
        index = index,
        group = group,
        oneShot = group,
        emote = "flee"
    }
    index = index + 1

	tb["passive"] = {
		icon = "passive",
		command = group and {[0] = "orders combat passive", [1] = "pet passive", [2] = "pet follow"} or {[0] = "orders combat passive"},
		strategy = "passive",
		tooltip = "Don't rush",
		index = index,
        group = group,
        oneShot = group
	}
    index = index + 1

    if (group) then
        tb["loot"] = {
            icon = "loot",
            command = {[0] = "nc ~loot"},
            strategy = "loot",
            tooltip = "Toggle persistent looting",
            index = index,
            group = group
        }
        index = index + 1
        tb["attack"] = {
            icon = "dps",
            command = {[0] = "attack"},
            strategy = "",
            tooltip = "Attack my target",
            index = index,
            group = group
        }
        index = index + 1
        tb["pull"] = {
            icon = "tank_assist",
            command = {[0] = "pull"},
            strategy = "",
            tooltip = "Pull",
            index = index,
            group = group
        }
        index = index + 1
        tb["summon"] = {
            icon = "summon",
            command = {[0] = "summon"},
            strategy = "",
            tooltip = "Summon at meeting stone",
            index = index,
            group = group
        }
        index = index + 1
    end

    return CreateToolBar(frame, -y, name, tb, x, spacing, register)
end

function CreateFormationToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "formation_near",
            command = {[0] = "formation near"},
            formation = "near",
            tooltip = "Half-circle",
            index = 0,
            group = group
        },
        ["melee"] = {
            icon = "formation_melee",
            command = {[0] = "formation melee"},
            formation = "melee",
            tooltip = "Similar to pets",
            index = 1,
            group = group
        },
        ["arrow"] = {
            icon = "formation_arrow",
            command = {[0] = "formation arrow"},
            formation = "arrow",
            tooltip = "Tank first, dps/healer last",
            index = 2,
            group = group
        },
        ["far"] = {
            icon = "formation_far",
            command = {[0] = "formation far"},
            formation = "far",
            tooltip = "Maintain a distance",
            index = 3,
            group = group
        },
        ["chaos"] = {
            icon = "formation_chaos",
            command = {[0] = "formation chaos"},
            formation = "chaos",
            tooltip = "Move freely",
            index = 4,
            group = group
        }
    }, x, spacing, register)
end

function CreateStanceToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "stance_near",
            command = {[0] = "stance near"},
            stance = "near",
            tooltip = "Default stance",
            index = 0,
            group = group
        },
        ["tank"] = {
            icon = "stance_tank",
            command = {[0] = "stance tank"},
            stance = "tank",
            tooltip = "Off-tank stance",
            index = 1,
            group = group
        },
        ["turnback"] = {
            icon = "stance_turnback",
            command = {[0] = "stance turnback"},
            stance = "turnback",
            tooltip = "Tank the enemy away from party",
            index = 2,
            group = group
        },
        ["behind"] = {
            icon = "stance_behind",
            command = {[0] = "stance behind"},
            stance = "behind",
            tooltip = "Attack from behind (melee)",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function StartUseItem(group)
    local editBox = getglobal("ChatFrameEditBox")
    editBox:Show()
    editBox:SetFocus()
    if (group) then
        if (GetNumRaidMembers() > 0) then
            editBox:SetText("/ra use ")
        else
            editBox:SetText("/p use ")
        end
    else
        local name = CurrentBot
        if (name == nil) then name = GetUnitName("target") end
        if (name ~= nil) then editBox:SetText("/w " .. name .. " use ") end
    end
end

function CMaNGOSAutomaticFeature(feature)
    print("|cffffcc00MangosBot:|r " .. feature .. " is automatic in CMaNGOS Playerbot.")
end

function CreateGenericNonCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["food"] = {
            icon = "food",
            command = {[0] = ""},
            strategy = "food",
            tooltip = "Use food/drink: click, then shift-click the item and press Enter",
            handler = function() StartUseItem(group) end,
            index = 0,
            group = group
        },
        ["buff"] = {
            icon = "bdps",
            command = {[0] = ""},
            strategy = "buff",
            tooltip = "Buff party members (automatic in CMaNGOS)",
            handler = function() CMaNGOSAutomaticFeature("Buffing") end,
            index = 1,
            group = group
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "collect combat loot quest"},
            strategy = "loot",
            tooltip = "Enable looting",
            index = 2,
            group = group
        },
        ["gather"] = {
            icon = "gather",
            command = {[0] = "collect profession objects"},
            strategy = "gather",
            tooltip = "Gather herbs, ore, etc.",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function CreateGenericCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["potions"] = {
            icon = "potions",
            command = {[0] = "co ~potions,?"},
            strategy = "potions",
            tooltip = "Use health and mana potions",
            index = 0,
            group = group
        },
        ["cast_time"] = {
            icon = "cast_time",
            command = {[0] = "co ~cast time,?"},
            strategy = "cast time",
            tooltip = "Do not cast long spells on almost dead targets",
            index = 1,
            group = group
        },
        ["mark_rti"] = {
            icon = "mark_rti",
            command = {[0] = "co ~mark rti,?"},
            strategy = "mark rti",
            tooltip = "Mark current target with raid icon",
            index = 2,
            group = group
        },
        ["ads"] = {
            icon = "ads",
            command = {[0] = "co ~ads,?", [1] = "nc ~ads,?"},
            strategy = "ads",
            tooltip = "Flee if ads might be pulled",
            index = 3,
            group = group
        },
        ["boost"] = {
            icon = "boost",
            command = {[0] = "co ~boost,?"},
            strategy = "boost",
            tooltip = "Boost dps by using cooldowns",
            index = 4,
            group = group
        },
        ["conserve_mana"] = {
            icon = "conserve_mana",
            command = {[0] = "co ~conserve mana,?"},
            strategy = "conserve mana",
            tooltip = "Reduce mana usage at cost of DPS",
            index = 5,
            group = group
        },
        ["cc"] = {
            icon = "cc",
            command = {[0] = "neutralize"},
            strategy = "cc",
            tooltip = "Use crowd control abilities",
            index = 6,
            group = group
        }
    }, x, spacing, register)
end

function CreateSaveManaToolBar(frame, y, name, group, x, spacing, register)
    local buttons = {};
    for i = 1, 5 do
        local level = i
        buttons["savemana"..i] = {
            icon = "savemana"..i,
            command = {[0] = "save mana "..i},
            tooltip = "Save mana level: "..(i>1 and "#"..i or "disabled"),
            index = i - 1,
            group = group,
            savemana = i,
            handler = not group and function() SetCurrentBotSaveMana(level) end or nil
        }
    end
    return CreateToolBar(frame, -y, name, buttons, x, spacing, register)
end

function StartChat()
    local editBox = getglobal("ChatFrameEditBox")
    editBox:Show()
    editBox:SetFocus()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
    editBox:SetText("/w " .. name .. " ")
end

function CreateMaintenanceIconButton(parent, icon, x, y, tooltip, handler, persistent)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(20)
    button:SetHeight(20)
    button:SetBackdrop({
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropBorderColor(0, 0, 0, 0.0)
    -- WoW 1.12 renders these textures reliably only through the same child
    -- frame structure used by the addon's original toolbar buttons.
    local image = CreateFrame("Frame", nil, button)
    image:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    image:SetWidth(16)
    image:SetHeight(16)
    image.texture = image:CreateTexture(nil, "ARTWORK")
    image.texture:SetTexture("Interface\\AddOns\\Mangosbot\\Images\\" .. icon .. ".tga")
    image.texture:SetAllPoints()
    button.image = image
    button.tooltip = tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(button.tooltip)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function()
        if (parent.ownerFrame ~= nil and parent.ownerFrame.botName ~= nil) then
            CurrentBot = parent.ownerFrame.botName
            SelectedBotPanel = parent.ownerFrame
        end
        if not persistent then
            button:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
            button.flashToken = (button.flashToken or 0) + 1
            local flashToken = button.flashToken
            wait(1.5, function(currentButton, expectedToken)
                if currentButton.flashToken == expectedToken then
                    currentButton:SetBackdropBorderColor(0, 0, 0, 0.0)
                end
            end, button, flashToken)
        end
        handler()
    end)
    return button
end

function CreateMaintenancePanel(frame, y)
    local panel = CreateFrame("Frame", nil, frame)
    panel.ownerFrame = frame
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -y)
    panel:SetWidth(280)
    panel:SetHeight(22)
    panel:SetBackdrop({
        bgFile="Interface/ChatFrame/ChatFrameBackground",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    panel:SetBackdropColor(0, 0, 0, 1.0)

    panel.resetTalentsButton = CreateMaintenanceIconButton(panel, "maintenance_reset_talents", 0, 0,
        "Reset Talents: clear this bot's talents, then recalculate its stats.", ResetCurrentBotTalents, false)
    panel.listTalentsButton = CreateMaintenanceIconButton(panel, "maintenance_list_talents", 27, 0,
        "List Talents: ask the bot for every available talent build.", ListCurrentBotTalents, false)
    panel.chooseTalentButton = CreateMaintenanceIconButton(panel, "maintenance_choose_spec", 54, 0,
        "Choose Spec: choose one of the talent builds returned by List Talents.", function() OpenTalentMenuForCurrentBot() end, false)
    panel.initButton = CreateMaintenanceIconButton(panel, "maintenance_match_level", 81, 0,
        "Match Level: match this bot to your level and initialize its basic equipment and abilities.", InitializeCurrentBot, false)
    panel.gearButton = CreateMaintenanceIconButton(panel, "maintenance_gear", 108, 0,
        "Gear: generate level- and specialization-appropriate equipment for this bot.", GearCurrentBot, false)
    panel.replyButton = CreateMaintenanceIconButton(panel, "maintenance_replies", 135, 0,
        "Bot command replies: OFF", ToggleBotReplies, true)

    frame.maintenance = panel
    UpdateReplyButton()
    return panel
end

function CreateSelectedBotPanel(botName)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.botName = botName
    frame:Hide()
    frame:SetWidth(170)
    frame:SetHeight(155)
    local panelIndex = tablelength(SelectedBotPanels or {})
    frame.defaultOffsetX = panelIndex * 28
    frame.defaultOffsetY = panelIndex * -28
    frame:SetPoint("CENTER", UIParent, "CENTER", frame.defaultOffsetX, frame.defaultOffsetY)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString(nil)
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Click!")

    frame.header.role = CreateFrame("Frame", nil, frame.header)
    frame.header.role:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    frame.header.role:SetWidth(16)
    frame.header.role:SetHeight(16)
    frame.header.role.texture = frame.header.role:CreateTexture(nil, "BACKGROUND")
    frame.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_dps.tga")
    frame.header.role.texture:SetAllPoints()

    EnablePositionSaving(frame, "SelectedBotPanel_" .. botName)

    local y = 25
    CreateMovementToolBar(frame, y, "movement", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "actions", {
        ["stats"] = {
            icon = "stats",
            command = {[0] = "stats"},
            strategy = "",
            tooltip = "Tell stats (XP, money, etc.)",
            index = 0
        },
        ["whisper"] = {
            icon = "whisper",
            command = {[0] = ""},
            tooltip = "Start whisper chat",
            strategy = "",
            handler = StartChat,
            index = 1
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "collect combat loot profession quest"},
            strategy = "",
            tooltip = "Loot everything",
            index = 2
        },
        ["release"] = {
            icon = "release",
            command = {[0] = "release"},
            strategy = "",
            tooltip = "Release spirit",
            index = 3
        },
        ["revive"] = {
            icon = "revive",
            command = {[0] = "follow"},
            strategy = "",
            tooltip = "Revive from corpse",
            index = 4
        },
        ["sell"] = {
            icon = "sell",
            command = {[0] = "sell all"},
            strategy = "",
            tooltip = "Sell vendor trash",
            index = 5
        },
        ["talk"] = {
            icon = "talk",
            command = {[0] = "quest fetch"},
            strategy = "",
            tooltip = "Talk",
            index = 6
        },
        ["menu"] = {
            icon = "menu",
            command = {[0] = ""},
            strategy = "",
            tooltip = "More...",
            handler = OpenDropDownMenuForCurrentBot,
            index = 7
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "inventory", {
        ["los"] = {
            icon = "los",
            command = {[0] = "los gos"},
            strategy = "",
            tooltip = "Show nearby game objects",
            index = 0
        },
        ["count"] = {
            icon = "count",
            command = {[0] = "c"},
            strategy = "",
            tooltip = "Show inventory",
            index = 1
        },
        ["bank"] = {
            icon = "bank",
            command = {[0] = "bank"},
            strategy = "",
            tooltip = "Show bank",
            index = 2
        },
        ["spells"] = {
            icon = "spells",
            command = {[0] = "spells"},
            strategy = "",
            tooltip = "Show crafting",
            index = 3
        },
        ["equip"] = {
            icon = "equip",
            command = {[0] = "equip info"},
            strategy = "",
            tooltip = "Show equipment",
            index = 4
        },
        ["mail"] = {
            icon = "mail",
            command = {[0] = "mail ?"},
            strategy = "",
            tooltip = "Show mail",
            index = 5
        }
    })

    y = y + 25
    CreateMaintenancePanel(frame, y)

    y = y + 25
    CreateFormationToolBar(frame, y, "formation", false, 5, 5, true)

    y = y + 25
    CreateStanceToolBar(frame, y, "stance", false, 5, 5, true)

    y = y + 25
    CreateSaveManaToolBar(frame, y, "savemana", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "loot", {
        ["ll_normal"] = {
            icon = "ll_normal",
            command = {[0] = "ll normal"},
            loot = "normal",
            tooltip = "Loot tradeskill items only",
            index = 0
        },
        ["ll_gray"] = {
            icon = "ll_gray",
            command = {[0] = "ll gray"},
            loot = "gray",
            tooltip = "Loot gray items",
            index = 1
        },
        ["ll_disenchant"] = {
            icon = "ll_disenchant",
            command = {[0] = "ll disenchant"},
            loot = "disenchant",
            tooltip = "Loot BoE items for disenchanting",
            index = 2
        },
        ["ll_all"] = {
            icon = "ll_all",
            command = {[0] = "ll all"},
            loot = "all",
            tooltip = "Loot everything",
            index = 3
        },
        ["reveal"] = {
            icon = "stats",
            command = {[0] = "nc ~reveal,?"},
            strategy = "reveal",
            tooltip = "Reveal gathering nodes",
            index = 4
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "attack_type", {
        ["tank_aoe"] = {
            icon = "tank_aoe",
            command = {[0] = "nc +tank aoe,?",[1] = "co +tank aoe,?"},
            strategy = "tank aoe",
            tooltip = "Grab all aggro",
            index = 0
        },
        ["dps_assist"] = {
            icon = "dps_assist",
            command = {[0] = "nc +dps assist,?",[1] = "co +dps assist,?"},
            strategy = "dps assist",
            tooltip = "Assist others",
            index = 1
        },
        ["defense"] = {
            icon = "tank_assist",
            command = {[0] = "nc +defense,?",[1] = "co +defense,?"},
            strategy = "defense",
            tooltip = "Defensive",
            index = 2
        },
        ["grind"] = {
            icon = "grind",
            command = {[0] = "nc +grind,?"},
            strategy = "grind",
            tooltip = "Aggresive mode (grinding)",
            index = 3,
        },
        ["close"] = {
            icon = "close",
            command = {[0] = "co ~close,?"},
            strategy = "close",
            tooltip = "Melee combat",
            index = 4
        },
        ["ranged"] = {
            icon = "ranged",
            command = {[0] = "co ~ranged,?"},
            strategy = "ranged",
            tooltip = "Ranged combat",
            index = 5
        },
        ["threat"] = {
            icon = "threat",
            command = {[0] = "co ~threat,?"},
            strategy = "threat",
            tooltip = "Keep threat level low",
            index = 6
        }
    })

    y = y + 25
    CreateRtiToolBar(frame, y, "rti", false, 5, 5, true)

    y = y + 25
    CreateRtiCcToolBar(frame, y, "rti cc", false, 5, 5, true)

    y = y + 25
    CreateGenericNonCombatToolBar(frame, y, "generic", false, 5, 5, true)

    y = y + 25
    CreateGenericCombatToolBar(frame, y, "generic_combat", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "CLASS_DRUID", {
        ["bear"] = {
            icon = "bear",
            command = {[0] = "co +bear,?"},
            strategy = "bear",
            tooltip = "Use bear form",
            index = 0
        },
        ["cat"] = {
            icon = "cat",
            command = {[0] = "co +cat,?"},
            strategy = "cat",
            tooltip = "Use cat form",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            command = {[0] = "co +caster,?"},
            strategy = "caster",
            tooltip = "Use caster form",
            index = 2
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 3
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 4
        },
        ["melee"] = {
            icon = "dps",
            command = {[0] = "co ~melee,?"},
            strategy = "melee",
            tooltip = "Melee",
            index = 5
        }
    })
    CreateToolBar(frame, -y, "CLASS_HUNTER", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        },
        ["bspeed"] = {
            icon = "bspeed",
            command = {[0] = "co ~bspeed,?", [1] = "nc ~bspeed,?"},
            strategy = "bspeed",
            tooltip = "Buff movement speed",
            index = 2
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 3
        },
        ["rnature"] = {
            icon = "bmana",
            command = {[0] = "co ~rnature,?", [1] = "nc ~rnature,?"},
            strategy = "rnature",
            tooltip = "Provide nature resistance",
            index = 4
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "co ~pet,?", [1] = "nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 5
        }
    })
    CreateToolBar(frame, -y, "CLASS_MAGE", {
        ["arcane"] = {
            icon = "arcane",
            command = {[0] = "co +arcane,?"},
            strategy = "arcane",
            tooltip = "Use arcane spells",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            command = {[0] = "co +fire,?"},
            strategy = "fire",
            tooltip = "Use fire spells",
            index = 1
        },
        ["fire_aoe"] = {
            icon = "fire_aoe",
            command = {[0] = "co ~fire aoe,?"},
            strategy = "fire aoe",
            tooltip = "Use fire AOE abilities",
            index = 2
        },
        ["frost"] = {
            icon = "frost",
            command = {[0] = "co +frost,?"},
            strategy = "frost",
            tooltip = "Use frost spells",
            index = 3
        },
        ["frost_aoe"] = {
            icon = "frost_aoe",
            command = {[0] = "co ~frost aoe,?"},
            strategy = "frost aoe",
            tooltip = "Use frost AOE abilities",
            index = 4
        },
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co ~bmana,?", [1] = "nc ~bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 5
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 6
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 7
        }
    })
    CreateToolBar(frame, -y, "CLASS_PALADIN", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Tank mode",
            index = 1
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 2
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 3
        },
        ["bthreat"] = {
            icon = "bthreat",
            command = {[0] = "nc ~bthreat,?"},
            strategy = "bthreat",
            tooltip = "Increase threat generation",
            index = 4
        }
    })
    CreateToolBar(frame, -y, "CLASS_PRIEST", {
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 0
        },
        ["holy"] = {
            icon = "holy",
            command = {[0] = "co +holy,?"},
            strategy = "holy",
            tooltip = "Use holy spells",
            index = 1
        },
        ["shadow"] = {
            icon = "shadow",
            command = {[0] = "co +shadow,?"},
            strategy = "shadow",
            tooltip = "Dps mode: shadow",
            index = 2
        },
        ["shadow_aoe"] = {
            icon = "shadow_aoe",
            command = {[0] = "co ~shadow aoe,?"},
            strategy = "shadow aoe",
            tooltip = "Use shadow AOE abilities",
            index = 3
        },
        ["shadow_debuff"] = {
            icon = "shadow_debuff",
            command = {[0] = "co ~shadow debuff,?"},
            strategy = "shadow debuff",
            tooltip = "Use shadow debuffs",
            index = 4
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 5
        },
        ["rshadow"] = {
            icon = "rshadow",
            command = {[0] = "co ~rshadow,?", [1] = "nc ~rshadow,?"},
            strategy = "rshadow",
            tooltip = "Provide shadow resistance",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_ROGUE", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN", {
        ["caster"] = {
            icon = "caster",
            command = {[0] = "co +caster,?"},
            strategy = "caster",
            tooltip = "Caster mode",
            index = 0
        },
        ["caster_aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "co ~caster aoe,?"},
            strategy = "caster aoe",
            tooltip = "Use caster AOE abilities",
            index = 1
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,+threat,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 2
        },
        ["melee"] = {
            icon = "dps",
            command = {[0] = "co +melee,?"},
            strategy = "melee",
            tooltip = "Melee mode",
            index = 3
        },
        ["melee_aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~melee aoe,?"},
            strategy = "melee aoe",
            tooltip = "Use melee AOE abilities",
            index = 4
        },
        ["totems"] = {
            icon = "totems",
            command = {[0] = "co ~totems,?"},
            strategy = "totems",
            tooltip = "Use totems",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARLOCK", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["dps_debuff"] = {
            icon = "dps_debuff",
            command = {[0] = "co ~dps debuff,?"},
            strategy = "dps debuff",
            tooltip = "Use DPS debuffs",
            index = 1
        },
        ["caster_aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 2
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Summon tanky demons",
            index = 3
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "co ~pet,?", [1] = "nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 4
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARRIOR", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["warrior_aoe"] = {
            icon = "warrior_aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Tank mode",
            index = 2
        }
    })
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_BUFF", {
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co +bmana,?", [1] = "nc +bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 0
        },
        ["bhealth"] = {
            icon = "bhealth",
            command = {[0] = "co +bhealth,?", [1] = "nc +bhealth,?"},
            strategy = "bhealth",
            tooltip = "Buff health regen",
            index = 1
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co +bdps,?", [1] = "nc +bdps,?"},
            strategy = "bdps",
            tooltip = "Buff melee DPS",
            index = 2
        },
        ["bstats"] = {
            icon = "holy",
            command = {[0] = "co +bstats,?", [1] = "nc +bstats,?"},
            strategy = "bstats",
            tooltip = "Buff stats",
            index = 3
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN_BUFF", {
        ["earth"] = {
            icon = "earth",
            command = {[0] = "co +earth,?"},
            strategy = "earth",
            tooltip = "Use earth spells",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            command = {[0] = "co +fire,?"},
            strategy = "fire",
            tooltip = "Use fire spells",
            index = 1
        },
        ["frost"] = {
            icon = "frost",
            command = {[0] = "co +frost,?"},
            strategy = "frost",
            tooltip = "Use frost spells",
            index = 2
        },
        ["air"] = {
            icon = "air",
            command = {[0] = "co +air,?"},
            strategy = "air",
            tooltip = "Use air spells",
            index = 3
        },
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co ~bmana,?", [1] = "nc ~bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 4
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 5
        },
    })
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_AURA", {
        ["baoe"] = {
            icon = "aoe",
            command = {[0] = "co +baoe,?", [1] = "nc +baoe,?"},
            strategy = "baoe",
            tooltip = "Retribution aura",
            index = 0
        },
        ["rfire"] = {
            icon = "fire",
            command = {[0] = "co +rfire,?", [1] = "nc +rfire,?"},
            strategy = "rfire",
            tooltip = "Fire resistance aura",
            index = 1
        },
        ["rfrost"] = {
            icon = "frost",
            command = {[0] = "co +rfrost,?", [1] = "nc +rfrost,?"},
            strategy = "rfrost",
            tooltip = "Frost resistance aura",
            index = 2
        },
        ["rshadow"] = {
            icon = "rshadow",
            command = {[0] = "co +rshadow,?", [1] = "nc +rshadow,?"},
            strategy = "rshadow",
            tooltip = "Shadow resistance aura",
            index = 3
        },
        ["barmor"] = {
            icon = "barmor",
            command = {[0] = "co +barmor,?", [1] = "nc +barmor,?"},
            strategy = "barmor",
            tooltip = "Devotion aura",
            index = 4
        }
    })
    

    frame:SetHeight(y + 25)
    return frame
end

function SetFrameColor(frame, class)
    local color = RAID_CLASS_COLORS[class]
    if (color == nil) then
        color = {r = 0.5, g = 0.1, b = 0.7};
    end
    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
end

local total = 0
function BotDebugTimer(self, elapsed)
    local elapsed = arg1
    if (elapsed) then
        total = total + elapsed
        if total >= 1 then
            local name = GetUnitName("target")
            if (name) then
                SendBotAddonCommand("debug action", "WHISPER", nil, name)
            end
            total = 0
        end
    end
end

local actionHistory = {}
local MaxDebugLines = 60
function CreateBotDebugPanel()
    local frame = CreateFrame("Frame", "BotDebugPanel", UIParent)
    frame:Hide()
    frame:SetWidth(300)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Debug Info")

    local lineSize = 12
    for i = 1,MaxDebugLines do
        local text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5 -i * lineSize)
        text:SetWidth(frame:GetWidth())
        text:SetHeight(18)
        text:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
        text:SetJustifyH("LEFT")
        text:SetText("Line"..i)
        frame["text"..i] = text

        actionHistory[i] = ""
    end
    frame:SetHeight(MaxDebugLines * lineSize + 30)

    EnablePositionSaving(frame, "BotDebugPanel")

    frame:SetScript("OnUpdate", BotDebugTimer)

    return frame
end

function UpdateBotDebugPanel(message, sender)
    local splitted = splitString2(message, "|")
    local length = tablelength(splitted)
    local filtered = {}
    for i = 1, length do
        local row = splitted[i];
        if (string.find(row, BotDebugFilter)) then
            table.insert(filtered, row)
        end
    end
    
    length = tablelength(filtered)
    BotDebugPanel.header.text:SetText("Debug Info "..length..", Filter: "..BotDebugFilter)
    
    if (length > MaxDebugLines) then length = MaxDebugLines end

    local first = MaxDebugLines - length + 1

    for i = 1, first-1 do
        local line = BotDebugPanel["text"..i]
        local source = BotDebugPanel["text"..(length + i)]
        line:SetText(source:GetText())
    end

    for i = first, MaxDebugLines do
        local idx = i - first + 1
        local name = trim2(filtered[idx])
        local line = BotDebugPanel["text"..i]
        line:SetText(name)
    end
end

function createDropdown(opts)
    local dropdown_name = opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local dropdown_width = 0
    local default_val = opts['defaultVal'] or ''
    local change_func = opts['changeFunc'] or function (dropdown_val) end
    local dropdown = CreateFrame("Frame", dropdown_name, opts['prnt'], "UIDropDownMenuTemplate")

    local dd_title = dropdown:CreateFontString(dropdown, 'OVERLAY', 'GameFontNormal')
    dd_title:SetPoint("TOPLEFT", 20, 10)

    for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
        dd_title:SetText(item)
        local text_width = dd_title:GetStringWidth() + 20
        if text_width > dropdown_width then
            dropdown_width = text_width
        end
    end

    dropdown:SetWidth(dropdown_width)
	getglobal(dropdown:GetName().."Text"):SetText(default_val)
    dd_title:SetText(title_text)
	dd_title:Hide()
	dropdown:Hide()

    UIDropDownMenu_Initialize(dropdown, function(self, level, _)
        local info = {}
        for key, val in pairs(menu_items) do
            info.text = val .. "...";
            info.checked = false
            info.menuList= key
            info.hasArrow = false
			info.justifyH = "LEFT"
            info.func = change_func
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")

    return dropdown
end

local MenuForBot = nil
BotMenuItems = {
	[1] = "Accept quest",
	[2] = "Complete quest",
	[3] = "Choose quest reward [item]",
	[4] = "Fly to",
	[5] = "Bind to innkeeper",
	[6] = "Trainer [spell] learn",
	[7] = "Send me an [item]",
	[8] = "Toggle loot +/-[item]",
	[9] = "Toggle +/-[spell]",
	[10] = "Make me party leader",
}
BotMenuChatTable = {
	[1] = "accept *",
	[2] = "d talk to quest giver",
	[3] = "r ",
	[4] = "taxi ?",
	[5] = "home",
	[6] = "trainer learn",
	[7] = "sendmail ",
	[8] = "ll ",
	[9] = "ss ",
	[10] = "d leader",
}
function CreateDropDownMenu(parent)
	local opts = {
		['name']='more',
		['prnt']=parent,
		['title']='More',
		['items']= BotMenuItems,
		['defaultVal']='', 
		['changeFunc']=function()
			local editBox = getglobal("ChatFrameEditBox")
			local id = this:GetID()
			editBox:Show()
			editBox:SetFocus()
			editBox:SetText("/w " .. MenuForBot .. " " .. BotMenuChatTable[id])
		end
	}
	local menu = createDropdown(opts)
	HideDropDownMenu(1)
	return menu
end

function OpenDropDownMenuForCurrentBot()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
	OpenDropDownMenu(name)
end

function OpenDropDownMenu(bot)
	local scale,x,y=BotRoster:GetEffectiveScale(),GetCursorPosition();
	DropDownMenu:SetPoint("CENTER",nil,"BOTTOMLEFT",x/scale,y/scale);
	MenuForBot = bot
	ToggleDropDownMenu(1, nil, DropDownMenu, 'cursor')
end

TalentMenuForBot = nil
PendingTalentListBots = {}

function CreateTalentDropDownMenu(parent)
    local menu = CreateFrame("Frame", "MangosbotTalentDropDownMenu", parent, "UIDropDownMenuTemplate")
    menu:Hide()
    UIDropDownMenu_Initialize(menu, function()
        local bot = TalentMenuForBot
        if (bot == nil or botTable[bot] == nil or botTable[bot].talentBuilds == nil) then return end
        for _, buildName in pairs(botTable[bot].talentBuilds) do
            local selectedBuild = buildName
            local info = {}
            info.text = selectedBuild
            info.checked = false
            info.justifyH = "LEFT"
            info.func = function() ApplyTalentBuild(selectedBuild) end
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")
    return menu
end

function OpenTalentMenu(bot)
    if (bot == nil) then bot = GetCurrentBotName() end
    if (bot == nil) then return end
    TalentMenuForBot = bot
    local builds = botTable[bot] and botTable[bot].talentBuilds
    if (builds == nil or tablelength(builds) == 0) then
        if (PendingTalentListBots[bot]) then
            botTable[bot].openTalentMenuWhenReady = true
            DEFAULT_CHAT_FRAME:AddMessage("MangosBot: talent specializations are still loading for " .. bot .. ".")
        else
            DEFAULT_CHAT_FRAME:AddMessage("MangosBot: loading talent specializations for " .. bot .. ".")
            RequestBotTalentList(bot, true)
        end
        return
    end
    local scale,x,y = SelectedBotPanel:GetEffectiveScale(),GetCursorPosition()
    TalentDropDownMenu:SetPoint("CENTER",nil,"BOTTOMLEFT",x/scale,y/scale)
    ToggleDropDownMenu(1, nil, TalentDropDownMenu, "cursor")
end

function OpenTalentMenuForCurrentBot()
    OpenTalentMenu(GetCurrentBotName())
end

function SetCurrentBotSaveMana(level)
    local bot = GetCurrentBotName()
    if (bot == nil or level == nil) then return end
    SendBotCommand("save mana " .. level, "WHISPER", nil, bot)
    if (botTable[bot] == nil) then botTable[bot] = {} end
    botTable[bot].savemana = tostring(level)
    for i = 1, 5 do
        ToggleButton(SelectedBotPanel, "savemana", "savemana" .. i, i == level)
    end
end


botTable = {}
SelectedBotPanels = {}
SelectedBotPanel = nil
BotRoster = CreateBotRoster();
BotDebugPanel = CreateBotDebugPanel();
DropDownMenu = CreateDropDownMenu(BotRoster)
TalentDropDownMenu = CreateTalentDropDownMenu(UIParent)
CurrentBot = nil
BotDebugFilter = ""

local function fmod(a,b)
    return a - math.floor(a/b)*b
end

function QueryBotParty()
    -- CMaNGOS Playerbot has no aiPlayerbot strategy-query protocol.
end

function QuerySelectedBot(name)
    -- The panel is populated from the roster and shown locally.  Sending the
    -- old '#a ... ?' queries only produces unknown commands on CMaNGOS.
end

function ShowSelectedBot(name)
    if (name == nil or botTable[name] == nil) then return end

    local panel = SelectedBotPanels[name]
    if (panel == nil) then
        panel = CreateSelectedBotPanel(name)
        SelectedBotPanels[name] = panel
    end
    SelectedBotPanel = panel
    CurrentBot = name

    local bot = botTable[name]
    if (bot["strategy"] == nil) then bot["strategy"] = {nc = {}, co = {}} end
    if (bot["role"] == nil) then bot["role"] = "dps" end

    local class = string.upper(bot["class"] or "")
    SetFrameColor(panel, class)
    panel.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_" .. bot["role"] .. ".tga")
    panel.header.text:SetText(name)

    local width = 0
    local height = 0
    for toolbarName,toolbar in pairs(ToolBars) do
        local panelVisible = true
        if (string.find(toolbarName, "CLASS_") == 1) then
            if (class ~= "" and string.find(string.sub(toolbarName, 7), class) == 1) then
                panel.toolbar[toolbarName]:Show()
            else
                panel.toolbar[toolbarName]:Hide()
                panelVisible = false
            end
        end
        if (panelVisible) then
            local numButtons = tablelength(toolbar)
            height = height + 1
            if (width < numButtons) then width = numButtons end
        end
    end
    height = height + 2
    if (width < 11) then width = 11 end
    UpdateReplyButton()
    ResizeBotPanel(panel, width * 25 + 20, height * 25 + 25)
    panel:Show()
end

function ToggleSelectedBotPanel(name)
    local panel = SelectedBotPanels[name]
    if (panel ~= nil and panel:IsVisible()) then
        panel:Hide()
        if (CurrentBot == name) then CurrentBot = nil end
        return
    end
    ShowSelectedBot(name)
    QuerySelectedBot(name)
end

function AddTalentBuild(bot, buildName, buildCommand)
    if (botTable[bot] == nil) then botTable[bot] = {} end
    if (botTable[bot].talentBuilds == nil) then botTable[bot].talentBuilds = {} end
    if (botTable[bot].talentBuildCommands == nil) then botTable[bot].talentBuildCommands = {} end
    for _, existing in pairs(botTable[bot].talentBuilds) do
        if (existing == buildName) then return false end
    end
    table.insert(botTable[bot].talentBuilds, buildName)
    botTable[bot].talentBuildCommands[buildName] = buildCommand or buildName
    return true
end

function FinalizeTalentList(bot)
    if (bot == nil or not PendingTalentListBots[bot]) then return end
    PendingTalentListBots[bot] = nil
    local count = 0
    if (botTable[bot] ~= nil and botTable[bot].talentBuilds ~= nil) then
        count = tablelength(botTable[bot].talentBuilds)
    end
    if (count > 0) then
        DEFAULT_CHAT_FRAME:AddMessage("MangosBot: " .. count .. " talent specializations loaded for " .. bot .. ".")
        if (botTable[bot].openTalentMenuWhenReady) then
            botTable[bot].openTalentMenuWhenReady = false
            OpenTalentMenu(bot)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("MangosBot: no talent specializations received from " .. bot .. ".")
    end
end

function ScheduleTalentListFinalize(bot)
    if (botTable[bot] == nil) then return end
    botTable[bot].talentListRevision = (botTable[bot].talentListRevision or 0) + 1
    local revision = botTable[bot].talentListRevision
    wait(1.0, function(name, expectedRevision)
        if (PendingTalentListBots[name] and botTable[name] ~= nil and botTable[name].talentListRevision == expectedRevision) then
            FinalizeTalentList(name)
        end
    end, bot, revision)
end

function ParseTalentBuildList(message, sender)
    if (sender == nil or not PendingTalentListBots[sender] or message == nil) then return false end
    local bot = botTable[sender]
    -- Join packets without inserting characters because classic chat may
    -- split in the middle of a build. Add a delimiter only when the server
    -- starts a fresh pve/pvp entry in a new packet without repeating a comma.
    local separator = ""
    if bot.talentListBuffer ~= nil and string.len(bot.talentListBuffer) > 0 then
        local startsFresh = string.find(message, "^pve ") == 1 or string.find(message, "^pvp ") == 1
        if startsFresh and string.sub(bot.talentListBuffer, -1) ~= "," then separator = "," end
    end
    bot.talentListBuffer = (bot.talentListBuffer or "") .. separator .. message
    bot.talentBuilds = {}
    bot.talentBuildCommands = {}
    local found = false
    local entries = splitString2(bot.talentListBuffer, ",")
    for _, entry in pairs(entries) do
        local buildName = trim2(SanitizeBotCommand(entry))
        -- Some classic cores surround each number with hyperlink markers,
        -- leaving text such as h17h/h34h/0h after chat formatting. Convert
        -- every supported representation to the command format 17-34-0.
        buildName = string.gsub(buildName, "h(%d+)h", "%1")
        buildName = string.gsub(buildName, "(%d+)h", "%1")
        local pointsStart, pointsEnd, tree1, tree2, tree3 = string.find(buildName, " %((%d+)[/%-](%d+)[/%-](%d+)%)%.?$")
        local buildCommand = buildName
        if (pointsStart ~= nil) then
            buildCommand = tree1 .. "-" .. tree2 .. "-" .. tree3
            buildName = trim2(string.sub(buildName, 1, pointsStart - 1)) .. " (" .. buildCommand .. ")"
        end
        -- Warrior lists also contain valid named builds without a pve/pvp
        -- prefix (arms axes, fury slam, furyprot, and others). The point
        -- distribution is the reliable marker that an entry is selectable.
        if (pointsStart ~= nil) then
            if (AddTalentBuild(sender, buildName, buildCommand)) then found = true end
        end
    end
    if (found) then ScheduleTalentListFinalize(sender) end
    return found
end

function IsBotGroupReply(message)
    if (message == nil) then return false end
    local prefixes = {
        "Level up!", "pve ", "pvp ", "Following", "Staying", "Fleeing",
        "Formation", "Stance", "Strategies:", "Loot strategy", "Mana save level",
        "rti set to", "rti cc set to"
    }
    for _, prefix in pairs(prefixes) do
        if (string.find(message, prefix) == 1) then return true end
    end
    return false
end

function IsBotStateReply(message)
    if (message == nil) then return false end
    local prefixes = {
        "Strategies: ", "Formation: ", "Stance: ",
        "Mana save level set: ", "Mana save level: ",
        "Loot strategy: ", "rti: ", "rti cc: "
    }
    for _, prefix in pairs(prefixes) do
        if (string.find(message, prefix) == 1) then return true end
    end
    return false
end

function ShouldHideBotChat(chatEvent, message, sender)
    if (BotRepliesEnabled() or sender == nil or botTable[sender] == nil) then return false end
    if (chatEvent == "CHAT_MSG_WHISPER" or chatEvent == "CHAT_MSG_WHISPER_INFORM") then return true end
    if (chatEvent == "CHAT_MSG_PARTY" or chatEvent == "CHAT_MSG_RAID" or chatEvent == "CHAT_MSG_GUILD") then
        return IsBotGroupReply(message)
    end
    return false
end

if (Mangosbot_OriginalChatFrame_OnEvent == nil and ChatFrame_OnEvent ~= nil) then
    Mangosbot_OriginalChatFrame_OnEvent = ChatFrame_OnEvent
    function ChatFrame_OnEvent(chatEvent)
        local currentEvent = chatEvent
        if (currentEvent == nil) then currentEvent = _G.event end
        if (ShouldHideBotChat(currentEvent, arg1, arg2)) then return end
        Mangosbot_OriginalChatFrame_OnEvent(chatEvent)
    end
end

Mangosbot_EventFrame:SetScript("OnEvent", function(self)
    if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_GUILD") then
        ParseTalentBuildList(arg1, arg2)
    end

    if (event == "CHAT_MSG_SYSTEM") then
        local message = arg1
        if (OnSystemMessage(message)) then
            if (BotRoster.ShowRequest) then
                BotRoster:Show()
                BotRoster.ShowRequest = false
            end
            for i = 1,10 do
                BotRoster.items[i]:Hide()
            end
            local index = 1
            local x = 5
            local width = 0
            local height = 0
            local y = 5
            local colCount = 2
            local allBots = ""
            local first = true
            local allBotsLoggedIn = true
            local allBotsLoggedOut = true
            local allBotsInParty = true
            local atLeastOneBotInParty = false
            for key,bot in pairs(botTable) do
                if (index > 10) then 
                    index = 1 
                    y = 5
                end
                local item = BotRoster.items[index]
                if (first) then first = false
                else allBots = allBots .. "," end
                allBots = allBots .. key

                item.text:SetText(key)
                local selectedItem = item
                item.cls["key"] = key
                item.cls:SetScript("OnClick", function()
                    ToggleSelectedBotPanel(selectedItem.cls["key"])
                end)
                -- The name/header area now selects the bot too; previously
                -- only the tiny 16x16 class icon was clickable.
                item:EnableMouse(true)
                item["key"] = key
                item:SetScript("OnMouseDown", function()
                    ToggleSelectedBotPanel(selectedItem["key"])
                end)

                local filename = "Interface\\Addons\\Mangosbot\\Images\\cls_" .. string.lower(bot["class"]) ..".tga"
                item.cls.texture:SetTexture(filename)

                local color = RAID_CLASS_COLORS[string.upper(bot["class"])]
                item.text:SetTextColor(color.r, color.g, color.b, 1.0)

                item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)

                local loginBtn = item.toolbar["quickbar"..index].buttons["login"]
                loginBtn:Hide()
                local logoutBtn = item.toolbar["quickbar"..index].buttons["logout"]
                logoutBtn:Hide()
                local inviteBtn = item.toolbar["quickbar"..index].buttons["invite"]
                inviteBtn:Show()
                local leaveBtn = item.toolbar["quickbar"..index].buttons["leave"]
                leaveBtn:Hide()
                local whisperBtn = item.toolbar["quickbar"..index].buttons["whisper"]
                whisperBtn:Hide()
                local summonBtn = item.toolbar["quickbar"..index].buttons["summon"]
                summonBtn:Hide()
                local menuBtn = item.toolbar["quickbar"..index].buttons["menu"]
                menuBtn:Hide()
                if (bot["online"]) then
                    item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
                    logoutBtn:Show()
                    whisperBtn:Show()
                    summonBtn:Show()
                    menuBtn:Show()
                    local inParty = false
                    for i = 1,5 do
                        if (partyName(i) == key) then
                            inviteBtn:Hide()
                            leaveBtn:Show()
                            atLeastOneBotInParty = true
                            inParty = true
                            item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
                        end
                    end
                    if (not inParty) then allBotsInParty = false end
                    allBotsLoggedOut = false
                else
                    item:SetBackdropBorderColor(0.2,0.2,0.2,1)
                    loginBtn:Show()
                    inviteBtn:Hide()
                    allBotsLoggedIn = false
                end
                loginBtn["key"] = key
                loginBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot add " .. loginBtn["key"], "SAY")
                end)
                logoutBtn["key"] = key
                logoutBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot rm " .. logoutBtn["key"], "SAY")
                end)
                inviteBtn["key"] = key
                inviteBtn:SetScript("OnClick", function()
                    local target = inviteBtn["key"]
                    if (VERSION == 0) then
                        InviteByName(target)
                    else
                        InviteUnit(target)
                    end
                end)
                leaveBtn["key"] = key
                leaveBtn:SetScript("OnClick", function()
                    SendBotCommand("leave", "WHISPER", nil, leaveBtn["key"])
                end)
                whisperBtn["key"] = key
                whisperBtn:SetScript("OnClick", function()
                    local editBox = getglobal("ChatFrameEditBox")
                    editBox:Show()
                    editBox:SetFocus()
                    editBox:SetText("/w " .. whisperBtn["key"] .. " ")
                end)
                summonBtn["key"] = key
                summonBtn:SetScript("OnClick", function()
                    SendBotCommand("summon", "WHISPER", nil, summonBtn["key"])
                end)
                menuBtn["key"] = key
                menuBtn:SetScript("OnClick", function()
					OpenDropDownMenu(menuBtn["key"])
                end)


                item:Show()

                index = index + 1
                x = x + (5 + item:GetWidth())
                height = item:GetHeight()
                if (width < x) then width = x end
                if (fmod((index - 1), colCount) == 0) then
                    y = y + (5 + height)
                    x = 5
                end
            end
            if (fmod((index - 1), colCount) ~= 0) then
                y = y + (5 + height)
            end
            
            if (botCount() >= 10) then 
                y = 230
            end
                        
            local tb = BotRoster.toolbar["quickbar"]
            tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            local loginAllBtn = tb.buttons["login_all"]
            x = 0
            loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedIn) then
                loginAllBtn:Show()
                x = x + 16
            else
                loginAllBtn:Hide()
            end
            loginAllBtn["allBots"] = allBots
            loginAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot add " .. loginAllBtn["allBots"], "SAY")
            end)

            local logoutAllBtn = tb.buttons["logout_all"]
            logoutAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                logoutAllBtn:Show()
                x = x + 16
            else
                logoutAllBtn:Hide()
            end
            logoutAllBtn["allBots"] = allBots
            logoutAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot rm " .. logoutAllBtn["allBots"], "SAY")
            end)

            local inviteAllBtn = tb.buttons["invite_all"]
            inviteAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsInParty) then
                inviteAllBtn:Show()
                x = x + 16
            else
                inviteAllBtn:Hide()
            end
            inviteAllBtn["key"] = key
            inviteAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key)
                        InviteByName(key)
                    end, key)
                    timeout = timeout + 0.1
                end
                wait(1, function() SendBotCommand(".bot list", "SAY") end)
            end)

            local leaveAllBtn = tb.buttons["leave_all"]
            leaveAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (atLeastOneBotInParty) then
                leaveAllBtn:Show()
                x = x + 16
            else
                leaveAllBtn:Hide()
            end
            leaveAllBtn["key"] = key
            leaveAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("leave", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
            end)
            
            local formationToolBar = BotRoster.toolbar["group_formation"]
            if (atLeastOneBotInParty) then
                formationToolBar:Show()
                y = y + 22
                formationToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                formationToolBar:Hide()
            end

            local movementToolBar = BotRoster.toolbar["group_movement"]
            if (atLeastOneBotInParty) then
                movementToolBar:Show()
                y = y + 22
                movementToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                movementToolBar:Hide()
            end

            local savemanaToolBar = BotRoster.toolbar["group_savemana"]
            if (atLeastOneBotInParty) then
                savemanaToolBar:Show()
                y = y + 22
                savemanaToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                savemanaToolBar:Hide()
            end

            local genericToolBar = BotRoster.toolbar["group_generic"]
            if (atLeastOneBotInParty) then
                genericToolBar:Show()
                y = y + 22
                genericToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericToolBar:Hide()
            end

            local genericCombatToolBar = BotRoster.toolbar["group_generic_combat"]
            if (atLeastOneBotInParty) then
                genericCombatToolBar:Show()
                y = y + 22
                genericCombatToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericCombatToolBar:Hide()
            end

            -- Reopening the roster must not clear optimistic ON/OFF markers.
            -- Authoritative strategy replies still refresh them separately.
            BotRoster:SetWidth(width)
            BotRoster:SetHeight(y + 22)
        end
    end

    if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_ADDON") then
        --print(event.." 1 "..arg1.." 2 "..arg2.." 3 "..arg3.." 4 "..arg4)
        local message = arg1
        local sender = arg2
        if (event == "CHAT_MSG_ADDON") then sender = arg4 end
        local stateReply = IsBotStateReply(message)

        OnWhisper(message, sender)
        
        if (BotDebugPanel:IsVisible()) then
            UpdateBotDebugPanel(message, sender)
        end

        if (BotRoster:IsVisible() or (SelectedBotPanel ~= nil and SelectedBotPanel:IsVisible())) then
            if (string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1) then
                SendBotCommand(".bot list", "SAY")
                QueryBotParty()
            end
            if (stateReply) then UpdateGroupToolBar() end
        end

        -- Normal acknowledgements such as "Staying" must not rebuild every
        -- toggle from incomplete state and clear the user's green ON markers.
        if (not stateReply) then return end

        local bot = botTable[sender]
        if (bot == nil or bot["strategy"] == nil or bot["role"] == nil) then
            -- Ordinary CMaNGOS replies do not contain the aiPlayerbot
            -- strategy state expected by the original addon.  Ignore such
            -- replies without closing the user's pinned control panel.
            return
        end
        local panel = SelectedBotPanels[sender]
        if (panel ~= nil) then
            SelectedBotPanel = panel
            panel:Show()

            local tmp, class = "Unknown";
            if (bot["class"] ~= nil) then
                class = string.upper(bot["class"])
            elseif (GetUnitName("target") ~= nil) then
                tmp,class = UnitClass("target")
            end
            SetFrameColor(panel, class)

            local filename = "Interface\\Addons\\Mangosbot\\Images\\role_" .. bot["role"] .. ".tga"
            panel.header.role.texture:SetTexture(filename)
            panel.header.text:SetText(sender)

            local width = 0
            local height = 0
            for toolbarName,toolbar in pairs(ToolBars) do
                local panelVisible = true
                if (string.find(toolbarName, "CLASS_") == 1) then
                    if (string.find(string.sub(toolbarName, 7), class) == 1) then
                        panel.toolbar[toolbarName]:Show()
                    else
                        panel.toolbar[toolbarName]:Hide()
                        panelVisible = false
                    end
                end
                local numButtons = 0
                for buttonName,button in pairs(toolbar) do
                    local toggle = false
                    if (button["strategy"] ~= nil) then
                        for key,strategy in pairs(bot["strategy"]["nc"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                        for key,strategy in pairs(bot["strategy"]["co"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                    end
                    if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                        toggle = true
                    end
                    if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                        toggle = true
                    end
                    if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                        toggle = true
                    end
                    if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                        toggle = true
                    end
                    ToggleButton(panel, toolbarName, buttonName, toggle)
                    numButtons = numButtons + 1
                end
                if (panelVisible) then
                    height = height + 1
                    if (width < numButtons) then width = numButtons end
                end
            end
            height = height + 2
            if (width < 11) then width = 11 end
            UpdateReplyButton()
            ResizeBotPanel(panel, width * 25 + 20, height * 25 + 25)
        end
    end
end)

function UpdateGroupToolBar()
    for toolbarName,toolbar in pairs(GroupToolBars) do
        for buttonName,button in pairs(toolbar) do
            local toggleCount = 0
            for botName,bot in pairs(botTable) do
                local toggle = false
                if (button["strategy"] ~= nil and bot["strategy"] ~= nil) then
                    for key,strategy in pairs(bot["strategy"]["nc"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                    for key,strategy in pairs(bot["strategy"]["co"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                end
                if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                    toggle = true
                end
                if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                    toggle = true
                end
                if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                    toggle = true
                end
                if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                    toggle = true
                end
                if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                    toggle = true
                end
                if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                    toggle = true
                end
                
                if (toggle) then 
                    for i = 1,5 do
                        if (partyName(i) == botName) then
                            toggleCount = toggleCount + 1
                        end
                    end
                end
            end
            ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
        end
    end
end

function trim2(s)

    local find = string.find
    local sub = string.sub
    function trim8(s)
      local i1,i2 = find(s,'^%s*')
      if i2 >= i1 then s = sub(s,i2+1) end
      local i1,i2 = find(s,'%s*$')
      if i2 >= i1 then s = sub(s,1,i1-1) end
      return s
    end
    return trim8(s)
end

function splitString2( self, inSplitPattern, outResults )
  if not inSplitPattern then
    return
  end
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function OnWhisper(message, sender)
    if (botTable[sender] == nil) then
        botTable[sender] = {}
    end

    local bot = botTable[sender]
    if (string.find(message, 'Strategies: ') == 1) then
        local list = {}
        local type = "co"
        local role = "dps"
        local text = string.sub(message, 13)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local name = trim2(splitted[i])
            table.insert(list, name)
            if (name == "nc") then type = 'nc' end
            if (name == "heal") then role = "heal" end
            if (name == "tank" or name == "bear") then role = "tank" end
        end
        if (bot['strategy'] == nil) then
            bot['strategy'] = {nc = {}, co = {}}
        end
        if (type == "co") then
            bot["role"] = role
        end
        bot['strategy'][type] = list
    end
    if (string.find(message, 'Formation: ') == 1) then
        bot['formation'] = string.sub(message, 11)
    end
    if (string.find(message, 'Stance: ') == 1) then
        bot['stance'] = string.sub(message, 11)
    end
    if (string.find(message, 'Mana save level set: ') == 1) then
        bot['savemana'] = string.sub(message, 21)
    end
    if (string.find(message, 'Mana save level: ') == 1) then
        bot['savemana'] = string.sub(message, 17)
    end
    if (string.find(message, 'Loot strategy: ') == 1) then
        bot['loot'] = string.sub(message, 15)
    end
    if (string.find(message, 'rti: ') == 1) then
        bot['rti'] = string.sub(message, 5)
    end
    if (string.find(message, 'rti cc: ') == 1) then
        bot['rti_cc'] = string.sub(message, 5)
    end
end

function OnSystemMessage(message)
    if (string.find(message, 'Bot roster: ') == 1) then
        local previousBotTable = botTable
        botTable = {}
        local text = string.sub(message, 13)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local line = trim2(splitted[i])
            local on = string.sub(line, 1, 1)
            local pos = string.find(line, " ")
            local name = string.sub(line, 2, pos - 1)
            local cls = string.sub(line, pos + 1)

            botTable[name] = previousBotTable[name] or {}
            botTable[name]["class"] = cls
            botTable[name]["online"] = (on == "+")
        end
        return true
    end
    return false
end

SLASH_MANGOSBOT1 = '/bot'
function SlashCmdList.MANGOSBOT(msg, editbox) -- 4.
    if (msg == "" or msg == "roster") then
        if (BotRoster:IsVisible()) then
            BotRoster:Hide()
        else
            BotRoster.ShowRequest = true
            SendBotCommand(".bot list", "SAY")
            QueryBotParty()
        end
    end
    if (string.find(msg, "debug")) then
        local cmd = string.sub(msg, 7)
        if (string.len(cmd) == 0 and BotDebugPanel:IsVisible()) then
            BotDebugPanel:Hide()
        else
            BotDebugPanel:Show()
            BotDebugFilter = cmd;
        end
    end
end

local waitTable = {};
local waitFrame = nil;

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function wait(delay, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("OnUpdate",function ()
      local elapse = 0.1
      local count = tablelength(waitTable);
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9}});
  return true;
end

function partyName(i)
    local p = UnitName("party"..i)
    local r = UnitName("raid"..i)
    if (r == nil) then return p end
    return r
end

function partySize()
    local p = GetNumPartyMembers()
    local r = GetNumRaidMembers()
    if (r == 0) then return p end
    return r
end

function botCount()
  local count = 0
  for _ in pairs(botTable) do count = count + 1 end
  return count
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

print("MangosBOT Addon is loaded");
