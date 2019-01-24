use "time"
use "random"



actor Main

	new create(env: Env) =>
		env.out.print("hello world")


primitive Start
primitive RoundEnd
primitive End
class val Turn
	let next_player: USize

	new val create(next_player': USize) =>
		next_player = next_player'

type GameState is ( Start | Turn | RoundEnd | End )

trait Player
	be do_bid(game: Game, pot: Pot val, history: Array[Bid] val)

primitive FaceOne
	fun apply(): U8 => 0
primitive FaceTwo
	fun apply(): U8 => 1
primitive FaceThree
	fun apply(): U8 => 2
primitive FaceFour
	fun apply(): U8 => 3
primitive FaceFive
	fun apply(): U8 => 4
primitive FaceSix
	fun apply(): U8 => 5
type Face is ( FaceOne | FaceTwo | FaceThree | FaceFour | FaceFive | FaceSix )

primitive Faces
	fun apply(n: U8): Face =>
		match n
		| 0 => FaceOne
		| 1 => FaceTwo
		| 2 => FaceThree
		| 3 => FaceFour
		| 4 => FaceFive
		| 5 => FaceSix
		else
			FaceOne
		end

	fun roll(rand: Random): Face =>
		apply(rand.int(6).u8())

primitive Randoms
	fun apply(): Random =>
		(let a: I64, let b: I64) = Time.now()
		Rand.create(a.u64(), b.u64())

primitive Pots
	fun create_pot(count: U8, rand: Random): Pot val =>
		let a: Array[Face] iso = recover iso Array[Face](count.usize()) end
		var i: U8 = 0
		while i < count do
			a.push(Faces.roll(rand))
			i = i + 1
		end
		Pot.create(recover val consume a end)

	fun with_different_size(pot: Pot, change: I32, rand: Random): (None | Pot val) =>
		let new_size: I32 = pot.dice.size().i32() + change
		if new_size < 0 then return None end
		create_pot(new_size.u8(), rand)

class val Pot
	let dice: Array[Face] val

//	new create(count: U8, rand: Random) =>
//		let dice' = recover iso Array[Face](count.usize()) end
//		var c: U8 = 0
//		while c < count do
//			dice'.push(Faces.roll(rand))
//			c = c + 1
//		end
//		dice = recover val consume dice' end

	new val create(dice': Array[Face] val) =>
		dice = dice'

	fun count_for_face(face: Face): U8 =>
		var c: U8 = 0
		for f in dice.values() do
			if f is face then
				c = c + 1
			end
		end
		c

class val Bid
	let face: Face
	let count: U8

	new val create(count': U8, face': Face) =>
		count = count'
		face = face'

	fun eq(that: Bid): Bool =>
		compare(that) == Equal

	fun gt(that: Bid): Bool =>
		compare(that) == Greater

	fun box compare(that: Bid): Compare =>
		// if this is less than that, return 'Less'
		let fake_count = if face is FaceOne then count * 2 else count end
		let that_fake_count = if that.face is FaceOne then that.count * 2 else that.count end
		if (face is that.face) and fake_count.eq(that_fake_count) then return Equal end
		let c: Compare = fake_count.compare(that_fake_count)
		if c != Equal then return c end
		face().compare(that.face())

class _Player
	let pot: Pot val
	let player: Player

	new initial(player': Player, pot': Pot) =>
		player = player'
		pot = pot'

actor Game
	var _state: GameState = Start
	let _starting_players: Array[Player]
	var _players: Array[_Player]
	var _bid_history: Array[Bid] = Array[Bid](10)
	let _rand: Random

	new create(starting_players': Array[Player] iso) =>
		_starting_players = consume starting_players'
		_players = Array[_Player](_starting_players.size())
		(let a: I64, let b: I64) = Time.now()
		var rand: Random = Randoms()
		rand.u128() // discard the first result as it is predictable.
		// TODO rebuild _players; fun called from do_call
		_rand = rand
		for p in _starting_players.values() do
			_players.push(_Player.initial(p, Pots.create_pot(5, rand)))
		end

	be do_bid(from: Player tag, bid: Bid) =>
		match _state
		| let state: Turn =>
			try
				let last_bid = if _bid_history.size() == 0 then
						Bid(0, FaceOne) // this is the first bid of the round, set last_bid to min_bid
					else
						_bid_history(_bid_history.size()-1)?
					end
				// next player when (new bid > latest bid) OR this is the first bid
				let index = state.next_player
				let next_index = if (bid > last_bid) then
						_bid_history.push(bid)
						(index + 1) % _players.size()
					else
						index
					end
				_state = Turn(next_index)
				let history_copy: Array[Bid] iso = recover iso Array[Bid](10) end
				for b in _bid_history.values() do
					history_copy.push(b)
				end
				let next_player = _players(next_index)?
				next_player.player.do_bid(this, next_player.pot, consume history_copy)
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

	be do_call(from: Player tag) =>
		match _state
		| let state: Turn =>
			let last_bid = _last_bid_safe()
			var count: U8 = 0
			for p in _players.values() do
				count = count + p.pot.count_for_face(last_bid.face)
				if not (last_bid.face is FaceOne) then
					p.pot.count_for_face(FaceOne)
				end
			end
			// work out which of the players won the call
			let lost_player = if count < last_bid.count then
				// call was correct, previous bid was too high; previous player lost
				((state.next_player + _players.size()) - 1) % _players.size()
			else
				state.next_player
			end

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
					players'.push(_Player.initial(player.player, pot'))
				end
			end
			_players = players'

			_bid_history.clear()
			try
				let next_player = _players(next_index)?
				_state = Turn(next_index)
				next_player.player.do_bid(this, next_player.pot, recover val Array[Bid](0) end)
			end


		end
		// work out which of the players won the call
		// remove a die from that player
		// that player starts, unless they have 0 dice, in which case, the next player starts
		// when eliminating a player, remove them from the _players array.
		// Game ends when one player remaining
		// rebuild _players, fun also called from create
		// re-roll dice for remaining players
		// send do_bid to the starting player







