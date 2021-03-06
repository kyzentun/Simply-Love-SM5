local Players = GAMESTATE:GetHumanPlayers()

-- SpeedModItems is a table that will contain the BitMapText Actors
-- for the SpeedModNew OptionRow for both P1 and P2
local SpeedModItems = {P1, P2}

local t = Def.ActorFrame{
	InitCommand=cmd(xy,_screen.cx,0);
	OnCommand=cmd(diffusealpha,0; linear,0.2;diffusealpha,1; queuecommand,"Capture");
	OffCommand=cmd(linear,0.2;diffusealpha,0);
	CaptureCommand=function(self)
		
		local ScreenOptions = SCREENMAN:GetTopScreen()
		
		-- reset for ScreenEditOptions
		SpeedModItems = {P1 = nil, P2 = nil}
		
		-- The bitmaptext actors for P1 and P2 speedmod are both named "Item"
		SpeedModItems.P1 = ScreenOptions:GetOptionRow(1):GetChild(""):GetChild("Item")[1]
		SpeedModItems.P2 = ScreenOptions:GetOptionRow(1):GetChild(""):GetChild("Item")[2]
			
		if SpeedModItems.P1 and GAMESTATE:IsPlayerEnabled(PLAYER_1) then
			self:playcommand("SetP1")
		end
		if SpeedModItems.P2 and GAMESTATE:IsPlayerEnabled(PLAYER_2) then
			self:playcommand("SetP2")
		end
	end
}

