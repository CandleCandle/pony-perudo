use "time"
use "random"
use "net"


actor Main

	new create(env: Env) =>
		let players: Array[(String val, Player tag)] iso = recover iso [] end

		let game = Game.create(consume players)

		try
			let listener = TCPListener(env.root as AmbientAuth, recover NetcatPlayers(game) end, "0.0.0.0", "8989")

			let timers = Timers
			let timer = Timer(Starter(game, listener), 10_000_000_000)
			timers(consume timer)
		end

class iso Starter is TimerNotify
	let _game: Game
	let _listener: TCPListener

	new iso create(game: Game, listener: TCPListener) =>
		_game = game
		_listener = listener

	fun ref apply(timer: Timer, count: U64): Bool =>
		_game.start()
		_listener.dispose()
		false




