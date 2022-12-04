package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:strconv"
import "../lib"

main :: proc() {
	fmt.println("Helope!")

	fd, e := os.open("input.txt")
	defer os.close(fd)

	if (e != os.ERROR_NONE) {
		fmt.eprintln("Error opening file:", e)
	}
	file_stream := os.stream_from_handle(fd)
	defer io.destroy(file_stream)

	reader := io.Reader{file_stream}

	br: bufio.Reader
	bufio.reader_init(&br, reader) // NOTE: allocates a buffer; there's also `reader_init_with_buf` to supply your own buffer instead.
	defer bufio.reader_destroy(&br)

	cnt := 0
	sum := 0
	sum2 := 0
	for {
		line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer
		defer delete(line)
		if (err != io.Error.None) {
			break
		}

		trimmed := strings.trim_right(line, "\r\n")
		fmt.println(trimmed)
		elves := strings.split(trimmed, ",")
		assert(len(elves) == 2)

		left := strings.split(elves[0], "-")
		right := strings.split(elves[1], "-")
		assert(len(left) == 2)
		assert(len(right) == 2)

		fmt.println(left, right)
		left_from, err1 := strconv.parse_int(left[0])
		left_to, err2 := strconv.parse_int(left[1])
		right_from, err3 := strconv.parse_int(right[0])
		right_to, err4 := strconv.parse_int(right[1])
		// fmt.println("read: ", left, right)
		assert(err1 && err2 && err3 && err4)
		fmt.println(left_from, left_to, right_from, right_to)

		// part2:
		if (max(left_from, right_from) <= min(left_to, right_to)) {
			sum2 += 1
		}

		// part1:
		if (left_from <= right_from) {
			if (left_to >= right_to) {
				sum += 1
				fmt.println("r in l")
				continue // dont count this case twice!
			}
		}
		if (right_from <= left_from) {
			if (right_to >= left_to) {
				sum += 1
				fmt.println("l in r")
			}
		}

		cnt += 1
	}
	fmt.println("part1:", sum)
	fmt.println("part2:", sum2)
}
