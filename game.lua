
-- delayed autoshift initial delay and time between shifts
local DAS_INIT_TIME = 12
local DAS_MOVE_TIME = 3

-- phasing out background music
local MUSIC_PHASE_OUT = false
local PHASE_OUT_DURATION = 2
local PHASE_OUT_TIMER = 0

-- libretro joypad buttons const
RETRO_DEVICE_ID_JOYPAD_B        = 1
RETRO_DEVICE_ID_JOYPAD_Y        = 2
RETRO_DEVICE_ID_JOYPAD_SELECT   = 3
RETRO_DEVICE_ID_JOYPAD_START    = 4
RETRO_DEVICE_ID_JOYPAD_UP       = 5
RETRO_DEVICE_ID_JOYPAD_DOWN     = 6
RETRO_DEVICE_ID_JOYPAD_LEFT     = 7
RETRO_DEVICE_ID_JOYPAD_RIGHT    = 8
RETRO_DEVICE_ID_JOYPAD_A        = 9
RETRO_DEVICE_ID_JOYPAD_X        = 10
RETRO_DEVICE_ID_JOYPAD_L        = 11
RETRO_DEVICE_ID_JOYPAD_R        = 12
RETRO_DEVICE_ID_JOYPAD_L2       = 13
RETRO_DEVICE_ID_JOYPAD_R2       = 14
RETRO_DEVICE_ID_JOYPAD_L3       = 15
RETRO_DEVICE_ID_JOYPAD_R3       = 16


Game = {
	NumPlayers = nil;
	NumLivePlayers = nil;
	Gridsize = nil;
	SqSize = nil;
	A1_coord = nil;
	HighSq = nil;
	SelSq = nil;
	TimeoutTimer = nil;
	Newgame = nil;
	NewgameHigh = nil;
	Paused = nil;
	PauseHighSq = nil;
	GameOver = nil;
	MoveLog = nil;
	HumanPlayers = {nil,nil,nil,nil};
	TimeControl = nil;
	Timers = {nil,nil,nil,nil};
}


function Game:init()
	
	-- set 2-player or 4-player mode
	self.NumPlayers = 2
	
	-- set number of alive players
	self.NumLivePlayers = self.NumPlayers
	
	-- set gridsize
	self.Gridsize = 9
	
	-- set size of square in pixels
	if self.Gridsize == 7 then self.SqSize = 30 end
	if self.Gridsize == 9 then self.SqSize = 24 end
	if self.Gridsize == 11 then self.SqSize = 20 end
	
	-- set coordinates of A1
	if self.Gridsize == 7 then self.A1_coord = {14,194} end
	if self.Gridsize == 9 then self.A1_coord = {11,203} end
	if self.Gridsize == 11 then self.A1_coord = {9,209} end

	-- set which players are human (not AI)
	self.HumanPlayers = {true, false, false, false}
	
	-- set time control (default off)
	self.TimeControl = 0
	
	-- set timers (in seconds)
	for p = 1,4 do self.Timers[p] = (2*self.TimeControl-1)*60 end
	
	-- set highlighted square (default center)
	self.HighSq = {(self.Gridsize+1)/2,(self.Gridsize+1)/2}
	
	-- set timeout timer to -100
	self.TimeoutTimer = -100
	
	-- set newgame to true 
	self.Newgame = true
	
	-- set newgame highlighter to "START GAME"
	self.NewgameHigh = {5,1}
	
	-- set paused to false
	self.Paused = false
	
	-- set game-over variable to false
	self.GameOver = false
	
	-- initialize the move log
	self.MoveLog = {}
	
	-- random number seed
	math.randomseed(os.time())
	
end

