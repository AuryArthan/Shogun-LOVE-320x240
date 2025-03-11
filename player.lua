
Player = {
	weights = {3, 1.47, 2.20, 10.0, 2.33, 4.64, 7.38, 2.25};	-- need to be positive
	ShortestPathlength = nil;
}


-- function that finds a move to recommend
function Player:recommend_move()
	local active_player = Board.Turn
	local base_score = Player:state_score(active_player, Board)		-- score of the current state
	local legal_moves = Board:list_legal_moves()					-- all legal moves
	local scores = {}
	for m=1,#legal_moves do											-- loop over them
		local testBoard = Board:copy()									-- make a test board copy
		testBoard:make_move(legal_moves[m][1], legal_moves[m][2])		-- make the move
		if testBoard:win_check() then return legal_moves[m] end			-- if the move wins just do it
		scores[m] = Player:state_score(active_player, testBoard)		-- evaluate the state 	
	end
	local best = three_largest(scores)								-- the three best moves (can be nil if not enough legal moves)
	if best[1][2] == 1 then return legal_moves[best[1][1]] end		-- if the score is 1 then win is guaranteed so just do it
	for b = 1,#best do best[b][2] = best[b][2]-base_score end		-- substract base score so they represent relative improvements
	if best[1][2] <= 0 then return legal_moves[best[1][1]] end		-- if none of the moves improve the state (strange), then choose the best of them (no probabilities)
	local chosen_move = Player:prob_choose(best)					-- probabilistically choose one based on their score
	return legal_moves[best[chosen_move][1]]
end

-- function that probabilistically chooses one move based on their scores
function Player:prob_choose(best)
	for b = 1,#best do				-- cube the values (so a move that is a bit better is much more likely to be chosen)
		if best[b] then best[b][2] = best[b][2]^3 end
	end
	local sum_pos = 0				-- sum of all positive moves
	for b = 1,#best do
		if best[b][2] > 0 then sum_pos = sum_pos+best[b][2] end
	end
	local probability = {}			-- probability of each move
	for b = 1,#best do
		if best[b][2] > 0 then
			probability[b] = best[b][2]/sum_pos
		else
			probability[b] = 0
		end
	end
	local cummulative = {}			-- cummulative values
	cummulative[1] = probability[1]
	for b = 2,#best do
		cummulative[b] = cummulative[b-1]+probability[b]
	end
	local rn = math.random()		-- random number
	for b = 1,#best do
		if rn <= cummulative[b] then return b end	-- return the chosen index
	end
	return nil		-- this should not happen
end

-- function that evaluates the board state (returns score between -1 and 1)
function Player:state_score(player, board)
	if Player:win_guaranteed(player, board) then return 1 end	-- if win is guaranteed just return 1
	Player:shortest_path(board)			-- compute shortest path (needed for evaluation)
	local score = 0
	score = score + Player:player_score(player, board)			-- player focused score
	for p=1,4 do
		if p ~= player and board.PlayerAlive[p] == 1 then
			score = score - Player:player_score(p, board)/(board:live_num()-1)	-- other player's score counts negatively
		end
	end
	return score
end

