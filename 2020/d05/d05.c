#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// AoC tip - always read data from file to some struct!
// calloc zeroes the memory.

static int LINE_LENGTH = 10;

void clear_line(char *line)
{
  for (int i = 0; i < LINE_LENGTH; ++i)
    line[i] = 0;
}

int to_id(char *str)
{
  uint8_t row = 0x0;
  // it's binary encoded 7bit.
  for (int i = 0; i < 7; i++)
  {
    //find proper level in uint8
    if (str[i] == 'B')
      row |= 1u << (6 - i);
  }
  // nor left/right
  // printf("%s is row %d\n", str, row);
  uint8_t seat = 0x0;
  for (int i = 7; i < 10; i++)
  {
    if (str[i] == 'R')
    {
      seat |= 1u << (2 - i + 7); // 2,1,0
    }
  }
  // printf("\tand column is %d\n", seat);
  return (uint32_t)row * 8 + seat;
}

int main(int argc, char *argv[])
{

  printf("hello day5!\n");
  if (argc != 2)
  {
    printf("Usage: %s filename\n", argv[0]);
    exit(1);
  }

  char buffer[LINE_LENGTH];
  size_t pos = 0;
  // Reuse buffer.
  FILE *fp = fopen(argv[1], "r");
  if (fp == 0)
  {
    printf("Cannot open file %s\n", argv[1]);
    exit(2);
  }
  printf("reading %s file into memory...", argv[1]);

  // TODO: extract to function and library
  char **contents;             // of size LINE_LENGTH +1.
  uint32_t lines = 0;          //for the one with EOF at least
  size_t contents_size = 1000; // no realloc needed
  contents = calloc(contents_size, sizeof(char *));

  char c;
  // BUG: on EOF, if buffer is not empty - one line is skipped
  while ((c = getc(fp)) != EOF)
  {
    if (c == '\r')
    {
      continue;
    }
    if (c == '\n')
    {
      contents[lines] = calloc(LINE_LENGTH + 1, sizeof(char));
      memcpy(contents[lines], buffer, LINE_LENGTH);
      lines++;
      pos = 0;
      continue;
    }
    buffer[pos++] = c;
  }
  fclose(fp);
  printf("read: %d\n", lines);

  int max_id = 0;
  int ids[1000] = {0}; // because I know max now

  for (int i = 0; i < lines; i++)
  {
    int curr_id = to_id(contents[i]);
    ids[curr_id] = 1;
    if (curr_id > max_id)
    {
      max_id = curr_id;
    }
  }
  printf("Part1: %d\n", max_id); // 904

  for (int i = 1; i < (max_id - 1); i++)
  {
    if ((1 == ids[i - 1]) && (1 == ids[i + 1]) && (ids[i] == 0))
    {
      printf("Part2: %d\n", i); // 669
    }
  }

  return 0;
}