-- reinit when updating options
function Game:reinit()

	-- set number of alive players
	self.NumLivePlayers = self.NumPlayers
	
	-- set size of square in pixels
	if self.Gridsize == 7 then self.SqSize = 30 end
	if self.Gridsize == 9 then self.SqSize = 24 end
	if self.Gridsize == 11 then self.SqSize = 20 end
	
	-- set coordinates of A1
	if self.Gridsize == 7 then self.A1_coord = {14,194} end
	if self.Gridsize == 9 then self.A1_coord = {11,203} end
	if self.Gridsize == 11 then self.A1_coord = {9,209} end
	
	-- set timers (in seconds)
	for p = 1,4 do self.Timers[p] = (2*self.TimeControl-1)*60 end
	
	-- set highlighted square (default center)
	self.HighSq = {(self.Gridsize+1)/2,(self.Gridsize+1)/2}
	
	-- set game-over variable to false
	self.GameOver = false
	
end

local DPAD = {false,false,false,false}	-- U,D,L,R
local ASDelay = {-1,-1,-1,-1}	-- autoshift delay for up, down, left, right
local A  = false		-- A button
local B  = false		-- B button
local startB = false	-- start button
function Game:update(dt)
	
	-- get the inputs
	local CUR_DPAD = {love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_UP),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_DOWN),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_LEFT),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_RIGHT)}
    local CUR_A = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_A) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_B)
    local CUR_B = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_X) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_Y)
    local CUR_startB = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_START)
	
	-- handle potential phasing out of music
	Game:phase_out_music(dt)
	
	-- start press
	if CUR_startB and not startB then	-- press-down
		startB = true
		self.Paused = not self.Paused
		self.PauseHighSq = 1
	end
	if not CUR_startB and startB then	-- press-up
		startB = false
	end
	
	-- check if its timeout
	if Game.TimeoutTimer > 0 then
		Game.TimeoutTimer = Game.TimeoutTimer-dt
		return
	end
	
	-- check if the game is over
	if self.GameOver then return end
	
	-- update time
	if self.TimeControl ~= 0 then
		if self.HumanPlayers[Board.Turn] then
			self.Timers[Board.Turn] = self.Timers[Board.Turn]-dt
			if self.Timers[Board.Turn] <= 0 then
				Sounds.BellSound:play()
				self.Timers[Board.Turn] = 0
				-- kill player
				Sounds.DeathSound:play()
				Board.PlayerAlive[Board.Turn] = 0 
				local pos = Board.PlayerPos[Board.Turn]
				Board.Squares[pos[1]][pos[2]] = -1
				Board.MarkedSqs[Board.Turn] = pos	
				Board:change_turn()
				-- check if its game over
				if sum(Board.PlayerAlive) == 1 then Game:end_game() end
			end
		end
	end
	
	-- check if its the AI's turn
	if self.HumanPlayers[Board.Turn] == false then
		if self.TimeoutTimer == -100 then
			self.TimeoutTimer = 1							-- timeout 1 second so AI doesnt move too fast
		else
			self.TimeoutTimer = -100						-- reset timeout
			local move = Player:recommend_move()			-- get move from AI
			Game:move_proposal(move[1], move[2])
		end
	end
	
	-- DPAD press-down/press-up events
	for d=1,4 do
		if CUR_DPAD[d] and not DPAD[d] then -- press-down
			Game:moveHighlighter(d)
			DPAD[d] = true
			ASDelay[d] = DAS_INIT_TIME
		end
		if not CUR_DPAD[d] and DPAD[d] then -- press-up
			DPAD[d] = false
			ASDelay[d] = -1
		end
	end
	
	-- delayed autoshift
	for d=1,4 do
		if DPAD[d] then
			if ASDelay[d] == 0 then
				Game:moveHighlighter(d)
				ASDelay[d] = DAS_MOVE_TIME
			else
				ASDelay[d] = ASDelay[d]-1
			end
		end
	end
	
	-- A button
	if CUR_A and not A then		-- press down
		A = true
		if square_compare(self.HighSq, self.SelSq) then		-- if you press A on the selected square you deselect it
			self.SelSq = nil
			Sounds.DeSelSound:play()
		else
			if self.SelSq then									-- if a move is proposed
				Game:move_proposal(self.SelSq, self.HighSq)
			else												-- if no square is selected
				Game:select_proposal(self.HighSq)
			end
		end
	end
	if not CUR_A and A then		-- press up
		A = false
	end
	
	-- B button
	if CUR_B and not B then		-- press down
		B = true
		if self.SelSq then
			self.SelSq = nil
			Sounds.DeSelSound:play()
		end
	end
	if not CUR_B and B then		-- press up
		B = false
	end
	
