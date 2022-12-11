package main

import "core:fmt"
import "core:math"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"



p :: [2]int

part1 :: proc(lines: []string) {

	curr : p = { 0, 0}
	h : p = { 0,0 }
	t : p = { 0,0 }

	visited := map[p]int{}
	defer delete(visited)

	for line in lines {
		if (line == "") {continue}

		strs := strings.split(line, " ")
		direction := strs[0]
		count, ok := strconv.parse_int(strs[1])

		x,y := 0,0
		switch direction {
			case "R": x = 1
			case "L": x = -1
			case "U": y = 1
			case "D": y = -1
		}
		for i := 0; i < count; i+= 1 {
			h[0] += x
			h[1] += y
			// fmt.println("head at", h[0], h[1])
			if (abs(t[0] - h[0]) > 1 || abs(t[1] - h[1]) > 1) {
				if (h[0] == t[0]) {
					// move tail on the y
					t[1] += y
				} else if (h[1] == t[1]) {
					// move tail on the y
					t[0] += x
				} else {
					// diagonals, move both axis
					if h[0] > t[0] {
						if h[1] > t[1] {
							// right up
							t[0] += 1
							t[1] += 1
						} else {
							// right down
							t[0] += 1
							t[1] -= 1
						}
					} else {
						// head is on the left
						if h[1] > t[1] {
							// left up
							t[0] -= 1
							t[1] += 1
						} else {
							// left down
							t[0] -= 1
							t[1] -= 1
						}
					}
				}
				// fmt.println("\ttail at", t[0], t[1])
				visited[t] += 1 // initializes at zero?
			}
		}
	}

	fmt.println("part1:", len(visited))
}

part2 :: proc(lines: []string) {

	curr : p = { 0, 0}
	rope : [10]p

	for i:= 0 ; i < len(rope); i+=1 {
		rope[i] = {0,0}
	}

	visited := map[p]int{}	// for the very tail
	defer delete(visited)

	moves := 0
	for line in lines {
		if (line == "") {continue}

		move, count := move(line)	// for head
		// fmt.println("move", move, count)
		for m:= 0; m < count; m+=1 {
			moves += 1

			rope[0] += move // yay, vectors!

			// move the body
			for i:= 1 ; i < len(rope); i+=1 {
				if i > moves {continue} // not exited the start

				// relative move:
				diff := rope[i-1] - rope[i]
				abs_diff : p = { abs(diff[0]), abs(diff[1])}

				if max(abs_diff[0], abs_diff[1]) > 1 {
					// gotta move
					if min(abs_diff[0], abs_diff[1]) == 0 {
						// one axis, repeat the move
						diff[0] = min(abs_diff[0], 1) * copy_sign(diff[0])
						diff[1] = min(abs_diff[1], 1) * copy_sign(diff[1])
						rope[i] += diff
					} else {
						// normalize diagonals
						diff[0] = diff[0] > 0 ? 1 : -1
						diff[1] = diff[1] > 0 ? 1 : -1
						rope[i] += diff
					}
				}
			} // knots
			// fmt.println("\t1 at", rope[1])
			visited[rope[9]] += 1 // initialized at zero?
			// fmt.println("Tail:", rope[9]) // initializes at zero?
		} // moves
	} // lines

	// fmt.println(visited)
	fmt.println("part2:", len(visited))
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}

copy_sign :: proc(i:int) -> int {
	copy_sign := 0
	if i == 0 {
		copy_sign = 0
	}
	else if i > 0 {
		copy_sign = 1
	}
	else {
		copy_sign = -1
	}
	return copy_sign
}


move :: proc(line:string) -> (p, int) {
	m : p = {0,0}

	strs := strings.split(line, " ")
	direction := strs[0]
	count, ok := strconv.parse_int(strs[1])

	x,y := 0,0
	switch direction {
		case "R": x = 1
		case "L": x = -1
		case "U": y = 1
		case "D": y = -1
	}
	m[0] = x
	m[1] = y

	return m, count
}
