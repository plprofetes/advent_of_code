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

stack_tops :: proc(stacks: [9]^queue.Queue(rune)) -> string {
	bld := strings.builder_make()
	defer strings.builder_destroy(&bld)
	for i in 0 ..= 8 {
		// fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
		strings.write_rune(&bld, queue.peek_front(stacks[i])^)
	}
	return strings.clone(strings.to_string(bld))
}

// TODO: build_stacks :: proc(lines: []string) {
//   guess width
//}

part1 :: proc(lines: []string) {

	// prepare stacks
	stacks: [9]^queue.Queue(rune)
	for i in 0 ..= 8 {
		q := new(queue.Queue(rune))
		queue.init(q)
		stacks[i] = q
	}
	defer {for i in 0 ..= 8 {queue.destroy(stacks[i])}}

	for line in lines {
		if line[1] == '1' {
			// fmt.println("end of stack input")
			break
		}
		update_stacks(line, stacks)
	}

	// for i in 0 ..= 8 {
	// 	fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
	// }
	// fmt.println(stacks[0]^)
	assert((queue.peek_front(stacks[0])^) == 'W')

	// operations. Stacks are single digit, so it can be indexed by position
	skip := true
	for line in lines {
		if (skip) {
			// fmt.println(line)
			if (line == "") {skip = false}
			continue

		}
		if (line == "") {continue} 	// end line, middle line, etc

		// move 2 from 8 to 2
		split := strings.split(line, " ")
		times, err1 := strconv.parse_int(split[1])
		from, err2 := strconv.parse_int(split[3])
		to, err3 := strconv.parse_int(split[5])

		buffer: queue.Queue(rune)
		queue.init(&buffer)

		for i := 0; i < times; i += 1 {
			// fmt.println("moving ", from, "to", to)
			queue.push_front(stacks[to - 1], queue.pop_front(stacks[from - 1]))
		}
	}
	fmt.println("part1:", stack_tops(stacks))
}

part2 :: proc(lines: []string) {
	// prepare stacks
	stacks: [9]^queue.Queue(rune)
	for i in 0 ..= 8 {
		q := new(queue.Queue(rune))
		queue.init(q)
		stacks[i] = q
	}
	defer {for i in 0 ..= 8 {queue.destroy(stacks[i])}}

	for line in lines {
		if line[1] == '1' {
			// fmt.println("end of stack input")
			break
		}
		update_stacks(line, stacks)
	}

	// for i in 0 ..= 8 {
	// 	fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
	// }
	// fmt.println(stacks[0]^)
	assert((queue.peek_front(stacks[0])^) == 'W')

	// operations. Stacks are single digit, so it can be indexed by position
	skip := true
	for line in lines {
		if (skip) {
			// fmt.println(line)
			if (line == "") {skip = false}
			continue
		}
		if (line == "") {continue}

		// move 2 from 8 to 2
		split := strings.split(line, " ")
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
	fmt.println("part2:", stack_tops(stacks))
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
