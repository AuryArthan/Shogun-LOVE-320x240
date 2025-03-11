
Board = {
	Squares = nil;
	Attacked = nil;
	Turn = nil;
	MarkedSqs = {nil,nil,nil,nil};
	PlayerPos = {nil,nil,nil,nil};
	PlayerAlive = {nil,nil,nil,nil};
}

-- piece numbers
--[[
0	empty
1 	player1
2	player2
3	player3
4	player4
5	up
6	down
7	left
8	right
9	goal
--]]


-- INIT AND COPY

function Board:init()
	
	-- intialize whos turn it is
	self.Turn = 1
	
	-- initialize board squares
	self.Squares = {}
	for i=1,Game.Gridsize do
		self.Squares[i] = {}
		for j=1,Game.Gridsize do
			self.Squares[i][j] = 0
		end
	end
	-- arrange pieces
	for i=1,Game.Gridsize/2 do
		self.Squares[Game.Gridsize+1-i][i] = 5
		self.Squares[Game.Gridsize+1-i][Game.Gridsize+1-i] = 7
		self.Squares[i][Game.Gridsize+1-i] = 6
		self.Squares[i][i] = 8
	end
	-- arrange player pieces
	self.Squares[(Game.Gridsize+1)/2][1] = 1
	self.Squares[(Game.Gridsize+1)/2][Game.Gridsize] = 3
	if Game.NumPlayers == 4 then
		self.Squares[1][(Game.Gridsize+1)/2] = 4
		self.Squares[Game.Gridsize][(Game.Gridsize+1)/2] = 2
	end
	-- place the goal in the center
	self.Squares[(Game.Gridsize+1)/2][(Game.Gridsize+1)/2] = 9
    
    -- reset marked squares
    self.MarkedSqs = {nil,nil,nil,nil};
    
    -- mark player positions
    self.PlayerPos[1] = {(Game.Gridsize+1)/2,1}
    self.PlayerPos[3] = {(Game.Gridsize+1)/2,Game.Gridsize}
    if Game.NumPlayers == 4 then
		self.PlayerPos[2] = {Game.Gridsize,(Game.Gridsize+1)/2}
		self.PlayerPos[4] = {1,(Game.Gridsize+1)/2}
    end
    
    -- mark that players are alive
    for i=1,4 do self.PlayerAlive[i] = 0 end
    for i=1,4,4/Game.NumPlayers do
		self.PlayerAlive[i] = 1
	end
	
    -- initialize attacked squares
    self.Attacked = {}
    for i=1,Game.Gridsize do
		self.Attacked[i] = {}
		for j=1,Game.Gridsize do
			self.Attacked[i][j] = 0		-- initialize to 0
		end
	end
	self:compute_attacked()
	
end

-- copy function
function Board:copy()
	local copy = {
		Squares = nil;
		Attacked = nil;
		Turn = nil;
		MarkedSqs = {nil,nil,nil,nil};
		PlayerPos = {nil,nil,nil,nil};
		PlayerAlive = {nil,nil,nil,nil};
	}
	-- copy squares
	copy.Squares = {}
	for i=1,Game.Gridsize do
		copy.Squares[i] = {}
		for j=1,Game.Gridsize do
			copy.Squares[i][j] = self.Squares[i][j]
		end
	end
	-- copy attacked
	copy.Attacked = {}
	for i=1,Game.Gridsize do
		copy.Attacked[i] = {}
		for j=1,Game.Gridsize do
			copy.Attacked[i][j] = self.Attacked[i][j]
		end
	end
	-- copy other things
	copy.Turn = self.Turn
	for i=1,4 do copy.MarkedSqs[i] = self.MarkedSqs[i] end
	for i=1,4 do copy.PlayerPos[i] = self.PlayerPos[i] end
	for i=1,4 do copy.PlayerAlive[i] = self.PlayerAlive[i] end
	setmetatable(copy, { __index = Board })
	return copy
end


-- CORE FUNCTIONS

-- checks if the player dies
function Board:death_check()
	local pos = self.PlayerPos[self.Turn]
	if self:attacked(pos) then					-- if the player is attacked
		moves = self:list_legal_moves()
		if #moves == 0 then 					-- and has no legal moves
			self.PlayerAlive[self.Turn] = 0 
			self.Squares[pos[1]][pos[2]] = -1
			self.MarkedSqs[self.Turn] = pos		-- mark the square so the dead player cannot be moved by other players
			self:change_turn()
			self:death_check()					-- check if the next player also dies on the next move
		end
	end
end

