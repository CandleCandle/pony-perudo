

trait Player
	// Actions:
	be do_bid(game: Game, pot: Pot val, history: Array[Bid] val)

	// Events:
	be game_start(all_players: Array[String] val) => None
	be round_start(current_players: Array[String] val, start_index: USize, your_index: USize, round: RoundType) => None
	be round_end(current_players: Array[String] val, losing_index: USize, your_index: USize, bid_history: Array[Bid] val) => None
	be game_end(all_players: Array[String] val, winning_index: USize, your_index: USize) => None


