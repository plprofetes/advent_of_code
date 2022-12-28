package main

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:math"
import "core:testing"
import "core:strings"
import "core:strconv"
import "../lib"

// approach: represent world safe places in hash with v3: {x,y,z}, where z is gen number.
// Generate data lazily, store newest generation only.
// A* with possible wait (cost just increases)

v2 :: [2]int
v3 :: [3]int

Dir :: enum {
	L, // <
	R, // >
	U, // ^
	D, // v,
}

DEBUG :: false

dir2vec :: proc(d: Dir) -> v2 {
	p: v2
	switch d {
	case Dir.L:
		p = v2{-1, 0}
	case Dir.R:
		p = v2{1, 0}
	case Dir.U:
		p = v2{0, 1}
	case Dir.D:
		p = v2{0, -1}
	}
	return p
}

dir2s :: proc(d: Dir) -> rune {
	s: rune
	switch d {
	case Dir.L:
		s = '<'
	case Dir.R:
		s = '>'
	case Dir.U:
		s = '^'
	case Dir.D:
		s = 'v'
	}
	return s
}

world :: struct {
	gen:   int,
	w:     int,
	h:     int,
	safe:  map[v3]int,
	state: map[v2]Dir,
}

world_init :: proc(w: ^world, input: []string) {
	w.gen = 0
	w.w = len(input[0])
	w.h = len(input)

	w.safe = make(map[v3]int) // lazily evaluated with word_gen(_, gen)
	w.state = make(map[v2]Dir) // initial locations of blizzards and their direction

	for line, y in input {
		for pos, x in line {
			// {0,0} is in lower left corner, because modulo in odin can be negative
			if line[x] == '#' do continue
			if pos == '.' do continue
			p := v2{x, w.h - y - 1}

			// switch on pos
			switch pos {
			case '<':
				w.state[p] = Dir.L
			case '>':
				w.state[p] = Dir.R
			case '^':
				w.state[p] = Dir.U
			case 'v':
				w.state[p] = Dir.D
			}
		}
	}
}

world_gen :: proc(w: ^world) {
	// generate a round of the world
	// fmt.println(w)

	m := lib.make_2d_slice(w.w, w.h, rune)
	defer lib.delete_2d_slice(m)

	for k, v in w.state {
		// get initial pos, add generations, modulo, corrections...
		unit := dir2vec(v)
		unit *= w.gen
		// fmt.println(unit)
		unit += k
		if v == Dir.L || v == Dir.R {
			unit.x = ((unit.x - 1) % (w.w - 2)) + 1
			if unit.x <= 0 do unit.x += w.w - 2
		} else {
			unit.y = ((unit.y - 1) % (w.h - 2)) + 1 // y=1
			if unit.y <= 0 do unit.y += w.h - 2
		}
		// fmt.println(k, g, "*", v, "->", unit)
		assert(unit.x != 0)
		assert(unit.x != w.w - 1)
		assert(unit.y != 0)
		assert(unit.y != w.h - 1)
		m[unit.x][unit.y] = dir2s(v)
		// for each point - check if it's safe
	}

	for y := 0; y < w.h; y += 1 {
		for x := 0; x < w.w; x += 1 {
			if (x == 0 || x == w.w - 1) && DEBUG {fmt.print("#");continue}
			if (y == 0 || y == w.h - 1) && DEBUG {fmt.print("#");continue}
			val := m[x][w.h - y - 1]
			if val != 0 {
				if DEBUG do fmt.print(val)
			} else {
				if DEBUG do fmt.print(" ")
				p := v3{x, w.h - y - 1, w.gen}
				w.safe[p] = 1 // the only thing that needs to have generations available.
			}
		}
		if DEBUG do fmt.print("\n")
	}

	if DEBUG {
		for s in w.safe {
			if s.z == w.gen {
				fmt.println("safe:", s)
			}
		}
		fmt.print("\n")
	}

	w.gen += 1 //get ready for next one. Not nice at all.
}

// for prioritizing node picking
dist :: proc(x: v2, y: v2) -> f32 {
	d := (x.x - y.x) * (x.x - y.x) + (y.y - x.y) * (y.y - x.y)
	return math.sqrt((f32)(d))
}

// basic bounds check for step in gen+1, without start and end.
// @param: gen: current generation
check_spot :: proc(w: ^world, c: v2, gen: int) -> (ok: bool) {
	// without side walls, start, end
	ok = c.x > 0 && c.y > 0 && c.x < w.w - 1 && c.y < w.h - 1
	if ok {
		p := v3{c.x, c.y, gen + 1} // will it be safe there next turn
		ok = p in w.safe // cheaper to add walls to exclude list?
		// if ok {fmt.println("\tsafe:", c)}
	}
	return
}

