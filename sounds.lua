
Sounds = {
	BackMusic = nil;
	TicSound = nil;
	SnapSound = nil;
	SelSound = nil;
	DeSelSound = nil;
	DeathSound = nil;
	WinSound = nil;
}

function Sounds:init()
	
	-- load sounds and music
	self.TicSound = love.audio.newSource("assets/sounds/tic.wav", "static")
	self.SelSound = love.audio.newSource("assets/sounds/select.wav", "static")
	self.DeSelSound = love.audio.newSource("assets/sounds/deselect.wav", "static")
	self.BellSound = love.audio.newSource("assets/sounds/bell.ogg", "static")
	self.SnapSound = love.audio.newSource("assets/sounds/snap.ogg", "static"); self.SnapSound:setVolume(3)
	self.DeathSound = love.audio.newSource("assets/sounds/death.ogg", "static"); 
	self.WinSound = love.audio.newSource("assets/sounds/win.ogg", "static"); self.WinSound:setVolume(1.6)
	self.BackMusic = love.audio.newSource("assets/sounds/background_music.ogg", "stream")
	
	-- set background music
	self.BackMusic:setVolume(0.4)
	self.BackMusic:play()
	self.BackMusic:setLooping(true)
	
end
