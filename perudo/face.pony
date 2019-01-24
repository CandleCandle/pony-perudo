use "random"

primitive FaceOne
	fun apply(): U8 => 0
	fun string(): String => "One"
primitive FaceTwo
	fun apply(): U8 => 1
	fun string(): String => "Two"
primitive FaceThree
	fun apply(): U8 => 2
	fun string(): String => "Three"
primitive FaceFour
	fun apply(): U8 => 3
	fun string(): String => "Four"
primitive FaceFive
	fun apply(): U8 => 4
	fun string(): String => "Five"
primitive FaceSix
	fun apply(): U8 => 5
	fun string(): String => "Six"
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


