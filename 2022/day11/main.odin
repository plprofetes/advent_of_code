package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:math"
import "core:testing"
import "core:slice"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

monkey :: struct {
	id:      int,
	op:      proc(old: int) -> int,
	test:    int,
	success: int,
	failure: int,
}

M :: 8

gcd :: proc(num: int, rem: int) -> int {
	if rem == 0 {
		return num
	} else {
		return gcd(rem, num % rem)
	}
}

part1 :: proc(lines: []string) {

	monkeys: [M]monkey = {
		// test
		// {0, proc(old: int) -> int {return old * 19}, 23, 2, 3},
		// {1, proc(old: int) -> int {return old + 6}, 19, 2, 0},
		// {2, proc(old: int) -> int {return old * old}, 13, 1, 3},
		// {3, proc(old: int) -> int {return old + 3}, 17, 0, 1},

		// nwd? biggest common denominator?

		{0,	proc(old: int ) -> int { return old * 11}, 7, 6,2 },
		{1,	proc(old: int ) -> int { return old + 1}, 11, 5,0 },
		{2,	proc(old: int ) -> int { return old * 7}, 13, 4,3 },
		{3,	proc(old: int ) -> int { return old + 3}, 3, 1,7 },
		{4,	proc(old: int ) -> int { return old + 6}, 17, 3,7 },
		{5,	proc(old: int ) -> int { return old + 5}, 2, 0,6 },
		{6,	proc(old: int ) -> int { return old * old}, 5, 2,4 },
		{7,	proc(old: int ) -> int { return old + 7}, 19, 5,1 },
	}
	items: [M]^queue.Queue(int) // TODO: delete

	for i := 0; i < len(items); i += 1 {
		q := new(queue.Queue(int))
		queue.init(q)
		items[i] = q

		stuff: [dynamic]int
		defer delete(stuff)

		switch i {
		case 0:
			stuff = {63,57}
			// stuff = {79, 98}
		case 1:
			stuff = {82, 66, 87, 78, 77, 92, 83}
			// stuff = {54, 65, 75, 74}
		case 2:
			stuff = {97, 53, 53, 85, 58, 54}
			// stuff = {79, 60, 97}
		case 3:
			stuff = {50}
			// stuff = {74}
		case 4:
			stuff = {64, 69, 52, 65, 73}
		case 5:
			stuff = {57, 91, 65}
		case 6:
			stuff = {67, 91, 84, 78, 60, 69, 99, 83}
		case 7:
			stuff = {58, 78, 69, 65}
		}
		for n in stuff {
			queue.push_back(q, n)
		}
	}
	inspections: [8]int
	// defer queue.destroy(&m)

	reductor := 1;
	for m in monkeys {
		reductor *= m.test
	}

	for i := 0; i < 10000; i += 1 {
		for m := 0; m < M; m += 1 {
			for {
				item, ok := queue.pop_front_safe(items[m])
				if !ok {break}

				inspections[m] += 1

				// worry := monkeys[m].op(item) / 3 // part1
				worry := monkeys[m].op(item)  // part2

				receiver := -1
				test := worry % monkeys[m].test == 0
				if test {
					receiver = monkeys[m].success
				} else {
					receiver = monkeys[m].failure
				}
				// div := gcd(worry, monkeys[m].test)
				// lcm := worry * monkeys[m].test / div
				// lcm := math.lcm(worry, monkeys[m].test)
				// it needs to be done globally, not per-monkey
				// different monkeys divide in different ways

				queue.push_back(items[receiver], worry % reductor)
			}
		}
		// fmt.println(items)
	} // rounds

	fmt.println(inspections)
	s := inspections[:]
	slice.reverse_sort(s)
	fmt.println("part1:", s[0] * s[1])
}

part2 :: proc(lines: []string) {
	for line in lines {
		if (line == "") {continue}
	}

	fmt.println("part2:", 0)
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	// part2(file)
}


@(test)
_test_simple_const_false :: proc(t: ^testing.T) {
	testing.expect(t, gcd(20, 8) == 4)
	testing.expect(t, gcd(12, 2) == 2)
	testing.expect(t, gcd(100, 25) == 25)
}