// next node to evaluate
get_next :: proc(open: ^[dynamic]node, end: v2) -> node {
	c: node = open[0]
	ndx: int = 0
	cost: f32 = f32(c.cost) + dist(c.point, end)
	for n, i in open {
		if f32(n.cost) + dist(n.point, end) < cost {
			// heuristics to promote nodes closer to the end
			c = n
			ndx = i
			cost = f32(n.cost) + dist(n.point, end)
		}
	}
	// swap and pop. Could be rewritten to pop_end for efficiency
	tmp := open[0]
	open[0] = open[ndx]
	open[ndx] = tmp
	c = pop_front(open)
	// fmt.println("open queue after:", open)
	// fmt.println("analyzing:", c.point, "with est. cost", c.cost)
	return c
}

node :: struct {
	point:  v2,
	parent: v2,
	cost:   int, // steps
	// wait time?
	// gen: int,		// what generation does this live right now? == steps?
}

// A* algorithm with temporal features and wait operation.
search :: proc(start: v2, end: v2, w: ^world, init_cost: int = 0) -> int {

	// distance/cost heuristics are computed online and applied each time. Node only tracks steps so far
	// all we care is the cheapest cost to reach each tile

	// track points in dynamic arrays
	// insert processed node into a map, insert queues for candidates.
	open := make([dynamic]node) // temporal aspect hidden in cost.
	start_node: node = {start, start, init_cost}
	// fmt.println(start_node, end)
	append(&open, start_node)
	tree := make(map[v3]node) // cost of getting to point v2 in gen z. Aka visited nodes

	end_node: node

	search: for gen in 0 ..= 100000000 { 	// it's more or less steps, because gen is written per node. Limit for safety.
		// dont sweep nodes that were destroyed by blizzard, just dont insert them.
		// can the same points occupy different nodes from different time periods? Yes, so tree must be v3, with generation info.

		assert(len(open) > 0)
		// fmt.println("open queue before:", open)

		// get node closest to the target. It should be a priority list sorted by that value, if we needed efficiency
		c := get_next(&open, end)
		// fmt.println("picked: ", c)
		ver := v3{c.point.x, c.point.y, c.cost + 1}
		if ver in tree {continue} 	// v2 would not suffice, v3 is perfect.

		for {
			if w.gen > c.cost + 1 {break} 	// w.gen is incremented before that gen is generated. not nice.
			world_gen(w) // simulate safety space for next turn, lazily
		}

		// insert into the tree - this node is visited, it was the cheapest and closest to target so far.
		tree[ver] = node({c.point, c.parent, c.cost})
		// ver will not be analyzed anymore

		// analyze possible next steps
		// left, right, up, down if no blizzard there
		// find candidatess
		cs := make([dynamic]v2)
		defer delete(cs)

		append(&cs, v2({c.point.x + 1, c.point.y}))
		append(&cs, v2({c.point.x - 1, c.point.y}))
		append(&cs, v2({c.point.x, c.point.y + 1}))
		append(&cs, v2({c.point.x, c.point.y - 1}))

		for n in cs {
			if n == end {
				fmt.println("Target reached")
				end_node = node{n, c.point, c.cost + 1}
				break search
			}
			if n == start || check_spot(w, n, c.cost) { 	// sometimes one has to hide again on start tile
				// fmt.println("Analyzing candidate ", n)
				ver := v3{n.x, n.y, c.cost + 1}
				if ver in tree {continue}
				found := false
				for q, i in open {
					if n != q.point || c.cost + 1 != q.cost {continue}
					found = true

					// cost so far + approx cost to the end
					if c.cost < q.cost {
						// fmt.println("Found cheaper path to", n, "in gen", c.cost + 1)
						// it was cheaper to get there. Update the item in queue
						open[i].cost = c.cost + 1
						open[i].parent = c.point
					}
					break
				}
				if !found {
					// insert new item in open list.
					// fmt.println("Append to open:", n, "cost:", c.cost+1)
					append(&open, node({n, c.point, c.cost + 1}))
				}
			} else {
				// fmt.println("Candidate ", n, "not safe in gen", c.cost+1)
			}
			if c.point == start || check_spot(w, c.point, c.cost) { 	// maybe we can wait here?
				// still safe, let's wait, add cost
				// fmt.println("we can wait at", c)
				append(&open, node{c.point, c.point, c.cost + 1})
			} else {
				// fmt.println("we cannot wait at", c)
			}
		}
		// fmt.println("Processed", c.point)
	}
	// fmt.println(tree)
	// backtrack not possible, cost in .cost

	delete(tree)
	delete(open)

	return end_node.cost
}

part1 :: proc(lines: []string) {
	start: v2 = {0, 0}
	end: v2 = {0, 0}
	for x, i in lines[0] {
		if x == '.' {
			start.x = i
			start.y = len(lines) - 1
			break
		}
	}
	for x, i in lines[len(lines) - 1] {
		if x == '.' {
			end.x = i
			end.y = 0
			break
		}
	}
	fmt.println(start, end)

	w: world = {}
	world_init(&w, lines)

	cost1 := search(start, end, &w)
	fmt.println("part1:", cost1)

	cost2 := search(end, start, &w, cost1)
	cost3 := search(start, end, &w, cost2)
	fmt.println("part2:", cost3)
}

part2 :: proc(lines: []string) {

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
