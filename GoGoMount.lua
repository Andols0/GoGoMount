local _
---------
function GoGo_OnLoad()
---------
	SLASH_GOGOMOUNT1 = "/gogo"
	SlashCmdList["GOGOMOUNT"] = function(msg) GoGo_OnSlash(msg) end
	SLASH_GOGOID1 = "/id"
	SlashCmdList["GOGOID"] = function(msg) GoGo_Msg(GoGo_Id(msg)) end

	GoGoFrame:RegisterEvent("ADDON_LOADED")
	GoGoFrame:RegisterEvent("UPDATE_BINDINGS")
	GoGoFrame:RegisterEvent("TAXIMAP_OPENED")
	GoGoFrame:RegisterEvent("CHAT_MSG_ADDON")
	GoGoFrame:RegisterEvent("COMPANION_LEARNED")
	GoGoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GoGoFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	GoGoFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	GoGoFrame:RegisterEvent("ZONE_CHANGED")
	
	if GoGo_SLFlying == nil then
		GoGo_SLFlying = false;
	end
end --function

---------
function GoGo_OnEvent(self, event, ...)
---------
	local arg1, arg2, arg3, arg4 = ...
	if event == "ADDON_LOADED" and arg1 == "GoGoMount" then
		GoGo_DebugLog = {}
		if not GoGo_Prefs then
			GoGo_Settings_Default()
		end --if
		GoGo_Prefs.UnknownMounts = {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_OnEvent(ADDON_LOADED): Addon Loaded event fired.")
		end --if
		GoGoFrame:UnregisterEvent("ADDON_LOADED")
		if not GoGo_Prefs_Template then
			GoGo_Prefs_Template = {}
		end --if
		if not GoGo_Prefs.version then
			GoGo_Settings_Default()
		elseif GoGo_Prefs.version ~= C_AddOns.GetAddOnMetadata("GoGoMount", "Version") then
			GoGo_Settings_SetUpdates()
		end --if
		GoGo_Variables.VerMajor, GoGo_Variables.VerMinor, GoGo_Variables.VerBuild = strsplit(".", C_AddOns.GetAddOnMetadata("GoGoMount", "Version"))
		GoGo_Variables.VerMajor, GoGo_Variables.VerMinor, GoGo_Variables.VerBuild = tonumber(GoGo_Variables.VerMajor), tonumber(GoGo_Variables.VerMinor), tonumber(GoGo_Variables.VerBuild)
		_, GoGo_Variables.Player.Class = UnitClass("player")
		_, GoGo_Variables.Player.Race = UnitRace("player")
		GoGo_Variables.Player.Covenant = C_Covenants.GetActiveCovenantID()
		GoGo_Variables.Player.Faction, _ = UnitFactionGroup("player")
		GoGoFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		GoGo_UpdateZonePrefs()  -- Migrate zone settings before attempting to draw options
		if (GoGo_Variables.Player.Class == "DRUID") then
			GoGo_Variables.Druid = {}
--			GoGoFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
			GoGo_Druid_Panel()
		elseif (GoGo_Variables.Player.Class == "SHAMAN") then
			GoGo_Variables.Shaman = {}
--			GoGoFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
			GoGo_Shaman_Panel()
		elseif (GoGo_Variables.Player.Class == "HUNTER") then
			GoGo_Hunter_Panel()
		end --if
		GoGo_Panel_Options()
		GoGo_ZoneFavorites_Panel()
		GoGo_GlobalFavorites_Panel()
		GoGo_ExtraPassengerMounts_Panel()
		GoGo_ZoneExclusions_Panel()
		GoGo_GlobalExclusions_Panel()
		GoGo_CheckBindings()  -- reset key bindings when issuing /console reloadui
		if GoGo_Prefs.autodismount then
			GoGo_SetOptionAutoDismount(1)
		end --if
	elseif event == "PLAYER_REGEN_DISABLED" then
		GoGo_Variables.Player.MapID = C_Map.GetBestMapForUnit("player")
		GoGo_Variables.Player.ZoneID = GoGo_Variables.ZoneMapID[GoGo_Variables.Player.MapID]
		for i, button in ipairs({GoGoButton, GoGoButton2, GoGoButton3, GoGoButton4, GoGoButton5}) do
			if GoGo_Variables.Player.Class == "SHAMAN" then
				if GoGo_Variables.Debug >= 10 then 
					GoGo_DebugAddLine("GoGo_OnEvent: Shaman entering combat.  Setting macro.")
				end --if
				GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["SHAMAN"]))
			elseif GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae and C_Spell.IsSpellUsable(GOGO_SPELLS["NIGHTFAE"]())then
				if GoGo_Variables.Debug >= 10 then 
					GoGo_DebugAddLine("GoGo_OnEvent: Night Fae entering combat.  Setting macro.")
				end --if
				GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["NIGHTFAE"]))
			elseif GoGo_Variables.Player.Class == "DRUID" then
				if not GoGo_Prefs.DruidDisableInCombat then
					GoGo_ZoneCheck()  -- Checking to see what we can and can not do in zones
					GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["DRUID"]))
					if GoGo_Variables.Debug >= 10 then 
						GoGo_DebugAddLine("GoGo_OnEvent: Druid entering combat.  Setting macro.")
					end --if
				else
					if GoGo_Variables.Debug >= 10 then 
						GoGo_DebugAddLine("GoGo_OnEvent: Druid entering combat.  Clearing macro because of set option.")
					end --if
					GoGo_FillButton(button)
				end --if
			elseif GoGo_Variables.Player.ZoneID == 950 then  -- everyone else if in nagrand
				local name = C_Spell.GetSpellInfo(161691).name
				_, _, _, _, _, _, spellID = C_Spell.GetSpellInfo(name)
				if spellID == 165803 or spellID == 164222 then
					if GoGo_Variables.Player.Faction == "Alliance" then
						GoGo_FillButton(button, GoGo_GetIDName(165803))
					elseif GoGo_Variables.Player.Faction == "Horde" then
						GoGo_FillButton(button, GoGo_GetIDName(164222))
					end --if
				end --if
			end --if
		end --for
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_OnEvent(ZONE_CHANGED_NEW_AREA): Event fired.")
		end --if
--		SetMapToCurrentZone()
		GoGo_Variables.Player.Zone = GetRealZoneText()
		GoGo_Variables.Player.MapID = C_Map.GetBestMapForUnit("player")
		GoGo_Variables.Player.ZoneID = GoGo_Variables.ZoneMapID[GoGo_Variables.Player.MapID]
--		GoGo_Variables.Player.ZoneID = GetCurrentMapAreaID()
		if GoGo_Variables.Debug >= 5 then GoGo_ZoneCheck() end --if
		GoGo_UpdateZonePrefs()
		if _G["GoGo_ZoneFavorites_ContentFrame"] and _G["GoGo_ZoneFavorites_ContentFrame"]:IsShown() then
			GoGo_AddOptionCheckboxes("GoGo_ZoneFavorites_ContentFrame")
		end --if
		if _G["GoGo_ZoneExclusions_ContentFrame"] and _G["GoGo_ZoneExclusions_ContentFrame"]:IsShown() then
			GoGo_AddOptionCheckboxes("GoGo_ZoneExclusions_ContentFrame")
		end --if
		-- Covenant is no set properly on start. Try to get it when we change zones
		if (GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NoCovenant) then
		    GoGo_Variables.Player.Covenant = C_Covenants.GetActiveCovenantID()
			if (GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae) then
				GoGo_NightFae_Panel()
			end --if
		end --if
	elseif event == "TAXIMAP_OPENED" then
		GoGo_Dismount()
	elseif event == "UPDATE_BINDINGS" then
		if not InCombatLockdown() then  -- ticket 213
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_OnEvent(UPDATE_BINDINGS): Updating key bindings.")
			end --if
			GoGo_CheckBindings()
		end --if
	elseif event == "UI_ERROR_MESSAGE" then
		if GOGO_ERRORS[arg1] and not IsFlying() then
			GoGo_Dismount()
		end --if
	elseif (event == "PLAYER_ENTERING_WORLD") then
		GoGo_StartStopDebug(0)
		GoGo_Variables.Player.Zone = GetRealZoneText()
		GoGo_Variables.Player.MapID = C_Map.GetBestMapForUnit("player")
		GoGo_Variables.Player.ZoneID = GoGo_Variables.ZoneMapID[GoGo_Variables.Player.MapID]
--		GoGo_Variables.Player.SubZoneID = GetCurrentMapDungeonLevel()
		GoGo_UpdateZonePrefs()
		GoGo_Variables.ExpansionAccount = GetAccountExpansionLevel()
		GoGo_Variables.ExpansionGame =  GetExpansionLevel()
--		local _ = RegisterAddonMessagePrefix("GoGoMountVER")
	elseif (event == "UNIT_TARGET" and arg1 == "player") then  -- find out what mount player is using - only enabled if debug level >= 6
		local GoGo_PlayerName = UnitName("target")
		local i = 1
		GoGo_GetMountDB()  -- get the mount list
		local buff, _, _, _, _, _, _, _, _, _, spellid = UnitAura("target", i)
		while buff do
			if GoGo_Variables.MountDB[spellid] then
				GoGo_DebugAddLine("EVENT UNIT_TARGET: " .. GoGo_PlayerName .. " buffs = " .. buff .. " - " .. spellid)
			end --if
			i = i + 1
			buff, _, _, _, _, _, _, _, _, _, spellid = UnitAura("target", i)
		end --while
	elseif (event == "CHAT_MSG_ADDON") and (arg1 == "GoGoMountVER") and not GoGo_Prefs.DisableUpdateNotice then
		local major, minor, build = strsplit(".", arg2)
		local major, minor, build = tonumber(major), tonumber(minor), tonumber(build)
		
		if not GoGo_Variables.UpdateShown then
			local GoGo_ShowUpdate = false
			if major > GoGo_Variables.VerMajor then
				GoGo_ShowUpdate = true
			elseif (major == GoGo_Variables.VerMajor) and (minor > GoGo_Variables.VerMinor) then
				GoGo_ShowUpdate = true
			elseif (major == GoGo_Variables.VerMajor) and (minor == GoGo_Variables.VerMinor) and (build > GoGo_Variables.VerBuild) then
				GoGo_ShowUpdate = true
			end --if
			
			if GoGo_ShowUpdate then
				GoGo_Variables.UpdateShown = true
				GoGo_Msg(GoGo_Variables.Localize.String.NewVersionFound)
			end --if
		end --if
	end --if
end --function

---------
function GoGo_OnSlash(msg)
---------
	if GOGO_COMMANDS[string.lower(msg)] then
		GOGO_COMMANDS[string.lower(msg)]()
	elseif string.find(msg, "spell:%d+") or string.find(msg, "item:%d+") then
		GoGo_CmdLineLinkProcessing(msg)
	else
		GoGo_Msg("optiongui")
		GoGo_Msg("auto")
		GoGo_Msg("updatenotice")
		GoGo_Msg("mountnotice")
		if GoGo_Variables.Player.Class == "DRUID" then GoGo_Msg("druidclickform") end --if
		if GoGo_Variables.Player.Class == "DRUID" then GoGo_Msg("druidflightform") end --if
		GoGo_Msg("pref")
		GoGo_Msg("globalexclude")
	end --if
end --function

---------
function GoGo_PreClick(button)
---------
	if GoGo_Variables.Debug >= 10 then
		_ = GoGo_DebugCollectInformation()
		GoGo_DebugAddLine("GoGo_PreClick: Starts")
	end --if
	
	if not InCombatLockdown() then
		GoGo_FillButton(button)
	end --if

	if IsMounted() or CanExitVehicle() then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_PreClick: Player is mounted and is being dismounted.")
		end --if
		GoGo_Dismount()
	elseif GoGo_Variables.Player.Class == "DRUID" and GoGo_IsShifted() and not InCombatLockdown() then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a druid, is shifted and not in combat.")
		end --if
		GoGo_Dismount(button)
--	elseif GoGo_Variables.Player.Class == "SHAMAN" and UnitBuff("player", Get1pellInfo(GoGo_Variables.Localize.GhostWolf)) then
	elseif GoGo_Variables.Player.Class == "SHAMAN" and AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.GhostWolf).name, "player") then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a shaman and is in wolf form.  Standing up.")
		end --if
		GoGo_Dismount(button)
	elseif GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae and AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.SoulShape).name, "player") then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_PreClick: Player is in SoulShape form.  Standing up.")
		end --if
		GoGo_Dismount(button)
	elseif not InCombatLockdown() then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_PreClick: Player not in combat, button pressed, looking for a mount.")
		end --if
		GoGo_FillButton(button, GoGo_GetMount())
	end --if
	
--[[ --Disabled for now since Blizzard keeps changing group & raid layouts	
	if not GoGo_Variables.TestVersion then
		if ( IsInGuild() ) then
			if GoGo_Variables.Debug >= 5 then
				GoGo_DebugAddLine("GoGo_PreClick: Is in guild - sending GoGoMount version information to guild addon channel.")
			end --if
			SendAddonMessage("GoGoMountVER", GetAddOnMetadata("GoGoMount", "Version"), "GUILD")
		else
			if GoGo_Variables.Debug >= 5 then
				GoGo_DebugAddLine("GoGo_PreClick: Is not in guild - not sending GoGoMount version information to guild addon channel.")
			end --if
		end --if
		if UnitInRaid("player") and not UnitInBattleground("player") then
			if GoGo_Variables.Debug >= 5 then
				GoGo_DebugAddLine("GoGo_PreClick: Is in raid - sending GoGoMount version information to raid addon channel.")
			end --if
			SendAddonMessage("GoGoMountVER", GetAddOnMetadata("GoGoMount", "Version"), "RAID")
		end --if
--		if UnitInParty("player") and not UnitInBattleground("player") then
--			if GoGo_Variables.Debug >= 5 then
--				GoGo_DebugAddLine("GoGo_PreClick: Is in party - sending GoGoMount version information to party addon channel.")
--			end --if
--			SendAddonMessage("GoGoMountVER", GetAddOnMetadata("GoGoMount", "Version"), "PARTY")
--		end --if
		if UnitInBattleground("player") then
			if GoGo_Variables.Debug >= 5 then
				GoGo_DebugAddLine("GoGo_PreClick: Is in battle ground - sending GoGoMount version information to battle ground addon channel.")
			end --if
			SendAddonMessage("GoGoMountVER", GetAddOnMetadata("GoGoMount", "Version"), "RAID")
		end --if
	end --if ]]
	if GoGo_Variables.Debug >= 10 and not GoGo_Variables.TestVersion then
		GoGo_Variables.Debug = 0
	end --if
end --function

---------
function GoGo_GetMount()
---------
	local GoGo_Mount = GoGo_ChooseMount()	-- find a mount to use
	local GoGo_Macro = ""
	if GoGo_Variables.Player.Class == "DRUID" and GoGo_Mount == GoGo_GetIDName(GoGo_Variables.Localize.RunningWild) .. "()" then
		GoGo_Macro = GoGo_Macro .. GoGo_RemoveBuffs(24858)	-- remove moonkin form - can't use running wild in moonkin form
	end --if
	
	if GoGo_Mount then	-- we have a mount to use so we are mounting
		GoGo_Macro = GoGo_Macro .. GoGo_RemoveBuffs()	-- remove buffs that could prevent us from mounting
--		GoGo_Macro = GoGo_Macro .. GoGo_CrusaderAura()	-- start Crusader Aura if needed  -- no longer available
		-- if GoGo_Macro ~= "" then ...
	end --if
	if GoGo_Macro ~= "" then
		GoGo_Mount = GoGo_Macro .. "/use " .. GoGo_Mount
	end --if
	return GoGo_Mount	-- returning the mount
end --function

---------
function GoGo_ChooseMount()
---------
--	SetMapToCurrentZone()  -- ticket 488
	GoGo_Variables.CanRide = true  -- resetting canride flag
	GoGo_Variables.NoFlying = false -- resetting flag to prevent flying

	local mounts = {}
	GoGo_Variables.FilteredMounts = {}
	GoGo_GetMountDB()

	GoGo_Variables.Player.Zone = GetRealZoneText()
	GoGo_Variables.Player.SubZone = GetSubZoneText()
	GoGo_Variables.Player.MiniSubZone = GetMinimapZoneText()
	GoGo_Variables.EngineeringLevel = GoGo_GetProfSkillLevel(GoGo_Variables.Localize.Skill.Engineering)
	GoGo_Variables.TailoringLevel = GoGo_GetProfSkillLevel(GoGo_Variables.Localize.Skill.Tailoring)
	GoGo_Variables.RidingLevel = GoGo_GetRidingSkillLevel() or 0
	GoGo_Variables.Player.Level = UnitLevel("player")

	GoGo_UpdateZonePrefs()  -- check & build zone preference table for this zone

	if (GoGo_Variables.Player.Class == "DRUID") then
		GoGo_TableAddUnique(GoGo_Variables.WaterSpeed, 101)  -- Aqua Form
		GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 101)  -- Aqua Form
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 130)  -- Cat Form
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 140)  -- Travel Form
	elseif (GoGo_Variables.Player.Class == "SHAMAN") then
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 130)  -- Ghost Wolf
	elseif (GoGo_Variables.Player.Class == "HUNTER") then
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 138) -- Aspects
	elseif (GoGo_Variables.Player.Class == "MONK") then
		GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 160)  -- Zen Flight
	end --if
	if (GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae) then
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 150)  -- Soulshape
	end --if

	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GoGo_Variables.Localize.Skill.Engineering .. " = "..GoGo_Variables.EngineeringLevel)
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GoGo_Variables.Localize.Skill.Tailoring .. " = "..GoGo_Variables.TailoringLevel)
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GoGo_Variables.Localize.Skill.Riding .. " = "..GoGo_Variables.RidingLevel)
	end --if

	if (table.getn(mounts) == 0) and GoGo_Variables.Player.MapID then
		if table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"]) > 0 then
			GoGo_Variables.FilteredMounts = GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"] or {}
			GoGo_CheckForUnknownMounts(GoGo_Variables.FilteredMounts)
			GoGo_Variables.FilteredMounts = GoGo_RemoveUnusableMounts(GoGo_Variables.FilteredMounts)  -- remove mounts blizzard says we can't use
--			GoGo_Variables.UnknownMountMsgShown = true
		end --if
	end --if

	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_ChooseMount: Checked for zone favorites.")
	end --if

	if (table.getn(mounts) == 0) and (table.getn(GoGo_Variables.FilteredMounts) == 0) then
		if GoGo_Prefs.GlobalPrefMounts then
			GoGo_Variables.FilteredMounts = GoGo_Prefs.GlobalPrefMounts or {}
			GoGo_CheckForUnknownMounts(GoGo_Variables.FilteredMounts)
			GoGo_Variables.FilteredMounts = GoGo_RemoveUnusableMounts(GoGo_Variables.FilteredMounts)  -- remove mounts blizzard says we can't use