t[#t+1] = LoadActor(THEME:GetPathB("ScreenPlayerOptions", "common"))

for player in ivalues(Players) do
	local pn = ToEnumShortString(player)

	t[#t+1] = Def.ActorFrame{

		-- Commands for player speedmod
		["SpeedModType" .. pn .. "SetMessageCommand"]=function(self,params)
					
			local oldtype = SL[pn].ActiveModifiers.SpeedModType
			local newtype = params.SpeedModType
			local song = GAMESTATE:GetCurrentSong()
			
			if oldtype ~= newtype then
				local bpm
				local oldspeed = SL[pn].ActiveModifiers.SpeedMod
				
				if GAMESTATE:IsCourseMode() then
					bpm = GetCourseModeBPMs()
				else
					bpm = song:GetDisplayBpms()
					if bpm[1] <= 0 or bpm[2] <= 0 then
						bpm = song:GetTimingData():GetActualBPM()
					end
				end
				
				if oldtype == "x" and (newtype == "C" or newtype == "M") then
					-- convert to the nearest MMod/CMod-appropriate integer by rounding to nearest 10
					SL[pn].ActiveModifiers.SpeedMod = (round((oldspeed * bpm[2]) / 10)) * 10	
				
				elseif newtype == "x" then
					-- convert to the nearest XMod-appropriate integer by rounding to 2 decimal places
					-- and then rounding that to the nearest 0.05 increment
					SL[pn].ActiveModifiers.SpeedMod = (round(round(oldspeed / bpm[2], 2) / 0.05)) * 0.05
				end
		
				SL[pn].ActiveModifiers.SpeedModType = newtype
		
				ApplySpeedMod(player)
				self:queuecommand("Set" .. pn)
				self:GetParent():GetChild(pn.."MusicRateHelper"):playcommand("Set")
			end
		end,
		
		["Set" .. pn .. "Command"]=function(self)
			local text = ""
			
			if  SL[pn].ActiveModifiers.SpeedModType == "x" then
				text = string.format("%.2f" , SL[pn].ActiveModifiers.SpeedMod ) .. "x"
			elseif  SL[pn].ActiveModifiers.SpeedModType == "C" then
				text = "C" .. tostring(SL[pn].ActiveModifiers.SpeedMod)
			elseif  SL[pn].ActiveModifiers.SpeedModType == "M" then
				text = "M" .. tostring(SL[pn].ActiveModifiers.SpeedMod)
			end
			
			SpeedModItems[pn]:settext( text )
			self:GetParent():GetChild(pn .. "SpeedModHelper"):settext( DisplaySpeedMod(pn) )
		end,
		
		["MenuLeft" .. pn .. "MessageCommand"]=function(self)
			if SCREENMAN:GetTopScreen():GetCurrentRowIndex(player) == 1 then
				ChangeSpeedMod( pn, -1 )
				self:queuecommand("Set"..pn)
			end	
		end,
		["MenuRight" .. pn .. "MessageCommand"]=function(self)
			if SCREENMAN:GetTopScreen():GetCurrentRowIndex(player) == 1 then
				ChangeSpeedMod( pn, 1 )
				self:queuecommand("Set"..pn)
			end
		end
	}
	
	-- the display that does math for you up at the top
	t[#t+1] = LoadFont("_wendy small")..{
		Name=pn.."SpeedModHelper",
		Text="",
		InitCommand=function(self)
			self:diffuse(PlayerColor(player))
			self:zoom(0.5)
			if player == PLAYER_1 then
				self:x(-100)
			elseif player == PLAYER_2 then
				self:x(150)
			end
			self:y(48)
			self:diffusealpha(0)
		end,
		OnCommand=cmd(linear,0.4;diffusealpha,1)
	}
	
	t[#t+1] = LoadFont("_misoreg hires")..{
		Name=pn.."MusicRateHelper",
		Text="",
		InitCommand=function(self)
			self:shadowlength(0.4)
			self:diffuse(PlayerColor(player))
			self:zoom(0.9)
			
			if IsUsingWideScreen() then		
				if player == PLAYER_1 then
					self:x(-100)
				elseif player == PLAYER_2 then
					self:x(150)
				end
				self:y(26)
			else
				if player == PLAYER_1 then
					self:x(-10)
				elseif player == PLAYER_2 then
					self:x(240)
				end
				self:y(50)
			end
			self:diffusealpha(0)
		end,
		OnCommand=cmd(linear,0.4;diffusealpha,1),
		SetCommand=function(self)
			local musicrate = SL.Global.ActiveModifiers.MusicRate
			
			-- settext on the musicrate helper
			if SL[pn].ActiveModifiers.SpeedModType == "x" then
				if musicrate == 1 then
					self:settext("")
				else
					self:settext(musicrate .. "x")
				end
			else
				self:settext("")
			end
			
			-- settext on the speedmod helper
			self:GetParent():GetChild(pn .. "SpeedModHelper"):settext( DisplaySpeedMod(pn) )
			
			-------------------------------
			-- variables to be used for setting the text in the "Speed Mod" OptionRow title
			local ScreenOptions = SCREENMAN:GetTopScreen()
			local SpeedModTitle = ScreenOptions:GetOptionRow(1):GetChild(""):GetChild("Title")
			local song = GAMESTATE:GetCurrentSong()
			
			-- get the song's native display BPM(s)
			local bpms = song:GetDisplayBpms()
			
			-- if either display BPM is negative or 0, use the actual BPMs instead...
			if bpms[1] <= 0 or bpms[2] <= 0 then
				bpms = song:GetTimingData():GetActualBPM()
			end
			
			-- truncate possible decimal places
			bpms[1] = ("%0.0f"):format(bpms[1])
			bpms[2] = ("%0.0f"):format(bpms[2])
			
			-- settext on "Speed Mod" OptionRow title
			if bpms[1] == bpms[2] then
				SpeedModTitle:settext( THEME:GetString("OptionTitles", "SpeedModNew") .. " (" .. bpms[1] * musicrate .. ")" )
			else
				SpeedModTitle:settext( THEME:GetString("OptionTitles", "SpeedModNew") .. " (" .. bpms[1] * musicrate ..  " - " .. bpms[2] * musicrate  .. ")" )
			end
		end,
		MusicRateChangedMessageCommand=cmd(playcommand,"Set")
	}
end

return t