package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

part1 :: proc(lines: []string) {

	done := make(map[string]int)

	loop: for {
		for line in lines {
			if (line == "") {continue}
			parts := strings.split(line, " ")
			id := strings.trim_right(parts[0], ":")
			// fmt.println(line)
			if id in done {continue}

			if len(parts) == 2 {
				val, ok := strconv.parse_int(parts[1])
				done[id] = val
			} else if len(parts) == 4 {
				id1 := parts[1]
				id2 := parts[3]
				op := parts[2]

				if id1 in done && id2 in done {
					val := 0
					switch op {
					case "+":
						val = done[id1] + done[id2]
					case "-":
						val = done[id1] - done[id2]
					case "*":
						val = done[id1] * done[id2]
					case "/":
						val = done[id1] / done[id2]
					}
					done[id] = val
					if id == "root" {break loop}
				}
			} else {
				assert(false, "should not happen")
			}
		}
	}

	fmt.println("part1:", done["root"])
}


// test ok, stack overflow for prod
// solution: rewrite equations and go from the bottom
solve_for :: proc(str: string, lines: []string, db: ^map[string]int) -> int {
	if str in db {
		// fmt.print(".")
		return db[str]
	} // all single values are already in map
	// or else: find line and
	// parts := strings.split(line, " ")
	// 		id := strings.trim_right(parts[0], ":")
	// 		// fmt.println(line)
	// 		if id in done {continue}

	// 		if len(parts) == 2 {
	// 			val, ok := strconv.parse_int(parts[1])
	// 			done[id] = val

	for line in lines {
		if (line == "") {continue}
		if strings.has_prefix(line, str) &&
		   len(strings.split(line, " ")) == 2 {assert(false, "todo")}
		if !strings.has_prefix(line, str) && strings.contains(line, str) {

			parts := strings.split(line, " ")
			id := strings.trim_right(parts[0], ":")
			left := parts[1]
			right := parts[3]
			op := parts[2] // it's + in my case, TODO do proper switch here

			bLeft := left == str
			res: int
			if bLeft {
				// left = id ~op right
				switch op {
				case "+":
					res = solve_for(id, lines, db) - solve_for(right, lines, db)
				case "-":
					res = solve_for(id, lines, db) + solve_for(right, lines, db)
				case "*":
					res = solve_for(id, lines, db) / solve_for(right, lines, db)
				case "/":
					res = solve_for(id, lines, db) * solve_for(right, lines, db)
				}
			} else {
				// str == R
				switch op {
				case "+":
					res = solve_for(id, lines, db) - solve_for(left, lines, db)
				case "-":
					res = solve_for(left, lines, db) - solve_for(id, lines, db)
				case "*":
					res = solve_for(id, lines, db) / solve_for(left, lines, db)
				case "/":
					res = solve_for(left, lines, db) / solve_for(id, lines, db)
				}
			}
			db[str] = res
			return res
		}
	}
	assert(false)
	return 0
}

// test ok, stack overflow for prod
// solution: iterative?
rewrite_for_rec :: proc(
	str: string,
	lines: []string,
	db: ^[dynamic]string,
	curr: ^map[string]int,
) {
	for line in lines {
		if (line == "") {continue}
		if (str in curr) {
			// dont duplicate
			return
		}
		if strings.has_prefix(line, str) && len(strings.split(line, " ")) == 2 {
			append(db, line)
			return
		}
		if !strings.has_prefix(line, str) && strings.contains(line, str) {

			parts := strings.split(line, " ")
			id := strings.trim_right(parts[0], ":")
			left := parts[1]
			right := parts[3]
			op := parts[2] // it's + in my case, TODO do proper switch here

			bLeft := left == str
			res: [5]string = {str, ": ", "", "", ""}
			newOp: string
			if bLeft {
				// left = id ~op right
				res[2] = id
				res[4] = right
				switch op {
				case "+":
					newOp = " - "
				case "-":
					newOp = " + "
				case "*":
					newOp = " / "
				case "/":
					newOp = " * "
				}
			} else {
				// str == R
				switch op {
				case "+":
					res[2] = id
					res[4] = left
					newOp = " - "
				case "-":
					res[2] = left
					res[4] = id
					newOp = " - "
				case "*":
					res[2] = id
					res[4] = left
					newOp = " / "
				case "/":
					res[2] = left
					res[4] = id
					newOp = " / "
				}

			}
			res[3] = newOp
			str, err := strings.join_safe(res[:], "")
			append(db, str)
			rewrite_for(res[2], lines, db, curr)
			rewrite_for(res[4], lines, db, curr)
			break
		}
	}
}

