package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:sort"
import "../lib"

decision :: proc(their: string, strategy: string) -> string {
	// optimal: truth table:
	truth := [3][3]string{
		// X: loose, Y: draw, Z: win
		// dec:		 X,   Y    Z		// their:
		[3]string{"C", "A", "B"}, // A: Rock
		[3]string{"A", "B", "C"}, // B: paper
		[3]string{"B", "C", "A"}, // C: scissors
	}
	str_id := 0
	switch strategy {
		case "X": str_id = 0
		case "Y": str_id = 1
		case "Z": str_id = 2
	}
	th := 0
	switch their {
		case "A": th = 0
		case "B": th = 1
		case "C": th = 2
	}

	decision : string
	res := truth[th][str_id]
	// map decision to match api
	if (res == "A") {
		decision = "X"
	} else 	if (res == "B") {
		decision = "Y"
	} else 	if (res == "C") {
		decision = "Z"
	}
	return decision
}

score :: proc(their: string, mine: string) -> int {
	score := 0
	// shape points
	switch mine {
	case "X":
		score += 1
	case "Y":
		score += 2
	case "Z":
		score += 3
	}

	// draw
	if (their == "A" && mine == "X") {
		score += 3
	}
	if (their == "B" && mine == "Y") {
		score += 3
	}
	if (their == "C" && mine == "Z") {
		score += 3
	}

	// win conditions
	switch mine {
	case "X":
		// rock
		score += (their == "C" ? 6 : 0)
	case "Y":
		// paper
		score += (their == "A" ? 6 : 0)
	case "Z":
		// scissors
		score += (their == "B" ? 6 : 0)
	}
	// fmt.println("round:", their, "vs", mine, "=", score)

	return score
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

	sum: int = 0
	sum_real: int = 0
	cnt: int = 0
	for {
		cnt += 1
		line, err := bufio.reader_read_string(&br, '\n') // NOTE: allocates a new buffer
		if (err != io.Error.None) {
			break
		}
		trimmed := strings.trim_right(line, "\r\n")
		// fmt.println("read: ", trimmed)
		defer delete(line)
		if (len(trimmed) == 0) {
			fmt.println("empty line")
			continue
		}
		sum += score(trimmed[0:1], trimmed[2:])
		sum_real += score(trimmed[0:1], decision(trimmed[0:1],trimmed[2:]))
	}
	fmt.println("Score part1:", sum, "pts, iters: ", cnt)
	fmt.println("Score part2:", sum_real, "pts, iters: ", cnt)
}
