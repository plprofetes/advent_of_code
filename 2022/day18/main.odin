package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

v3 :: [3]int
neighbors: [6]v3 = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}}

part1 :: proc(lines: []string) {

	world := make(map[v3]int)
	defer delete(world)
	for line in lines {
		if (line == "") {continue}
		pts := strings.split(line, ",")
		x, _ := strconv.parse_int(pts[0])
		y, _ := strconv.parse_int(pts[1])
		z, _ := strconv.parse_int(pts[2])
		world[v3{x, y, z}] = 1
	}

	sum := 0
	for p, _ in world {
		contacts := 0
		for n in neighbors {
			if (p + n) in world {contacts += 1}
		}
		sum += 6 - contacts
	}

	fmt.println("part1:", sum)
}

// Fun!
part2 :: proc(lines: []string) {
	world := make(map[v3]int)
	defer delete(world)

	for line in lines {
		if (line == "") {continue}
		pts := strings.split(line, ",")
		x, _ := strconv.parse_int(pts[0])
		y, _ := strconv.parse_int(pts[1])
		z, _ := strconv.parse_int(pts[2])
		world[v3{x, y, z}] = 1
	}

	// are air cubes also 1x1x1? if so - it's easy,
	// because one has to check just one more cube in every direction
	// and subtract 6 from the sum for every bubble
	// LATER:
	// no, air bubbles are not 1x1x1. Test passes, but prod not.
	// is it convex or concave?

	// air_candidates := make(map[v3]int) // to reduce duplicates. I cant do sets here.
	// defer delete(air_candidates)

	min_x, min_y, min_z, max_x, max_y, max_z := 100, 100, 100, 0, 0, 0 // world size

	sum := 0
	for p, _ in world {
		if p.x < min_x do min_x = p.x
		if p.y < min_y do min_y = p.y
		if p.z < min_z do min_z = p.z
		if p.x > max_x do max_x = p.x
		if p.y > max_y do max_y = p.y
		if p.z > max_z do max_z = p.z

		contacts := 0
		for n in neighbors {
			if world[p + n] == 1 {contacts += 1} else {
				// it might be air bubble
				// air_candidates[p + n] = 2
			}
		}
		sum += 6 - contacts
	}
	// fmt.println("world size", min_x, min_y, min_z, max_x, max_y, max_z)

	// let's check if it's internal or external:
	// 		* recursively expand each bubble until we hit end of world or lava
	// 		* dedup as well, if we encounter bubbles already exported
	//		* on return call mark area as external air
	//	  * compute the wall area of this new shape
	// or maybe just slice 2d 3 times
	// or maybe start in 0,0,0 and discover the external shape?
	// BFS search? A* towards 10,10,10?

	// Does not work:
	// for a, _ in air_candidates {
	// 	contacts := 0
	// 	for n in neighbors {
	// 		if world[a + n] == 1 {contacts += 1} else {break}
	// 	}
	// 	fmt.println("air bubble has", contacts, "contacts with lava")
	// 	if contacts == 6 {
	// 		fmt.println("single air bubble at", a)
	// 		sum -= 6
	// 	} else if contacts > 0 {
	// 		fmt.println("TODO: open bubble at", a)
	// 	}
	// }


	// BFS it is!
	queue := make([dynamic]v3)
	defer delete(queue)

	visited := make(map[v3]int)
	defer delete(visited)

	// make space to walk around the shape
	min := v3{min_x, min_y, min_z} - v3{1, 1, 1}
	max := v3{max_x, max_y, max_z} + v3{1, 1, 1}

	append(&queue, v3{min_x, min_y, min_z} - v3{1, 1, 1})
	sum2 := 0

	for {
		if len(queue) == 0 do break

		item := pop_front(&queue)
		if (item) in visited do continue // can this be optimized?
		visited[item] = 1

		// fmt.println("checking what's at", item)
		assert(world[item] != 1)
		// if world[item] == 1 do continue // should not ever happen

		for n in neighbors {
			if !is_valid(item + n, min, max) do continue
			// is it lava?
			if world[item+n] == 1 {
				// it's lava!
				sum2 += 1
			} else {
				// it must be air. Check it later
				append(&queue, item + n)
			}
		}
	}

	fmt.println("part2:", sum2)
}

// is it in world bounds?
is_valid :: proc(v: v3, min: v3, max: v3) -> bool {
	return(
		v.x >= min.x &&
		v.y >= min.y &&
		v.z >= min.z &&
		v.x <= max.x &&
		v.y <= max.y &&
		v.z <= max.z
	)
	// NOTE: vector math in Odin should support vectoriwise comparison!
	// NOTE: and spat operator
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