--			GoGo_Variables.UnknownMountMsgShown = true
		end --if
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checked for global favorites.")
		end --if
	end --if

	if (table.getn(mounts) == 0) and (table.getn(GoGo_Variables.FilteredMounts) == 0) then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checking for spell and item mounts.")
		end --if
		GoGo_Variables.FilteredMounts = GoGo_BuildMountList() or {}
		GoGo_CheckForUnknownMounts(GoGo_Variables.FilteredMounts)
		GoGo_Variables.FilteredMounts = GoGo_RemoveUnusableMounts(GoGo_Variables.FilteredMounts)  -- remove mounts blizzard says we can't use
	end --if


	if ((GoGo_Variables.SelectPassengerMount) and table.getn(GoGo_Prefs.ExtraPassengerMounts) > 0) then
		for GoGo_TempLoopCounter=1, table.getn(GoGo_Prefs.ExtraPassengerMounts) do
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: Passenger mount selected, extras to include.  Including them now.")
			end --if
			GoGo_TableAddUnique(GoGo_Variables.FilteredMounts, GoGo_Prefs.ExtraPassengerMounts[GoGo_TempLoopCounter])
			GoGo_Variables.FilteredMounts = GoGo_RemoveUnusableMounts(GoGo_Variables.FilteredMounts)  -- remove mounts blizzard says we can't use
		end --for
	end --if
	
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_ChooseMount: ** Searched all areas for mounts and found " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts.")
	end --if

	GoGo_ZoneCheck()  -- Checking to see what we can and can not do in zones

	GoGo_UpdateMountData()  -- update mount information with changes from talents, glyphs, etc.
--[[
	if GoGo_Variables.EngineeringLevel <= 299 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 45)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 46)
	elseif GoGo_Variables.EngineeringLevel >= 300 and GoGo_Variables.EngineeringLevel <= 374 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 46)
	elseif GoGo_Variables.EngineeringLevel >= 375 then
		-- filter nothing
	else
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 45)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 46)
	end --if
	if GoGo_Variables.TailoringLevel <= 299 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 49)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 48)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 47)
	elseif GoGo_Variables.TailoringLevel >= 300 and GoGo_Variables.TailoringLevel <= 424 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 49)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 47)
	elseif GoGo_Variables.TailoringLevel >= 425 and GoGo_Variables.TailoringLevel <= 449 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 47)
	elseif GoGo_Variables.TailoringLevel >= 450 then
		-- filter nothing
	else
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 49)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 48)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 47)
	end --if
]]

	if GoGo_Variables.Player.MapID == 1355 then


	elseif GoGo_Variables.RidingLevel <= 224 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 36)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 35)
	elseif GoGo_Variables.RidingLevel >= 225 and GoGo_Variables.RidingLevel <= 299 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 35)
	elseif GoGo_Variables.RidingLevel >= 300 then
		-- filter nothing
	else
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 36)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 35)
	end --if

	if GoGo_Variables.RidingLevel <= 74 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 37)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 38)
	elseif GoGo_Variables.RidingLevel >= 75 and GoGo_Variables.RidingLevel <= 149 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 37)
	end --if

	if IsSubmerged() then
		GoGo_CheckSwimSurface()
	elseif GoGo_Variables.Player.MapID ~= 1355 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 53)
	end --if

	if (GoGo_Variables.Player.Level < 30) then
		if (GoGo_Variables.Player.Level >= 58 and GoGo_Variables.Player.Class == "DRUID") then
			-- do nothing.. druids can fly at 58
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: Disabling flying - under level 30")
			end --if
			GoGo_Variables.NoFlying = true
		end --if
	end --if

--	if GoGo_Variables.ExpansionAccount == 3 then  -- only exists for 4.x with Cataclysm expansion
--		if UnitBuff("player", GetSpellInfo(GoGo_Variables.Localize.SeaLegs)) then
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.SeaLegs).name, "player") then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: Sea Legs buff found - not removing Vashj'ir mount.")
			end --if
			-- do nothing, we can use the abyssal seahorse
			if IsSubmerged() then
				GoGo_Variables.NoFlying = true  -- block flying since we're swimming in vashir and most likely have water breathing buff
			end --if
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: Sea Legs buff not found - removing Vashj'ir mount.")
			end --if
			GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 401)
		end --if
--	end --if

	if GoGo_Prefs.AutoExcludeFlyingMounts and (not GoGo_Variables.ZoneExclude.CanFly or GoGo_Variables.NoFlying) and not GoGo_Variables.SelectHerbMount then
		GoGo_Variables.SkipFlyingMount = true
	end --if


	if (GoGo_Variables.Player.Class == "DRUID" and GoGo_Prefs.DruidFormNotRandomize and not GoGo_IsMoving() and not IsFalling()) then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 9998)
	end --if
	
	if GoGo_Variables.SelectPassengerMount then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts except passenger mounts since passenger mount only was requested.")
		end --if
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 2) or {}
	end --if

	if GoGo_Variables.SelectSellerMount then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts except seller mounts since seller mount only was requested.")
		end --if
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 3) or {}
	end --if

	if GoGo_Variables.SelectHerbMount then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts except herbalism mounts since herbalism only was requested.")
		end --if
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 6) or {}
	end --if

	if GoGo_Variables.SkipFlyingMount then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts that can fly (button 2 pressed or no flying mounts preference set).")
		end --if
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 10003) or {}
	end --if

	if GoGo_Variables.ZoneExclude.NorthrendLoanedMounts then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 52) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated loaned mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	if GoGo_Variables.ZoneExclude.TheOculus then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 54)
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated Oculus mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if
	
	if GoGo_Variables.ZoneExclude.Draenor_Nagrand then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 202) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated Draenor's Nagrand ability mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	if GoGo_Variables.ZoneExclude.AQ40 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 201) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated AQ40 mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	if GoGo_Variables.ZoneExclude.ThousandNeedles then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 200) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated Thousand Needles boat - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	if GoGo_Variables.ZoneExclude.LegionZones then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 203) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated mounts requiring Legion zones - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	if not GoGo_Variables.SwimSurface then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 55) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated mounts requiring water surface - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

--[[
	if not GoGo_InBook(GoGo_Variables.Localize.CloudSerpentRiding) then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 100) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated mounts requiring Cloud Serpent Riding - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if
]]

	if IsFalling() or GoGo_IsMoving() then  -- we're falling.. save us  (only grab instant cast spells)
		local GoGo_TempMounts = {}
		GoGo_TempMounts = GoGo_GetInstantMounts(GoGo_Variables.FilteredMounts) or {}
		if table.getn(GoGo_TempMounts) == 0 then
			GoGo_TempMounts = GoGo_GetMountsWhileMoving(GoGo_Variables.FilteredMounts) or {}
		end --if
		GoGo_Variables.FilteredMounts = GoGo_TempMounts or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated all mounts except mounts that can be summoned while moving or falling - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if
	
	-- The True Maw Walker is not in the speelbook. Using quest completion instead
	if not (GoGo_Variables.ZoneExclude.TheMaw or C_QuestLog.IsQuestFlaggedCompleted(GoGo_Variables.Localize.TheTrueMawWalkerQuest) ) then
	    -- cannot summon mounts in The Maw
	    GoGo_Variables.FilteredMounts = GoGo_GetInstantMounts(GoGo_Variables.FilteredMounts) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated all mounts except mounts that can be summoned in The Maw - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if


	if GoGo_Variables.ZoneExclude.RestrictedIndoorMounts then  -- only select what we can use in here..
		GoGo_Variables.FilteredMounts = GoGo_GetIndoorMounts(GoGo_Variables.FilteredMounts) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated all mounts except indoor mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if

	GoGo_RemoveExcluded()
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated excluded mounts - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
	end --if
	
	if GoGo_Variables.ZoneExclude.UseMountGroup then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, GoGo_Variables.ZoneExclude.UseMountGroup) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Selected specific group of mounts - " .. GoGo_Variables.ZoneExclude.UseMountGroup .. " - " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if
	
	if GoGo_Variables.ZoneExclude.CanFly and not GoGo_Variables.SkipFlyingMount and not GoGo_Variables.NoFlying then
		GoGo_Variables.CanFly = true
	else
		GoGo_Variables.CanFly = false
	end --if 

	if GoGo_Variables.Debug >= 6 then
		GoGo_DebugAddLine("GoGo_ChooseMount: ZoneExclude.Canfly = " .. tostring(GoGo_Variables.ZoneExclude.CanFly))
		GoGo_DebugAddLine("GoGo_ChooseMount: SkipFlyingMount = " .. tostring(GoGo_Variables.SkipFlyingMount))
		GoGo_DebugAddLine("GoGo_ChooseMount: NoFlying = " .. tostring(GoGo_Variables.NoFlying))
	end --if
	
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated mounts we can't use; " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
	end --if

	if IsSubmerged() and not GoGo_Variables.CanFly then  -- find a mount to use in water
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Swimming and can't fly.")
		end --if
		-- indoors shouldn't matter now since we've filtered out anything that can't be used indoors above
		--if not IsIndoors() then
			mounts = GoGo_GetBestWaterMounts(GoGo_Variables.FilteredMounts) or {}
		--else  -- we are indoors
		--	if (table.getn(mounts) == 0) and (GoGo_Variables.Player.Class == "DRUID") and GoGo_InBook(GoGo_Variables.Localize.AquaForm) then
		--		return GoGo_InBook(GoGo_Variables.Localize.AquaForm)
		--	end --if
		--end --if
	elseif IsSubmerged() and GoGo_Variables.CanFly then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Swimming but can fly.")
		end --if
		mounts = GoGo_GetBestAirMounts(GoGo_Variables.FilteredMounts) or {}
		if table.getn(mounts) == 0 then	
			mounts = GoGo_GetBestWaterMounts(GoGo_Variables.FilteredMounts) or {}
		end --if
	end --if

	if GoGo_Variables.Player.MapID ~= 1355 then
	GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 53)
	end
	
	-- Force Dragon riding mounts only
	if (#mounts == 0) and GoGo_Variables.ZoneExclude.DragonRiding and not(GoGo_Variables.SkipFlyingMount) then
		mounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 406) or {}
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Forcing Dragon riding mounts.")
		end --if		-- if this comes empty we will still have ground mounts
	end
	
	if (table.getn(mounts) == 0) and GoGo_Variables.CanFly then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for flying mounts since we past flight checks.")
		end --if
		mounts = GoGo_GetBestAirMounts(GoGo_Variables.FilteredMounts)
--	elseif (table.getn(mounts) == 0) and UnitBuff("player", GetSpellInfo(168796)) then
	elseif (table.getn(mounts) == 0) and AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(168796).name, "player") then
		-- Druids in Ashran with "Book of Flight Form" buff can fly in Ashran zones
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Didn't pass flight checks but we're a Druid with buff 168796 so we're attempting to select flight form to fly.")
		end --if
		mounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 501) or {}
	else
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Not looking for flying mounts since we didn't past flight checks (or found a better mount to use).")
		end --if
	end --if
	
	-- Set the oculus mounts as the only mounts available if we're in the oculus, not skiping flying and have them in inventory
	if (table.getn(mounts) == 0) and (table.getn(GoGo_Variables.FilteredMounts) > 0) and not GoGo_Variables.ZoneExclude.TheOculus and not GoGo_Variables.SkipFlyingMount then  -- skip flying is here because we already know we can't normally fly here
		mounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 54) or {}
		if (table.getn(mounts) > 0) then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, Oculus only mount found, using.")
			end --if
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, no oculus mount found in inventory.")
			end --if
		end --if
	end --if

	if (table.getn(GoGo_Variables.FilteredMounts) >= 1) then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, "FlightOnly")
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Eliminated mounts that require skill 225 or 300 to use; " .. (table.getn(GoGo_Variables.FilteredMounts) or 0) .. " mounts left.")
		end --if
	end --if
	--
	if not GoGo_Variables.ZoneExclude.DRIVE and GoGo_InBook(1215279) then
		mounts = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 332)
	end

	-- Select ground mounts
	if (table.getn(mounts) == 0) and GoGo_Variables.CanRide then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for ground mounts since we can't fly.")
		end --if
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Ground mount count = " .. table.getn(GoGo_Variables.FilteredMounts) .. ".")
		end --if
		if (table.getn(mounts) == 0) then
			mounts = GoGo_GetBestGroundMounts(GoGo_Variables.FilteredMounts) or {}
		end --if
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_ChooseMount: Mount count of 100% = " .. table.getn(mounts) .. ".")
		end --if
	end --if
	
	if table.getn(GoGo_Variables.FilteredMounts) >= 1 then
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 37)
		GoGo_Variables.FilteredMounts = GoGo_FilterMountsOut(GoGo_Variables.FilteredMounts, 38)
	end --if
	
	if (table.getn(mounts) >= 1) then
		if GoGo_Variables.Debug >= 10 then
			for a = 1, table.getn(mounts) do
				GoGo_DebugAddLine("GoGo_ChooseMount: Found mount " .. mounts[a] .. " - included in random pick.")
			end --for
		end --if
		local selected = mounts[math.random(table.getn(mounts))]

		if GoGo_Variables.Debug >= 5 then
			if 	GoGo_Variables.MountDB[selected][10001] then
				GoGo_DebugAddLine("GoGo_ChooseMount: Under water mount speed should be " .. GoGo_Variables.MountDB[selected][10001])
			end --if
			if 	GoGo_Variables.MountDB[selected][10002] then
				GoGo_DebugAddLine("GoGo_ChooseMount: Ground mount speed should be " .. GoGo_Variables.MountDB[selected][10002])
			end --if
			if 	GoGo_Variables.MountDB[selected][10003] then
				GoGo_DebugAddLine("GoGo_ChooseMount: Air mount speed should be " .. GoGo_Variables.MountDB[selected][10003])
			end --if
			if 	GoGo_Variables.MountDB[selected][10004] then
				GoGo_DebugAddLine("GoGo_ChooseMount: Water surface mount speed should be " .. GoGo_Variables.MountDB[selected][10004])
			end --if
		end --if

		if type(selected) == "string" then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_ChooseMount: Selected string " .. selected)
			end --if
			return selected
		else
			local GoGo_SpellTemp = {}
			table.insert(GoGo_SpellTemp, selected)
			GoGo_SpellTemp = GoGo_FilterMountsIn(GoGo_SpellTemp, 50000)
			selected = GoGo_GetIDName(selected)
			if table.getn(GoGo_SpellTemp) == 0 then
				selected = selected .. "()"
			end --if
			return selected
		end --if
	end --if
end --function

---------
function GoGo_FilterMountsOut(PlayerMounts, FilterID)
---------
	local GoGo_FilteringMounts = {}
	if not PlayerMounts then PlayerMounts = {} end --if --Make sure at least something is passed.
	if table.getn(PlayerMounts) == 0 then --return if passed nothing.
		return GoGo_FilteringMounts
	end --if
	if not GoGo_Variables.MountDB then --If passed the wrong object fetch the correct one
		GoGo_GetMountDB()
	end --if
	for a = 1, table.getn(PlayerMounts) do
		local MountID = PlayerMounts[a]
		if not GoGo_Variables.MountDB[MountID][FilterID] then
			table.insert(GoGo_FilteringMounts, MountID)
		end --if
	end --for
	return GoGo_FilteringMounts
end --function

---------
function GoGo_FilterMountsIn(PlayerMounts, FilterID, Value)
---------
	local GoGo_FilteringMounts = {}
	if not PlayerMounts then PlayerMounts = {} end --if
	if table.getn(PlayerMounts) == 0 then
		return GoGo_FilteringMounts
	end --if
	if Value == nil then
		local Value = true
	end --if
	if not GoGo_Variables.MountDB then
		GoGo_GetMountDB()
	end --if
	
	for a = 1, table.getn(PlayerMounts) do
		local MountID = PlayerMounts[a]
		if GoGo_Variables.MountDB[MountID] then
			if GoGo_Variables.MountDB[MountID][FilterID] then
				if Value and GoGo_Variables.MountDB[MountID][FilterID] == Value then
					table.insert(GoGo_FilteringMounts, MountID)
				elseif Value == nil then
					table.insert(GoGo_FilteringMounts, MountID)
				end --if
			end --if
		else
			if GoGo_Variables.Debug >= 5 then
				GoGo_DebugAddLine("GoGo_FilterMountsIn: Function called looking for unknown mount:  " .. MountID)
			end --if
			
		end --if
	end --for
	return GoGo_FilteringMounts
end --function

---------
function GoGo_UpdateMountSpeedDB(PlayerMounts, FilterID, SpeedID, Value)  -- eg. mount list, select filter, speed id to set, value to set
---------
	local GoGo_TempMountDB = {}
	local GoGo_TempLoopCounter
	GoGo_TempMountDB = GoGo_FilterMountsIn(PlayerMounts, FilterID)
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_UpdateMountSpeedDB: FilterID = " .. FilterID .. ", SpeedID = " .. SpeedID .. ", Value = " .. Value)
		GoGo_DebugAddLine("GoGo_UpdateMountSpeedDB: Number of mounts to be modified:  " .. (table.getn(GoGo_TempMountDB) or 0))
	end --if
	for GoGo_TempLoopCounter=1, table.getn(GoGo_TempMountDB) do
		GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempLoopCounter]][SpeedID] = Value
	end --for
end --function

---------
function GoGo_Dismount(button)
---------
	if IsMounted() then
		Dismount()
	elseif CanExitVehicle() then	
		VehicleExit()
	elseif GoGo_Variables.Player.Class == "DRUID" then
		if GoGo_IsShifted() and button then
			if GoGo_Prefs.DruidClickForm and not IsFlying() then
				GoGo_FillButton(button, GoGo_GetMount())
			else
--				CancelUnitBuff("player", GoGo_IsShifted())  -- protected by blizzard now
				GoGo_FillButton(button, GoGo_GetIDName(GoGo_IsShifted()))
			end --if
		end --if
	elseif GoGo_Variables.Player.Class == "SHAMAN" then
--		if UnitBuff("player", C_Spell.GetSpellInfo(GoGo_Variables.Localize.GhostWolf)) and button then
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.GhostWolf).name, "player") and button then
			if GoGo_Prefs.ShamanClickForm then
				GoGo_FillButton(button, GoGo_GetMount())
			else
		--		CancelUnitBuff("player", GoGo_InBook(GoGo_Variables.Localize.GhostWolf))
				GoGo_FillButton(button, GoGo_InBook(GoGo_Variables.Localize.GhostWolf))
			end --if
		end --if
	elseif GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_Dismount: Getting out of Soulshape ")
		end --if
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.SoulShape).name, "player") and button then
			if GoGo_Prefs.NightFaeClickForm then
				GoGo_FillButton(button, GoGo_GetMount())
			else
			    -- Soulshape button is replaced by Flicker. Clicking on the button while in Soulshape without the ClickForm option
				-- will Flicker instead of getting out of Soulshape
				GoGo_FillButton(button, GoGo_InBook(GoGo_Variables.Localize.SoulShape))
			end --if
		end --if
	else
		return nil
	end --if
	return true
end --function

