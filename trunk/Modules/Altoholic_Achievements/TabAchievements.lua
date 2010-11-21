local addonName = "Altoholic"
local addon = _G[addonName]

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"
local GOLD		= "|cFFFFD700"
local THIS_ACCOUNT = "Default"

local ICON_NOT_STARTED = "Interface\\RaidFrame\\ReadyCheck-NotReady" 
local ICON_PARTIAL = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local ICON_COMPLETED = "Interface\\RaidFrame\\ReadyCheck-Ready" 

local parent = "AltoholicTabAchievements"
local classMenu = parent .. "ClassIconMenu"	-- name of mouse over menu frames (add a number at the end to get it)

local view
local highlightIndex

local currentRealm = GetRealmName()
local currentAccount = THIS_ACCOUNT

local DDM_Add = addon.Helpers.DDM_Add
local DDM_AddTitle = addon.Helpers.DDM_AddTitle
local DDM_AddCloseMenu = addon.Helpers.DDM_AddCloseMenu

addon.Tabs.Achievements = {}

local ns = addon.Tabs.Achievements		-- ns = namespace

local function BuildView()
	view = view or {}
	wipe(view)
	
	local cats = GetCategoryList()
	for _, categoryID in ipairs(cats) do
		local _, parentID = GetCategoryInfo(categoryID)
		
		if parentID == -1 then		-- add categories, followed by their respective sub-categories
			table.insert(view, { id = categoryID, isCollapsed = true } )
			
			for _, subCatID in ipairs(cats) do
				local _, subCatParentID = GetCategoryInfo(subCatID)
				if subCatParentID == categoryID then
					table.insert(view, subCatID )
				end
			end
		end
	end
end

local function Header_OnClick(frame)
	highlightIndex = frame.categoryIndex
	local header = view[highlightIndex]
	header.isCollapsed = not header.isCollapsed

	ns:Update();
	AltoholicFrameAchievements:Show()
	addon.Achievements:SetCategory(header.id)
	addon.Achievements:Update()
end

local function Item_OnClick(frame)
	highlightIndex = frame.subCategoryIndex
	local item = view[highlightIndex]
	
	ns:Update();
	AltoholicFrameAchievements:Show()
	addon.Achievements:SetCategory(item)
	addon.Achievements:Update()
end

function ns:UpdateClassIcons()
	local key = addon:GetOption(format("Tabs.Achievements.%s.%s.Column1", currentAccount, currentRealm))
	if not key then	-- first time this realm is displayed
	
		local index = 1

		-- add the first 10 keys found on this realm
		for characterName, characterKey in pairs(DataStore:GetCharacters(currentRealm, currentAccount)) do	
			-- ex: : ["Tabs.Achievements.Default.MyRealm.Column4"] = "Account.realm.alt7"

			addon:SetOption(format("Tabs.Achievements.%s.%s.Column%d", currentAccount, currentRealm, index), characterKey)
			
			index = index + 1
			if index > 10 then
				break
			end
		end
	end
	
	local itemName, itemButton
	for i = 1, 10 do
		itemName = parent .. "_ClassIcon" .. i
		itemButton = _G[itemName]
		
		key = addon:GetOption(format("Tabs.Achievements.%s.%s.Column%d", currentAccount, currentRealm, i))
		
		if key then
			local _, class = DataStore:GetCharacterClass(key)
			local tc = CLASS_ICON_TCOORDS[class]
		
			local itemTexture = _G[itemName .. "IconTexture"]
			itemTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");
			itemTexture:SetTexCoord(tc[1], tc[2], tc[3], tc[4]);
			itemTexture:SetWidth(36);
			itemTexture:SetHeight(36);
			itemTexture:SetAllPoints(itemButton);

			addon:CreateButtonBorder(itemButton)
		
			if DataStore:GetCharacterFaction(key) == "Alliance" then
				itemButton.border:SetVertexColor(0.1, 0.25, 1, 0.5)
			else
				itemButton.border:SetVertexColor(1, 0, 0, 0.5)
			end
			itemButton.border:Show()
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

