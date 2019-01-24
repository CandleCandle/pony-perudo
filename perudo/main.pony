use "time"
use "random"



actor Main

	new create(env: Env) =>
		let players: Array[(String val, Player tag)] iso = recover iso [
				("a", BasicIncrementingBidder)
				("b", BasicIncrementingBidder)
				("c", BasicIncrementingBidder)
			] end

		let game = Game.create(consume players)
		game.start()