-- checks if the player wins
function Board:win_check()
	if self:live_num() == 1 then									-- if all other players are dead
		return true
	else
		for p=1,4 do
			local pos = self.PlayerPos[p]
			local center = (Game.Gridsize+1)/2
			if pos and pos[1] == center and pos[2] == center then	-- if any player reached the goal
				return true
			end
		end
	end
	return false
end

-- just moves the piece (does not check legality or handle other variables)
function Board:move_piece(sq1, sq2)
	piece = self:square_value(sq1)
	if self:minor_piece_present(sq1) then
		piece = self:piece_orientation(sq1, sq2)
	end	
	self:write_to_square(sq2, piece)
	self:write_to_square(sq1, 0)
end

-- makes the move fully: moves the piece, updates attacked squares and changes player turn (does not check legality)
function Board:make_move(sq1, sq2)
	self.MarkedSqs[self.Turn] = {sq2[1],sq2[2]}												-- mark the moved piece
	self:update_attacked(sq1, sq2)															-- update attacked values
	self:move_piece(sq1, sq2)																-- move the piece
	if self:player_present(sq2) then self.PlayerPos[self.Turn] = square_copy(sq2) end		-- track player position
	self:change_turn()																		-- change turn
	self:death_check()																		-- check for deaths
end

-- checks if the move sq1 -> sq2 is legal
function Board:move_legality(sq1, sq2)
	if math.abs(sq1[1]-sq2[1])+math.abs(sq1[2]-sq2[2]) ~= 1 then					-- if the move is not to adjacent square
		return false
	elseif not inbounds(sq2) then												-- if square is out of bounds
		return false
	elseif self:piece_present(sq2) then											-- if the square is occupied
		return false
	elseif self:move_is_backward(sq1, sq2) then									-- if moving backwards
		return false
	elseif self:player_present(sq1) and self:attacked(sq2) > 0 then				-- if a player tries to move to an atacked square
		return false
	elseif self:player_present(sq1) and self:square_value(sq1) ~= self.Turn then	-- if a player tries to move another player's piece
		return false
	elseif self:marked_square(sq1) and self:marked_square(sq1) ~= self.Turn then	-- if a player tries to move a piece that is marked by another player
		return false
	elseif self:minor_piece_present(sq1) and self:square_value(sq2) == 9 then		-- if a minor piece tries to reach goal
		return false
	elseif self:attacked(self.PlayerPos[self.Turn]) > 0 then 						-- if the player is attacked
		if not self:player_present(sq1) then return false end							-- and does not try to move out of attack																					
	elseif self:minor_piece_present(sq1) then										-- if the player tries to attack himself
		for i = 1,2 do
			if sq2[i] == self.PlayerPos[self.Turn][i] then								-- (if they allign on an axis)
				for s = -1,1,2 do
					if sq2[i%2+1] == self.PlayerPos[self.Turn][i%2+1]+s and sq1[i%2+1] == self.PlayerPos[self.Turn][i%2+1]+2*s then
						return false
					end
				end
			end
		end
	end
	return true
end

-- lists all legal moves
function Board:list_legal_moves()
	local moves = {}
	for i = 1,Game.Gridsize do
		for j = 1,Game.Gridsize do
			if self:piece_present({i,j}) then			-- if a piece is present
				local prop_sqs = {{i+1,j},{i-1,j},{i,j+1},{i,j-1}}
				for index,pr in ipairs(prop_sqs) do		-- check adjacent squares for legal moves
					if self:move_legality({i,j}, pr) then table.insert(moves, {{i,j},pr}) end
				end
			end
		end
	end
	return moves
end


-- DRAWING FUNCTIONS

