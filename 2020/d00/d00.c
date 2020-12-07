#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef uint_least32_t u32;

int main(int argc, char **argv)
{
  printf("hello!\n");

  FILE *fp = fopen("in.txt", "r");
  if (fp == 0)
  {
    printf("Cannot open file in.txti\n");
    exit(1);
  }
  u32 input[200];
  int lines = 0;
  char line[5] = {0, 0, 0, 0, 0};
  int digit = 0;
  int c;

  while (1)
  {
    c = getc(fp);
    // printf("%d\n", c);
    if (c == '\r')
    {
      continue;
    }
    if (c == '\n' || c == EOF)
    {
      // next
      input[lines++] = atoi(line);
      for (int j = 0; j < digit; j++)
      {
        line[j] = 0;
      }
      digit = 0;
      if (c == EOF)
        break;
    }
    line[digit++] = c;
  }
  fclose(fp);

  printf("File loaded with %d lines\n", lines);
  // for (int i = 0; i < lines; ++i)
  // {
  //   printf("%0d: %d\n", i, input[i]);
  // }

  int found = 0;
  for (int outer = 0; outer < lines; ++outer)
  {
    for (int inner = 0; inner < lines; ++inner)
    {
      if (inner == outer)
        continue;
      if (input[inner] + input[outer] == 2020)
      {
        printf("Part1: %d*%d=%d\n", input[outer], input[inner], input[outer] * input[inner]);
        found = 1;
        break;
      }
    }
    if (found)
      break;
  }

  found = 0;
  for (int external = 0; external < lines; ++external)
  {
    for (int outer = 0; outer < lines; ++outer)
    {
      for (int inner = 0; inner < lines; ++inner)
      {
        if (inner == outer || inner == external || outer == external)
          continue;
        if (input[external] + input[inner] + input[outer] == 2020)
        {
          printf("Part2: %d*%d*%d=%d\n", input[external], input[outer], input[inner], input[external] * input[outer] * input[inner]);
          found = 1;
          break;
        }
      }
      if (found)
        break;
    }
    if (found)
      break;
  }

  return 0;
}