---------
function GoGo_BuildMountList()
---------
	local GoGo_MountList = {}

	if (GetNumCompanions("MOUNT") >= 1) then
		local mountIDs = C_MountJournal.GetMountIDs()
		for i, id in pairs(mountIDs) do
			local _, SpellID, _, _, isUsable, _, _, isFactionSpecific, faction, _, isCollected, _ = C_MountJournal.GetMountInfoByID(id)

			if GoGo_Variables.Debug >= 10 then 
				-- show a line for each mount and indicate if it's usable, etc. in debug log?
				--GoGo_DebugAddLine("GoGo_BuildMountList: Found mount spell ID " .. SpellID .. " and added to known mount list.")
				if SpellID == 0 then
				    GoGo_DebugAddLine("GoGo_BuildMountList: SpellID: " .. SpellID )
				else
					GoGo_DebugAddLine("GoGo_BuildMountList: SpellID: " .. SpellID .. "  isUsable: " .. tostring(isUsable) .. "  isFactionSpecific: " .. tostring(isFactionSpecific) .. "  faction: " .. tostring(faction) .. "  isCollected: " .. tostring(isCollected) .. "  IsUsableSpell(): " .. tostring(C_Spell.IsSpellUsable(SpellID)) .. "  IsSpellKnown(): " .. tostring(IsSpellKnown(SpellID)))
				end --if
			end --if

			if isCollected and isUsable then
					if GoGo_Variables.Debug >= 10 then 
						GoGo_DebugAddLine("GoGo_BuildMountList: " .. SpellID .. " has been added to the list of mounts available.")
					end --if
					table.insert(GoGo_MountList, SpellID)  -- copy this line to the 'else' statement below to find new mounts on the ptr
			else
					if GoGo_Variables.Debug >= 10 then 
						GoGo_DebugAddLine("GoGo_BuildMountList: " .. SpellID .. " has not been added to the list of mounts available.")
					end --if
			end --if
		end --for
	end --if

	if GoGo_Variables.Player.Class == "DRUID" then
		if GoGo_InBook(GoGo_Variables.Localize.AquaForm) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.AquaForm)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.CatForm) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.CatForm)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.TravelForm2) then  -- may not be used any more since Warcraft 6.0
			table.insert(GoGo_MountList, GoGo_Variables.Localize.TravelForm2)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.FastFlightForm) then  -- may not be used any more since Warcraft 6.0
			table.insert(GoGo_MountList, GoGo_Variables.Localize.FastFlightForm)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.FlightForm) then  -- Flight Form that appears with "Glyph of the Stag" in Warcraft 6.0
			table.insert(GoGo_MountList, GoGo_Variables.Localize.FlightForm)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.MountForm) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.MountForm)
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.TravelForm) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.TravelForm)
		end --if
	elseif GoGo_Variables.Player.Class == "SHAMAN" then
		if GoGo_InBook(GoGo_Variables.Localize.GhostWolf) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.GhostWolf)
		end --if
	elseif GoGo_Variables.Player.Class == "HUNTER" then
		if GoGo_InBook(GoGo_Variables.Localize.AspectPack) and GoGo_Prefs.AspectPack then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.AspectPack)
			GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 138)
		elseif GoGo_InBook(GoGo_Variables.Localize.AspectCheetah) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.AspectCheetah)
			GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 138)
		end --if
	elseif GoGo_Variables.Player.Class == "MONK" then
		if GoGo_InBook(GoGo_Variables.Localize.ZenFlight) then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.ZenFlight)
			GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 160)
		end --if
	end --if
	if GoGo_Variables.Player.Covenant == GoGo_Variables.Localize.NightFae then
			table.insert(GoGo_MountList, GoGo_Variables.Localize.SoulShape)
	end --if

	if GoGo_Variables.Player.Race == "Worgen" then
		if (GoGo_InBook(GoGo_Variables.Localize.RunningWild)) then
			if GoGo_Variables.Debug >= 10 then 
				GoGo_DebugAddLine("GoGo_BuildMountList: We are a Worgen and have Running Wild - added to known mount list.")
			end --if
			table.insert(GoGo_MountList, GoGo_Variables.Localize.RunningWild)
		end --if
	end --if

	for MountItemID, MountItemData in pairs(GoGo_Variables.MountItemIDs) do
		local GoGo_SpellId = GoGo_Variables.MountItemIDs[MountItemID][50000]
		if GoGo_Variables.MountItemIDs[MountItemID][51000] then  -- in bag items
			if GoGo_InBags(MountItemID) then
				if GoGo_Variables.Debug >= 10 then 
					GoGo_DebugAddLine("GoGo_BuildMountList: Found mount item ID " .. MountItemID .. " in a bag and added to known mount list.")
				end --if
				table.insert(GoGo_MountList, GoGo_SpellId)
			end --if
		elseif GoGo_Variables.MountItemIDs[MountItemID][51001] then  -- equipable items
			if C_Item.IsEquippedItem(MountItemID) then
				table.insert(GoGo_MountList, GoGo_SpellId)
			elseif GoGo_InBags(MountItemID) then
				table.insert(GoGo_MountList, GoGo_SpellId)
			end --if
		end --if
	end --for

	-- WoD Nagrand's Garrison mounts
	GoGo_Variables.Player.MapID = C_Map.GetBestMapForUnit("player")
	if GoGo_Variables.Player.MapID == 550 then
		-- or 551, 552, 553 TODO	
		local name = C_Spell.GetSpellInfo(161691).name
		local spellID = C_Spell.GetSpellInfo(name).spellID
		if spellID == 165803 or spellID == 164222 then
			table.insert(GoGo_MountList, spellID)
		end --if
	end --if
	
	if GoGo_Variables.Player.MapID == 2346 then
		local name = C_Spell.GetSpellInfo(1215279).name
		local spellID = C_Spell.GetSpellInfo(name).spellID
		table.insert(GoGo_MountList, spellID)
	end
	return GoGo_MountList
end  --function

---------
function GoGo_RemoveUnusableMounts(MountList)  -- Remove mounts Blizzard says we can't use due to location, timers, etc.
---------
	if not MountList or table.getn(MountList) == 0 then
		return {}
	end --if
	
	local GoGo_NewTable = {}
	for a=1, table.getn(MountList) do
		local GoGo_SpellID = MountList[a]
		if not GoGo_SearchTable(GoGo_Prefs.UnknownMounts, GoGo_SpellID) then		-- if mount spell is unknown then don't search the database - it's not in it
			if GoGo_Variables.MountDB[GoGo_SpellID][50000] then
				-- item mount, check item status
				local GoGo_ItemID = GoGo_Variables.MountDB[GoGo_SpellID][50000]  -- get item id
				if GoGo_Variables.MountItemIDs[GoGo_ItemID][51000] then  -- if item should be in bags
					if GoGo_InBags(GoGo_ItemID) then  -- if item is in bag
						if GetItemCooldown(GoGo_ItemID) == 0 then  -- if item doens't have a cooldown timer
							if IsUsableItem(GoGo_ItemID) then  -- if item can be used
								table.insert(GoGo_NewTable, GoGo_SpellID)
							end --if
						end --if
					end --if
				elseif GoGo_Variables.MountItemIDs[GoGo_ItemID][51001] then  -- if item should be equiped
					if IsEquippedItem(GoGo_ItemID) then  -- if item is equipped
						if GetItemCooldown(GoGo_ItemID) == 0 then  -- if item doens't have a cooldown timer
							if IsUsableItem(GoGo_ItemID) then  -- if item can be used
								table.insert(GoGo_NewTable, GoGo_SpellID)
							end --if
						end --if
					end --if
				end --if
			else  -- it's a mount spell or class shape form
				if C_Spell.IsSpellUsable(GoGo_SpellID) then  -- don't use IsSpellKnown() - mounts in collection are not known... morons....
					table.insert(GoGo_NewTable, GoGo_SpellID)
				end --if
			end --if
		end --if
	end --for

	return GoGo_NewTable
end --function

---------
function GoGo_InBags(item)
---------
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_InBags: Searching for " .. item)
	end --if

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local link = C_Container.GetContainerItemLink(bag, slot)
			if link then
				local _, itemid, _ = strsplit(":",link,3)
				if tonumber(itemid) == item then
					if GoGo_Variables.Debug >= 10 then 
						GoGo_DebugAddLine("GoGo_InBags: Found item ID " .. item .. " in bag " .. (bag+1) .. ", at slot " .. slot .. " and added to known mount list.")
					end --if
					return C_Item.GetItemInfo(link)
				end --if
			end --if
		end --for
	end --for
end --function

---------
function GoGo_InBook(spell)
---------
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_InBook: Searching for type " .. type(spell))
	end --if
	if type(spell) == "function" then
		return spell()
	else
		if type(spell) == "string" then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_InBook: Searching for " .. spell)
			end --if
			local slot = 1
			while GetSpellBookItemName(slot, "spell") do
				local name = GetSpellBookItemName(slot, "spell")
				if name == spell then
					if IsSpellKnown(spell) then  -- make sure we know the spell and not seeing it as a learnable spell in the book
						return spell
					end --if
				end --if
				slot = slot + 1
			end --while
		elseif type(spell) == "number" then
			local spellname = C_Spell.GetSpellInfo(spell).name
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_InBook: Searching for spell ID " .. spell)
			end --if
			if FindSpellBookSlotBySpellID(spell) and IsSpellKnown(spell) then
				if GoGo_Variables.Debug >= 10 then
					GoGo_DebugAddLine("GoGo_InBook: Spell ID " .. spell .. " found at slot " .. FindSpellBookSlotBySpellID(spell))
				end --if
				return spellname
			end --if
			-- blah
		end --if
	end --if
end --function

---------
function GoGo_IsShifted()
---------
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_IsShifted:  GoGo_IsShifted starting")
	end --if
	for i = 1, GetNumShapeshiftForms() do
		local _, active, _, spellID = GetShapeshiftFormInfo(i)
		if active then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_IsShifted: Found " .. spellID)
			end --if
			return spellID
		end
	end --for
	return false
end --function

---------
function GoGo_SearchTable(GoGo_Table, GoGo_Value)
---------
	if type(GoGo_Table) == "table" and table.getn(GoGo_Table) > 0 then
		for a=1, table.getn(GoGo_Table) do
			if GoGo_Table[a] == GoGo_Value then
				return true
			end --if
		end --for
	end --if
	return false
end --function

---------
function GoGo_RemoveBuffs(GoGo_Buff)  -- adds lines to button macro to remove removable buffs
---------
	if not GoGo_Prefs.RemoveBuffs then
		return ""
	end --if
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_RemoveBuffs: Removing buffs preventing mounting.")
	end --if
	local GoGo_Macro = ""
	local spellid = 0
	if GoGo_Buff then  -- specifying buff to remove
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_RemoveBuffs: Checking for " .. GoGo_Buff .. " (" .. C_Spell.GetSpellInfo(GoGo_Buff).name .. ")")
		end --if
--		if UnitBuff("player", C_Spell.GetSpellInfo(GoGo_Buff)) then
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Buff).name, "player") then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_RemoveBuffs: Found and removing buff " .. GoGo_Buff .. " (" .. C_Spell.GetSpellInfo(GoGo_Buff).name .. ")")
			end --if
			GoGo_Macro = GoGo_Macro .. "/cancelaura " .. C_Spell.GetSpellInfo(GoGo_Buff).name .. " \n"
		end --if
		return GoGo_Macro
	end --if
	
	for spellid = 1, table.getn(GoGo_Variables.DebuffDB) do
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_RemoveBuffs: Checking for " .. GoGo_Variables.DebuffDB[spellid] .. " (" .. C_Spell.GetSpellInfo(GoGo_Variables.DebuffDB[spellid]).name .. ")")
		end --if
--		if UnitBuff("player", C_Spell.GetSpellInfo(GoGo_Variables.DebuffDB[spellid])) then
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.DebuffDB[spellid]).name, "player") then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_RemoveBuffs: Found and removing buff " .. GoGo_Variables.DebuffDB[spellid] .. " (" .. C_Spell.GetSpellInfo(GoGo_Variables.DebuffDB[spellid]).name .. ")")
			end --if
			GoGo_Macro = GoGo_Macro .. "/cancelaura " .. C_Spell.GetSpellInfo(GoGo_Variables.DebuffDB[spellid]).name .. " \n"
		end --if
	end --for
	return GoGo_Macro
end --if

---------
function GoGo_TableAddUnique(GoGo_Table, GoGo_Value)  -- add a value to a table if it's not already in the table and sort
---------
	if GoGo_Value == nil then
		return
	end --if
	
	if type(GoGo_Table) ~= "table" then
		return
	end --if
	
	if table.getn(GoGo_Table) == 0 then
		table.insert(GoGo_Table, GoGo_Value)
		return
	end --if
	
	if table.getn(GoGo_Table) > 0 then
		if GoGo_SearchTable(GoGo_Table, GoGo_Value) then  -- value already in table - do nothing
			return
		else
			table.insert(GoGo_Table, GoGo_Value)
			table.sort(GoGo_Table, function(a,b) return a>b end)
			return
		end --if
	end --if
end --function

---------
function GoGo_ZonePrefMount(SpellID)
---------
	if SpellID == nil then
		return
	else
		SpellID = tonumber(SpellID)
	end --if
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_ZonePrefMount: Preference ID " .. SpellID)
	end --if
	for GoGo_CounterA = 1, table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"]) do
		if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"][GoGo_CounterA] == SpellID then
			table.remove(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"], GoGo_CounterA)
			return -- mount found, removed and now returning
		end --if
	end --for
	if not GoGo_SearchTable(GoGo_Prefs.UnknownMounts, SpellID) then
		table.insert(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"], SpellID)
	end --if
end --function

---------
function GoGo_ZoneExcludeMount(SpellID)
---------
	if SpellID == nil then
		return
	else
		SpellID = tonumber(SpellID)
	end --if
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_ZoneExcludedMount: Excluded ID " .. SpellID)
	end --if
	for GoGo_CounterA = 1, table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]) do
		if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"][GoGo_CounterA] == SpellID then
			table.remove(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"], GoGo_CounterA)
			return -- mount found, removed and now returning
		end --if
	end --for
	table.insert(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"], SpellID)
end --function

---------
function GoGo_ExtraPassengerMounts(SpellID)
---------
	if SpellID == nil then
		return
	else
		SpellID = tonumber(SpellID)
	end --if
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_ZoneExcludedMount: Excluded ID " .. SpellID)
	end --if
	for GoGo_CounterA = 1, table.getn(GoGo_Prefs.ExtraPassengerMounts) do
		if GoGo_Prefs.ExtraPassengerMounts[GoGo_CounterA] == SpellID then
			table.remove(GoGo_Prefs.ExtraPassengerMounts, GoGo_CounterA)
			return -- mount found, removed and now returning
		end --if
	end --for
	table.insert(GoGo_Prefs.ExtraPassengerMounts, SpellID)
end --function

---------
function GoGo_GlobalPrefMount(SpellID)
---------
	if SpellID == nil then
		return
	else
		SpellID = tonumber(SpellID)
	end --if
	
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_GlobalPrefMount: Preference ID " .. SpellID)
	end --if

	if not GoGo_Prefs.GlobalPrefMounts then
		GoGo_Prefs.GlobalPrefMounts = {}
	else
		for GoGo_CounterA = 1, table.getn(GoGo_Prefs.GlobalPrefMounts) do
			if GoGo_Prefs.GlobalPrefMounts[GoGo_CounterA] == SpellID then
				table.remove(GoGo_Prefs.GlobalPrefMounts, GoGo_CounterA)
				if table.getn(GoGo_Prefs.GlobalPrefMounts) == 0 then
					GoGo_Prefs.GlobalPrefMounts = nil
				end --if
				return -- mount found, removed and now returning
			end --if
		end --for
	end --if

	if not GoGo_SearchTable(GoGo_Prefs.UnknownMounts, SpellID) then
		table.insert(GoGo_Prefs.GlobalPrefMounts, SpellID)
	end --if
end --function

---------
function GoGo_GlobalExcludeMount(SpellID)
---------
	if SpellID == nil then
		return
	else
		SpellID = tonumber(SpellID)
	end --if
	
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_GlobalExcludeMount: Mount ID " .. SpellID)
	end --if

	if not GoGo_Prefs.GlobalExclude then
		GoGo_Prefs.GlobalExclude = {}
		table.insert(GoGo_Prefs.GlobalExclude, SpellID)
	else
		for GoGo_CounterA = 1, table.getn(GoGo_Prefs.GlobalExclude) do
			if GoGo_Prefs.GlobalExclude[GoGo_CounterA] == SpellID then
				table.remove(GoGo_Prefs.GlobalExclude, GoGo_CounterA)
				if table.getn(GoGo_Prefs.GlobalExclude) == 0 then
					GoGo_Prefs.GlobalExclude = nil
				end --if
				return -- mount found, removed and now returning
			end --if
		end --for
		table.insert(GoGo_Prefs.GlobalExclude, SpellID)
	end --if
end --function

---------
function GoGo_RemoveExcluded()  -- removes excluded mounts from mount selection during mounting process
---------
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_RemoveExcluded: Executed")
	end --if
	if GoGo_Prefs.GlobalExclude and table.getn(GoGo_Variables.FilteredMounts) then
		for a = 1, table.getn(GoGo_Prefs.GlobalExclude) do
			for b = 1, table.getn(GoGo_Variables.FilteredMounts) do
				if GoGo_Variables.FilteredMounts[b] == GoGo_Prefs.GlobalExclude[a] then
					table.remove(GoGo_Variables.FilteredMounts, b)
				end --if
			end --for
		end --for
	end --if
	if GoGo_Variables.Player.MapID and table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]) > 0 then
		for a = 1, table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]) do
			for b = 1, table.getn(GoGo_Variables.FilteredMounts) do
				if GoGo_Variables.FilteredMounts[b] == GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"][a] then
					table.remove(GoGo_Variables.FilteredMounts, b)
				end --if
			end --for
		end --for
	end --if
end --function

---------
function GoGo_CmdLineLinkProcessing(msg)
---------
	local FItemID = string.gsub(msg,".-\124H([^\124]*)\124h.*", "%1");
	local idtype, itemid = strsplit(":",FItemID);
	itemid = tonumber(itemid)
	if string.find(msg, "item:%d+") then
		if GoGo_Variables.MountItemIDs[itemid] and GoGo_Variables.MountItemIDs[itemid][50000] then
			itemid = GoGo_Variables.MountItemIDs[itemid][50000]
		else
			GoGo_Msg("Unknown mount details - not added")
		end --if
	end --if
	
	if string.find(msg, "exclude", 1, true) then
		GoGo_GlobalExcludeMount(itemid)
	else
		if GoGo_Prefs.GlobalPrefMount then
			GoGo_GlobalPrefMount(itemid)
		else
			GoGo_ZonePrefMount(itemid)
		end --if
	end --if
	GoGo_Msg("pref")
end --function