// test ok, production too slow.
// solution: another approach?
rewrite_for :: proc(item: string, lines: []string, db: ^[dynamic]string, curr: ^map[string]int) {

	queue := make([dynamic]string)
	defer delete(queue)

	safety := make(map[string]int)

	append(&queue, item)

	for {
		if (len(queue) == 0) {break}
		str := pop_front(&queue)

		// fmt.println("processing ", str, "queue size", len(queue))
		for line in lines {
			if (line == "") {continue}
			if (str in curr) { 	// humn in there
				// dont duplicate
				break
			}
			if strings.has_prefix(line, str) && len(strings.split(line, " ")) == 2 {
				parts := strings.split(line, " ")
				val, ok := strconv.parse_int(parts[1])
				curr[str] = val
				// assert(false, "impossible")
				break
			}
			if !strings.has_prefix(line, str) && strings.contains(line, str) {
				parts := strings.split(line, " ")
				id := strings.trim_right(parts[0], ":")
				// if id in curr {  break } // bad optimization
				left := parts[1]
				right := parts[3]
				op := parts[2]

				bLeft := left == str
				res: [5]string = {str, ": ", "", "", ""}
				newOp: string
				if bLeft {
					// if (right in curr && id in curr) {
					// 	v := 0
					// 	switch op {
					// 	case "+":
					// 		v = curr[id] - curr[right]
					// 	case "-":
					// 		v = curr[id] + curr[right]

					// 	case "*":
					// 		v = curr[id] / curr[right]
					// 	case "/":
					// 		v = curr[id] * curr[right]
					// 	}
					// 	curr[str] = v
					// } else {
					// left = id ~op right
					res[2] = id
					res[4] = right
					switch op {
					case "+":
						newOp = " - "
					case "-":
						newOp = " + "
					case "*":
						newOp = " / "
					case "/":
						newOp = " * "
					}
					res[3] = newOp
					s, err := strings.join_safe(res[:], "")
					append(db, s)
					s1, ok1 := strings.clone_safe(res[2])
					s2, ok2 := strings.clone_safe(res[2])


					if !(s1 in safety) {
						safety[s1] = 1
						append(&queue, s1)
					}
					if !(s2 in safety) {
						safety[s2] = 1
						append(&queue, s2)
					}
					// }
				} else {
					// str == R
					switch op {
					case "+":
						res[2] = id
						res[4] = left
						newOp = " - "
					case "-":
						res[2] = left
						res[4] = id
						newOp = " - "
					case "*":
						res[2] = id
						res[4] = left
						newOp = " / "
					case "/":
						res[2] = left
						res[4] = id
						newOp = " / "
					}

					// if (left in curr && id in curr) {
					// 	v := 0
					// 	switch op {
					// 	case "+":
					// 		v = curr[id] - curr[left]
					// 	case "-":
					// 		v = curr[left] - curr[id]

					// 	case "*":
					// 		v = curr[id] / curr[left]
					// 	case "/":
					// 		v = curr[left] / curr[id]
					// 	}
					// 	curr[str] = v
					// } else {
					res[3] = newOp
					s, err := strings.join_safe(res[:], "")
					append(db, s)
					s1, ok1 := strings.clone_safe(res[2])
					s2, ok2 := strings.clone_safe(res[2])
					if !(s1 in safety) {
						safety[s1] = 1
						append(&queue, s1)
					}
					if !(s2 in safety) {
						safety[s2] = 1
						append(&queue, s2)
					}
					// }
				}

			}
		}
	}
}

rewrite_solve :: proc(item: string, lines: []string, db: ^[dynamic]string, curr: ^map[string]int) {
	// so the idea is that we have all the equations. If we know 2 out of 3 elements we can compute the third.
	// feed the curr with results and try to solve next one.
	// add some safeguards


}

