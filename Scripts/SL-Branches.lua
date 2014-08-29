if not Branch then Branch = {}; end

function SelectMusicOrCourse()
	local pm = GAMESTATE:GetPlayMode()
	if pm == "PlayMode_Nonstop"	then
		return "ScreenSelectCourseNonstop"
	else
		return "ScreenSelectMusic"
	end
end


Branch.AfterGameplay = function()
	local pm = GAMESTATE:GetPlayMode()
	if( pm == "PlayMode_Regular" )	then return "ScreenEvaluationStage" end
	if( pm == "PlayMode_Nonstop" )	then return "ScreenEvaluationNonstop" end
end

-- Let's pretend I understand why this is necessary
Branch.AfterScreenSelectPlayMode = function()
	local gameName = GAMESTATE:GetCurrentGame():GetName()
	if gameName=="techno" then
		return "ScreenSelectStyleTechno"
	else
		return "ScreenSelectStyle"
	end
end

Branch.PlayerOptions = function()
	if SCREENMAN:GetTopScreen():GetGoToOptions() then
		return "ScreenPlayerOptions"
	else
		return "ScreenGameplay"
	end
end

Branch.SSMCancel = function()

	if GAMESTATE:GetCurrentStageIndex() > 0 then
		return "ScreenEvaluationSummary"
	end

	return Branch.TitleMenu()
end

Branch.AfterProfileSave = function()
	
	if GAMESTATE:IsEventMode() then
		return SelectMusicOrCourse()
		
	elseif GAMESTATE:IsCourseMode() then
		return "ScreenNameEntryTraditional"
		
	else
		
		-- take rate mods into consideration when calculating stage "cost"
		local song = GAMESTATE:GetCurrentSong()	
		local Duration = song:GetLastSecond()
		local DurationWithRate = Duration / SL.Global.ActiveModifiers.MusicRate
		
		local LongCutoff = PREFSMAN:GetPreference("LongVerSongSeconds")
		local MarathonCutoff = PREFSMAN:GetPreference("MarathonVerSongSeconds")

		local IsMarathonWithRate = DurationWithRate/MarathonCutoff > 1 and true or false		
		local IsLongWithRate = DurationWithRate/LongCutoff > 1 and true or false
		
		if song:IsMarathon() then			
			SL.Global.Stages.Remaining = SL.Global.Stages.Remaining - 3
		elseif song:IsLong() then
			SL.Global.Stages.Remaining = SL.Global.Stages.Remaining - 2
		else
			SL.Global.Stages.Remaining = SL.Global.Stages.Remaining - 1
		end
		
		if SL.Global.ActiveModifiers.MusicRate ~= 1 then
			
			local StagesToAdd = 0
			
			if song:IsMarathon() and not IsLongWithRate and not IsMarathonWithRate then	
				StagesToAdd = 2
			elseif song:IsMarathon() and IsLongWithRate and not IsMarathonWithRate then			
				StagesToAdd = 1
			elseif song:IsLong() and not IsLongWithRate and not IsMarathonWithRate then				
				StagesToAdd = 1
			end
			
			local Players = GAMESTATE:GetHumanPlayers()	
			for pn in ivalues(Players) do
				for i=1, StagesToAdd do
					GAMESTATE:AddStageToPlayer( pn )
				end
			end
			
			SL.Global.Stages.Remaining = SL.Global.Stages.Remaining + StagesToAdd
		end
		

		-- If we don't allow players to fail out of a set early
		if ThemePrefs.Get("AllowFailingOutOfSet") == "No" then
			
			-- check first to see how many songs are remaining
			-- if none, send the player(s) on to ScreenEvalutationSummary
			if SL.Global.Stages.Remaining == 0 then

				return "ScreenEvaluationSummary"
			
			-- otherwise, there are some stages remaining
			else
				
				-- However, if the player(s) just failed, then SM thinks there are no stages remaining
				-- so IF the player(s) did fail, reinstate the appropriate number of stages.
				-- If we don't do this, and simply send the player(s) back to ScreenSelectMusic,
				-- the MusicWheel will be empty! (I guess because SM thinks there are no stages remaining...?) 
				if STATSMAN:GetCurStageStats():AllFailed() then
					local Players = GAMESTATE:GetHumanPlayers()	
					for pn in ivalues(Players) do
						for i=1, SL.Global.Stages.Remaining do
							GAMESTATE:AddStageToPlayer(pn)
						end
					end
				end
				
				
				return SelectMusicOrCourse()
			end
			
		else
		
			if STATSMAN:GetCurStageStats():AllFailed() or GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() == 0 then
				SL.Global.Stages.Remaining = PREFSMAN:GetPreference("SongsPerPlay")		
				return "ScreenEvaluationSummary"
			else
				return SelectMusicOrCourse()
			end
			
		end
	end
			
	-- just in case?
	return SelectMusicOrCourse()
end