CFLAGS = -Wall -g -std=c11 -Wpedantic

all: *.c
	$(CC) $(CFLAGS) -O2 *.c -o solution

valgrind: all
	valgrind --tool=memcheck --leak-check=yes ./solution