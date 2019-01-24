

actor BasicCaller is Player
	be do_bid(game: Game, pot: Pot val, history: Array[Bid] val) =>
		game.do_call(this)

actor BasicIncrementingBidder is Player
	var _bid_count: USize = 20

	be game_start(all_players: Array[String] val) =>
		@printf[None]("*** game start:\n".cstring())
		for (i, n) in all_players.pairs() do
			@printf[None]("***     game start: %d -> %s.\n".cstring(), i, n.cstring())
		end

	be round_start(current_players: Array[String] val, start_index: USize, your_index: USize, round: RoundType) =>
		@printf[None]("*** round start: starting %d, me %d.\n".cstring(), start_index, your_index)
		for (i, n) in current_players.pairs() do
			@printf[None]("***     round start: %d -> %s.\n".cstring(), i, n.cstring())
		end

	be round_end(current_players: Array[String] val, losing_index: USize, your_index: USize, history: Array[Bid] val) =>
		@printf[None]("*** round end: loser %d, me %d.\n".cstring(), losing_index, your_index)
		for (i, n) in current_players.pairs() do
			@printf[None]("***     round end: %d -> %s.\n".cstring(), i, n.cstring())
		end

	be game_end(all_players: Array[String] val, winning_index: USize, your_index: USize) =>
		@printf[None]("*** game end: winner %d, me %d.\n".cstring(), winning_index, your_index)
		for (i, n) in all_players.pairs() do
			@printf[None]("***     game end: %d -> %s.\n".cstring(), i, n.cstring())
		end

	fun tag _last_bid_safe(history: Array[Bid] val): Bid =>
		if history.size() == 0 then
			Bid(0, FaceOne)
		else
			try
				history(history.size()-1)?
			else
				Bid(0, FaceOne)
			end
		end

	be do_bid(game: Game, pot: Pot val, history: Array[Bid] val) =>
		if history.size() > _bid_count then
			game.do_call(this)
			return
		end
		let b = _last_bid_safe(history)
		var count = b.count
		var new_face = Faces((b.face() + 1) % 6 )
		match new_face
		| FaceOne =>
			count = (count / 2) + 1
		| FaceTwo =>
			count = count * 2
		else
			count = count + 1
		end
		game.do_bid(this, Bid.create(count, new_face))