-- auxiliary for state_score(), just focuses on one player
function Player:player_score(player, board)
	local comp = {}			-- each component has to be between 0 and 1
	-- free squares around the player
	comp[1] = Player:free_adjacent_squares(player, board)/4
	-- free secondary squares
	comp[2] = Player:free_secondary_squares(player, board)/8
	-- potential attacks
	comp[3] = 1-Player:potential_attacks(player, board)/4
	-- distance to the center
	comp[4] = (1-Player:distance_center(player, board)/Game.Gridsize)^2
	-- shortest unobstructed path
	local pos = board.PlayerPos[player]
	local thr = (Game.Gridsize+1)/2
	local pathlength = Player.ShortestPathlength[pos[1]][pos[2]]
	if pathlength then
		comp[5] = (1-cap(Player.ShortestPathlength[pos[1]][pos[2]],thr)/thr)^2
	else
		comp[5] = 0
	end
	-- number of live players (for 4 player mode)
	comp[6] = 1-board:live_num()/Game.NumPlayers
	-- number of free 'in between' squares
	comp[7] = (Player:in_between_free(player, board)+0.1)/(#in_between_squares(board.PlayerPos[player])+0.1)		-- +0.1 up and down so that 0/0 is 1
	-- number of attacked 'in between' squares
	comp[8] = 1-(Player:in_between_attacked(player, board)+0.1)/(#in_between_squares(board.PlayerPos[player])+0.1)	-- +0.1 up and down so that 0/0 is 1
	-- weighted sum
	local result = 0
	for i=1,#comp do
		result = result + self.weights[i]*comp[i]
	end
	return result/(sum(self.weights)+1)
end

-- checks if win is guaranteed (2 player mode guarantee only)
function Player:win_guaranteed(player, board)
	-- if center is not distance 1
	if Player:distance_center(player, board) ~= 1 then return false end
	-- if center is attacked
	local center = {(Game.Gridsize+1)/2,(Game.Gridsize+1)/2}
	if board:attacked(center) then return false end
	-- if there are potential attacks on the center
	local adjacents = neighbors(center)				-- adjacent squares (UDLR)
	local p_positions = {}
	for i=1,4 do
		p_positions[i] = {pos[1]+2*(adjacents[i][1]-pos[1]), pos[2]+2*(adjacents[i][2]-pos[2])}		-- positions from which an attack can come (UDLR)
	end
	for i=1,4 do
		if inbounds(p_positions[i]) then
			if board:minor_piece_present(p_positions[i]) then										-- if there is a minor piece in the right position
				if board:empty_square(adjacents[i]) then											-- if the square in between is empty
					if board:square_value(p_positions[i]) ~= i+4 then return false end				-- if the piece is not facing outward
				end
			end
		end
	end
	return true
end

-- count free adjacent squares
function Player:free_adjacent_squares(player, board)
	local cnt = 0
	local pos = board.PlayerPos[player]
	local adjacents = neighbors(pos)
	for i=1,4 do
		if inbounds(adjacents[i]) then
			if board:empty_square(adjacents[i]) and board:attacked(adjacents[i]) == 0 then cnt = cnt+1 end
		end
	end
	return cnt
end

-- count free secondary squares (distance 2)
function Player:free_secondary_squares(player, board)
	local cnt = 0
	local pos = board.PlayerPos[player]
	local secondary = second_neighbors(pos)
	for i=1,8 do
		if inbounds(secondary[i]) then
			if board:empty_square(secondary[i]) and board:attacked(secondary[i]) == 0 then cnt = cnt+1 end
		end
	end
	return cnt
end

-- count potential attacks
function Player:potential_attacks(player, board)
	local cnt = 0
	local pos = board.PlayerPos[player]
	local adjacents = neighbors(pos)			-- adjacent squares (UDLR)
	local p_positions = {}
	for i=1,4 do
		p_positions[i] = {pos[1]+2*(adjacents[i][1]-pos[1]), pos[2]+2*(adjacents[i][2]-pos[2])}		-- positions from which the piece can attack (UDLR)
	end
	for i=1,4 do
		if inbounds(p_positions[i]) then
			if board:minor_piece_present(p_positions[i]) then										-- if there is a minor piece in the right position
				if board:empty_square(adjacents[i]) then											-- if the square in between is empty
					if board:square_value(p_positions[i]) ~= i+4 then cnt = cnt+1 end				-- if the piece is not facing outward
				end
			end
		end
	end
	return cnt
end

-- distance of the player to the center
function Player:distance_center(player, board)
	return distance(board.PlayerPos[player], {(Game.Gridsize+1)/2,(Game.Gridsize+1)/2})
end

-- number of free 'in between squares' between the player and the goal
function Player:in_between_free(player, board)
	local ibs = in_between_squares(board.PlayerPos[player])
	local cnt = 0
	for i=1,#ibs do
		if board:empty_square(ibs[i]) then cnt=cnt+1 end
	end
	return cnt
end

-- number of attacked 'in between squares' between the player and the goal
function Player:in_between_attacked(player, board)
	local ibs = in_between_squares(board.PlayerPos[player])
	local cnt = 0
	for i=1,#ibs do
		if board:attacked(ibs[i]) then cnt=cnt+1 end
	end
	return cnt
end

-- auxiliary for shortest_path(), recursively marks the pathlength of neighboring squares
function Player:mark_neighbors_pathlength(pos, board)
	local adj = neighbors(pos)								-- adjacent squares (UDLR)
	local val = self.ShortestPathlength[pos[1]][pos[2]]		-- shortest path at the position
	for i=1,4 do
		if inbounds(adj[i]) then
			if self.ShortestPathlength[adj[i][1]][adj[i][2]] == nil or self.ShortestPathlength[adj[i][1]][adj[i][2]] > val+1 then	-- if the shortes path has not reached that square yet or if the new path is shorter
				if board:attacked(adj[i]) == 0 then								-- if the square is not attacked
					if board:square_value(adj[i]) <= 4 then						-- if square is empty or with a player
						self.ShortestPathlength[adj[i][1]][adj[i][2]] = val+1	-- mark pathlength as one larger
						if board:square_value(adj[i]) == 0 then
							Player:mark_neighbors_pathlength(adj[i], board)			-- if square is empty recursively mark neighbors
						end
					end
				end
			end
		end
	end
end

-- for each squre computes the shortest unobstructed path to the center (nil if there is no free path)
function Player:shortest_path(board)
	self.ShortestPathlength = {}
	for i=1,Game.Gridsize do
		self.ShortestPathlength[i] = {}
		for j=1,Game.Gridsize do
			self.ShortestPathlength[i][j] = nil	-- initialize squares to nil
		end
	end
	self.ShortestPathlength[(Game.Gridsize+1)/2][(Game.Gridsize+1)/2] = 0				-- set pathlength 0 at the center
	Player:mark_neighbors_pathlength({(Game.Gridsize+1)/2,(Game.Gridsize+1)/2}, board)	-- recursivelly mark all the squares
end