part2 :: proc(lines: []string) {
	left, right: string
	for line in lines {
		if strings.has_prefix(line, "root:") {
			parts := strings.split(line, " ")

			left = parts[1]
			right = parts[3]
			op := parts[2] // + in test and prod data
			break
		}
	}

	// fmt.println(left, right)

	done := make(map[string]int)
	rootL, rootR: int = 0, 0

	loop: for {
		for line in lines {
			if line == "" {continue}
			if strings.has_prefix(line, "humn: ") {continue}

			parts := strings.split(line, " ")
			id := strings.trim_right(parts[0], ":")
			// fmt.println(line)
			if id in done {continue}

			if len(parts) == 2 {
				val, ok := strconv.parse_int(parts[1])
				done[id] = val
			} else if len(parts) == 4 {
				id1 := parts[1]
				id2 := parts[3]
				op := parts[2]

				if id == "root" && (id1 in done || id2 in done) {
					// either of these can be true, but just once
					if id1 in done {
						// fmt.println("root L=", done[id1])
						done[id2] = done[id1]
						rootL = done[id1]
					}
					if id2 in done {
						// fmt.println("root R=", done[id2])
						done[id1] = done[id2]
						rootR = done[id2]
					}
					break loop
				}
				if id1 in done && id2 in done {

					val := 0
					switch op {
					case "+":
						val = done[id1] + done[id2]
					case "-":
						val = done[id1] - done[id2]
					case "*":
						val = done[id1] * done[id2]
					case "/":
						val = done[id1] / done[id2]
					}
					done[id] = val
				}
			} else {
				assert(false, "should not happen")
			}
		}
	}

	// fmt.println(rootL, rootR)
	// fmt.println(done[left], done[right])

	q := rootL == 0 ? left : right // that part need to be solved
	delete_key(&done,"root")

	// transform the queries to solve for humn. All data is given now.
	// patched := make([dynamic]string)
	// res := solve_for("humn", lines, &done)
	// fmt.println("fjcf", done["fjcf"], "fjvm", done["fjvm"], "tcmj", done["tcmj"])

	// fmt.println("rewriting...")

	// SOLUTION RATIONALE:
	// rewrite must be constatnt. For each line get values that are availabile.
	// if there are 2 - figure out the 3rd.
	//
	// rewrite_for("humn", lines, &patched, &done)

	// fmt.println("rewritten", len(patched), patched)

	delete_key(&done, "humn")

	// fmt.println("fjcf", done["fjcf"], "fjvm", done["fjvm"], "tcmj", done["tcmj"])

	loop2: for {
		hit := false
		for line in lines {
			if (line == "") {break}
			parts := strings.split(line, " ")
			id := strings.trim_right(parts[0], ":")
			if id == "humn" {continue}

			if len(parts) == 2 {
				val, ok := strconv.parse_int(parts[1])
				if id in done {continue}
				done[id] = val
				hit = true
			} else if len(parts) == 4 {
				hit = true

				id1 := parts[1]
				id2 := parts[3]
				op := parts[2]

				known := 0
				if id in done {known += 1}
				if id1 in done {known += 1}
				if id2 in done {known += 1}
				if (known == 2) {
					// let's convert equation to get the third value
				} else if known == 3 {
					continue
				} else if known < 2 {
					// assert(false)
					continue
				}
				unknown := id in done ? (id1 in done ? 'r' : 'l') : 'e'
				// fmt.println("solving ", unknown, line, done[id], done[id1], done[id2])
				solution: string
				switch unknown {
				case 'e':
					// just compute
					done[id] = eval(done[id1], done[id2], op)
					solution = id
				case 'l':
					newOp: string
					switch op {
					case "+":
						newOp = "-"
					case "-":
						newOp = "+"
					case "*":
						newOp = "/"
					case "/":
						newOp = "*"
					}
					done[id1] = eval(done[id], done[id2], newOp)
					solution = id1
				case 'r':
					switch op {
					case "+":
						done[id2] = eval(done[id], done[id1], "-")
					case "-":
						done[id2] = eval(done[id1], done[id], "-")
					case "*":
						done[id2] = eval(done[id], done[id1], "/")
					case "/":
						done[id2] = eval(done[id1], done[id], "/")
					}
					solution = id2
				}
				// fmt.println("solved: ", solution, done[solution])

				if solution == "humn" {
					// assert(false)
					break loop2
				}
			} else {
				fmt.println(line)
				assert(false, "should not happen")
			}
		}
		assert(hit, "nothing happened")
	}

	fmt.println("part2:", done["humn"])
	// to be efficient - lines should be a hashmap I guess
}

eval :: proc(a: int, b: int, op: string) -> int {
	eval := 0
	switch op {
	case "+":
		eval = a + b
	case "-":
		eval = a - b
	case "*":
		eval = a * b
	case "/":
		eval = a / b
	}
	// fmt.println("\t", a, op, b)
	return eval
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
