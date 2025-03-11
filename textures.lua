
Textures = {
	Background = nil;
	Grid = nil;
	Highlighter = nil;
	Selected = nil;
	MoveOption = nil;
	PiecesUDLR = {nil,nil,nil,nil};
	Players = {nil,nil,nil,nil};
	PlayerDead = nil;
	MarkedSqs = {nil,nil,nil,nil};
	Goal = nil;
}

function Textures:init()

	-- load font
	font = love.graphics.newImageFont("assets/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-*/\\=.,!?:;()[]&#%\"\'_|")
	love.graphics.setFont(font)
	
	-- load backgrounds
	self.Background = love.graphics.newImage("assets/backgrounds/back.png")
	self.PauseBackground = love.graphics.newImage("assets/backgrounds/pause_background.png")
	self.NewgameBackground = love.graphics.newImage("assets/backgrounds/newgame_background.png")
	
	-- load highlighters
	self.Highlighter = love.graphics.newImage("assets/highlighters/highlighter_"..Game.Gridsize..".png")
	self.Selected = love.graphics.newImage("assets/highlighters/selected_"..Game.Gridsize..".png")
	self.MoveOption = love.graphics.newImage("assets/highlighters/move_option_"..Game.Gridsize..".png")
	self.Attacked = love.graphics.newImage("assets/highlighters/attacked_"..Game.Gridsize..".png")
	self.MarkedSqs = {love.graphics.newImage("assets/highlighters/marked_p1_"..Game.Gridsize..".png"),love.graphics.newImage("assets/highlighters/marked_p2_"..Game.Gridsize..".png"),love.graphics.newImage("assets/highlighters/marked_p3_"..Game.Gridsize..".png"),love.graphics.newImage("assets/highlighters/marked_p4_"..Game.Gridsize..".png")}
	self.PauseHighlighter = love.graphics.newImage("assets/highlighters/pause_highlighter.png")
	self.Turn = love.graphics.newImage("assets/highlighters/turn.png")
	
	-- load piece textures
	self.PiecesUDLR = {love.graphics.newImage("assets/pieces/piece_u_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/piece_d_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/piece_l_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/piece_r_"..Game.Gridsize..".png")}
	self.Players = {love.graphics.newImage("assets/pieces/player1_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/player2_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/player3_"..Game.Gridsize..".png"), love.graphics.newImage("assets/pieces/player4_"..Game.Gridsize..".png")}
	self.PlayerDead = love.graphics.newImage("assets/pieces/player_dead_"..Game.Gridsize..".png")
	self.Goal = love.graphics.newImage("assets/pieces/goal_"..Game.Gridsize..".png")
	
	-- load grid
	self.Grid = love.graphics.newImage("assets/grids/grid_"..Game.Gridsize..".png")
	
	-- aditional textures for the newgame menu
	self.NewgameStartGame = love.graphics.newImage("assets/highlighters/startgame_highlighter.png")
	self.NewgameHighlighter = love.graphics.newImage("assets/highlighters/highlighter_11.png")
	self.NewgameMarker = love.graphics.newImage("assets/highlighters/move_option_11.png")
	self.SmallPlayer = {love.graphics.newImage("assets/pieces/player1_11.png"), love.graphics.newImage("assets/pieces/player2_11.png"), love.graphics.newImage("assets/pieces/player3_11.png"), love.graphics.newImage("assets/pieces/player4_11.png")}
	self.SmallPlayerDead = love.graphics.newImage("assets/pieces/player_dead_11.png")
	
	-- load signature
	self.Sign = love.graphics.newImage("assets/sign.png")
	
end
