package lib

import "core:os"
import "core:fmt"
import "core:strings"
import "core:testing"

// Read the file
read_lines :: proc(filename: string = "input.txt") -> []string {
	data, success := os.read_entire_file_from_filename(filename)
	if !success {
		// could not read file
		return {}
	}

	str := string(data)
	ret := strings.split(str, "\n")
	// delete(data)
	return ret[0:len(ret)-1]
}
// read_grid :: proc(filename: string = "input.txt") -> [][]string {
// 	data, success := os.read_entire_file_from_filename(filename)
// 	if !success {
// 		// could not read file
// 		return {}
// 	}

// 	str := string(data)
// 	ret := strings.split(str, "\n")
// 	// delete(data)
// 	return ret
// }


// m := make([][10]int, 5)
// fmt.printf("len(m): %d \n", len(m))
// fmt.printf("len(m[0]): %d \n", len(m[0]))

make_2d_slice :: proc(y, x: int, $T: typeid, allocator := context.allocator) -> (res: [][]T) {
	assert(x > 0 && y > 0)
	context.allocator = allocator

	backing := make([]T, x * y)
	res      = make([][]T, y)

	for i in 0..<y {
			res[i] = backing[x * i:][:x]
	}
	return
}

delete_2d_slice :: proc(slice: [][]$T, allocator := context.allocator) {
	delete(slice[0], allocator)
	delete(slice,    allocator)
}

@(test)
_test_simple_const_false :: proc(t: ^testing.T) {
	data := read_lines("lib.odin")
	testing.expect_value(t, data[0], "package lib")
	fmt.println("data[0]", data[0])
	delete(data)

	data2 := read_lines("blah.foo")
	testing.expect(t, len(data2) == 0)
	delete(data2)
}
