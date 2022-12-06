package main

import "core:fmt"
import "core:strings"
import "core:container/small_array"
import "../lib"

buffer_to_s2 :: proc(buffer: ^small_array.Small_Array($N/$Number, rune)) -> string {
	bld := strings.builder_make()
	defer strings.builder_destroy(&bld)
	for i in 0 ..= small_array.len(buffer^) - 1 {
		// fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
		strings.write_rune(&bld, small_array.get(buffer^, i))
	}
	return strings.clone(strings.to_string(bld))
}

part1 :: proc(lines: []string) {
	input := lines[0]
	ary: small_array.Small_Array(4, rune)

	uniq := false
	checks :=0
	for l in input {
		checks += 1
		ok := true
		small_array.push_back(&ary, l)
		// fmt.println("len", small_array.len(ary))
		if small_array.len(ary) < 4 {continue}

		for i := 0; i < 4; i += 1 {
			for j := 0; j < 4; j += 1 {
				if i == j {continue}
				// fmt.println(small_array.get(ary, i), "vs", small_array.get(ary, j))
				if small_array.get(ary, i) == small_array.get(ary, j) {
					ok = false
					small_array.pop_front(&ary)
					break
				}
			}
			if !ok {break}
		}
		if !ok {continue}
		uniq = true
		if uniq {break}
	}

	fmt.println("part1:", buffer_to_s2(&ary), "steps:", checks)
}

part2 :: proc(lines: []string) {
	input := lines[0]
	ary: small_array.Small_Array(14, rune)

	uniq := false
	checks :=0
	for l in input {
		checks += 1
		ok := true
		small_array.push_back(&ary, l)
		// fmt.println("len", small_array.len(ary))
		if small_array.len(ary) < 14 {continue}

		for i := 0; i < 14; i += 1 {
			for j := 0; j < 14; j += 1 {
				if i == j {continue}
				// fmt.println(small_array.get(ary, i), "vs", small_array.get(ary, j))
				if small_array.get(ary, i) == small_array.get(ary, j) {
					ok = false
					small_array.pop_front(&ary)
					break
				}
			}
			if !ok {break}
		}
		if !ok {continue}
		uniq = true
		if uniq {break}
	}

	fmt.println("part2:", buffer_to_s2(&ary), "steps:", checks)
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
