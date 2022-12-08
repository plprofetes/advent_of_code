package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

SIZE :: 99

part1 :: proc(lines: []string) {

	// how many sides are visible?
	grid : [SIZE][SIZE]int = {}
	visibility : [SIZE][SIZE]int = {}
	for i:= 0; i < SIZE; i+=1 {
		for j:= 0; j < SIZE; j+=1 {
			grid[i][j]=-1
			if i == 0 || j == 0 || i == SIZE - 1 || j == SIZE - 1 {
				visibility[i][j]=4 // always visible from outside
			} else {
				visibility[i][j]=0
			}
		}
	}
	for i:=0; i<len(lines);i+=1{
		line := lines[i]
		if line == "" {continue}
		for j:=0; j < len(line); j+=1 {
			ch := line[j:j+1]
			v, ok := strconv.parse_int(ch)
			grid[i][j] = v
		}
	}

	// TODO: code below should be wrapped in a proc

	// left to right
	for i:= 0; i < SIZE; i+=1 {
		max := -1
		for j:= 0; j < SIZE; j+=1 {
			v := grid[i][j]
			if v > max {
				// fmt.println("L", i,j,v,max)
				max = v
				visibility[i][j] +=1
				if v == 9 {break}
			}
		}
	}
	// top to bottom
	for i:= 0; i < SIZE; i+=1 {
		max := -1
		for j:= 0; j < SIZE; j+=1 {
			v := grid[j][i]
			if v > max {
				max = v
				visibility[j][i] +=1
				if v == 9 {break}
			}
		}
	}
	// righth to left
	for i:= 0; i < SIZE; i+=1 {
		max := -1
		for j:= SIZE - 1; j >= 0; j-=1 {
			v := grid[i][j]
			if v > max {
				max = v
				visibility[i][j] +=1
				if v == 9 {break}
			}
		}
	}
	// bottom to top
	for i:= SIZE - 1; i >= 0; i-=1 {
		max := -1
		for j:= SIZE - 1; j >= 0; j-=1 {
			v := grid[j][i]
			if v > max {
				max = v
				visibility[j][i] +=1
				if v == 9 {break}
			}
		}
	}

	// find >=1
	sum := 0
	for i:= 0; i < SIZE; i+=1 {
		for j:= 0; j < SIZE; j+=1 {
			if visibility[i][j] >= 1  { sum += 1}
		}
	}
	// fmt.println(grid)
	// fmt.println(visibility)
	fmt.println("part1:", sum)

	// well, it's possible to do:
	s : []int = grid[0][:]
	sum2 := 0
	for i:= 0; i < SIZE; i+=1 {
		for j:= 0; j < SIZE; j+=1 {

			score := vis(i, j, &grid)
			// fmt.println("score:",i,j,score)

			if score >= sum2  { sum2 = score}
		}
	}

	fmt.println("part2:", sum2)
}

vis :: proc(x: int, y: int, grid: ^[SIZE][SIZE]int) -> int {
	row := grid^[x][:]
	col := grid^[:][y] // nope. this does not select a column!
	v := grid^[x][y]

	up, down, left, right := 0,0,0,0
	// fmt.println("testing",x,y,v, row, col)
	for i:=1; x+i<SIZE; i+=1 {
		right +=1
		// fmt.println("R",i)
		if grid^[i+x][y] >= v {break }
	}
	for i:=1; x-i>=0; i+=1 {
		left += 1
		// fmt.println("L",i, row[x-i])
		if grid^[x-i][y] >= v { break }
	}
	for i:=1; y+i<SIZE; i+=1 {
		// fmt.println("U",i)
		up += 1
		if grid^[x][i+y] >= v { break }
	}
	for i:=1; y-i>=0; i+=1 {
		down += 1
		// fmt.println("D",i)
		if grid^[x][y-i] >= v { break }
	}

	// fmt.println("\tres: ",up , down , left , right)
	return up * down * left * right
}

part2 :: proc(lines: []string) {
	for line in lines {
		if (line == "") {continue}
	}
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
	part2(file)
}