function ns:Update()
	if not view then
		BuildView()
	end

	local VisibleLines = 15

	local categoryIndex				-- index of the category in the menu table
	local categoryCacheIndex		-- index of the category in the cache table
	local MenuCache = {}
	
	for k, v in pairs (view) do		-- rebuild the cache
		if type(v) == "table" then		-- header
			categoryIndex = k
			table.insert(MenuCache, { linetype=1, nameIndex=k } )
			categoryCacheIndex = #MenuCache
			
			if (highlightIndex) and (highlightIndex == k) then
				MenuCache[#MenuCache].needsHighlight = true
			end
		else
			if view[categoryIndex].isCollapsed == false then
				table.insert(MenuCache, { linetype=2, nameIndex=k, parentIndex=categoryIndex } )
				
				if (highlightIndex) and (highlightIndex == k) then
					MenuCache[#MenuCache].needsHighlight = true
					MenuCache[categoryCacheIndex].needsHighlight = true
				end
			end
		end
	end
	
	local buttonWidth = 156
	if #MenuCache > 15 then
		buttonWidth = 136
	end
	
	local scrollFrame = AltoholicAchievementsMenuScrollFrame
	local offset = FauxScrollFrame_GetOffset( scrollFrame );
	local itemButtom = parent .. "MenuItem"
	for i=1, VisibleLines do
		local line = i + offset
		
		if line > #MenuCache then
			_G[itemButtom..i]:Hide()
		else
			local p = MenuCache[line]
			
			_G[itemButtom..i]:SetWidth(buttonWidth)
			_G[itemButtom..i.."NormalText"]:SetWidth(buttonWidth - 21)
			if p.needsHighlight then
				_G[itemButtom..i]:LockHighlight()
			else
				_G[itemButtom..i]:UnlockHighlight()
			end			
			
			if p.linetype == 1 then
				local catName = GetCategoryInfo(view[p.nameIndex].id)
				
				_G[itemButtom..i.."NormalText"]:SetText(WHITE .. catName)
				_G[itemButtom..i]:SetScript("OnClick", Header_OnClick)
				_G[itemButtom..i].categoryIndex = p.nameIndex
			elseif p.linetype == 2 then
				local catName = GetCategoryInfo(view[p.nameIndex])
				
				_G[itemButtom..i.."NormalText"]:SetText("|cFFBBFFBB   " .. catName)
				_G[itemButtom..i]:SetScript("OnClick", Item_OnClick)
				_G[itemButtom..i].categoryIndex = p.parentIndex
				_G[itemButtom..i].subCategoryIndex = p.nameIndex
			end

			_G[itemButtom..i]:Show()
		end
	end
	
	FauxScrollFrame_Update( scrollFrame, #MenuCache, VisibleLines, 20);
end

function ns:GetRealm()
	return currentRealm, currentAccount
end


-- ** realm selection **
local function OnRealmChange(self, account, realm)
	local oldAccount = currentAccount
	local oldRealm = currentRealm

	currentAccount = account
	currentRealm = realm

	UIDropDownMenu_ClearAll(_G[ parent .. "_SelectRealm" ]);
	UIDropDownMenu_SetSelectedValue(_G[ parent .. "_SelectRealm" ], account .."|".. realm)
	UIDropDownMenu_SetText(_G[ parent .. "_SelectRealm" ], GREEN .. account .. ": " .. WHITE.. realm)
	
	if oldRealm and oldAccount then	-- clear the "select char" drop down if realm or account has changed
		if (oldRealm ~= realm) or (oldAccount ~= account) then
			ns:UpdateClassIcons()
			_G[ parent .. "Status" ]:SetText("")
			addon.Achievements:Update()
		end
	end
end

local function AddRealm(realm, account)
	local info = UIDropDownMenu_CreateInfo(); 

	info.text = format("%s: %s", GREEN..account, WHITE..realm)
	info.value = format("%s|%s", account, realm)
	info.checked = nil
	info.func = OnRealmChange
	info.arg1 = account
	info.arg2 = realm
	UIDropDownMenu_AddButton(info, 1); 
end

function ns:DropDownRealm_Initialize()
	if not currentAccount or not currentRealm then return end

	-- this account first ..
	DDM_AddTitle(GOLD..L["This account"])
	for realm in pairs(DataStore:GetRealms()) do
		local info = UIDropDownMenu_CreateInfo()

		info.text = WHITE..realm
		info.value = format("%s|%s", THIS_ACCOUNT, realm)
		info.checked = nil
		info.func = OnRealmChange
		info.arg1 = THIS_ACCOUNT
		info.arg2 = realm
		UIDropDownMenu_AddButton(info, 1)
	end

	-- .. then all other accounts
	local accounts = DataStore:GetAccounts()
	local count = 0
	for account in pairs(accounts) do
		if account ~= THIS_ACCOUNT then
			count = count + 1
		end
	end
	
	if count > 0 then
		DDM_AddTitle(" ")
		DDM_AddTitle(GOLD..OTHER)
		for account in pairs(accounts) do
			if account ~= THIS_ACCOUNT then
				for realm in pairs(DataStore:GetRealms(account)) do
					local info = UIDropDownMenu_CreateInfo()

					info.text = format("%s: %s", GREEN..account, WHITE..realm)
					info.value = format("%s|%s", account, realm)
					info.checked = nil
					info.func = OnRealmChange
					info.arg1 = account
					info.arg2 = realm
					UIDropDownMenu_AddButton(info, 1)
				end
			end
		end
	end
	
	DDM_AddTitle(" ")
	DDM_AddTitle(GOLD..L["Not started"], ICON_NOT_STARTED)
	DDM_AddTitle(GOLD..L["Started"], ICON_PARTIAL)
	DDM_AddTitle(GOLD..COMPLETE, ICON_COMPLETED)
end


-- ** Icon events **
local function OnCharacterChange(self, id)
	local key = self.value
	if not key then return end

	addon:SetOption(format("Tabs.Achievements.%s.%s.Column%d", currentAccount, currentRealm, id), key)
	ns:UpdateClassIcons()
	addon.Achievements:Update()
end

-- ** Menu Icons **
function ns:Icon_OnEnter(frame)
	local currentMenuID = frame:GetID()
	
	-- hide all
	for i = 1, 8 do
		if i ~= currentMenuID and _G[ classMenu .. i ].visible then
			ToggleDropDownMenu(1, nil, _G[ classMenu .. i ], frame:GetName(), 0, -5);	
			_G[ classMenu .. i ].visible = false
		end
	end

	-- show current
	ToggleDropDownMenu(1, nil, _G[ classMenu .. currentMenuID ], frame:GetName(), 0, -5);	
	_G[ classMenu .. currentMenuID ].visible = true
	
	local key = addon:GetOption(format("Tabs.Achievements.%s.%s.Column%d", currentAccount, currentRealm, currentMenuID))
	if key then
		addon:DrawCharacterTooltip(frame, key)
	end
end

local function ClassIcon_Initialize(self, level)
	local id = self:GetID()
	
	DDM_AddTitle(L["Characters"])
	local nameList = {}		-- we want to list characters alphabetically
	for _, character in pairs(DataStore:GetCharacters(currentRealm, currentAccount)) do
		table.insert(nameList, character)	-- we can add the key instead of just the name, since they will all be like account.realm.name, where account & realm are identical
	end
	table.sort(nameList)
	
	-- get the key associated with this button
	local key = addon:GetOption(format("Tabs.Achievements.%s.%s.Column%d", currentAccount, currentRealm, id)) or ""
	
	for _, character in ipairs(nameList) do
		local info = UIDropDownMenu_CreateInfo(); 
		
		info.text		= DataStore:GetColoredCharacterName(character)
		info.value		= character
		info.func		= OnCharacterChange
		info.checked	= (key == character)
		info.arg1		= id
		UIDropDownMenu_AddButton(info, 1)
	end

	DDM_AddCloseMenu()
end

function ns:OnLoad()
	for i = 1, 10 do
		UIDropDownMenu_Initialize(_G[classMenu..i], ClassIcon_Initialize, "MENU")
	end

end

local function OnAchievementEarned(event, id)
	if id then
		addon.Achievements:Update()
	end
end

addon:RegisterEvent("ACHIEVEMENT_EARNED", OnAchievementEarned)