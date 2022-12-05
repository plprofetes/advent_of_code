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
	return ret
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
