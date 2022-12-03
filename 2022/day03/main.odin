package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "../lib"

find_dups :: proc(left: string, right: string) -> rune {
	find_dups := ' '

	for a in left {
		for b in right {
			if a == b {
				find_dups = a
				break
			}
		}
	}
	return find_dups
}

find_badge :: proc(b1: string, b2: string, b3: string) -> rune {
	find_badge := ' '
	for a in b1 {
		for b in b2 {
			for c in b3 {
				if a == b && b == c {
					find_badge = a
					break
				}
			}
		}
	}
	return find_badge
}

to_priority :: proc(r: rune) -> int {
	num := int(r)
	to_priority := 0
	switch num {
		case 97..=122:
			to_priority = num - 96
		case 65..=90:
			to_priority = num - 64 + 26
		case:
			to_priority = 0
	}
	return to_priority
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

	dups: [dynamic]rune = {}
	cnt := 0

	groups: queue.Queue(string)
	queue.init(&groups)

	badges: [dynamic]rune = {}

	for {
		line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer

		if (err != io.Error.None) {
			break
		}

		trimmed := strings.trim_right(line, "\r\n")

		mid := len(trimmed) / 2
		left := trimmed[0:mid]
		right := trimmed[mid:]

		// fmt.println("read: ", left, right)

		both := find_dups(left, right)
		append(&dups, both)

		queue.push_back(&groups,trimmed)
		if queue.len(groups) == 3 {
			// fmt.println(groups)
			l1 := queue.pop_front(&groups)
			l2 := queue.pop_front(&groups)
			l3 := queue.pop_front(&groups)

			badge := find_badge(l1, l2, l3)

			append(&badges, badge)
			assert(queue.len(groups) == 0)

			delete(l1)
			delete(l2)
			delete(l3)
		}

		cnt += 1
	}
	fmt.println("dups:", dups)
	fmt.println("badges:", badges)
	sum := 0
	for x in dups {
		// fmt.print(x, to_priority(x), "| ")
		sum += to_priority(x)
	}
	fmt.println("part1:", sum)

	sum2 := 0
	for x in badges {
		// fmt.print(x, to_priority(x), "| ")
		sum2 += to_priority(x)
	}
	fmt.println("part2:", sum2)
}