end

-- newgame update
function Game:newgame_update()

	-- get the inputs
	local CUR_DPAD = {love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_UP),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_DOWN),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_LEFT),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_RIGHT)}
    local CUR_A = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_A) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_B)
    local CUR_B = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_X) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_Y)
    local CUR_startB = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_START)
    
    -- start press starts the game
	if CUR_startB and not startB then	-- press-down
		startB = true
		self.Newgame = false
		Sounds.BellSound:play()
	end
	if not CUR_startB and startB then	-- press-up
		startB = false
	end
	
	-- DPAD controlls highlighter
	for d=1,4 do
		if CUR_DPAD[d] and not DPAD[d] then -- press-down
			Game:moveNewgameHighlighter(d)
			DPAD[d] = true
			ASDelay[d] = DAS_INIT_TIME
		end
		if not CUR_DPAD[d] and DPAD[d] then -- press-up
			DPAD[d] = false
			ASDelay[d] = -1
		end
	end
	-- delayed autoshift
	for d=1,4 do
		if DPAD[d] then
			if ASDelay[d] == 0 then
				Game:moveNewgameHighlighter(d)
				ASDelay[d] = DAS_MOVE_TIME
			else
				ASDelay[d] = ASDelay[d]-1
			end
		end
	end
	
	-- A button
	if CUR_A and not A then		-- press down
		A = true
		Game:newgameA()
	end
	if not CUR_A and A then		-- press up
		A = false
	end
	
end

-- handle A press in the newgame menu
function Game:newgameA()
	if self.NewgameHigh[1] == 5 then		-- start game
		self.Newgame = false
		Sounds.BellSound:play()
	end
	if self.NewgameHigh[1] == 4 then		-- gridsize
		if self.Gridsize ~= 5+2*self.NewgameHigh[2] then Sounds.SelSound:play() end
		self.Gridsize = 5+2*self.NewgameHigh[2]
	end
	if self.NewgameHigh[1] == 3 then		-- number of players
		if self.NumPlayers ~= 2*self.NewgameHigh[2] then Sounds.SelSound:play() end
		self.NumPlayers = 2*self.NewgameHigh[2]
	end
	if self.NewgameHigh[1] == 2 then		-- human players
		if self.NumPlayers ~= 2 or self.NewgameHigh[2]%2 ~= 0 then Sounds.SelSound:play() end
		self.HumanPlayers[self.NewgameHigh[2]] = not self.HumanPlayers[self.NewgameHigh[2]]
	end
	if self.NewgameHigh[1] == 1 then		-- time control
		if self.TimeControl ~= self.NewgameHigh[2]-1 then Sounds.SelSound:play() end
		self.TimeControl = self.NewgameHigh[2]-1
	end
	if self.NumPlayers == 2 then self.HumanPlayers[2] = false; self.HumanPlayers[4] = false end		-- if 2 player mode then set P2 and P4 human to false 
	Game:reinit()
	Board:init()
	Textures:init()
end