---------
function GoGo_UpdateZonePrefs()
---------
	GoGo_Variables.Player.Zone = GetRealZoneText()
	GoGo_Variables.Player.MapID = C_Map.GetBestMapForUnit("player")
	GoGo_Variables.Player.ZoneID = GoGo_Variables.ZoneMapID[GoGo_Variables.Player.MapID]

	if not GoGo_Prefs then return end
	
	if GoGo_Prefs[GoGo_Variables.Player.Zone] then
		if not GoGo_Prefs.Zones then
			GoGo_Prefs.Zones = {}
		end --if
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID] = {}
		end --if
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"] = {}
		end --if
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"] = {}
		end --if

		while table.getn(GoGo_Prefs[GoGo_Variables.Player.Zone]) > 0 do
			local GoGo_Temp = GoGo_Prefs[GoGo_Variables.Player.Zone][1]
			if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"][GoGo_Temp] then
				table.insert(GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"], GoGo_Temp)
			end --if
			table.remove(GoGo_Prefs[GoGo_Variables.Player.Zone], 1)
		end --while
		GoGo_Prefs[GoGo_Variables.Player.Zone] = nil
	end --if

	if GoGo_Prefs.Zones and GoGo_Prefs.Zones[GoGo_Variables.Player.Zone] then
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID] = {}
		end --if
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"] = {}
		end --if
		if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"] then
			GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"] = {}
		end --if
		if GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Preferred"] then
			while table.getn(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Preferred"]) > 0 do
				local GoGo_Temp = GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Preferred"][1]
				if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"][GoGo_Temp] then
					table.insert(GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"], GoGo_Temp)
				end --if
				table.remove(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Preferred"], 1)
			end --while
			GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Preferred"] = nil
		end --if
		if GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Excluded"] then
			while table.getn(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Excluded"]) > 0 do
				local GoGo_Temp = GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Excluded"][1]
				if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"][GoGo_Temp] then
					table.insert(GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Excluded"], GoGo_Temp)
				end --if
				table.remove(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Excluded"], 1)
			end --while
			GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]["Excluded"] = nil
		end --if

		while table.getn(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone]) > 0 do
			local GoGo_Temp = GoGo_Prefs.Zones[GoGo_Variables.Player.Zone][1]
			if not GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"][GoGo_Temp] then
				table.insert(GoGo_Prefs.Zones[GoGo_Variables.Player.ZoneID]["Preferred"], GoGo_Temp)
			end --if
			table.remove(GoGo_Prefs.Zones[GoGo_Variables.Player.Zone], 1)
		end --while

		GoGo_Prefs.Zones[GoGo_Variables.Player.Zone] = nil
	end --if

	-- Moving from GoGoPrefs.Zones to GoGoPrefs.MapIDs
	GoGo_ZoneMapIDMigration()
end --function

---------
function GoGo_CheckForUnknownMounts(MountList)
---------
	MountList = MountList or {}
	for a = 1, table.getn(MountList) do
		local MountID = MountList[a]
		if not GoGo_Variables.MountDB[MountID] then
			if not GoGo_SearchTable(GoGo_Prefs.UnknownMounts, MountID) then
				table.insert(GoGo_Prefs.UnknownMounts, MountID)
			end --if
			GoGo_ZonePrefMount(MountID)		-- to remove zone favorite flag if mount unknown
			GoGo_GlobalPrefMount(MountID)		-- to remove global favorite flag if mount unknown
			if GoGo_Variables.Debug >= 6 then
				GoGo_DebugAddLine("GoGo_CheckForUnknownMounts: Unknown mount found:  " .. MountID)
			end --if
			if not GoGo_Prefs.DisableMountNotice and not GoGo_Variables.UnknownMountMsgShown then
				GoGo_Variables.UnknownMountMsgShown = true
				GoGo_Msg("UnknownMount")
			end --if
		end --for
	end --for
end --function

---------
function GoGo_GetMountID(mountid)
---------
	-- Pass mount IDs to this function will return the same spell ID if the ..

end --function

---------
function GoGo_GetIDName(itemid)
---------
	local tempname = ""
	local ItemName = ""
	if type(itemid) == "number" then
		local GoGo_TempMount = {}
		table.insert(GoGo_TempMount, itemid)
		if (table.getn(GoGo_FilterMountsIn(GoGo_TempMount, 50000)) == 1) then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetIDName: GetItemID for " .. itemid .. " " .. C_Item.GetItemInfo(GoGo_Variables.MountDB[itemid][50000]).itemName)
			end --if
			return C_Item.GetItemInfo(GoGo_Variables.MountDB[itemid][50000]).itemName or "Unknown Mount"
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetIDName: GetSpellID for " .. itemid .. " " .. (C_Spell.GetSpellInfo(itemid).name or "Unknown Mount"))
			end --if
			return C_Spell.GetSpellInfo(itemid).name or "Unknown Mount"
		end --if
	elseif type(itemid) == "table" then
		for a=1, table.getn(itemid) do
			local GoGo_TempTable = {}
			table.insert(GoGo_TempTable, itemid[a])
			if (table.getn(GoGo_FilterMountsIn(GoGo_TempTable, 50000)) == 1) then
--				tempname = C_Item.GetItemInfo(tempname)
				if GoGo_Variables.Debug >= 10 then
					GoGo_DebugAddLine("GoGo_GetIDName: GetItemID for " .. itemid[a] .. C_Item.GetItemInfo(GoGo_Variables.MountDB[itemid[a]][50000]).itemName)
				end --if
				ItemName = ItemName .. (C_Item.GetItemInfo(GoGo_Variables.MountDB[itemid[a]][50000]).itemName or "Unknown Mount") .. ", "
			else
--				tempname = C_Spell.GetSpellInfo(tempname)
				if GoGo_Variables.Debug >= 10 then
					GoGo_DebugAddLine("GoGo_GetIDName: GetSpellID for " .. itemid[a] .. C_Spell.GetSpellInfo(itemid[a]).name)
				end --if
				ItemName = ItemName .. (C_Spell.GetSpellInfo(itemid[a]).name or "Unknown Mount") .. ", "
			end --if
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetIDName: Itemname string is " .. ItemName)
			end --if
		end --for
		return ItemName
	end --if
end --function

--[[  -- no longer working with MoP
---------
function GoGo_GetTalentInfo(talentname)
---------
	if GoGo_Variables.Debug >= 10 then 
		GoGo_DebugAddLine("GoGo_GetTalentInfo: Searching talent tree for " .. talentname)
	end --if
	local numTabs = GetNumTalentTabs()
	for tab=1, numTabs do
		local numTalents = GetNumTalents(tab)
		for talent=1, numTalents do
			local name, _, _, _, rank, maxrank = GetTalentInfo(tab,talent)
			if (talentname == name) then
				if GoGo_Variables.Debug >= 10 then 
					GoGo_DebugAddLine("GoGo_GetTalentInfo: Found " .. talentname .. " with rank " .. rank)
				end --if
				return rank, maxrank
			end --if
		end --for
	end --for
	return 0,0
end --function
]]

---------
function GoGo_FillButton(button, mount)
---------
	if InCombatLockdown() then
		-- do nothing - macro should be filled already with available options
		-- need to exclude calling :SetAttribute while in combat due to some bug collecting
		-- mods flagging this as an error
		if GoGo_Variables.Debug >= 10 then 
			GoGo_DebugAddLine("GoGo_FillButton: In combat.  Casting pre-assigned mount")
		end --if
	elseif mount then
		if GoGo_Variables.Debug >= 10 then 
			GoGo_DebugAddLine("GoGo_FillButton: Casting " .. mount)
		end --if
		if string.find(mount, "/use ", 1, true) then
			button:SetAttribute("macrotext", mount)
		else
			button:SetAttribute("macrotext", "/use "..mount)
		end --if
	else
		button:SetAttribute("macrotext", nil)
	end --if
end --function

---------
function GoGo_CheckBindings()
---------
	for binding, button in pairs({GOGOBINDING = GoGoButton, GOGOBINDING2 = GoGoButton2, GOGOBINDING3 = GoGoButton3, GOGOBINDING4 = GoGoButton4, GOGOBINDING5 = GoGoButton5}) do
		ClearOverrideBindings(button)
		local key1, key2 = GetBindingKey(binding)
		if key1 then
			SetOverrideBindingClick(button, true, key1, button:GetName())
		end --if
		if key2 then
			SetOverrideBindingClick(button, true, key2, button:GetName())
		end --if
	end --if
end --function

---------
function GoGo_IsInBattleGround()
---------
  for GoGo_TempCount = 1, MAX_BATTLEFIELD_QUEUES do
    local Status, MapName = GetBattlefieldStatus(GoGo_TempCount);
    if(Status=="active")then
      return MapName;
    end --if
  end --if
end --function

---------
function GoGo_CanRide()
---------
	if GoGo_Variables.Player.Level >= 10 then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_CanRide: Passed - Player is over level 10.")
		end --if
		return true
	end --if
end --function

---------
function GoGo_IsMoving()
---------
    if GetUnitSpeed("player") ~= 0 then
        return true
    else
        return false
    end --if
end --function

---------
function GoGo_GetProfSkillLevel(searchname)
---------
	local prof1, prof2 = GetProfessions()
	if prof1 then
		local name, _, rank, maxrank, numspells, spelloffset, skillline = GetProfessionInfo(prof1)
		if (name == searchname) then
			return rank
		end --if
	end --if

	if prof2 then
		local name, _, rank, maxrank, numspells, spelloffset, skillline = GetProfessionInfo(prof2)
		if (name == searchname) then
			return rank
		end --if
	end --if
	
	return 0
end --function

--[[
---------
function GoGo_GlyphActive(spellid)
---------
	for TempCount = 1, NUM_GLYPH_SLOTS do
		local enabled, _, _, TempSpellID = GetGlyphSocketInfo(TempCount)
		if enabled and TempSpellID == spellid then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GlyphActive: Found active glyph " .. spellid .. " (" .. C_Spell.GetSpellInfo(spellid) .. ")")
			end --if
			return true
		end --if
	end --for
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_GlyphActive: Not found active glyph " .. spellid .. " (" .. C_Spell.GetSpellInfo(spellid) .. ")")
	end --if

	return false
end --function
]]

---------
function GoGo_CheckSwimSurface()
---------
	GoGo_Variables.SwimSurface = true

	if GoGo_Prefs.DisableWaterFlight then  -- don't want to fly from water as per client option
		GoGo_Variables.NoFlying = true
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_CheckSwimSurface: Don't want to fly from water surface.  Disabling flying.")
		end --if
		GoGo_Variables.SwimSurface = false
		return
	end --if
	
	for GoGo_TempCount = 1, MIRRORTIMER_NUMTIMERS do
		local timer, value, maxvalue, scale, paused, label = GetMirrorTimerInfo(GoGo_TempCount)
		if timer == "BREATH" then
			if (scale == -1) then
				if GoGo_Variables.Debug >= 10 then
					GoGo_DebugAddLine("GoGo_CheckSwimSurface: Breath timer bar found and it's slowly draining.  Disabling flying.")
				end --if
				GoGo_Variables.NoFlying = true
				GoGo_Variables.SwimSurface = false
			else
				if GoGo_Variables.Debug >= 10 then
					GoGo_DebugAddLine("GoGo_CheckSwimSurface: Breath timer not bar found.  Looks like we can fly here.")
				end --if
			end --if
		end --if	
	end --for
end --function

---------
function GoGo_GetSkillLevel(searchname)
---------  may not work after cata
	for skillIndex = 1, GetNumSkillLines() do
		skillName, isHeader, isExpanded, skillRank = GetSkillLineInfo(skillIndex)
		if isHeader == nil then
			if skillName == searchname then
				return skillRank
			end --if
		end --if
	end --for
end --function

---------
function GoGo_GetRidingSkillLevel()
--------- 
	if GoGo_InBook(GoGo_Variables.Localize.MasterRiding) then
		return GoGo_Variables.Localize.Skill.MasterRiding
	elseif GoGo_InBook(GoGo_Variables.Localize.ArtisanRiding) then
		return GoGo_Variables.Localize.Skill.ArtisanRiding
	elseif GoGo_InBook(GoGo_Variables.Localize.ExpertRiding) then
		return GoGo_Variables.Localize.Skill.ExpertRiding
	elseif GoGo_InBook(GoGo_Variables.Localize.JourneymanRiding) then
		return GoGo_Variables.Localize.Skill.JourneymanRiding
	elseif GoGo_InBook(GoGo_Variables.Localize.ApprenticeRiding) then
		return GoGo_Variables.Localize.Skill.ApprenticeRiding
	else
		return GoGo_Variables.Localize.Skill.NoRiding
	end --if

	-- master riding just makes epic flying mounts faster - no need to search for it specifically
	
end --function

---------
function GoGo_CheckCoOrds(ZoneName, SubZoneName)
---------
	local posX, posY = GetPlayerMapPosition("Player")
	local CanFlyHere = false
	local ZoneName = GoGo_FlyCoOrds[ZoneName]
	local SubZoneName = ZoneName[SubZoneName]
	for a = 1, table.getn(SubZoneName) or 0 do
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_CheckCoOrds: Checking CoOrds " .. a)
		end --if
		local PointAX, PointAY, PointBX, PointBY = SubZoneName[a][1], SubZoneName[a][2], SubZoneName[a][3], SubZoneName[a][4]
		if posX >= PointAX and posX <= PointBX and posY >= PointAY and posY <= PointBY then
			-- we are in the rectangle a
			return true
		end --if
	end --for
	return false
end --function

---------
function GoGo_Msg(msg)
---------
	if msg then
		if GOGO_MESSAGES[msg] then
			GoGo_Msg(GOGO_MESSAGES[msg]())
		else
			msg = string.gsub(msg, "<", LIGHTYELLOW_FONT_COLOR_CODE)
			msg = string.gsub(msg, ">", "|r")
			DEFAULT_CHAT_FRAME:AddMessage(GREEN_FONT_COLOR_CODE.."GoGo: |r"..tostring(msg))
		end --if
	end --if
end --function

---------
function GoGo_Id(link)
---------
-- tested list:
-- item spell glyph achievement battlepet battlePetAbil talent quest enchant currency follower mission
	local s, e = string.find(link, "|H(.-):([-0-9]+)")
	link = string.sub(link, s+2, e)
--	linktype, linkID = strsplit(":", link)
	return link
end --function

---------
function GoGo_GetInstantMounts(GoGo_FilteredMounts)
---------
	-- Grab all mounts flagged as instant cast for falling or moving conditions
	GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 7) or {}
	return GoGo_FilteredMounts
end --function

---------
function GoGo_GetMountsWhileMoving(GoGo_FilteredMounts)
---------
	-- Grab all mounts that can be casted (1.5 seconds) while moving
	-- (Currently used for Nagrand (WoD) garrison ability mounts)
	GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 5) or {}
	return GoGo_FilteredMounts
end --function

---------
function GoGo_GetIndoorMounts(GoGo_FilteredMounts)
---------
	GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 8) or {}
	return GoGo_FilteredMounts
end --function

---------
function GoGo_GetOculusMounts280(GoGo_FilteredMounts)
---------
	GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 54) or {}
	return GoGo_FilteredMounts
end --function

---------
function GoGo_GetBestAirMounts(GoGo_FilteredMounts)
---------
	local mounts = {}
	local GoGo_TempLoopCount = 1
	local GoGo_SearchString = table.concat(GoGo_FilteredMounts, ":")
	if GoGo_Variables.Player.Class == "DRUID" and GoGo_Prefs.DruidFlightForm then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_GetBestAirMounts: Druid with preferred flight forms option enabled.  Using flight form.")
		end --if
		if string.find(GoGo_SearchString, GoGo_Variables.Localize.FlightForm, 1, true) then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetBestAirMounts: Found FlightForm")
			end --if
			table.insert(mounts, GoGo_Variables.Localize.FlightForm)
		elseif string.find(GoGo_SearchString, GoGo_Variables.Localize.TravelForm, 1, true) then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetBestAirMounts: Found TravelForm")
			end --if
			table.insert(mounts, GoGo_Variables.Localize.TravelForm)
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_GetBestAirMounts: No flight forms found")
				GoGo_DebugAddLine("GoGo_GetBestAirMounts: GoGo_SearchString: "..GoGo_SearchString)
			end --if
		end --if
	end --if

	while (table.getn(mounts) == 0) and (GoGo_TempLoopCount <= table.getn(GoGo_Variables.AirSpeed)) do
		mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 10003, GoGo_Variables.AirSpeed[GoGo_TempLoopCount])
		GoGo_TempLoopCount = GoGo_TempLoopCount + 1
	end --while

	return mounts
end --function

---------
function GoGo_GetBestGroundMounts(GoGo_FilteredMounts)
---------
	local mounts = {}
	local GoGo_TempLoopCount = 1
	while (table.getn(mounts) == 0) and (GoGo_TempLoopCount <= table.getn(GoGo_Variables.GroundSpeed)) do
		mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 10002, GoGo_Variables.GroundSpeed[GoGo_TempLoopCount])
		GoGo_TempLoopCount = GoGo_TempLoopCount + 1
	end --while
	return mounts
end --function

---------
function GoGo_GetBestWaterMounts(GoGo_FilteredMounts)
---------
	local mounts = {}
	local GoGo_TempLoopCount = 1
	if not GoGo_Variables.SwimSurface then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_GetBestWaterMounts: Under water mount selection.")
		end --if
		while (table.getn(mounts) == 0) and (GoGo_TempLoopCount <= table.getn(GoGo_Variables.WaterSpeed)) do
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 10001, GoGo_Variables.WaterSpeed[GoGo_TempLoopCount])
			GoGo_TempLoopCount = GoGo_TempLoopCount + 1
		end --while
	else
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_GetBestWaterMounts: Water surface mount selection.")
		end --if
		while (table.getn(mounts) == 0) and (GoGo_TempLoopCount <= table.getn(GoGo_Variables.WaterSurfaceSpeed)) do
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 10004, GoGo_Variables.WaterSurfaceSpeed[GoGo_TempLoopCount])
			GoGo_TempLoopCount = GoGo_TempLoopCount + 1
		end --while
	end --if
	if GoGo_Variables.Debug >= 10 then
		GoGo_DebugAddLine("GoGo_GetBestWaterMounts: " .. table.getn(mounts) .. " water mounts found in " .. (GoGo_TempLoopCount - 1) .. " loop count.")
	end --if
	return mounts
end --function

---------
function GoGo_UpdateMountData()
---------
	if (GoGo_Variables.Player.Class == "DRUID") and (GoGo_Variables.Player.Level>=20) then
		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10002] = 200
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 200)
	end --if

	if (GoGo_Variables.Player.Class == "DRUID") and GoGo_InBook(GoGo_Variables.Localize.FelineSwiftness) then
		GoGo_Variables.MountDB[GoGo_Variables.Localize.CatForm][10002] = 149
		GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 149)
		if (GoGo_Variables.Player.Level<20) then
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10002] = 161
			GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 161)
		else
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10002] = 230
			GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 230)
		end --if
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Druid with Feline Swiftness.  Modifying shape form speed data.")
		end --if
	end --if

