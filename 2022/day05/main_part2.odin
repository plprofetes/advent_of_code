package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

update_stacks :: proc(line: string, stacks: [9]^queue.Queue(rune)) {
	ndx := 0
	for i := 1; i < len(line); i += 4 {
		r := rune(line[i])
		if r != ' ' {
			queue.push_back(stacks[ndx], r) // copy?
			// fmt.println("put ", r, "under stack ", ndx + 1)
		}

		ndx += 1
	}
}

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

	// prepare stacks
	stacks: [9]^queue.Queue(rune)
	for i in 0 ..= 8 {
		q := new(queue.Queue(rune))
		queue.init(q)
		stacks[i] = q
	} // remember to free it later

	for {
		// read the stacks
		line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer
		defer delete(line)
		trimmed := strings.trim_right(line, "\r\n")

		if trimmed[1] == '1' {
			// fmt.println("end of stack input")
			break
		}

		update_stacks(trimmed, stacks)
	}
	for i in 0 ..= 8 {
		// fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
	}
	// fmt.println(stacks[0]^)
	assert((queue.peek_front(stacks[0])^) == 'W')

	// one more line
	line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer
	defer delete(line)

	// operations. Stacks are single digit, so it can be indexed by position
	for {
		line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer
		if (err != io.Error.None) {
			break
		}
		trimmed := strings.trim_right(line, "\r\n")
		// move 2 from 8 to 2
		split := strings.split(trimmed, " ")
		times, err1 := strconv.parse_int(split[1])
		from, err2 := strconv.parse_int(split[3])
		to, err3 := strconv.parse_int(split[5])

		buffer: queue.Queue(rune)
		queue.init(&buffer)

		for i := 0; i < times; i += 1 {
			queue.push_front(&buffer, queue.pop_front(stacks[from - 1]))
			// fmt.println("moving ", from, "to buffer")
		}
		for i := 0; i < times; i += 1 {
			queue.push_front(stacks[to - 1], queue.pop_front(&buffer))
			// fmt.println("moving from buffer", "to", to)
		}
	}
	bld := strings.builder_make()
	defer strings.builder_destroy(&bld)
	for i in 0 ..= 8 {
		// fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
		strings.write_rune(&bld, queue.peek_front(stacks[i])^)
	}
	fmt.println("part2:", strings.to_string(bld))

}
