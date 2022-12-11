package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"
import "core:strings"
import "core:container/queue"
import "core:strconv"
import "../lib"

cpu :: struct {
	cycle: int, // TODO: uint, try transmuting
	x: int,
	io: ^int,
	crt: [240]rune,
}

init_cpu :: proc (cpu: ^cpu, io: ^int) {
	cpu^.cycle = 0
	cpu^.x = 1
	cpu^.io = io
}
cpu_noop :: proc(cpu: ^cpu) {
	crt(cpu)
	cpu^.cycle += 1
	debug(cpu, cpu^.io)
}
cpu_add :: proc(cpu: ^cpu, value: int) {
	crt(cpu)
	cpu^.cycle += 1
	debug(cpu, cpu^.io)
	crt(cpu)
	cpu^.cycle += 1
	debug(cpu, cpu^.io)
	cpu^.x += value
}
cpu_dump :: proc(cpu: ^cpu) {
	fmt.println(cpu^)
}
crt_dump :: proc(cpu: ^cpu) {
	fmt.println()
	for i:= 0; i< len(cpu^.crt); i+=1 {
		if i > 0 && (i % 40 == 0) {
			fmt.println()
		}
		fmt.print(cpu^.crt[i])
	}
	fmt.println()
}

debug :: proc(cpu: ^cpu, io: ^int) {
	if cpu.cycle == 20 || ((cpu.cycle -20) % 40) == 0 {
		sig_str := cpu.cycle * cpu.x
		fmt.println("debug,", cpu.cycle, cpu.x, sig_str)
		io^ += sig_str
	}
}
crt :: proc(cpu: ^cpu) {
	sprite_start := cpu.x - 1
	sprite_end := cpu.x + 1
	// crt
	if (cpu.cycle % 40) >= sprite_start && (cpu.cycle % 40) <= sprite_end {
		cpu^.crt[cpu.cycle] = '#'
	} else {
		cpu^.crt[cpu.cycle] = '.'
	}
}

part1 :: proc(lines: []string) {

	cpu : cpu = {}
	debug := 0
	init_cpu(&cpu, &debug)

	for line in lines {
		if (line == "") {continue}

		cmd := strings.split(line, " ")

		switch cmd[0] {
			case "noop":
				cpu_noop(&cpu)
			case "addx":
				val, ok := strconv.parse_int(cmd[1])
				cpu_add(&cpu, val)
		}
	}

	// cpu_dump(&cpu)
	fmt.println("part1:", debug)
	fmt.println("part2:")
	crt_dump(&cpu)
}

main :: proc() {
	fmt.println("Helope!")

	file := lib.read_lines("input.txt")
	defer delete(file)

	part1(file)
}