--[[
	if (GoGo_Variables.Player.Class == "DRUID") and (GoGo_GlyphActive(GoGo_Variables.Localize.Glyph_AquaticForm)) then
		GoGo_Variables.MountDB[GoGo_Variables.Localize.AquaForm][10001] = 135
		GoGo_TableAddUnique(GoGo_Variables.WaterSpeed, 135)
		GoGo_Variables.MountDB[GoGo_Variables.Localize.AquaForm][10004] = 135
		GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 135)
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Druid with Glyph of Aquatic Form.  Modifying Aquatic Form speed data.")
		end --if
	end --if
]]
	if (GoGo_Variables.Player.Class == "DRUID" and (IsSwimming() or IsSubmerged())) then
		-- set the swim speeds to whatever AquaForm speed is including possible glyph modifier set above
		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10001] = GoGo_Variables.MountDB[GoGo_Variables.Localize.AquaForm][10001]
		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10004] = GoGo_Variables.MountDB[GoGo_Variables.Localize.AquaForm][10004]
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Druid in or under water.  Updated Travel Form with swimming properties.")
		end --if
		if IsIndoors() then
			-- Druid's travel form is now Aqua form and works indoors for swimming only
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][8] = true
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][53] = true
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Druid in or under water and indoors.  Updated Travel Form to work indoors as well.")
			end --if
		end --if
	end --if

	--[[
	if (GoGo_Variables.Player.Class == "DRUID") and (GoGo_GlyphActive(GoGo_Variables.Localize.Glyph_Stag) and not GoGo_GlyphActive(GoGo_Variables.Localize.Glyph_Cheetah)) then
		-- Druid's travel form can carry a passenger
		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][2] = true
	end --if

	if (GoGo_Variables.Player.Class == "DRUID") and not GoGo_GlyphActive(GoGo_Variables.Localize.Glyph_Stag) then
		-- Druid's travel form is used for flight form, travel form and aqua forms based on location
		if not (GoGo_Variables.SkipFlyingMount == true) then
			-- If player presses "no flying" mount key or uses no flying mount option, these modifiers will remove travel form preventing aqua form in water, etc.
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][9] = true
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][300] = true
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][301] = true
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][403] = true
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][501] = true
	--		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10001] = 101
			GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10003] = 250
	--		GoGo_Variables.MountDB[GoGo_Variables.Localize.TravelForm][10004] = 101
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Druid, not skipping flying so let travel form fly!")
			end --if
		end --if
	end --if

	
	if (GoGo_Variables.Player.Class == "SHAMAN") and (GoGo_GlyphActive(19264)) then
	-- player = shaman and has glyph of Ghost Wolf (cast ghost wolf while dead)
		GoGo_Variables.MountDB[GoGo_Variables.Localize.GhostWolf][550] = true
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: We're a Shaman with Glyph of Ghost Wolf.  Modifying Ghost Wolf to work while the player is dead.")
		end --if
	end --if
	
]]
	
	if not GoGo_Variables.ZoneExclude.ThousandNeedles then  -- we are in thousand needles - ground mounts swim faster with buff
		local GoGo_TempMountDB = {}
		local GoGo_TempLoopCounter
--		if UnitBuff("player", C_Spell.GetSpellInfo(75627)) and IsSwimming() then
		if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(75627).name, "player") and IsSwimming() then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: In Thousand Needles with buff.  Updating water speed of ground mounts.")
			end --if

			GoGo_TempMountDB = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 400)
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: Number of mounts to increase water speed on:  " .. (table.getn(GoGo_TempMountDB) or 0))
			end --if
			for GoGo_TempLoopCounter=1, table.getn(GoGo_TempMountDB) do
				GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempLoopCounter]][10001] = 108
				GoGo_TableAddUnique(GoGo_Variables.WaterSpeed, 108)
				GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempLoopCounter]][10004] = 108
				GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 108)
			end --for
		end --if
	end --if
	
--	if UnitBuff("player", C_Spell.GetSpellInfo(80610)) and IsSwimming() then
	if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(80610).name, "player") and IsSwimming() then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: Swimming with Water Gliding buff.  Updating water speed of ground mounts - increasing by 50%.")
		end --if
		GoGo_TempMountDB = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 405)
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: Number of mounts to increase water speed on:  " .. (table.getn(GoGo_TempMountDB) or 0))
		end --if
		for GoGo_TempLoopCounter=1, table.getn(GoGo_TempMountDB) do
			GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempLoopCounter]][10001] = 101
			GoGo_TableAddUnique(GoGo_Variables.WaterSpeed, 101)
			GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempLoopCounter]][10004] = 101
			GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 101)
		end --for
	end --if

	if (GoGo_Variables.Player.ZoneID == 610) or (GoGo_Variables.Player.ZoneID == 614) or (GoGo_Variables.Player.ZoneID == 615) then
		if GoGo_Variables.ExpansionAccount == 3 then  -- only exists for 4.x with Cataclysm expansion
			if AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(GoGo_Variables.Localize.SeaLegs).name, "player") then
--			if UnitBuff("player", C_Spell.GetSpellInfo(GoGo_Variables.Localize.SeaLegs)) then
				GoGo_UpdateMountSpeedDB(GoGo_Variables.FilteredMounts, 404, 10001, 270)
				GoGo_TableAddUnique(GoGo_Variables.WaterSpeed, 270)
				GoGo_UpdateMountSpeedDB(GoGo_Variables.FilteredMounts, 404, 10004, 270)
				GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 270)

			end --if
		end --if
	end --if

--	if (GoGo_Variables.Player.ZoneID == 978) and (UnitBuff("player", C_Spell.GetSpellInfo(170495))) then
	if (GoGo_Variables.Player.ZoneID == 978) and (AuraUtil.FindAuraByName(C_Spell.GetSpellInfo(170495).name, "player")) then
	-- Makes mounts instant cast if in Ashran with "Swift Riding Crop" buff
		local GoGo_TempMountDB = {}
		GoGo_TempMountDB = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 701) or {}
		for GoGo_TempCounter = 1, table.getn(GoGo_TempMountDB) do
			GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][6] = true
		end --for
	end --if
	
	-- mount speed updates based on riding skill
	if GoGo_GetRidingSkillLevel() == GoGo_Variables.Localize.Skill.MasterRiding then  -- increase air mounts to 410
		GoGo_UpdateMountSpeedDB(GoGo_Variables.FilteredMounts, 300, 10003, 410)
	elseif GoGo_GetRidingSkillLevel() == 300 then  -- increase air mounts to 380
		GoGo_UpdateMountSpeedDB(GoGo_Variables.FilteredMounts, 301, 10003, 380)
	end --if

	if GoGo_GetRidingSkillLevel() >= GoGo_Variables.Localize.Skill.JourneymanRiding then  -- increase ground mounts to 200
		GoGo_UpdateMountSpeedDB(GoGo_Variables.FilteredMounts, 330, 10002, 200)
	end --if	

	-- Mount Up guild perk updates
	if IsInGuild() and IsSpellKnown(78633) then
		if GoGo_Variables.Debug >= 10 then
			GoGo_DebugAddLine("GoGo_UpdateMountData: In guild, with Mount Up perk")
		end --if
		if not UnitInBattleground("player") then
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: Increasing mount speed data because of Mount Up")
			end --if
			local GoGo_TempMountDB = {}
			GoGo_TempMountDB = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 402) or {}  -- ground mounts to modify
			for GoGo_TempCounter = 1, table.getn(GoGo_TempMountDB) do
				if GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] == 200 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] = 220
					GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 220)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] == 160 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] = 170
					GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 170)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] == 100 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10002] = 110
					GoGo_TableAddUnique(GoGo_Variables.GroundSpeed, 110)
				end --if
				if GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10004] == 200 then
					-- warlock mounts with water surface glyph
					-- water skitter mounts and any other water surface mount riding at ground mount speed
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10004] = 220
					GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 220)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10004] == 160 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10004] = 176
					GoGo_TableAddUnique(GoGo_Variables.WaterSurfaceSpeed, 176)
				end --if
			end --for
			GoGo_TempMountDB = GoGo_FilterMountsIn(GoGo_Variables.FilteredMounts, 403) or {}  -- air mounts to modify
			for GoGo_TempCounter = 1, table.getn(GoGo_TempMountDB) do
				if GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] == 250 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] = 275
					GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 275)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] == 380 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] = 418
					GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 418)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] == 410 then
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] = 451
					GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 451)
				elseif GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] == 160 then  -- Monk's Zen Flight
					GoGo_Variables.MountDB[GoGo_TempMountDB[GoGo_TempCounter]][10003] = 176
					GoGo_TableAddUnique(GoGo_Variables.AirSpeed, 176)
				end --if
			end --for
		else
			if GoGo_Variables.Debug >= 10 then
				GoGo_DebugAddLine("GoGo_UpdateMountData: Not increasing mount speed data because of Mount Up - in battle ground")
			end --if
		end --if
	end --if

end --function

GOGO_ERRORS = {
	[SPELL_FAILED_NOT_MOUNTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[ERR_ATTACK_MOUNTED] = true,
	[SPELL_FAILED_NO_ACTIONS] = true,  -- Spell casting while in Zen Flight
}

GOGO_SPELLS = {
	["DRUID"] = function()
		local GoGo_CastString
		local UseSeperator = false
		GoGo_CastString = ""
		if GoGo_Prefs.DruidClickForm then
			GoGo_CastString = "/cancelform [flying] \n"
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.TravelForm) or GoGo_InBook(GoGo_Variables.Localize.CatForm) then
			GoGo_CastString = GoGo_CastString .. "/use "
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.TravelForm) then
			GoGo_CastString = GoGo_CastString .. "[swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			UseSeperator = true
		end --if
		if GoGo_InBook(GoGo_Variables.Localize.CatForm) then
			if UseSeperator then
				GoGo_CastString = GoGo_CastString .. ";"
			end --if
			GoGo_CastString = GoGo_CastString .. "[indoors] "..GoGo_InBook(GoGo_Variables.Localize.CatForm)
			UseSeperator = true
		end --if
		if not GoGo_Variables.SkipFlyingMount and GoGo_InBook(GoGo_Variables.Localize.FlightForm) and GoGo_Variables.CanFly then
			if UseSeperator then
				GoGo_CastString = GoGo_CastString .. ";"
			end --if
			if GoGo_InBook(GoGo_Variables.Localize.TravelForm) then
				GoGo_CastString = GoGo_CastString .. "[combat] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
				UseSeperator = true
			end --if
			if UseSeperator then
				GoGo_CastString = GoGo_CastString .. ";"
			end --if
			GoGo_CastString = GoGo_CastString .. GoGo_InBook(GoGo_Variables.Localize.FlightForm)
		else
			if UseSeperator then
				GoGo_CastString = GoGo_CastString .. ";"
			end --if
			if GoGo_InBook(GoGo_Variables.Localize.TravelForm) then
				GoGo_CastString = GoGo_CastString .. GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			end --if
		end --if
		return GoGo_CastString
	end, --function

--[[
	["DRUID"] = function()
		if GoGo_Prefs.DruidClickForm then
			if not GoGo_Variables.SkipFlyingMount and GoGo_InBook(GoGo_Variables.Localize.FlightForm) and GoGo_Variables.CanFly then
				return "/cancelform [flying] \n/use [swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm).."; [combat]"..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; "..GoGo_InBook(GoGo_Variables.Localize.FlightForm)
			elseif not GoGo_Variables.SkipFlyingMount and GoGo_Variables.CanFly then
				return "/cancelform [flying] \n/use [swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm).."; "..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			else
				return "/cancelform [flying] \n/use [swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm)..";"..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			end --if
		else
			local GoGo_CastString = "/use "
			local GoGo_NumForms = GetNumShapeshiftForms()
			local GoGo_FormName = ""
			for GoGo_TempCount = 1, GoGo_NumForms do
				_, GoGo_FormName = GetShapeshiftFormInfo(GoGo_TempCount)
				GoGo_CastString = GoGo_CastString .. "[form:" .. GoGo_TempCount .. "] "..GoGo_FormName..";"
			end --for
			if not GoGo_Variables.SkipFlyingMount and GoGo_InBook(GoGo_Variables.Localize.FlightForm) and GoGo_Variables.CanFly then
				GoGo_CastString = GoGo_CastString .. "[swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm).."; [combat]"..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; "..GoGo_InBook(GoGo_Variables.Localize.FlightForm)
			elseif not GoGo_Variables.SkipFlyingMount and GoGo_Variables.CanFly then
				GoGo_CastString = GoGo_CastString .. "[swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm).."; [combat]"..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			else
				GoGo_CastString = GoGo_CastString .. "[swimming] "..GoGo_InBook(GoGo_Variables.Localize.TravelForm).."; [indoors]"..GoGo_InBook(GoGo_Variables.Localize.CatForm)..";"..GoGo_InBook(GoGo_Variables.Localize.TravelForm)
			end --if
			return GoGo_CastString
		end --if
	end, --function
]]

	["SHAMAN"] = function()
		return GoGo_InBook(GoGo_Variables.Localize.GhostWolf)
	end, --function

	["NIGHTFAE"] = function()
		return GoGo_InBook(GoGo_Variables.Localize.SoulShape)
	end, --function
}

---------
function GoGo_SetOptionAutoDismount(GoGo_Value)
---------
	if GoGo_Value == 1 then
		GoGoFrame:RegisterEvent("UI_ERROR_MESSAGE")
		if _G["GoGo_Panel_AutoDismount"] then  -- check before setting - (ticket 709)
			GoGo_Panel_AutoDismount:SetChecked(1)
		end --if
		GoGo_Prefs.autodismount = true
	elseif GoGo_Value == 0 then	
		GoGoFrame:UnregisterEvent("UI_ERROR_MESSAGE")
		GoGo_Panel_AutoDismount:SetChecked(false)
		GoGo_Prefs.autodismount = false
	end --if
end --function

GOGO_COMMANDS = {
	["auto"] = function()
		GoGo_Prefs.autodismount = not GoGo_Prefs.autodismount
		GoGo_Msg("auto")
		if GoGo_Prefs.autodismount then
			GoGo_SetOptionAutoDismount(1)
		else
			GoGo_SetOptionAutoDismount(0)
		end --if
	end, --function
	["clear"] = function()
		if GoGo_Prefs.GlobalPrefMount then
			GoGo_Prefs.GlobalPrefMounts = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end --for
			end --if
		else
			GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID] = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end --for
			end --if
		end --if
		GoGo_Msg("pref")
	end, --function
	["debug"] = function()
		GoGo_StartStopDebug(10)
		GoGo_Msg("debug")
	end, --function
	["debug 0"] = function()
		GoGo_StartStopDebug(0)
		GoGo_Msg("debug")
	end, --function
	["debug 6"] = function()
		GoGo_StartStopDebug(6)
		GoGo_Msg("debug")
	end, --function
	["debug 5"] = function()
		GoGo_StartStopDebug(5)
		GoGo_Msg("debug")
	end, --function
	["updatenotice"] = function()
		GoGo_Prefs.DisableUpdateNotice = not GoGo_Prefs.DisableUpdateNotice
		GoGo_Msg("updatenotice")
		if GoGo_Prefs.DisableUpdateNotice then
			GoGo_Panel_DisableUpdateNotice:SetChecked(1)
		else
			GoGo_Panel_DisableUpdateNotice:SetChecked(false)
		end --if
	end, --function
	["mountnotice"] = function()
		GoGo_Prefs.DisableMountNotice = not GoGo_Prefs.DisableMountNotice
		GoGo_Msg("mountnotice")
		if GoGo_Prefs.DisableMountNotice then
			GoGo_Panel_DisableMountNotice:SetChecked(1)
		else
			GoGo_Panel_DisableMountNotice:SetChecked(false)
		end --if
	end, --function
	["druidclickform"] = function()
		GoGo_SetPref("DruidClickForm", not GoGo_Prefs.DruidClickForm)
		GoGo_Msg("druidclickform")
	end, --function
	["druidflightform"] = function()
		GoGo_SetPref("DruidFlightForm", not GoGo_Prefs.DruidFlightForm)
		GoGo_Msg("druidflightform")
	end, --function
	["options"] = function()
		Settings.OpenToCategory(GoGo_Panel.name)
	end, --function
}

GOGO_MESSAGES = {
	["auto"] = function()
		if GoGo_Prefs.autodismount then
			return "Autodismount active - </gogo auto> to toggle"
		else
			return "Autodismount inactive - </gogo auto> to toggle"
		end --if
	end, --function
	["pref"] = function()
		local msg = ""
		if not GoGo_Prefs.GlobalPrefMount then
			local list = ""
			if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID] then
				list = list .. GoGo_GetIDName(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID])
				msg = GoGo_Variables.Player.Zone..": "..list.." - </gogo clear> to clear"
			else
				msg = GoGo_Variables.Player.Zone..": ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end --if
			if GoGo_Prefs.GlobalPrefMounts then
				local listb = ""
				listb = listb .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = msg .. "\nGlobal Preferred Mounts: "..listb.." - Enable global mount preferences to change."
			end --if
			return msg
		else
			local list = ""
			if GoGo_Prefs.GlobalPrefMounts then
				list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = "Global Preferred Mounts: "..list.." - </gogo clear> to clear"
			else
				msg =  "Global Preferred Mounts: ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end --if
			if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID] then
				local listb = ""
				listb = listb .. GoGo_GetIDName(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID])
				msg = msg .. "\n" .. GoGo_Variables.Player.Zone ..": "..listb.." - Disable global mount preferences to change."
			end --if
			return msg
		end --if
	end, --function
	["debug"] = function()
		if GoGo_Variables.Debug >= 10 then
			return "GoGoMount debugging enabled for 1 GoGoButton click."
		elseif GoGo_Variables.Debug == 6 then
			return "GoGoMount debugging level 6 set"
		elseif GoGo_Variables.Debug == 5 then
			return "GoGoMount debugging level 5 set"
		elseif GoGo_Variables.Debug == 0 then
			return "GoGoMount debugging disabled for 1 GoGoButton click."
		end --if
	end, --function
	["globalexclude"] = function()
		local msg = ""
		if table.getn(GoGo_Prefs.GlobalExclude) == 0 then
			msg = "Excluded Mounts: ?".." - </gogo exclude [ItemLink]> or </gogo exclude [SpellName]> to add / remove"
			return msg
		else
			local list = ""
			list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalExclude)
			msg = "Excluded Mounts: "..list.." - </gogo exclude [ItemLink]> or </gogo exclude [SpellName]> to add / remove"
			return msg
		end --if
	end, --function
	["updatenotice"] = function()
		if GoGo_Prefs.DisableUpdateNotice then
			return "Update notices from other players disabled - </gogo updatenotice> to toggle"
		else
			return "Update notices from other players enabled - </gogo updatenotice> to toggle"
		end --if
	end, --function
	["mountnotice"] = function()
		if GoGo_Prefs.DisableMountNotice then
			return "Update notices about unknown mounts are disabled - </gogo mountnotice> to toggle"
		else
			return "Update notices about unknown mounts are enabled - </gogo mountnotice> to toggle"
		end --if
	end, --function
	["druidclickform"] = function()
		if GoGo_Prefs.DruidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end --if
	end, --function
	["druidflightform"] = function()
		if GoGo_Prefs.DruidFlightForm then
			return "Flight Forms always used over flying mounts - </gogo druidflightform> to toggle"
		else
			return "Flighing mounts selected, flight forms if moving - </gogo druidflightform> to toggle"
		end --if
	end, --function
	["UnknownMount"] = function() return GoGo_Variables.Localize.String.UnknownMountFound end, --function
	["UnknownMountType"] = function() return GoGo_Variables.Localize.String.UnknownMountTypeFound end, --function
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end, --function
}

---------
function GoGo_DebugAddLine(LogLine)
---------
	if not GoGo_Variables.DebugLine then GoGo_Variables.DebugLine = 1 end --if
	GoGo_DebugLog[GoGo_Variables.DebugLine] = (debugprofilestop()-GoGo_Variables.DebugTimer) .. " " .. LogLine
	GoGo_Msg(LogLine)
	if DLAPI then DLAPI.DebugLog("GoGoMount", LogLine) end 
	GoGo_Variables.DebugLine = GoGo_Variables.DebugLine + 1
	
end --function

---------
function GoGo_Panel_OnLoad(GoGo_Panel)
---------
	GoGo_Panel.name = "GoGoMount"
	GoGo_Panel.default = function (self) GoGo_Settings_Default("MAIN"); end;
	GoGo_category, _  = Settings.RegisterCanvasLayoutCategory(GoGo_Panel, GoGo_Panel.name)
	Settings.RegisterAddOnCategory(GoGo_category)
	
end --function

