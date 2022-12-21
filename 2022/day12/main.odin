package main

import "core:fmt"
import "core:mem"
import "core:math"
import "core:testing"
import "core:strings"
import "core:strconv"
import "../lib"

p :: [2]int

dist :: proc(x: p, y: p) -> f32 {
	d := (x.x - y.x) * (x.x - y.x) + (y.y - x.y) * (y.y - x.y)
	return math.sqrt((f32)(d))
}

check_candidate :: proc(lines: []string, c: p, h: int) -> bool {
	check_candidate := false
	if c.x >= 0 && c.y >= 0 && c.x < len(lines[0]) && c.y < len(lines) {
		ch := (int)(lines[c.y][c.x])
		if ch == 69 {ch = 122} 	// E

		// fmt.println("In grid:", c, "h:", ch, "vs", h)
		check_candidate = ch - 1 <= h
	}
	return check_candidate
}

search :: proc(start: p, lines: []string) -> int {

	length := len(lines[0])

	target: p = {0, 0}

	for line, i in lines { 	//y
		for j in 0 ..= len(line) - 1 { 	//x
			if line[j] == 'E' {
				target.x = j
				target.y = i
				// optimize: parse height here
				break
			}
		}
	}
	// fmt.println(start, target)
	// fmt.println("map is ", len(lines[0]), "x", len(lines))

	// A* algorithm. Or Dijksta?
	node :: struct {
		point:     p,
		parent:    p,
		cost:      f32, // approximate cost for prioritizin nodes from open queue
		real_cost: f32, // not needed.
		done:      bool, // not needed.
	}
	// dont deallocate, plz

	// put that into a map.
	// track points in dynamic arrays
	// insert processed node into a map, insert queues for candidates.

	open := make([dynamic]node)
	start_node: node = {start, start, dist(start, target), 1, true}
	append(&open, start_node)
	tree := make(map[p]node)

	search: for {
		if len(open) == 0 {break}
		// fmt.println("open queue before:", open)

		// get node closest to the target. It should be a priority list sorted by that value...
		c: node = open[0]
		ndx: int = 0
		for n, i in open {
			// TODO: bug: cost function is different?
			if n.cost < c.cost {
				c = n
				ndx = i
			}
		}
		// swap and pop
		tmp := open[0]
		open[0] = open[ndx]
		open[ndx] = tmp
		c = pop_front(&open)
		// fmt.println("open queue after:", open)
		// fmt.println("analyzing:", c.point, "with est. cost", c.cost, "h: ", lines[c.point.y][c.point.x])

		// insert into the tree
		tree[c.point] = node({c.point, c.parent, c.cost, c.real_cost + 1, true})
		// remove from all queues, already done in the beginning.

		if c.point == target {
			// fmt.println("Target reached")
			// insert target to the map
			break search
		}

		// analyze possible next steps
		// left, right, up, down if index allows and slope is not too steep
		current_h := (int)(lines[c.point.y][c.point.x]) // S is bad!
		if current_h == 83 {current_h = 97}
		if current_h == 69 {current_h = 122}

		// find candidatess
		cs := make([dynamic]p)
		defer delete(cs)

		append(&cs, p({c.point.x + 1, c.point.y}))
		append(&cs, p({c.point.x - 1, c.point.y}))
		append(&cs, p({c.point.x, c.point.y + 1}))
		append(&cs, p({c.point.x, c.point.y - 1}))

		for n in cs {
			// fmt.println("Checking candidate", n, "from", c.point)
			if check_candidate(lines, n, current_h) {
				// fmt.println("Analyzing candidate ", n)

				if n in tree {
					// fmt.println("Already processed", n)
					continue
				} // already processed

				d := dist(n, target) // add or replace in open queue
				found := false
				for q, i in open {
					if n != q.point {continue}
					found = true

					if d + c.cost < q.cost {
						// fmt.println("Found cheaper path to", n)
						// update queue
						open[i].cost = d + c.cost
						open[i].parent = c.point
						open[i].real_cost = c.real_cost
					}
					break
				}
				if !found {
					// insert
					// fmt.println("Append to open:", n, "cost:", c.cost + d)
					append(&open, node({n, c.point, c.cost + d, c.real_cost, false}))
				}
			}
		}

		// fmt.println("Processed", c.point)
	}
	// fmt.println(tree)
	// backtrack from target and count steps
	path := make([dynamic]node)
	current := tree[target]
	for {
		// fmt.println("backtracking", current)
		append(&path, current)
		if current.parent == current.point {break}
		assert(current.parent in tree)
		current = tree[current.parent]
	}



	defer delete(path)
	delete(tree)
	delete(open)

	return len(path) - 1
}

part1 :: proc(lines: []string) {

	start: p = {0, 0}
	for line, i in lines { 	//y
		for j in 0 ..= len(line) - 1 { 	//x
			if line[j] == 'S' {
				start.x = j
				start.y = i
				// optimize: parse height here
				break
			}
		}
	}

	fmt.println("part1:", search(start, lines))
}

part2 :: proc(lines: []string) {

	result := 1_000_000_000
	for line, i in lines { 	//y
		for j in 0 ..= len(line) - 1 { 	//x
			if line[j] == 'S' || line[j] == 'a' {
				start: p = {j, i}
				cost := search(start, lines)
				// fmt.println(cost)
				if cost > 0 && cost < result { result = cost}
			}
		}
	}

	fmt.println("part2:", result)
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}


@(test)
_test_simple_const_false :: proc(t: ^testing.T) {
	testing.expect_value(t, dist({1, 1}, {4, 5}), 5.0)
	testing.expect_value(t, dist({-1, -1}, {-4, -5}), 5.0)
}