-- move newgame highlighter
function Game:moveNewgameHighlighter(dir)
	if dir == 1 and self.NewgameHigh[1] < 5 then
		self.NewgameHigh[1] = self.NewgameHigh[1]+1 -- up
		self.NewgameHigh[2] = 1
		Sounds.TicSound:play()
	elseif dir == 2 and self.NewgameHigh[1] > 1 then
		self.NewgameHigh[1] = self.NewgameHigh[1]-1 -- down 
		self.NewgameHigh[2] = 1
		Sounds.TicSound:play()
	elseif dir == 3 and self.NewgameHigh[2] > 1 then
		self.NewgameHigh[2] = self.NewgameHigh[2]-1 -- left
		Sounds.TicSound:play()
	elseif dir == 4 and self.NewgameHigh[2] < ({4,4,2,3,1})[self.NewgameHigh[1]] then
		self.NewgameHigh[2] = self.NewgameHigh[2]+1 -- right
		Sounds.TicSound:play()
	end
end

-- pause update
function Game:pause_update()
	
	-- get the inputs
	local CUR_DPAD = {love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_UP),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_DOWN),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_LEFT),love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_RIGHT)}
    local CUR_A = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_A) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_B)
    local CUR_B = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_X) or love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_Y)
    local CUR_startB = love.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_START)
    
	-- start press unpauses
	if CUR_startB and not startB then	-- press-down
		startB = true
		self.Paused = not self.Paused
	end
	if not CUR_startB and startB then	-- press-up
		startB = false
	end
	
	-- DPAD
	for d=1,4 do
		if CUR_DPAD[d] and not DPAD[d] then -- press-down
			DPAD[d] = true
			if d < 3 then
				self.PauseHighSq = d
				Sounds.TicSound:play()
			end
		end
		if not CUR_DPAD[d] and DPAD[d] then -- press-up
			DPAD[d] = false
		end
	end
	
	-- A press
	if CUR_A then
		A = true
		if self.PauseHighSq == 1 then self.Paused = not self.Paused end
		if self.PauseHighSq == 2 then self.Paused = false; Game:reinit(); Board:init(); Sounds.BackMusic:stop(); Sounds:init(); self.Newgame = true end
	end
	
end

-- handle the game ending
function Game:end_game()
	self.GameOver = true
	MUSIC_PHASE_OUT = true
	PHASE_OUT_TIMER = PHASE_OUT_DURATION
	Sounds.WinSound:play()
	-- adjust turn back to the winner (if center was reached)
	local center_val = Board:square_value({(Game.Gridsize+1)/2,(Game.Gridsize+1)/2})
	if center_val >= 1 and center_val <= 4 then Board.Turn = center_val end
end

-- handle phasing out background music
function Game:phase_out_music(dt)
	if MUSIC_PHASE_OUT then
		PHASE_OUT_TIMER = PHASE_OUT_TIMER-dt
		if PHASE_OUT_TIMER <= 0 then
			Sounds.BackMusic:stop()
			MUSIC_PHASE_OUT = false
		else Sounds.BackMusic:setVolume(PHASE_OUT_TIMER/PHASE_OUT_DURATION) end
	end
end

-- handle a proposed square selection
function Game:select_proposal(sq)
	if Board:empty_square(sq) then																-- if the square is empty
		return
	elseif Board:square_value(sq) == -1 then													-- if the square hosts a dead player
		return
	elseif Board:player_present(sq) and Board.Squares[sq[1]][sq[2]] ~= Board.Turn then			-- if a player tries to select another players piece
		return
	elseif Board:minor_piece_present(sq) then
		if Board:marked_square(sq) and not square_compare(sq,Board.MarkedSqs[Board.Turn]) then	-- if a player tries to select another player's marked piece
			return
		end
	end
	self.SelSq = square_copy(sq)
	Sounds.SelSound:play()
end

