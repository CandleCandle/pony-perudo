use "time"
use "random"

primitive _GameStart
primitive _GameEnd

class val _GamePalaficoTurn
	let _next_player: USize

	new val create(next_player': USize) =>
		_next_player = next_player'

	fun next_player(): USize => _next_player

class val _GameNormalTurn
	let _next_player: USize

	new val create(next_player': USize) =>
		_next_player = next_player'

	fun next_player(): USize => _next_player

type _GameTurn is ( _GameNormalTurn | _GamePalaficoTurn )

type _GameState is ( _GameStart | _GameTurn | _GameEnd )

primitive Randoms
	fun apply(): Random ref =>
		(let a: I64, let b: I64) = Time.now()
		let random = Rand.create(a.u64(), b.u64())
		random.>u128()

class _Player
	let pot: Pot val
	let name: String val
	let player: Player tag

	new initial(name': String, player': Player tag, pot': Pot) =>
		player = player'
		pot = pot'
		name = name'

actor Game
	var _state: _GameState = _GameStart
	let _starting_players: Array[_Player]
	var _players: Array[_Player]
	var _bid_history: Array[Bid] = Array[Bid](10)
	let _rand: Random

	new create(starting_players': Array[(String val, Player tag)] val) =>
		_starting_players = Array[_Player](starting_players'.size())
		_players = Array[_Player](starting_players'.size())
		_rand = Randoms()
		for (n, p) in starting_players'.values() do
			_add_player(n, p)
		end

	be add_player(name: String val, player: Player tag) =>
		match _state
		| _GameStart =>
			_add_player(name, player)
		end

	fun ref _add_player(name: String val, player: Player tag) =>
		_starting_players.push(_Player.initial(name, player, Pot.create([])))
		_players.push(_Player.initial(name, player, Pots.create_pot(5, _rand)))

	be start() =>
		match _state
		| _GameStart =>
			if _starting_players.size() == 0 then return end
			_dispatch_game_start()
			_state = _GameNormalTurn(0)
			_dispatch_round_start(0, RoundNormal)
			try
				let next_player = _players(0)?
				@printf[None]("starting with %d\n".cstring(), U32(0))
				next_player.player.do_bid(this, next_player.pot, recover val Array[Bid](0) end)
			end
		end

	be do_bid(from: Player tag, bid: Bid) =>
		@printf[None]("bid received: %s\n".cstring(), bid.string().cstring())
		match _state
		| let state: _GameTurn =>
			try
				let last_bid = _last_bid_safe()
				// next player when (new bid > latest bid) OR this is the first bid
				let index = state.next_player()
				let next_index = match state
				| let state': _GameNormalTurn =>
					if (bid > last_bid) then
						_bid_history.push(bid)
						(index + 1) % _players.size()
					else
						index
					end
				| let state': _GamePalaficoTurn =>
					if _bid_history.size() == 0 then
						_bid_history.push(bid)
						(index + 1) % _players.size()
					else
						if (bid > last_bid) then
							_bid_history.push(bid)
							(index + 1) % _players.size()
						else
							index
						end
					end
				end

				_state = match state
					| let state': _GameNormalTurn => _GameNormalTurn(next_index)
					| let state': _GamePalaficoTurn => _GamePalaficoTurn(next_index)
					end
				let next_player = _players(next_index)?
				@printf[None]("requesting bid from: %d\n".cstring(), next_index)
				next_player.player.do_bid(this, next_player.pot, _copy_bid_history())
			end
		end

	fun _last_bid_safe(): Bid =>
		if _bid_history.size() == 0 then
			Bid(0, FaceOne)
		else
			try
				_bid_history(_bid_history.size()-1)?
			else
				Bid(0, FaceOne)
			end
		end

	fun _copy_bid_history(): Array[Bid] val =>
		let history_copy: Array[Bid] iso = recover iso Array[Bid](10) end
		for b in _bid_history.values() do
			history_copy.push(b)
		end
		recover val consume history_copy end

	fun ref _dispatch_game_start() =>
		let names = _names_from(_starting_players)
		for (idx, player) in _starting_players.pairs() do
			player.player.game_start(names)
		end

	fun ref _dispatch_round_start(start_index: USize, round_type: RoundType) =>
		let names = _names_from(_players)
		for (idx, player) in _players.pairs() do
			player.player.round_start(names, start_index, idx, round_type)
		end

	fun ref _dispatch_round_end(lost_index: USize) =>
		let names = _names_from(_players)
		let history = _copy_bid_history()
		for (idx, player) in _players.pairs() do
			player.player.round_end(names, lost_index, idx, history)
		end

	fun ref _dispatch_game_end() =>
		try
			let winner = _players(0)?
			let names = _names_from(_starting_players)
			var win_index: USize = 0
			for (idx, player) in _starting_players.pairs() do
				if player.player is winner.player then
					win_index = idx
				end
			end
			for (idx, player) in _starting_players.pairs() do
				player.player.game_end(names, win_index, idx)
			end
		end

	fun ref _names_from(arr: Array[_Player]): Array[String] val =>
		let size = arr.size()
		let names': Array[String] iso = recover iso Array[String](size) end
		for (idx, player) in arr.pairs() do
			names'.push(player.name)
		end
		consume names'

	be do_call(from: Player tag) =>
		match _state
		| let state: _GameTurn =>
			@printf[None]("call from %d; history was:\n".cstring(), state.next_player())
			for b in _bid_history.values() do
				@printf[None]("\t%s\n".cstring(), b.string().cstring())
			end
			let last_bid = _last_bid_safe()
			var count: U8 = 0
			for (i, p) in _players.pairs() do
				@printf[None]("\tplayer %d has %s\n".cstring(), i, p.pot.string().cstring())
				count = count + p.pot.count_for_face(last_bid.face)
				match state
				| let state': _GameNormalTurn =>
					if not (last_bid.face is FaceOne) then
						count = count + p.pot.count_for_face(FaceOne)
					end
				end
			end
			// work out which of the players won the call
			let lost_player = if count < last_bid.count then
				// call was correct, previous bid was too high; previous player lost
				((state.next_player() + _players.size()) - 1) % _players.size()
			else
				state.next_player()
			end
			@printf[None]("losing player was %d, there were %d of face %s\n".cstring(), lost_player, count, last_bid.face.string().cstring())

			_dispatch_round_end(lost_player)
			// rebuild _players
			var next_index = lost_player
			let players' = Array[_Player](_players.size())
			for (i, player) in _players.pairs() do
				let replacement_pot: (Pot | None) = if i == lost_player then
						Pots.with_different_size(player.pot, -1, _rand)
					else
						Pots.with_different_size(player.pot, 0, _rand)
					end
				if (i == lost_player) and (replacement_pot is None) then
					// on player elimination, the next player starts rather than the one who lost a die.
					next_index = (_players.size() + 1) % (_players.size()-1)
				end
				match replacement_pot
				| let pot': Pot =>
					// players with zero dice do not get re-added here.
					players'.push(_Player.initial(player.name, player.player, pot'))
				end
			end
			_players = players'

			if _players.size() == 1 then
				_state = _GameEnd
				_dispatch_game_end()
			else
				_bid_history.clear()
				try
					let next_player = _players(next_index)?
					if next_player.pot.dice.size() == 1 then
						_state = _GamePalaficoTurn(next_index)
						_dispatch_round_start(next_index, RoundPalafico)
					else
						_state = _GameNormalTurn(next_index)
						_dispatch_round_start(next_index, RoundNormal)
					end
					next_player.player.do_bid(this, next_player.pot, recover val Array[Bid](0) end)
				end
			end
		end
