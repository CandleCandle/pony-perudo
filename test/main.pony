

use "ponytest"
use "../perudo"

actor Main is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestBidCompare(Equal, 4, FaceTwo, 4, FaceTwo, "eq"))
		test(_TestBidCompare(Greater, 5, FaceTwo, 4, FaceTwo, "gt/count"))
		test(_TestBidCompare(Greater, 4, FaceThree, 4, FaceTwo, "gt/face"))
		test(_TestBidCompare(Less, 4, FaceFive, 5, FaceFive, "lt/count"))
		test(_TestBidCompare(Less, 4, FaceFive, 4, FaceSix, "lt/face"))
		test(_TestBidCompare(Greater, 4, FaceOne, 7, FaceSix, "gt/ones/0"))
		test(_TestBidCompare(Less, 7, FaceSix, 4, FaceOne, "lt/ones/1"))
		test(_TestBidCompare(Less, 4, FaceOne, 8, FaceTwo, "lt/ones/2"))
		test(_TestBidCompare(Greater, 8, FaceTwo, 4, FaceOne, "lt/ones/3"))

class iso _TestBidCompare is UnitTest
	let _suffix: String
	let _expected: Compare
	let _c0: U8
	let _f0: Face
	let _c1: U8
	let _f1: Face
	new iso create(expected: Compare, c0: U8, f0: Face, c1: U8, f1: Face, suffix: String) =>
		_suffix = suffix
		_expected = expected
		_c0 = c0
		_f0 = f0
		_c1 = c1
		_f1 = f1
	fun name():String => "bid/compare/" + _suffix
	fun apply(h: TestHelper) =>
		h.assert_eq[Compare](_expected, Bid(_c0, _f0).compare(Bid(_c1, _f1)))