-- handle a proposed move
function Game:move_proposal(sq1, sq2)
	if Board:move_legality(sq1, sq2) then									-- if move is legal, make it
		if self.HumanPlayers[Board.Turn] then 
			self.Timers[Board.Turn] = self.Timers[Board.Turn]+self.TimeControl	-- time increment
		end
		Board:make_move(sq1, sq2)												-- make move
		self.MoveLog[#self.MoveLog+1] = {square_copy(sq1), square_copy(sq2)}	-- record move in log
		Sounds.SnapSound:play()													-- play sound
		self.SelSq = nil														-- unselect square
		if self.NumLivePlayers ~= sum(Board.PlayerAlive) then					-- check if anyone died
			Sounds.DeathSound:play()												-- play death sound
			self.NumLivePlayers = sum(Board.PlayerAlive)
		end
		if Board:win_check() then Game:end_game() end							-- check if the player won
	else
		Game:select_proposal(sq2)											-- if move is not legal then try to select the end square
	end
end

-- move highlighted square
function Game:moveHighlighter(dir)
	if dir == 1 and self.HighSq[2] < self.Gridsize then
		self.HighSq[2] = self.HighSq[2]+1 -- up
		Sounds.TicSound:play()
	elseif dir == 2 and self.HighSq[2] > 1 then
		self.HighSq[2] = self.HighSq[2]-1 -- down 
		Sounds.TicSound:play()
	elseif dir == 3 and self.HighSq[1] > 1 then
		self.HighSq[1] = self.HighSq[1]-1 -- left
		Sounds.TicSound:play()
	elseif dir == 4 and self.HighSq[1] < self.Gridsize then
		self.HighSq[1] = self.HighSq[1]+1 -- right
		Sounds.TicSound:play()
	end
end

-- renders player turn and time
function Game:renderPlayerTurn(posx, posy)
	for p = 1,self.NumPlayers do
		love.graphics.draw(Textures.SmallPlayer[1+(p-1)*4/self.NumPlayers], posx, posy+30*(p-1))
		if Board.PlayerAlive[1+(p-1)*4/self.NumPlayers] == 0 then love.graphics.draw(Textures.SmallPlayerDead, posx, posy+30*(p-1)) end
		if self.HumanPlayers[1+(p-1)*4/self.NumPlayers] then
			if self.TimeControl == 0 then
				love.graphics.print("Human", posx+28, posy+9+30*(p-1))
			else
				local t = self.Timers[1+(p-1)*4/self.NumPlayers]
				local minutes = math.floor(t/60)
				local seconds = math.floor(t-60*math.floor(t/60))
				love.graphics.print(minutes, posx+31, posy+9+30*(p-1))
				love.graphics.print(":", posx+37, posy+9+30*(p-1))
				if seconds < 10 then
					love.graphics.print("0"..seconds, posx+42, posy+9+30*(p-1))
				else
					love.graphics.print(seconds, posx+42, posy+9+30*(p-1))
				end
			end
		else
			love.graphics.print(" CPU", posx+27, posy+9+30*(p-1))
		end
	end
	love.graphics.draw(Textures.Turn, posx-3, posy-3+30*(Board.Turn-1)*self.NumPlayers/4)
end

-- renders the winner at the end of the game
function Game:renderWinner(posx, posy)
	love.graphics.print("WINNER:", posx, posy)
	local center_val = Board:square_value({(Game.Gridsize+1)/2,(Game.Gridsize+1)/2})
	if center_val >= 1 and center_val <= 4 then									-- if the center was reached
		love.graphics.draw(Textures.SmallPlayer[center_val], posx+37, posy-8)
	else																		-- last one standing
		love.graphics.draw(Textures.SmallPlayer[Board.Turn], posx+37, posy-8)
	end
end

-- coordinates of A1 square in pixels on screen
function Game:sq_coordinates(sq)
	return self.A1_coord[1]+(sq[1]-1)*self.SqSize, self.A1_coord[2]-(sq[2]-1)*self.SqSize
end

-- renders the newgame menu
function Game:renderNewgameMenu()
	love.graphics.draw(Textures.NewgameBackground, 0, 0)
	-- categories
	love.graphics.print("GridSize", 257, 86)
	love.graphics.print("No. Players", 248, 86+35)
	love.graphics.print("Human Players", 242, 86+2*35)
	love.graphics.print("Timer", 266, 86+3*35)
	-- button labels
	love.graphics.print("7", 252, 103)
	love.graphics.print("9", 252+25, 103)
	love.graphics.print("1", 252+2*26-4, 103)
	love.graphics.print("1", 252+2*26+1, 103)
	love.graphics.print("2", 263, 103+35)
	love.graphics.print("4", 263+27, 103+35)
	for p = 1,4 do love.graphics.draw(Textures.SmallPlayer[p], 238+(p-1)*20, 104+2*30) end
	if self.NumPlayers == 2 then for p = 2,4,2 do love.graphics.draw(Textures.SmallPlayerDead, 238+(p-1)*20, 104+2*30) end end
	love.graphics.print("OFF", 241, 103+3*35)
	love.graphics.print("1/1", 241+20, 103+3*35)
	love.graphics.print("3/2", 241+2*20, 103+3*35)
	love.graphics.print("5/3", 241+3*20, 103+3*35)
	-- selected parameters
	love.graphics.draw(Textures.NewgameMarker, 243+(self.Gridsize-7)/2*25, 94)
	love.graphics.draw(Textures.NewgameMarker, 254+(self.NumPlayers-2)/2*27, 94+35)
	for p = 1,4 do
		if self.HumanPlayers[p] then love.graphics.draw(Textures.NewgameMarker, 238+(p-1)*20, 104+2*30) end
	end
	love.graphics.draw(Textures.NewgameMarker, 258+(self.TimeControl-1)*20, 103+3*32)
	-- highlighter
	local offset = 0; local offset_mul = 0;
	if self.NewgameHigh[1] == 3 then offset = 16; offset_mul = 7 end
	if self.NewgameHigh[1] == 4 then offset = 5; offset_mul = 5 end
	if self.NewgameHigh[1] ~= 5 then
		love.graphics.draw(Textures.NewgameHighlighter, 238+(self.NewgameHigh[2]-1)*(20+offset_mul)+offset, 234-self.NewgameHigh[1]*35)
	else
		love.graphics.draw(Textures.NewgameStartGame, 244, 5)
	end
end

-- renders the whole game
function Game:renderGame()

	-- draw background
	love.graphics.draw(Textures.Background, 0, 0)
	
	-- draw grid
	love.graphics.draw(Textures.Grid, 0, 0)

	-- draw highlighed squares
	if self.SelSq then
		love.graphics.draw(Textures.Selected, Game:sq_coordinates(self.SelSq))
		for i=-1,1 do
			for j = -1,1 do
				if Board:move_legality(self.SelSq, {self.SelSq[1]+i, self.SelSq[2]+j}) then
					love.graphics.draw(Textures.MoveOption, Game:sq_coordinates({self.SelSq[1]+i,self.SelSq[2]+j}))
				end
			end
		end
	end
	love.graphics.draw(Textures.Highlighter, Game:sq_coordinates(self.HighSq))
	
	-- draw pieces
	Board:draw_pieces()
	Board:draw_attacked()
	
	-- draw marked squares
	for i=1,4 do
		if Board.MarkedSqs[i] then
			if Board:square_value(Board.MarkedSqs[i]) ~= -1 then	-- do not plot the mark on dead players
				love.graphics.draw(Textures.MarkedSqs[i], Game:sq_coordinates(Board.MarkedSqs[i]))
			end
		end
	end
	
	-- draw hud
	if self.GameOver then Game:renderWinner(250, 40) end
	Game:renderPlayerTurn(253, 75)
	
	-- if newgame over-draw newgame menu
	if self.Newgame then
		Game:renderNewgameMenu()
	end
	
	-- if paused over-draw pause menu
	if self.Paused then
		love.graphics.draw(Textures.PauseBackground, 0, 0)
		love.graphics.draw(Textures.PauseHighlighter, 96, 80+36*(self.PauseHighSq-1))
	end
	
	-- signature
	love.graphics.draw(Textures.Sign, 290, 227)
	
end
