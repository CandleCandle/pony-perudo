use "random"

class val Pot
	let dice: Array[Face] val

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

	fun string(): String =>
		recover val
			let s = String
			for d in dice.values() do
				if (s.size() > 0) then s.append(" ") end
				s.append(d.string())
			end
			s
		end

primitive Pots
	fun create_pot(count: U8, rand: Random ref): Pot val =>
		let a: Array[Face] iso = recover iso Array[Face](count.usize()) end
		var i: U8 = 0
		while i < count do
			a.push(Faces.roll(rand))
			i = i + 1
		end
		Pot.create(recover val consume a end)

	fun with_different_size(pot: Pot, change: I32, rand: Random): (None | Pot val) =>
		let new_size: I32 = pot.dice.size().i32() + change
		if new_size <= 0 then return None end
		create_pot(new_size.u8(), rand)

