package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "core:testing"

import "../lib"

LIMIT :: 100_000
NEEDED :: 8_381_165

path :: proc(q: ^queue.Queue(string)) -> string {
	strs: [dynamic]string = {}
	defer delete(strs)
	for i in 0 ..= queue.len(q^) - 1 {
		// fmt.println("stack", i + 1, " top value:", queue.peek_front(stacks[i])^)
		append(&strs, queue.get(q, i))
	}
	path := strings.join(strs[:], "/")

	return strings.clone(path)
}

is_child :: proc(base: string, suspect: string) -> bool {
	is_child := false
	raw_base := strings.split(base, "/")
	raw_suspect := strings.split(suspect, "/")

	// fmt.println(strings.has_prefix(suspect, base), len(raw_base), len(raw_suspect))
	// fmt.println(raw_base, raw_suspect)
	is_child = len(raw_base) == (len(raw_suspect) - 1) && strings.has_prefix(suspect, base)

	delete(raw_base)
	delete(raw_suspect)

	return is_child
}

part1 :: proc(lines: []string) {

	my_map := map[string]int{}
	defer delete(my_map)

	// recursive approach would be nice, pass queue/list made of lines and reference to the map.
	// otherwise - we have a state machine. NO! we have parser and then post-processing. Dumb!

	curr_path: queue.Queue(string)
	queue.init(&curr_path)
	defer queue.destroy(&curr_path)

	dirs: [dynamic]string = {}

	for line in lines {
		if (line == "") {continue}

		// fmt.println(line)

		if strings.has_prefix(line, "$ cd") {
			dest := strings.clone(strings.split(line, " ")[2])
			if dest == ".." {
				// fmt.println("\tgo up!")
				queue.pop_back(&curr_path) // actually go up
				prefix := path(&curr_path)
				// fmt.println("\tcwd ", prefix)
			} else {
				// fmt.println("\tgo down ", dest)
				queue.push_back(&curr_path, dest)
				prefix := path(&curr_path)
				append(&dirs, prefix)
				// fmt.println("\tcwd ", prefix)
				my_map[prefix] = 0 // will be updated later
			}
		} else if (line == "$ ls") {
		} else {
			if strings.has_prefix(line, "dir") {
			} else {
				// file!
				parts := strings.split(line, " ")
				size, ok := strconv.parse_int(parts[0])
				queue.push_back(&curr_path, strings.clone(parts[1]))
				path := path(&curr_path)
				my_map[path] = size
				queue.pop_back(&curr_path)
				// fmt.println(path, size)
			}
		}
	}

	// fmt.println(dirs)
	// fmt.println(my_map)

	big_sum := 0
	min_dir := NEEDED*100 // just to have some space
	for i := len(dirs) - 1; i > 0; i -= 1 {
		sum := 0
		// check the size
		// sooooo ineffective... but there is no Regexp in Odin currently
		for key, value in my_map {
			// wtf, no regex in Odin?
			if is_child(dirs[i], key) {
				// fmt.println("\tChild found:", key, "-", value)
				sum += value
			}
		}
		my_map[dirs[i]] = sum
		if sum < LIMIT {
			big_sum += sum
		}
		if sum >= NEEDED && sum < min_dir {
			min_dir = sum
		}

	}
	fmt.println("part1:", big_sum)
	fmt.println("part2:", min_dir)
}


main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file) // and part2
}

@(test)
_test_simple_const_false :: proc(t: ^testing.T) {
	testing.expect(t, is_child("/a", "/a/b"))
	testing.expect(t, !is_child("/a", "/a/b/c"))
	testing.expect(t, !is_child("/a", "/a/b/c/d"))
}
