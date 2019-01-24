

class val Bid
	let face: Face
	let count: U8

	new val create(count': U8, face': Face) =>
		count = count'
		face = face'

	fun string(): String =>
		count.string() + " " + face.string()

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


