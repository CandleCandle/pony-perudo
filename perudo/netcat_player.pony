use "net"


class NetcatPlayers is TCPListenNotify
	let _game: Game

	new create(game: Game) =>
		_game = game

	fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
		NetcatPlayerConNotify(_game)

	fun ref not_listening(listen: TCPListener ref) => None

class iso NetcatPlayerConNotify is TCPConnectionNotify
	let _game: Game
	var _player: ( None | NetcatPlayer ) = None

	new iso create(game: Game) =>
		_game = game

	fun ref accepted(conn: TCPConnection ref) =>
		_player = NetcatPlayer.create(_game, conn)
		@printf[None]("new player: %d\n".cstring(), conn.remote_address().port())

	fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
		match _player
		| let p: NetcatPlayer => p.received(conn, consume data, times)
		end
		true

	fun ref connected(conn: TCPConnection ref) => None
	fun ref connect_failed(conn: TCPConnection ref) => None



primitive _NcStateWaiting
primitive _NcStateAccepted
primitive _NcStateBidding
primitive _NcStateEnd

type _NcState is ( _NcStateWaiting | _NcStateAccepted | _NcStateBidding | _NcStateEnd )


actor NetcatPlayer is Player
	var _state: _NcState = _NcStateAccepted
	let _conn: TCPConnection
	let _game: Game

	new create(game: Game, conn: TCPConnection) =>
		_game = game
		_conn = conn
		conn.write("Name:\n")

	be received(conn: TCPConnection tag, data: Array[U8] iso, times: USize) =>
		match _state
		| _NcStateAccepted =>
			_process_name(String.from_array(consume data).clone().>rstrip(), conn)
		| _NcStateBidding =>
			_process_bid(String.from_array(consume data), conn)
		end

	fun ref _process_name(name: String, conn: TCPConnection tag) =>
		_game.add_player(name, this)

	fun ref _process_bid(bid: String, conn: TCPConnection tag) =>
		try
			if bid.contains("call") then
				_game.do_call(this)
				return
			end
			let split: ISize = bid.find(" ")?
			let count': String = bid.substring(0, split)
			let face': String = bid.substring(split+1).>rstrip()
			let count: U8 = count'.u8()?
			let face: Face = Faces(face'.u8()? - 1)
			let actual = Bid(count, face)
			_game.do_bid(this, actual)
			_state = _NcStateWaiting
		else
			conn.write("parse error, try again\n")
		end

	be game_start(all_players: Array[String] val) =>
		_conn.write("*** game start:\n")
		for (i, n) in all_players.pairs() do
			_conn.write("***     game start: "+i.string()+" -> "+n+".\n")
		end

	be round_start(current_players: Array[String] val, start_index: USize, your_index: USize, round: RoundType) =>
		_conn.write("*** round start: starting "+start_index.string()+", me "+your_index.string()+" mode: "+round.string()+".\n")
		for (i, n) in current_players.pairs() do
			_conn.write("***     round start: "+i.string()+" -> "+n+".\n")
		end

	be round_end(current_players: Array[String] val, losing_index: USize, your_index: USize, history: Array[Bid] val) =>
		_conn.write("*** round end: loser "+losing_index.string()+", me "+your_index.string()+".\n")
		for (i, n) in current_players.pairs() do
			_conn.write("***     round end: "+i.string()+" -> "+n+".\n")
		end

	be game_end(all_players: Array[String] val, winning_index: USize, your_index: USize) =>
		_conn.write("*** game end: winner "+winning_index.string()+", me "+your_index.string()+".\n")
		for (i, n) in all_players.pairs() do
			_conn.write("***     game end: "+i.string()+" -> "+n+".\n")
		end
		_state = _NcStateEnd
		_conn.dispose()

	be do_bid(game: Game, pot: Pot val, history: Array[Bid] val) =>
		_conn.write("*** bid with: "+pot.string()+"\n")
		for (i, b) in history.pairs() do
			_conn.write("***     "+(i+1).string()+": "+b.string()+"\n")
		end
		_state = _NcStateBidding