---------
function GoGo_Panel_Options()
---------
	GoGo_Panel_AutoDismount = CreateFrame("CheckButton", "GoGo_Panel_AutoDismount", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_AutoDismount:SetPoint("TOPLEFT", 16, -16)
	GoGo_Panel_AutoDismountText:SetText(GoGo_Variables.Localize.String.EnableAutoDismount)
	GoGo_Panel_AutoDismount:SetScript("OnClick",
		function(self)
			if GoGo_Panel_AutoDismount:GetChecked() then
				GoGo_SetOptionAutoDismount(1)
			else
				GoGo_SetOptionAutoDismount(0)
			end --if
		end --function
	)
	GoGo_Panel_AutoDismount:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.autodismount then
				GoGo_Panel_AutoDismount:SetChecked(1)
			else
				GoGo_Panel_AutoDismount:SetChecked(false)
			end --if
		end --function
	)

	GoGo_Panel_GlobalPrefMount = CreateFrame("CheckButton", "GoGo_Panel_GlobalPrefMount", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_GlobalPrefMount:SetPoint("TOPLEFT", "GoGo_Panel_AutoDismount", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_GlobalPrefMountText:SetText("Preferred mount changes apply to global setting")
	GoGo_Panel_GlobalPrefMount:SetScript("OnClick",
		function(self)
			if GoGo_Panel_GlobalPrefMount:GetChecked() then
				GoGo_Prefs.GlobalPrefMount = true
			else
				GoGo_Prefs.GlobalPrefMount = false
			end --if
		end --function
	)
	GoGo_Panel_GlobalPrefMount:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.GlobalPrefMount then
				GoGo_Panel_GlobalPrefMount:SetChecked(1)
			else
				GoGo_Panel_GlobalPrefMount:SetChecked(false)
			end --if
		end --function
	)

	GoGo_Panel_DisableUpdateNotice = CreateFrame("CheckButton", "GoGo_Panel_DisableUpdateNotice", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_DisableUpdateNotice:SetPoint("TOPLEFT", "GoGo_Panel_GlobalPrefMount", "BOTTOMLEFT", 0, -12)
	GoGo_Panel_DisableUpdateNoticeText:SetText(GoGo_Variables.Localize.String.DisableUpdateNotices)
	GoGo_Panel_DisableUpdateNotice:SetScript("OnClick",
		function(self)
			if GoGo_Panel_DisableUpdateNotice:GetChecked() then
				GoGo_Prefs.DisableUpdateNotice = true
			else
				GoGo_Prefs.DisableUpdateNotice = false
			end --if
		end --function
	)
	GoGo_Panel_DisableUpdateNotice:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.DisableUpdateNotice then
				GoGo_Panel_DisableUpdateNotice:SetChecked(1)
			else
				GoGo_Panel_DisableUpdateNotice:SetChecked(false)
			end --if
		end --function
	)

	GoGo_Panel_DisableMountNotice = CreateFrame("CheckButton", "GoGo_Panel_DisableMountNotice", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_DisableMountNotice:SetPoint("TOPLEFT", "GoGo_Panel_DisableUpdateNotice", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_DisableMountNoticeText:SetText(GoGo_Variables.Localize.String.DisableUnknownMountNotices)
	GoGo_Panel_DisableMountNotice:SetScript("OnClick",
		function(self)
			if GoGo_Panel_DisableMountNotice:GetChecked() then
				GoGo_Prefs.DisableMountNotice = true
			else
				GoGo_Prefs.DisableMountNotice = false
			end --if
		end --function
	)
	GoGo_Panel_DisableMountNotice:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.DisableMountNotice then
				GoGo_Panel_DisableMountNotice:SetChecked(1)
			else
				GoGo_Panel_DisableMountNotice:SetChecked(false)
			end --if
		end --function
	)

	GoGo_Panel_DisableWaterFlight = CreateFrame("CheckButton", "GoGo_Panel_DisableWaterFlight", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_DisableWaterFlight:SetPoint("TOPLEFT", "GoGo_Panel_DisableMountNotice", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_DisableWaterFlightText:SetText(GoGo_Variables.Localize.String.DisableFlyingFromWater)
	GoGo_Panel_DisableWaterFlight:SetScript("OnClick",
		function(self)
			if GoGo_Panel_DisableWaterFlight:GetChecked() then
				GoGo_Prefs.DisableWaterFlight = true
			else
				GoGo_Prefs.DisableWaterFlight = false
			end --if
		end --function
	)
	GoGo_Panel_DisableWaterFlight:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.DisableWaterFlight then
				GoGo_Panel_DisableWaterFlight:SetChecked(1)
			else
				GoGo_Panel_DisableWaterFlight:SetChecked(false)
			end --if
		end --function
	)
	
	GoGo_Panel_RemoveBuffs = CreateFrame("CheckButton", "GoGo_Panel_RemoveBuffs", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_RemoveBuffs:SetPoint("TOPLEFT", "GoGo_Panel_DisableWaterFlight", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_RemoveBuffsText:SetText(GoGo_Variables.Localize.String.RemoveBuffs)
	GoGo_Panel_RemoveBuffs.tooltipText = GoGo_Variables.Localize.String.RemoveBuffs_Long
	if GoGo_Prefs.RemoveBuffs then
		GoGo_Panel_RemoveBuffs:SetChecked(1)
	end --if
	GoGo_Panel_RemoveBuffs:SetScript("OnClick",
		function(self)
			GoGo_SetPref("RemoveBuffs", GoGo_Panel_RemoveBuffs:GetChecked())
		end --function
	)

	GoGo_Panel_AutoExcludeFlyingMounts = CreateFrame("CheckButton", "GoGo_Panel_AutoExcludeFlyingMounts", GoGo_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Panel_AutoExcludeFlyingMounts:SetPoint("TOPLEFT", "GoGo_Panel_RemoveBuffs", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_AutoExcludeFlyingMountsText:SetText(GoGo_Variables.Localize.String.AutoExcludeFlyingMountsInNoFlyAreas)
	GoGo_Panel_AutoExcludeFlyingMounts.tooltipText = GoGo_Variables.Localize.String.AutoExcludeFlyingMountsInNoFlyAreas_Long
	if GoGo_Prefs.AutoExcludeFlyingMounts then
		GoGo_Panel_AutoExcludeFlyingMounts:SetChecked(1)
	end --if
	GoGo_Panel_AutoExcludeFlyingMounts:SetScript("OnClick",
		function(self)
			GoGo_SetPref("AutoExcludeFlyingMounts", GoGo_Panel_AutoExcludeFlyingMounts:GetChecked())
		end --function
	)
end --function

---------
function GoGo_Druid_Panel()
---------
	GoGo_Druid_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_Druid_Panel.name = GoGo_Variables.Localize.String.DruidOptions
	GoGo_Druid_Panel.parent = "GoGoMount"
--	GoGo_Druid_Panel.okay = function (self) GoGo_Panel_Okay("DRUID"); end;
	GoGo_Druid_Panel.default = function (self) GoGo_Settings_Default("DRUID"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category,GoGo_Druid_Panel, GoGo_Variables.Localize.String.DruidOptions)

	GoGo_Druid_Panel_ClickForm = CreateFrame("CheckButton", "GoGo_Druid_Panel_ClickForm", GoGo_Druid_Panel,"InterfaceOptionsCheckButtonTemplate")
	GoGo_Druid_Panel_ClickForm:SetPoint("TOPLEFT", 16, -16)
	GoGo_Druid_Panel_ClickFormText:SetText(GoGo_Variables.Localize.String.DruidSingleClick)
	if GoGo_Prefs.DruidClickForm then
		GoGo_Druid_Panel_ClickForm:SetChecked(1)
	end --if
	GoGo_Druid_Panel_ClickForm:SetScript("OnClick",
		function(self)
			GoGo_SetPref("DruidClickForm", GoGo_Druid_Panel_ClickForm:GetChecked())
		end --function
	)

	GoGo_Druid_Panel_FlightForm = CreateFrame("CheckButton", "GoGo_Druid_Panel_FlightForm", GoGo_Druid_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Druid_Panel_FlightForm:SetPoint("TOPLEFT", "GoGo_Druid_Panel_ClickForm", "BOTTOMLEFT", 0, -4)
	GoGo_Druid_Panel_FlightFormText:SetText(GoGo_Variables.Localize.String.DruidFlightPreference)
	if GoGo_Prefs.DruidFlightForm then
		GoGo_Druid_Panel_FlightForm:SetChecked(1)
	end --if
	GoGo_Druid_Panel_FlightForm:SetScript("OnClick",
		function(self)
			GoGo_SetPref("DruidFlightForm", GoGo_Druid_Panel_FlightForm:GetChecked())
		end --function
	)

	GoGo_Druid_Panel_NoShapeInRandom = CreateFrame("CheckButton", "GoGo_Druid_Panel_NoShapeInRandom", GoGo_Druid_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Druid_Panel_NoShapeInRandom:SetPoint("TOPLEFT", "GoGo_Druid_Panel_FlightForm", "BOTTOMLEFT", 0, -4)
	GoGo_Druid_Panel_NoShapeInRandomText:SetText(GoGo_Variables.Localize.String.NoShapeInRandom)
	if GoGo_Prefs.DruidFormNotRandomize then
		GoGo_Druid_Panel_NoShapeInRandom:SetChecked(1)
	end --if
	GoGo_Druid_Panel_NoShapeInRandom:SetScript("OnClick",
		function(self)
			GoGo_SetPref("DruidFormNotRandomize", GoGo_Druid_Panel_NoShapeInRandom:GetChecked())
		end --function
	)

	GoGo_Druid_Panel_DisableInCombat = CreateFrame("CheckButton", "GoGo_Druid_Panel_DisableInCombat", GoGo_Druid_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Druid_Panel_DisableInCombat:SetPoint("TOPLEFT", "GoGo_Druid_Panel_NoShapeInRandom", "BOTTOMLEFT", 0, -4)
	GoGo_Druid_Panel_DisableInCombatText:SetText(GoGo_Variables.Localize.String.DisableInCombat)
	GoGo_Druid_Panel_DisableInCombat.tooltipText = GoGo_Variables.Localize.String.DisableInCombat_Long
	GoGo_Druid_Panel_DisableInCombat:SetScript("OnClick",
		function(self)
			GoGo_SetPref("DruidDisableInCombat", GoGo_Druid_Panel_DisableInCombat:GetChecked())
		end --function
	)
	GoGo_Druid_Panel_DisableInCombat:SetScript("OnShow",
		function(self)
			if GoGo_Prefs.DruidDisableInCombat then
				GoGo_Druid_Panel_DisableInCombat:SetChecked(1)
			else
				GoGo_Druid_Panel_DisableInCombat:SetChecked(false)
			end --if
		end --function
	)
end --function

---------
function GoGo_Hunter_Panel()
---------
	GoGo_Hunter_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_Hunter_Panel.name = GoGo_Variables.Localize.String.HunterOptions
	GoGo_Hunter_Panel.parent = "GoGoMount"
--	GoGo_Hunter_Panel.okay = function (self) GoGo_Panel_Okay("HUNTER"); end;
	GoGo_Hunter_Panel.default = function (self) GoGo_Settings_Default("HUNTER"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_Hunter_Panel,GoGo_Hunter_Panel.name)

	GoGo_Hunter_Panel_AspectOfPack = CreateFrame("CheckButton", "GoGo_Hunter_Panel_AspectOfPack", GoGo_Hunter_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Hunter_Panel_AspectOfPack:SetPoint("TOPLEFT", 16, -16)
	GoGo_Hunter_Panel_AspectOfPackText:SetText(GoGo_Variables.Localize.String.UseAspectOfThePackInstead)
	GoGo_Hunter_Panel_AspectOfPack.tooltipText = GoGo_Variables.Localize.String.UseAspectOfThePackInstead_Long
	if GoGo_Prefs.AspectPack then
		GoGo_Hunter_Panel_AspectOfPack:SetChecked(1)
	end --if
	GoGo_Hunter_Panel_AspectOfPack:SetScript("OnClick",
		function(self)
			GoGo_SetPref("AspectPack", GoGo_Hunter_Panel_AspectOfPack:GetChecked())
		end --function
	)
end --function

---------
function GoGo_Shaman_Panel()
---------
	GoGo_Shaman_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_Shaman_Panel.name = GoGo_Variables.Localize.String.ShamanOptions
	GoGo_Shaman_Panel.parent = "GoGoMount"
	GoGo_Shaman_Panel.default = function (self) GoGo_Settings_Default("SHAMAN"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_Shaman_Panel, GoGo_Shaman_Panel.name)

	GoGo_Shaman_Panel_ClickForm = CreateFrame("CheckButton", "GoGo_Shaman_Panel_ClickForm", GoGo_Shaman_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_Shaman_Panel_ClickForm:SetPoint("TOPLEFT", 16, -16)
	GoGo_Shaman_Panel_ClickFormText:SetText(GoGo_Variables.Localize.String.ShamanSingleClick)
	if GoGo_Prefs.ShamanClickForm then
		GoGo_Shaman_Panel_ClickForm:SetChecked(1)
	end --if
	GoGo_Shaman_Panel_ClickForm:SetScript("OnClick",
		function(self)
			GoGo_SetPref("ShamanClickForm", GoGo_Shaman_Panel_ClickForm:GetChecked())
		end --function
	)
end --function

---------
function GoGo_NightFae_Panel()
---------
	GoGo_NightFae_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_NightFae_Panel.name = GoGo_Variables.Localize.String.NightFaeOptions
	GoGo_NightFae_Panel.parent = "GoGoMount"
	GoGo_NightFae_Panel.default = function (self) GoGo_Settings_Default("NIGHTFAE"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_NightFae_Panel,GoGo_NightFae_Panel.name)

	GoGo_NightFae_Panel_ClickForm = CreateFrame("CheckButton", "GoGo_NightFae_Panel_ClickForm", GoGo_NightFae_Panel, "InterfaceOptionsCheckButtonTemplate")
	GoGo_NightFae_Panel_ClickForm:SetPoint("TOPLEFT", 16, -16)
	GoGo_NightFae_Panel_ClickFormText:SetText(GoGo_Variables.Localize.String.NightFaeSingleClick)
	if GoGo_Prefs.NightFaeClickForm then
		GoGo_NightFae_Panel_ClickForm:SetChecked(1)
	end --if
	GoGo_NightFae_Panel_ClickForm:SetScript("OnClick",
		function(self)
			GoGo_SetPref("NightFaeClickForm", GoGo_NightFae_Panel_ClickForm:GetChecked())
		end --function
	)
end --function

---------
function GoGo_ZoneFavorites_Panel()
---------
	GoGo_ZoneFavorites_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_ZoneFavorites_Panel.name = GoGo_Variables.Localize.String.CurrentZoneFavorites
	GoGo_ZoneFavorites_Panel.parent = "GoGoMount"
	GoGo_ZoneFavorites_Panel.default = function (self) GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"]={}; GoGo_AddOptionCheckboxes("GoGo_ZoneFavorites_ContentFrame"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_ZoneFavorites_Panel, GoGo_ZoneFavorites_Panel.name)
	
	GoGo_ZoneFavorites_ScrollFrame = CreateFrame("ScrollFrame", "GoGo_ZoneFavorites_ScrollFrame", GoGo_ZoneFavorites_Panel, "UIPanelScrollFrameTemplate")
	GoGo_ZoneFavorites_ScrollFrame:SetPoint("TOPLEFT", "GoGo_ZoneFavorites_Panel", "TOPLEFT", 0, -5)
	GoGo_ZoneFavorites_ScrollFrame:SetPoint("BOTTOMLEFT", "GoGo_ZoneFavorites_Panel", "BOTTOMLEFT", 0, 5)
	GoGo_ZoneFavorites_ScrollFrame:SetPoint("RIGHT", "GoGo_ZoneFavorites_Panel", "RIGHT", -2000)

	GoGo_ZoneFavorites_Panel.ScrollFrame = GoGo_ZoneFavorites_ScrollFrame  --

	GoGo_ZoneFavorites_ContentFrame = CreateFrame("Frame", "GoGo_ZoneFavorites_ContentFrame")
	GoGo_ZoneFavorites_ContentFrame:SetWidth(600)
	GoGo_ZoneFavorites_ContentFrame:SetHeight(1)
	GoGo_ZoneFavorites_ContentFrame:SetPoint("TOPLEFT", "GoGo_ZoneFavorites_Panel", "TOPLEFT", 0, 0)

	GoGo_ZoneFavorites_ScrollFrame:SetScrollChild(GoGo_ZoneFavorites_ContentFrame)

	GoGo_ZoneFavorites_ContentFrameTitle = GoGo_ZoneFavorites_ContentFrame:CreateFontString("GoGo_ZoneFavorites_ContentFrameTitle", 'ARTWORK', 'GameFontHighlightMedium')
	GoGo_ZoneFavorites_ContentFrameTitle:SetPoint('TOPLEFT', "GoGo_ZoneFavorites_ContentFrame", 'TOPLEFT', 16, -8)
	GoGo_ZoneFavorites_ContentFrameTitle:SetJustifyH('LEFT')
	GoGo_ZoneFavorites_ContentFrameTitle:SetJustifyV('TOP')
	--GoGo_ZoneFavorites_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.CurrentZone .. ":  " .. GoGo_Variables.Player.Zone)

	local GoGo_ZoneFavorites_ContentFrameDescription = GoGo_ZoneFavorites_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	GoGo_ZoneFavorites_ContentFrameDescription:SetHeight(32)
	GoGo_ZoneFavorites_ContentFrameDescription:SetPoint('TOPLEFT', "GoGo_ZoneFavorites_ContentFrame", 'TOPLEFT', 16, -24)
	GoGo_ZoneFavorites_ContentFrameDescription:SetPoint('RIGHT', "GoGo_ZoneFavorites_ScrollFrame", -32, 0)
	GoGo_ZoneFavorites_ContentFrameDescription:SetWordWrap(true)
	GoGo_ZoneFavorites_ContentFrameDescription:SetJustifyH('LEFT')
	GoGo_ZoneFavorites_ContentFrameDescription:SetJustifyV('TOP')
	GoGo_ZoneFavorites_ContentFrameDescription:SetText(GoGo_Variables.Localize.String.CurrentZoneDescription)
	GoGo_AddOptionCheckboxes("GoGo_ZoneFavorites_ContentFrame")
	GoGo_ZoneFavorites_ContentFrame:SetScript("OnShow", function(self) GoGo_AddOptionCheckboxes("GoGo_ZoneFavorites_ContentFrame") end)
end --function

---------
function GoGo_GlobalFavorites_Panel()
---------
	GoGo_GlobalFavorites_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_GlobalFavorites_Panel.name = GoGo_Variables.Localize.String.GlobalFavorites
	GoGo_GlobalFavorites_Panel.parent = "GoGoMount"
	GoGo_GlobalFavorites_Panel.default = function (self) GoGo_Prefs.GlobalPrefMounts = nil; GoGo_AddOptionCheckboxes("GoGo_GlobalFavorites_ContentFrame"); end;  -- use clear command with default button

	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_GlobalFavorites_Panel, GoGo_GlobalFavorites_Panel.name)
	
	GoGo_GlobalFavorites_ScrollFrame = CreateFrame("ScrollFrame", "GoGo_GlobalFavorites_ScrollFrame", GoGo_GlobalFavorites_Panel, "UIPanelScrollFrameTemplate")
	GoGo_GlobalFavorites_ScrollFrame:SetPoint("TOPLEFT", "GoGo_GlobalFavorites_Panel", "TOPLEFT", 0, -5)
	GoGo_GlobalFavorites_ScrollFrame:SetPoint("BOTTOMLEFT", "GoGo_GlobalFavorites_Panel", "BOTTOMLEFT", 0, 5)
	GoGo_GlobalFavorites_ScrollFrame:SetPoint("RIGHT", "GoGo_GlobalFavorites_Panel", "RIGHT", -2000)

	GoGo_GlobalFavorites_Panel.ScrollFrame = GoGo_GlobalFavorites_ScrollFrame  --

	GoGo_GlobalFavorites_ContentFrame = CreateFrame("Frame", "GoGo_GlobalFavorites_ContentFrame")
	GoGo_GlobalFavorites_ContentFrame:SetWidth(600)
	GoGo_GlobalFavorites_ContentFrame:SetHeight(1)
	GoGo_GlobalFavorites_ContentFrame:SetPoint("TOPLEFT", "GoGo_GlobalFavorites_Panel", "TOPLEFT", 0, 0)
	GoGo_GlobalFavorites_ContentFrame:SetScript("OnShow", function(self) GoGo_AddOptionCheckboxes("GoGo_GlobalFavorites_ContentFrame") end)
	GoGo_AddOptionCheckboxes("GoGo_GlobalFavorites_ContentFrame")

	GoGo_GlobalFavorites_ScrollFrame:SetScrollChild(GoGo_GlobalFavorites_ContentFrame)

	local GoGo_GlobalFavorites_ContentFrameTitle = GoGo_GlobalFavorites_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	GoGo_GlobalFavorites_ContentFrameTitle:SetPoint('TOPLEFT', "GoGo_GlobalFavorites_ContentFrame", 'TOPLEFT', 16, -8)
	GoGo_GlobalFavorites_ContentFrameTitle:SetJustifyH('LEFT')
	GoGo_GlobalFavorites_ContentFrameTitle:SetJustifyV('TOP')
	GoGo_GlobalFavorites_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.GlobalFavorites)
	
	local GoGo_GlobalFavorites_ContentFrameDescription = GoGo_GlobalFavorites_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	GoGo_GlobalFavorites_ContentFrameDescription:SetHeight(32)
	GoGo_GlobalFavorites_ContentFrameDescription:SetPoint('TOPLEFT', "GoGo_GlobalFavorites_ContentFrame", 'TOPLEFT', 16, -24)
	GoGo_GlobalFavorites_ContentFrameDescription:SetPoint('RIGHT', "GoGo_GlobalFavorites_ScrollFrame", -32, 0)
	GoGo_GlobalFavorites_ContentFrameDescription:SetWordWrap(true)
	GoGo_GlobalFavorites_ContentFrameDescription:SetJustifyH('LEFT')
	GoGo_GlobalFavorites_ContentFrameDescription:SetJustifyV('TOP')
	GoGo_GlobalFavorites_ContentFrameDescription:SetText(GoGo_Variables.Localize.String.GlobalZoneDescription)

end --function

---------
function GoGo_ExtraPassengerMounts_Panel()
---------
	GoGo_ExtraPassengerMounts_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_ExtraPassengerMounts_Panel.name = GoGo_Variables.Localize.String.ExtraPassengerMounts
	GoGo_ExtraPassengerMounts_Panel.parent = "GoGoMount"
	GoGo_ExtraPassengerMounts_Panel.default = function (self) GoGo_Prefs.ExtraPassengerMounts={}; GoGo_AddOptionCheckboxes("GoGo_ExtraPassengerMounts_ContentFrame"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_ExtraPassengerMounts_Panel, GoGo_ExtraPassengerMounts_Panel.name)
	
	GoGo_ExtraPassengerMounts_ScrollFrame = CreateFrame("ScrollFrame", "GoGo_ExtraPassengerMounts_ScrollFrame", GoGo_ExtraPassengerMounts_Panel, "UIPanelScrollFrameTemplate")
	GoGo_ExtraPassengerMounts_ScrollFrame:SetPoint("TOPLEFT", "GoGo_ExtraPassengerMounts_Panel", "TOPLEFT", 0, -5)
	GoGo_ExtraPassengerMounts_ScrollFrame:SetPoint("BOTTOMLEFT", "GoGo_ExtraPassengerMounts_Panel", "BOTTOMLEFT", 0, 5)
	GoGo_ExtraPassengerMounts_ScrollFrame:SetPoint("RIGHT", "GoGo_ExtraPassengerMounts_Panel", "RIGHT", -2000)

	GoGo_ExtraPassengerMounts_Panel.ScrollFrame = GoGo_ExtraPassengerMounts_ScrollFrame  --

	GoGo_ExtraPassengerMounts_ContentFrame = CreateFrame("Frame", "GoGo_ExtraPassengerMounts_ContentFrame")
	GoGo_ExtraPassengerMounts_ContentFrame:SetWidth(600)
	GoGo_ExtraPassengerMounts_ContentFrame:SetHeight(1)
	GoGo_ExtraPassengerMounts_ContentFrame:SetPoint("TOPLEFT", "GoGo_ExtraPassengerMounts_Panel", "TOPLEFT", 0, 0)

	GoGo_ExtraPassengerMounts_ScrollFrame:SetScrollChild(GoGo_ExtraPassengerMounts_ContentFrame)

	GoGo_ExtraPassengerMounts_ContentFrameTitle = GoGo_ExtraPassengerMounts_ContentFrame:CreateFontString("GoGo_ExtraPassengerMounts_ContentFrameTitle", 'ARTWORK', 'GameFontHighlightMedium')
	GoGo_ExtraPassengerMounts_ContentFrameTitle:SetPoint('TOPLEFT', "GoGo_ExtraPassengerMounts_ContentFrame", 'TOPLEFT', 16, -8)
	GoGo_ExtraPassengerMounts_ContentFrameTitle:SetJustifyH('LEFT')
	GoGo_ExtraPassengerMounts_ContentFrameTitle:SetJustifyV('TOP')
	GoGo_ExtraPassengerMounts_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.ExtraPassengerMounts)

	local GoGo_ExtraPassengerMounts_ContentFrameDescription = GoGo_ExtraPassengerMounts_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetHeight(32)
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetPoint('TOPLEFT', "GoGo_ExtraPassengerMounts_ContentFrame", 'TOPLEFT', 16, -24)
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetPoint('RIGHT', "GoGo_ExtraPassengerMounts_ScrollFrame", -32, 0)
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetWordWrap(true)
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetJustifyH('LEFT')
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetJustifyV('TOP')
	GoGo_ExtraPassengerMounts_ContentFrameDescription:SetText(GoGo_Variables.Localize.String.ExtraPassengerMountsDescription)
	GoGo_AddOptionCheckboxes("GoGo_ExtraPassengerMounts_ContentFrame")
	GoGo_ExtraPassengerMounts_ContentFrame:SetScript("OnShow", function(self) GoGo_AddOptionCheckboxes("GoGo_ExtraPassengerMounts_ContentFrame") end)
end --function

---------
function GoGo_GlobalExclusions_Panel()
---------
	GoGo_GlobalExclusions_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_GlobalExclusions_Panel.name = GoGo_Variables.Localize.String.GlobalExclusions
	GoGo_GlobalExclusions_Panel.parent = "GoGoMount"
	GoGo_GlobalExclusions_Panel.default = function (self) GoGo_Prefs.GlobalExclude = nil; GoGo_AddOptionCheckboxes("GoGo_GlobalExclusions_ContentFrame"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_GlobalExclusions_Panel, GoGo_GlobalExclusions_Panel.name)
	
	GoGo_GlobalExclusions_ScrollFrame = CreateFrame("ScrollFrame", "GoGo_GlobalExclusions_ScrollFrame", GoGo_GlobalExclusions_Panel, "UIPanelScrollFrameTemplate")
	GoGo_GlobalExclusions_ScrollFrame:SetPoint("TOPLEFT", "GoGo_GlobalExclusions_Panel", "TOPLEFT", 0, -5)
	GoGo_GlobalExclusions_ScrollFrame:SetPoint("BOTTOMLEFT", "GoGo_GlobalExclusions_Panel", "BOTTOMLEFT", 0, 5)
	GoGo_GlobalExclusions_ScrollFrame:SetPoint("RIGHT", "GoGo_GlobalExclusions_Panel", "RIGHT", -2000)

	GoGo_GlobalExclusions_Panel.ScrollFrame = GoGo_GlobalExclusions_ScrollFrame  --

	GoGo_GlobalExclusions_ContentFrame = CreateFrame("Frame", "GoGo_GlobalExclusions_ContentFrame")
	GoGo_GlobalExclusions_ContentFrame:SetWidth(600)
	GoGo_GlobalExclusions_ContentFrame:SetHeight(1)
	GoGo_GlobalExclusions_ContentFrame:SetPoint("TOPLEFT", "GoGo_GlobalExclusions_Panel", "TOPLEFT", 0, 0)
	GoGo_GlobalExclusions_ContentFrame:SetScript("OnShow", function(self) GoGo_AddOptionCheckboxes("GoGo_GlobalExclusions_ContentFrame") end)
	GoGo_AddOptionCheckboxes("GoGo_GlobalExclusions_ContentFrame")
	GoGo_GlobalExclusions_ScrollFrame:SetScrollChild(GoGo_GlobalExclusions_ContentFrame)

	local GoGo_GlobalExclusions_ContentFrameTitle = GoGo_GlobalExclusions_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	GoGo_GlobalExclusions_ContentFrameTitle:SetPoint('TOPLEFT', "GoGo_GlobalExclusions_ContentFrame", 'TOPLEFT', 16, -8)
	GoGo_GlobalExclusions_ContentFrameTitle:SetJustifyH('LEFT')
	GoGo_GlobalExclusions_ContentFrameTitle:SetJustifyV('TOP')
	GoGo_GlobalExclusions_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.GlobalExclusions)

	local GoGo_GlobalExclusions_ContentFrameDescription = GoGo_GlobalExclusions_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	GoGo_GlobalExclusions_ContentFrameDescription:SetHeight(32)
	GoGo_GlobalExclusions_ContentFrameDescription:SetPoint('TOPLEFT', "GoGo_GlobalExclusions_ContentFrame", 'TOPLEFT', 16, -24)
	GoGo_GlobalExclusions_ContentFrameDescription:SetPoint('RIGHT', "GoGo_GlobalExclusions_ScrollFrame", -32, 0)
	GoGo_GlobalExclusions_ContentFrameDescription:SetWordWrap(true)
	GoGo_GlobalExclusions_ContentFrameDescription:SetJustifyH('LEFT')
	GoGo_GlobalExclusions_ContentFrameDescription:SetJustifyV('TOP')
	GoGo_GlobalExclusions_ContentFrameDescription:SetText(GoGo_Variables.Localize.String.GlobalExclusionsDescription)

end --function

---------
function GoGo_ZoneExclusions_Panel()
---------
	GoGo_ZoneExclusions_Panel = CreateFrame("Frame", nil, UIParent)
	GoGo_ZoneExclusions_Panel.name = GoGo_Variables.Localize.String.CurrentZoneExclusions
	GoGo_ZoneExclusions_Panel.parent = "GoGoMount"
	GoGo_ZoneExclusions_Panel.default = function (self) GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]={}; GoGo_AddOptionCheckboxes("GoGo_ZoneExclusions_ContentFrame"); end;  -- use clear command with default button
	Settings.RegisterCanvasLayoutSubcategory(GoGo_category, GoGo_ZoneExclusions_Panel, GoGo_ZoneExclusions_Panel.name)
	
	GoGo_ZoneExclusions_ScrollFrame = CreateFrame("ScrollFrame", "GoGo_ZoneExclusions_ScrollFrame", GoGo_ZoneExclusions_Panel, "UIPanelScrollFrameTemplate")
	GoGo_ZoneExclusions_ScrollFrame:SetPoint("TOPLEFT", "GoGo_ZoneExclusions_Panel", "TOPLEFT", 0, -5)
	GoGo_ZoneExclusions_ScrollFrame:SetPoint("BOTTOMLEFT", "GoGo_ZoneExclusions_Panel", "BOTTOMLEFT", 0, 5)
	GoGo_ZoneExclusions_ScrollFrame:SetPoint("RIGHT", "GoGo_ZoneExclusions_Panel", "RIGHT", -2000)

	GoGo_ZoneExclusions_Panel.ScrollFrame = GoGo_ZoneExclusions_ScrollFrame  --

	GoGo_ZoneExclusions_ContentFrame = CreateFrame("Frame", "GoGo_ZoneExclusions_ContentFrame")
	GoGo_ZoneExclusions_ContentFrame:SetWidth(600)
	GoGo_ZoneExclusions_ContentFrame:SetHeight(1)
	GoGo_ZoneExclusions_ContentFrame:SetPoint("TOPLEFT", "GoGo_ZoneExclusions_Panel", "TOPLEFT", 0, 0)

	GoGo_ZoneExclusions_ScrollFrame:SetScrollChild(GoGo_ZoneExclusions_ContentFrame)

	GoGo_ZoneExclusions_ContentFrameTitle = GoGo_ZoneExclusions_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	GoGo_ZoneExclusions_ContentFrameTitle:SetPoint('TOPLEFT', "GoGo_ZoneExclusions_ContentFrame", 'TOPLEFT', 16, -8)
	GoGo_ZoneExclusions_ContentFrameTitle:SetJustifyH('LEFT')
	GoGo_ZoneExclusions_ContentFrameTitle:SetJustifyV('TOP')
--	GoGo_ZoneExclusions_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.CurrentZoneExclusions)

	local GoGo_ZoneExclusions_ContentFrameDescription = GoGo_ZoneExclusions_ContentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	GoGo_ZoneExclusions_ContentFrameDescription:SetHeight(32)
	GoGo_ZoneExclusions_ContentFrameDescription:SetPoint('TOPLEFT', "GoGo_ZoneExclusions_ContentFrame", 'TOPLEFT', 16, -24)
	GoGo_ZoneExclusions_ContentFrameDescription:SetPoint('RIGHT', "GoGo_ZoneExclusions_ScrollFrame", -32, 0)
	GoGo_ZoneExclusions_ContentFrameDescription:SetWordWrap(true)
	GoGo_ZoneExclusions_ContentFrameDescription:SetJustifyH('LEFT')
	GoGo_ZoneExclusions_ContentFrameDescription:SetJustifyV('TOP')
	GoGo_ZoneExclusions_ContentFrameDescription:SetText(GoGo_Variables.Localize.String.ZoneExclusionsDescription)
	GoGo_AddOptionCheckboxes("GoGo_ZoneExclusions_ContentFrame")
	GoGo_ZoneExclusions_ContentFrame:SetScript("OnShow", function(self) GoGo_AddOptionCheckboxes("GoGo_ZoneExclusions_ContentFrame") end)

end --function

---------
function GoGo_SetPref(strPref, intValue, boolNoPanel)
---------
	-- boolNoPanel = set to true to skip updating GUI checkboxes  (called by setdefaults before GUI frames are loaded)
	if (not strPref) then
		return
	end --if
	
	if strPref == "DruidClickForm" then
		GoGo_Prefs.DruidClickForm = intValue
		if (not boolNoPanel) then
			GoGo_Druid_Panel_ClickForm:SetChecked(intValue)
		end --if
	elseif strPref == "DruidFlightForm" then
		GoGo_Prefs.DruidFlightForm = intValue
		if (not boolNoPanel) then
			GoGo_Druid_Panel_FlightForm:SetChecked(intValue)
		end --if
	elseif strPref == "DruidFormNotRandomize" then
		GoGo_Prefs.DruidFormNotRandomize = intValue
		if (not boolNoPanel) then
			GoGo_Druid_Panel_NoShapeInRandom:SetChecked(intValue)
		end --if
	elseif strPref == "ShamanClickForm" then
		GoGo_Prefs.ShamanClickForm = intValue
		if (not boolNoPanel) then
			GoGo_Shaman_Panel_ClickForm:SetChecked(intValue)
		end --if
	elseif strPref == "NightFaeClickForm" then
		GoGo_Prefs.NightFaeClickForm = intValue
		if (not boolNoPanel) then
			GoGo_NightFae_Panel_ClickForm:SetChecked(intValue)
		end --if
	elseif strPref == "DruidDisableInCombat" then
		GoGo_Prefs.DruidDisableInCombat = intValue
		if (not boolNoPanel) then
			GoGo_Druid_Panel_DisableInCombat:SetChecked(intValue)
		end --if
	elseif strPref == "RemoveBuffs" then
		GoGo_Prefs.RemoveBuffs = intValue
		if (not boolNoPanel) then
			GoGo_Panel_RemoveBuffs:SetChecked(intValue)
		end --if
	elseif strPref == "AutoExcludeFlyingMounts" then
		GoGo_Prefs.AutoExcludeFlyingMounts = intValue
		if (not boolNoPanel) then
			GoGo_Panel_AutoExcludeFlyingMounts:SetChecked(intValue)
		end --if
	elseif strPref == "AspectPack" then
		GoGo_Prefs.AspectPack = intValue
		if (not boolNoPanel) then
			GoGo_Hunter_Panel_AspectOfPack:SetChecked(intValue)
		end --if
	end --if

end --function

---------
function GoGo_Settings_Default(Class)
---------
	-- class should only be set if using the default button from the option gui
	if Class == "DRUID" then
		GoGo_SetPref("DruidClickForm", true)
		GoGo_SetPref("DruidFlightForm", false)
		GoGo_SetPref("DruidFormNotRandomize", false)
		GoGo_SetPref("DruidDisableInCombat", false)
		Settings.OpenToCategory(GoGo_Druid_Panel.name)
	elseif Class == "HUNTER" then
		GoGo_SetPref("AspectPack", false)
		Settings.OpenToCategory(GoGo_Hunter_Panel.name)
	elseif Class == "SHAMAN" then
		GoGo_SetPref("ShamanClickForm", false)
	elseif Class == "MAIN" then
		--GoGo_Prefs.autodismount = true
		GoGo_SetOptionAutoDismount(1)
		GoGo_Prefs.DisableUpdateNotice = false
		GoGo_Prefs.DisableMountNotice = false
		GoGo_Prefs.GlobalPrefMount = false
		GoGo_Prefs.DisableWaterFlight = true
		GoGo_SetPref("RemoveBuffs", true)
		GoGo_SetPref("AutoExcludeFlyingMounts", false)
		Settings.OpenToCategory(GoGo_Panel_Options.name)
	else
		GoGo_Prefs = {}
		GoGo_Prefs.MapIDs = {}
		GoGo_Prefs.ExtraPassengerMounts = {}
		GoGo_Prefs.GlobalExclude = {}
		GoGo_Prefs.version = C_AddOns.GetAddOnMetadata("GoGoMount", "Version")
--		GoGo_Prefs.autodismount = true
		GoGo_SetOptionAutoDismount(1)
		GoGo_Prefs.DisableUpdateNotice = false
		GoGo_Prefs.DisableMountNotice = false
		GoGo_SetPref("DruidClickForm", true, true)
		GoGo_SetPref("DruidFlightForm", false, true)
		GoGo_Prefs.UnknownMounts = {}
		GoGo_Prefs.GlobalPrefMounts = {}
		GoGo_Prefs.GlobalPrefMount = false
		GoGo_SetPref("AspectPack", false, true)
		GoGo_SetPref("DruidFormNotRandomize", false, true)
		GoGo_Prefs.DisableWaterFlight = true
		GoGo_SetPref("RemoveBuffs", true, true)
		GoGo_SetPref("AutoExcludeFlyingMounts", false, true)
		GoGo_SetPref("DruidDisableInCombat", false, true)
		GoGo_SetPref("ShamanClickForm", false, true)
		GoGo_SetPref("NightFaeClickForm", false, true)
		GoGo_Prefs.PrefVer = 1

	end --if
end --function

---------
function GoGo_Settings_SetUpdates()
---------
	GoGo_Prefs.version = C_AddOns.GetAddOnMetadata("GoGoMount", "Version")
	if not GoGo_Prefs.autodismount then GoGo_Prefs.autodismount = false end
	if not GoGo_Prefs.DisableUpdateNotice then GoGo_Prefs.DisableUpdateNotice = false end
	if not GoGo_Prefs.DisableMountNotice then GoGo_Prefs.DisableMountNotice = false end
	if not GoGo_Prefs.DruidClickForm then GoGo_Prefs.DruidClickForm = false end
	if not GoGo_Prefs.DruidFlightForm then GoGo_Prefs.DruidFlightForm = false end
	if not GoGo_Prefs.GlobalPrefMount then GoGo_Prefs.GlobalPrefMount = false end
	if not GoGo_Prefs.AspectPack then GoGo_Prefs.AspectPack = false end
	if not GoGo_Prefs.DruidFormNotRandomize then GoGo_Prefs.DruidFormNotRandomize = false end
	if not GoGo_Prefs.DisableWaterFlight then GoGo_Prefs.DisableWaterFlight = false end
	if not GoGo_Prefs.RemoveBuffs then GoGo_Prefs.RemoveBuffs = false end
	if not GoGo_Prefs.AutoExcludeFlyingMounts then GoGo_Prefs.AutoExcludeFlyingMounts = false end
	if not GoGo_Prefs.DruidDisableInCombat then GoGo_Prefs.DruidDisableInCombat = false end
	if not GoGo_Prefs.ShamanClickForm then GoGo_Prefs.ShamanClickForm = false end
	if not GoGo_Prefs.NightFaeClickForm then GoGo_Prefs.NightFaeClickForm = false end

	GoGo_Prefs.UnknownMounts = {}
	if not GoGo_Prefs.GlobalExclude then
		GoGo_Prefs.GlobalExclude = {}
	end --if
	if not GoGo_Prefs.MapIDs then
		GoGo_Prefs.MapIDs = {}
	end --if
	if not GoGo_Prefs.ExtraPassengerMounts then
		GoGo_Prefs.ExtraPassengerMounts = {}
	end --if
	
	-- old variables no longer used so we're removing them from the saved variables
	GoGo_Prefs.preferflight = nil
	GoGo_Prefs.RemoveDebuffs = nil
	GoGo_Prefs.checkspells = nil
	GoGo_Prefs.PaliUseCrusader = nil
	GoGo_Prefs.PaladinUseCrusaderAura = nil
	
	GoGo_Prefs.PrefVer = 1

end --function

---------
function GoGo_AddOptionCheckboxes(GoGo_FrameParentText)
---------
	-- GoGo_FrameParentText will contain a string to indicate which panel called this function
		-- "GoGo_ZoneFavorites_ContentFrame"
		-- "GoGo_GlobalFavorites_ContentFrame"
		-- "GoGo_GlobalExclusions_ContentFrame"
		-- "GoGo_ZoneExclusions_ContentFrame"
	if not GoGo_Variables.Player.MapID then
		return  -- some UI mods try to draw frames before game has loaded causing errors.. this is to stop the errors.
	end --if
--	if not GoGo_Prefs then
		-- like above, something tries to draw the options before we've even created our default settings on new installs
--		return
--	elseif not GoGo_Prefs.MapIDs then
--		return
--	elseif not GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID] then
--		return
--	end --if
	
	local GoGo_Mounts = GoGo_BuildMountList()
	local GoGo_MountCount = table.getn(GoGo_Mounts) or 0
	local _G = getfenv()
	GoGo_FrameParent = _G[GoGo_FrameParentText]
	GoGo_UpdateZonePrefs()  -- to build zone template with preferred and excluded mounts incase it didn't work at logon

--	GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): on show ran")

	if GoGo_FrameParentText == "GoGo_ZoneFavorites_ContentFrame" then
		_G["GoGo_ZoneFavorites_ContentFrame"]:SetHeight((16 * GoGo_MountCount)+44)
		GoGo_ZoneFavorites_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.CurrentZoneFavorites .. " - "  .. GoGo_Variables.Player.Zone)
	elseif GoGo_FrameParentText == "GoGo_GlobalFavorites_ContentFrame" then
		_G["GoGo_GlobalFavorites_ContentFrame"]:SetHeight((16 * GoGo_MountCount)+44)
	elseif GoGo_FrameParentText == "GoGo_GlobalExclusions_ContentFrame" then
		_G["GoGo_GlobalExclusions_ContentFrame"]:SetHeight((16 * GoGo_MountCount)+44)
	elseif GoGo_FrameParentText == "GoGo_ZoneExclusions_ContentFrame" then
		_G["GoGo_ZoneExclusions_ContentFrame"]:SetHeight((16 * GoGo_MountCount)+44)
		GoGo_ZoneExclusions_ContentFrameTitle:SetText(GoGo_Variables.Localize.String.CurrentZoneExclusions .. " - " .. GoGo_Variables.Player.Zone)
	elseif GoGo_FrameParentText == "GoGo_ExtraPassengerMounts_ContentFrame" then
		GoGo_Mounts = GoGo_FilterMountsIn(GoGo_Mounts, 2) or {}
		GoGo_MountCount = table.getn(GoGo_Mounts) or 0
		_G["GoGo_ExtraPassengerMounts_ContentFrame"]:SetHeight((16 * GoGo_MountCount)+44)
	end --if

	if GoGo_MountCount == 0 then
		return nil
	end --if

	local tMountNames = {}
	local tMountIDNames = {}
	local sMountName
	local i
	for i=1, GoGo_MountCount do
		sMountName = GoGo_GetIDName(GoGo_Mounts[i])
		table.insert(tMountNames, sMountName)
		tMountIDNames[sMountName] = GoGo_Mounts[i]
	end --for
	table.sort(tMountNames)

	for i=1, GoGo_MountCount do
		local GoGo_MountID = tMountIDNames[tMountNames[i]]
		local GoGo_checkboxrow = (-44 + (-16 * i))
		local GoGo_CheckBoxName = GoGo_FrameParentText .. GoGo_MountID
		if _G[GoGo_CheckBoxName] then
			_G[GoGo_CheckBoxName]:SetPoint("TOPLEFT", 16, GoGo_checkboxrow)
			_G[GoGo_CheckBoxName]:SetChecked(false)
--				_G[GoGo_CheckBoxName].tooltipText = "" -- clear tool tip text
		else
			GoGo_CheckButton = CreateFrame("CheckButton", GoGo_CheckBoxName, GoGo_FrameParent, "ChatConfigCheckButtonTemplate")
			GoGo_CheckButton:SetPoint("TOPLEFT", 16, GoGo_checkboxrow)
			getglobal(GoGo_CheckButton:GetName() .. 'Text'):SetText(GoGo_GetIDName(GoGo_MountID))
		end --if

		if GoGo_Variables.Player.Class == "HUNTER" then  -- clear aspect of cheetah / pack incase hunter option changes
			if GoGo_MountID == GoGo_Variables.Localize.AspectPack and _G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectCheetah] then
				_G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectCheetah]:Hide()
				_G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectPack]:Show()
			elseif GoGo_MountID == GoGo_Variables.Localize.AspectCheetah and _G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectPack] then
				_G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectCheetah]:Show()
				_G[GoGo_FrameParentText .. GoGo_Variables.Localize.AspectPack]:Hide()
			end --if
		end --if
		
		if GoGo_FrameParentText == "GoGo_ZoneFavorites_ContentFrame" then
		    -- Checking if MapID is valid as we sometimes get called before MapID is valid (e.g. jumping in the Maw)
			if  GoGo_Variables.Player.MapID then
				if table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"]) > 0 then
					--GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): zone exists ")
					for GoGo_FavoriteCount = 1, table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"]) do
						if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Preferred"][GoGo_FavoriteCount] == GoGo_MountID then
							_G[GoGo_CheckBoxName]:SetChecked(1)
							-- GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): set checked " .. GoGo_MountID)
						end --if
					end --for
				end --if
			end --if
			_G[GoGo_CheckBoxName]:SetScript("OnClick",
				function(self)
					GoGo_ZonePrefMount(GoGo_MountID)
				end --function
			)
		elseif GoGo_FrameParentText == "GoGo_GlobalFavorites_ContentFrame" then
			if GoGo_Prefs.GlobalPrefMounts then
				--GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): zone exists ")
				for GoGo_FavoriteCount = 1, table.getn(GoGo_Prefs.GlobalPrefMounts) do
					if GoGo_Prefs.GlobalPrefMounts[GoGo_FavoriteCount] == GoGo_MountID then
						_G[GoGo_CheckBoxName]:SetChecked(1)
