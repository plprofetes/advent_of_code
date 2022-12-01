package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "../lib"
import "core:strings"
import "core:strconv"
import "core:sort"

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

	cals: [dynamic]int
	sum: int = 0
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
			// push to array
      // fmt.println("next Elf!")
			append(&cals, sum)
			sum = 0
			continue
		}
		num, parse_error := strconv.parse_int(trimmed)
    // fmt.println("parsed: ", num, "from", trimmed, ".")
		sum += num
	}
	fmt.println("Consumed data:", len(cals), "Elves, iters: ", cnt)

	max := 0
	for i in cals {
		if i > max {
			max = i
		}
	}
  fmt.println("Max:", max)

  sort.bubble_sort(cals[:])

  fmt.println("top3: ", cals[len(cals)-1]+cals[len(cals)-2]+cals[len(cals)-3])
}
