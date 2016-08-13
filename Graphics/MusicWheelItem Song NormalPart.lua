return Def.ActorFrame{
	InitCommand=cmd(x, 26),

	Def.Quad{
		InitCommand=function(self) self:diffuse(color("#000a11")):zoomto(_screen.w/2.1675, _screen.h/15):diffusealpha(0.5) end
	},
	Def.Quad{
		InitCommand=function(self)
			self:diffuse( SL_Config:get_data().RainbowMode and Color.White or color("#0a141b"))
				:diffusealpha( SL_Config:get_data().RainbowMode and 0.5 or 1 )
				:zoomto(_screen.w/2.1675, _screen.h/15 - 1)
		 end
	}
}