--							GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): set checked ")
					end --if
				end --for
			end --if
			_G[GoGo_CheckBoxName]:SetScript("OnClick",
				function(self)
					GoGo_GlobalPrefMount(GoGo_MountID)
				end --function
			)
		elseif GoGo_FrameParentText == "GoGo_ExtraPassengerMounts_ContentFrame" then
			if GoGo_Prefs.ExtraPassengerMounts then
				--GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): zone exists ")
				for GoGo_FavoriteCount = 1, table.getn(GoGo_Prefs.ExtraPassengerMounts) do
					if GoGo_Prefs.ExtraPassengerMounts[GoGo_FavoriteCount] == GoGo_MountID then
						_G[GoGo_CheckBoxName]:SetChecked(1)
--							GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): set checked ")
					end --if
				end --for
			end --if
			_G[GoGo_CheckBoxName]:SetScript("OnClick",
				function(self)
					GoGo_ExtraPassengerMounts(GoGo_MountID)
				end --function
			)
		elseif GoGo_FrameParentText == "GoGo_GlobalExclusions_ContentFrame" then
			if GoGo_Prefs.GlobalExclude then
				--GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): zone exists ")
				for GoGo_FavoriteCount = 1, table.getn(GoGo_Prefs.GlobalExclude) do
					if GoGo_Prefs.GlobalExclude[GoGo_FavoriteCount] == GoGo_MountID then
						_G[GoGo_CheckBoxName]:SetChecked(1)