function Board:draw_pieces()
	for i=1,Game.Gridsize do
		for j=1,Game.Gridsize do
			if self.Squares[i][j] == 5 then			-- up
				love.graphics.draw(Textures.PiecesUDLR[1], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 6 then		-- down
				love.graphics.draw(Textures.PiecesUDLR[2], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 7 then		-- left
				love.graphics.draw(Textures.PiecesUDLR[3], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 8 then		-- right
				love.graphics.draw(Textures.PiecesUDLR[4], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 1 then		-- player1
				love.graphics.draw(Textures.Players[1], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 2 then		-- player2
				love.graphics.draw(Textures.Players[2], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 3 then		-- player3
				love.graphics.draw(Textures.Players[3], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 4 then		-- player4
				love.graphics.draw(Textures.Players[4], Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == 9 then		-- goal
				love.graphics.draw(Textures.Goal, Game:sq_coordinates({i,j}))
			elseif self.Squares[i][j] == -1 then	-- dead player
				love.graphics.draw(Textures.PlayerDead, Game:sq_coordinates({i,j}))
			end
		end
	end
end

function Board:draw_attacked()
	for i=1,Game.Gridsize do
		for j=1,Game.Gridsize do
			if self.Attacked[i][j] > 0 then
				love.graphics.draw(Textures.Attacked, Game:sq_coordinates({i,j}))
			end
		end
	end
end


-- OTHER MINOR FUNCTIONS

-- checks if square 'sq' is attacked
function Board:attacked(sq)
	if sq then return self.Attacked[sq[1]][sq[2]] end
end

-- returns the value on square 'sq'
function Board:square_value(sq)
	return self.Squares[sq[1]][sq[2]]
end

-- writes value 'val' to square 'sq'
function Board:write_to_square(sq, val)
	self.Squares[sq[1]][sq[2]] = val
end

-- computes the atacked squares by going through the board and checking which piece attacks what
function Board:compute_attacked()
	for i=1,Game.Gridsize do
		for j=1,Game.Gridsize do
			piece = self.Squares[i][j]
			if 5 <= piece and piece <= 8 then
				ii,jj = self:piece_attacks({i,j}, piece)
				self.Attacked[ii][jj] = self.Attacked[ii][jj] + 1
			end
		end
	end
end

-- which square the piece 'piece' is attacking from square 'sq'
function Board:piece_attacks(sq, piece)
	i = sq[1]
	j = sq[2]
	if piece == 5 then
		j = j + 1
	elseif piece == 6 then
		j = j - 1
	elseif piece == 7 then
		i = i - 1
	elseif piece == 8 then
		i = i + 1
	end
	return i,j
end

-- updates the attacked squares caused by a potential move sq1 -> sq2
function Board:update_attacked(sq1, sq2)
	if self:minor_piece_present(sq1) then
		piece_before = self:square_value(sq1)
		piece_after = self:piece_orientation(sq1, sq2)
		-- which square to decrease the attacked value
		i,j = self:piece_attacks(sq1, piece_before)
		if inbounds({i,j}) then
			self.Attacked[i][j] = self.Attacked[i][j] - 1
		end
		-- which square to increase the attacked value
		i,j = self:piece_attacks(sq2, piece_after)
		if inbounds({i,j}) then
			self.Attacked[i][j] = self.Attacked[i][j] + 1
		end
	end
end

-- returns the orientation of a minor piece after a move sq1 -> sq2
function Board:piece_orientation(sq1, sq2)
	if sq2[2] == sq1[2]+1 then
		return 5				-- up
	elseif sq2[2] == sq1[2]-1 then
		return 6				-- down
	elseif sq2[1] == sq1[1]-1 then
		return 7				-- left
	elseif sq2[1] == sq1[1]+1 then
		return 8				-- right
	end
end

-- returns number of live players
function Board:live_num()
	local sum = 0
	for i=1,4 do
		if self.PlayerAlive[i] then
			sum = sum+self.PlayerAlive[i]
		end
	end
	return sum
end

-- changes the player turn
function Board:change_turn()
	repeat
		self.Turn = 1 + self.Turn%4
	until self.PlayerAlive[self.Turn] == 1
end

-- computes the previous turn
function Board:previous_turn()
	local pr_turn = self.Turn
	repeat
		pr_turn = pr_turn-1
		if pr_turn == 0 then pr_turn = 4 end
	until self.PlayerAlive[pr_turn] == 1
	return pr_turn
end

-- checks if square 'sq' is empty
function Board:empty_square(sq)
	return self:square_value(sq) == 0 or self:square_value(sq) == 9
end

-- checks if a piece (any) is present on square 'sq'
function Board:piece_present(sq)
	return not self:empty_square(sq)
end

-- checks if a player (1-4) is present on square 'sq'
function Board:player_present(sq)
	if 1 <= self:square_value(sq) and self:square_value(sq) <= 4 then
		return true
	end
	return false
end

-- checks if a minor piece (5-8) is present on square 'sq'
function Board:minor_piece_present(sq)
	if 5 <= self:square_value(sq) and self:square_value(sq) <= 8 then
		return true
	end
	return false
end

-- checks if the move sq1 -> sq2 is by a minor piece moving backwards
function Board:move_is_backward(sq1, sq2)
	if self:square_value(sq1) == 5 and sq2[2] == sq1[2]-1 then
		return true
	elseif self:square_value(sq1) == 6 and sq2[2] == sq1[2]+1 then
		return true
	elseif self:square_value(sq1) == 7 and sq2[1] == sq1[1]+1 then
		return true
	elseif self:square_value(sq1) == 8 and sq2[1] == sq1[1]-1 then
		return true
	end
	return false
end

-- checks if a square 'sq' is marked
function Board:marked_square(sq)
	for i=1,4 do
		if square_compare(sq, self.MarkedSqs[i]) then
			return i
		end
	end
	return false
end

