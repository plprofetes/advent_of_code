package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"


Dir :: enum {
	N,
	S,
	W,
	E,
}

p :: [2]int


print_elves :: proc(elves: ^map[p]int) -> int {
	min_x := 1000
	max_x := 0
	min_y := 1000
	max_y := 0

	for e, v in elves {
		if e.x < min_x {min_x = e.x}
		if e.y < min_y {min_y = e.y}
		if e.x > max_x {max_x = e.x}
		if e.y > max_y {max_y = e.y}
	}
	empty := 0
	for y := max_y; y >= min_y; y -= 1 {
		for x := min_x; x <= max_x; x += 1 {
			if p({x, y}) in elves {
				fmt.print("#")
			} else {
				fmt.print(".")
				empty += 1
			}
		}
		fmt.print("\n")
	}

	// count free spaces in the area
	return empty
}

part1 :: proc(lines: []string) {

	dir: [4]Dir = {Dir.N, Dir.S, Dir.W, Dir.E}

	elves := make(map[p]int) // current positions. Rewrite every step?

	for line, y in lines {
		if (line == "") {continue}
		for r, x in line {
			if r == '#' {
				// fmt.println("elf at", x, -y)
				elves[p({x, -y})] = 1
			}
		}
	}
	// fmt.println("Initial")
	val := 0 //;print_elves(&elves)

	ranges: [4][3]p = {
		{p{-1, 1}, p{0, 1}, p{1, 1}}, // N
		{p{-1, -1}, p{0, -1}, p{1, -1}}, // S
		{p{-1, -1}, p{-1, 0}, p{-1, 1}}, // W
		{p{1, 1}, p{1, 0}, p{1, -1}}, // E
	}

	for round := 0; round < 10; round += 1 {
		// fmt.println("start round", round + 1, " - going", dir[round % 4])

		moves := make(map[p]p) // dest -> src
		dups := make(map[p]int) // dest -> src
		defer delete(moves)
		defer delete(dups)

		// planning
		for e, _ in elves {
			alone := true
			a: for i := -1; i <= 1; i += 1 {
				for j := -1; j <= 1; j += 1 {
					if i == 0 && j == 0 {continue}
					if (e + p{i, j}) in elves {
						alone = false
						break a
					}
				}
			}
			if alone {continue} 	// if there are no elves around - dont move

			// find the unoccupied direction
			for i := 0; i < 4; i += 1 {
				range := ranges[(i + round) % 4]

				if (e + range[0]) not_in elves &&
				   (e + range[1]) not_in elves &&
				   (e + range[2]) not_in elves {

					// the field is clear
					d := dups[e + range[1]] //default: 0
					dups[e + range[1]] = d + 1

					moves[e] = e + range[1]
					break // no more moves
				}
			}
		}

		// moving
		// fmt.println(moves)

		for from, to in moves {
			d := dups[to]
			if d > 1 {continue} 	// nope, collision
			assert(d > 0)
			// actual move from -> to
			delete_key(&elves, from)
			elves[to] = 1
		}

		// fmt.println("After round", round + 1)
		// val = print_elves(&elves)
	}

	val = print_elves(&elves)
	fmt.println("part1:", val)
}

part2 :: proc(lines: []string) {
	dir: [4]Dir = {Dir.N, Dir.S, Dir.W, Dir.E}

	elves := make(map[p]int) // current positions. Rewrite every step?

	for line, y in lines {
		if (line == "") {continue}
		for r, x in line {
			if r == '#' {
				// fmt.println("elf at", x, -y)
				elves[p({x, -y})] = 1
			}
		}
	}
	// fmt.println("Initial")
	val := 0 //;print_elves(&elves)

	ranges: [4][3]p = {
		{p{-1, 1}, p{0, 1}, p{1, 1}}, // N
		{p{-1, -1}, p{0, -1}, p{1, -1}}, // S
		{p{-1, -1}, p{-1, 0}, p{-1, 1}}, // W
		{p{1, 1}, p{1, 0}, p{1, -1}}, // E
	}
	round := 0
	for {
		// fmt.println("start round", round + 1, " - going", dir[round % 4])

		moves := make(map[p]p) // dest -> src
		dups := make(map[p]int) // dest -> src
		defer delete(moves)
		defer delete(dups)

		// planning
		for e, _ in elves {
			alone := true
			a: for i := -1; i <= 1; i += 1 {
				for j := -1; j <= 1; j += 1 {
					if i == 0 && j == 0 {continue}
					if (e + p{i, j}) in elves {
						alone = false
						break a
					}
				}
			}
			if alone {continue} 	// if there are no elves around - dont move

			// find the unoccupied direction
			for i := 0; i < 4; i += 1 {
				range := ranges[(i + round) % 4]

				if (e + range[0]) not_in elves &&
				   (e + range[1]) not_in elves &&
				   (e + range[2]) not_in elves {

					// the field is clear
					d := dups[e + range[1]] //default: 0
					dups[e + range[1]] = d + 1

					moves[e] = e + range[1]
					break // no more moves
				}
			}
		}

		// moving
		// fmt.println(len(moves))
		if len(moves) == 0 {break}

		for from, to in moves {
			d := dups[to]
			if d > 1 {continue} 	// nope, collision
			assert(d > 0)
			// actual move from -> to
			delete_key(&elves, from)
			elves[to] = 1
		}

		// fmt.println("After round", round + 1)
		// val = print_elves(&elves)
		round += 1
	}

	// val = print_elves(&elves)
	fmt.println("part2:", round + 1)
}


main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