--							GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): set checked ")
					end --if
				end --for
			end --if
			_G[GoGo_CheckBoxName]:SetScript("OnClick",
				function(self)
					GoGo_GlobalExcludeMount(GoGo_MountID)
				end --function
			)
		elseif GoGo_FrameParentText == "GoGo_ZoneExclusions_ContentFrame" then
			if table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]) > 0 then
				--GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): zone exists ")
				for GoGo_FavoriteCount = 1, table.getn(GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"]) do
					if GoGo_Prefs.MapIDs[GoGo_Variables.Player.MapID]["Excluded"][GoGo_FavoriteCount] == GoGo_MountID then
						_G[GoGo_CheckBoxName]:SetChecked(1)
--							GoGo_DebugAddLine("GoGo_AddOptionCheckboxes(): set checked ")
					end --if
				end --for
			end --if
			_G[GoGo_CheckBoxName]:SetScript("OnClick",
				function(self)
					GoGo_ZoneExcludeMount(GoGo_MountID)
				end --function
			)
		end --if
	end --for
end --function

---------
function GoGo_DebugCollectInformation()
---------
	GoGo_DebugAddLine("Information: GoGoMount Version " .. C_AddOns.GetAddOnMetadata("GoGoMount", "Version"))
--	GoGo_DebugAddLine("Information: GoGoMount build version:  " ..  GetAddOnMetadata("GoGoMount", "Interface"))
	GoGo_DebugAddLine("Information: World of Warcraft build version:  " .. select(4, _G.GetBuildInfo()))
	if GoGo_Variables.ExpansionAccount == 0 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft (Classic) enabled.")
	elseif GoGo_Variables.ExpansionAccount == 1 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: The Burning Crusade enabled.")
	elseif GoGo_Variables.ExpansionAccount == 2 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Wrath of the Lich King enabled.")
	elseif GoGo_Variables.ExpansionAccount == 3 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Cataclysm enabled.")
	elseif GoGo_Variables.ExpansionAccount == 4 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Mists of Pandaria enabled.")
	elseif GoGo_Variables.ExpansionAccount == 5 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Warlords of Draenor enabled.")
	elseif GoGo_Variables.ExpansionAccount == 6 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Legion enabled.")
	elseif GoGo_Variables.ExpansionAccount == 7 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Battle for Azeroth enabled.")
	elseif GoGo_Variables.ExpansionAccount == 8 then
		GoGo_DebugAddLine("Information: Account - World of Warcraft: Shadowlands enabled.")
	end --if
	if GoGo_Variables.ExpansionGame == 0 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft (Classic) enabled.")
	elseif GoGo_Variables.ExpansionGame == 1 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: The Burning Crusade enabled.")
	elseif GoGo_Variables.ExpansionGame == 2 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Wrath of the Lich King enabled.")
	elseif GoGo_Variables.ExpansionGame == 3 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Cataclysm enabled.")
	elseif GoGo_Variables.ExpansionGame == 4 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Mists of Pandaria enabled.")
	elseif GoGo_Variables.ExpansionGame == 5 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Warlords of Draenor enabled.")
	elseif GoGo_Variables.ExpansionGame == 6 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Legion enabled.")
	elseif GoGo_Variables.ExpansionGame == 7 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Battle for Azeroth enabled.")
	elseif GoGo_Variables.ExpansionGame == 8 then
		GoGo_DebugAddLine("Information: Game - World of Warcraft: Shadowlands enabled.")
	end --if
	GoGo_DebugAddLine("Information: Client locale is " .. GetLocale())
	GoGo_DebugAddLine("Information: Location = " .. GetRealZoneText() .. " - " .. GetZoneText() .. " - " ..GetSubZoneText() .. " - " .. GetMinimapZoneText())
	AreaID = C_Map.GetBestMapForUnit("player")
	if AreaID then
		GoGo_DebugAddLine("Information: Current zone area ID as per C_Map.GetBestMapForUnit('player'): " .. AreaID)
	else
		GoGo_DebugAddLine("Information: Current zone area ID as per C_Map.GetBestMapForUnit('player') returned a nil value ")
	end --if
--	GoGo_DebugAddLine("Information: Current map ID as per GetCurrentMapDungeonLevel(): " .. GetCurrentMapDungeonLevel())
--	local posX, posY = GetPlayerMapPosition("Player")
--	GoGo_DebugAddLine("Information: Player location: X = ".. posX .. ", Y = " .. posY)
	GoGo_DebugAddLine("Information: Current unit speed is " .. GetUnitSpeed("player"))
	local level = UnitLevel("player")
	GoGo_DebugAddLine("Information: We are level " .. level)
	GoGo_DebugAddLine("Information: We are a " .. GoGo_Variables.Player.Race .. " " .. GoGo_Variables.Player.Class)
	if GoGo_Variables.Player.Covenant == 0 then
		GoGo_DebugAddLine("Information: We do not have a covenant.")
	elseif GoGo_Variables.Player.Covenant == 1 then
		GoGo_DebugAddLine("Information: Our covenant is Kyrian.")
	elseif GoGo_Variables.Player.Covenant == 2 then
		GoGo_DebugAddLine("Information: Our covenant is Venthyr.")
	elseif GoGo_Variables.Player.Covenant == 3 then
		GoGo_DebugAddLine("Information: Our covenant is Night Fae.")
	elseif GoGo_Variables.Player.Covenant == 4 then
		GoGo_DebugAddLine("Information: Our covenant is Necro Lord.")
	end --if
	if IsInGuild() and GetGuildPerkInfo(2) then
		GoGo_DebugAddLine("Information: We are in a guild with the Mount Up perk")
	end --if
	if InCombatLockdown() then
		GoGo_DebugAddLine("Information: We are in combat as per InCombatLockdown()")
	else
		GoGo_DebugAddLine("Information: We are not in combat as per InCombatLockdown()")
	end --if
	if IsOutdoors() then
		GoGo_DebugAddLine("Information: We are outdoors as per IsOutdoors()")
	else
		GoGo_DebugAddLine("Information: We are not outdoors as per IsOutdoors()")
	end --if
	if IsIndoors() then
		GoGo_DebugAddLine("Information: We are indoors as per IsIndoors()")
	else
		GoGo_DebugAddLine("Information: We are not indoors as per IsIndoors()")
	end --if
	if IsInInstance() then
		GoGo_DebugAddLine("Information: We are in an instance as per IsInInstance()")
	else
		GoGo_DebugAddLine("Information: We are not in an instance as per IsInInstance()")
	end --if
	if IsFlyableArea() then
		GoGo_DebugAddLine("Information: We can fly here as per IsFlyableArea()")
	else
		GoGo_DebugAddLine("Information: We can not fly here as per IsFlyableArea()")
	end --if
	if IsFlying() then
		GoGo_DebugAddLine("Information: We are flying as per IsFlying()")
	else
		GoGo_DebugAddLine("Information: We are not flying as per IsFlying()")
	end --if
	if IsSwimming() then
		GoGo_DebugAddLine("Information: We are swimming as per IsSwimming()")
	else
		GoGo_DebugAddLine("Information: We are not swimming as per IsSwimming()")
	end --if
	if IsSubmerged() then
		GoGo_DebugAddLine("Information: We are submerged as per IsSubmerged()")
	else
		GoGo_DebugAddLine("Information: We are not submerged as per IsSubmerged()")
	end --if
	if IsFalling() then
		GoGo_DebugAddLine("Information: We are falling as per IsFalling()")
	else
		GoGo_DebugAddLine("Information: We are not falling as per IsFalling()")
	end --if
	if GoGo_IsMoving() then
		GoGo_DebugAddLine("Information: We are moving as per GoGo_IsMoving()")
	else
		GoGo_DebugAddLine("Information: We are not moving as per GoGo_IsMoving()")
	end --if
	if IsPlayerMoving() then
		GoGo_DebugAddLine("Information: We are moving as per IsPlayerMoving()")
	else
		GoGo_DebugAddLine("Information: We are not moving as per IsPlayerMoving()")
	end --if
	
--[[	-- Temporarily disabling this for now to get GoGoMount working again with 8.0
	local buffs, i = { }, 1
	local buff = UnitBuff("player", i)
	while buff do
		buffs[#buffs + 1] = buff
		i = i + 1
		buff = UnitBuff("player", i)
	end --while
	if #buffs < 1 then
		buffs = "We are not buffed"
	else
		buffs[1] = "We are buffed with: "..buffs[1]
		buffs = table.concat(buffs, ", ")
	end --if
	GoGo_DebugAddLine("Information: " .. buffs)
]]
	GoGo_DebugAddLine("Information: End of information.")	
end --function

function GoGo_StartStopDebug(level)

	if level then
		GoGo_Variables.Debug = level
	else
		GoGo_Variables.Debug = 10
	end --if
	
	if GoGo_Variables.Debug >= 6 then
		GoGoFrame:RegisterEvent("UNIT_TARGET")
	else
		GoGoFrame:UnregisterEvent("UNIT_TARGET")
	end --if
end --function
