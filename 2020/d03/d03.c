#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static int LINE_LENGTH = 31;

void clear_line(char *line)
{
  for (int i = 0; i < LINE_LENGTH; ++i)
    line[i] = 0;
}

int main(int argc, char **argv)
{
  printf("hello day3!\n");

  FILE *fp = fopen("in.txt", "r");
  if (fp == 0)
  {
    printf("Cannot open file in.txt\n");
    exit(1);
  }

  char line[LINE_LENGTH];
  int pos = 0;
  int c;

  uint_least32_t count_tree = 0;
  int offset = 0;
  int line_no = -1;
  while (1)
  {
    c = getc(fp);
    // printf("%d\n", c);
    if (c == '\n' || c == EOF)
    {
      line_no++;
      if(line_no == 0) {
        pos=0;
        continue;
      }
      // check if we bumped into a tree
      offset = (offset + 3) % (LINE_LENGTH);
      // printf("Line %d offset %d, hit: %c, line %s\n", line_no, offset, line[offset], line);

      if (line[offset] == '#')
        count_tree += 1;
      
      if (c == EOF)
        break;
      pos = 0;
      // clear_line(line);
    }
    else if (c == '\r')
    {
      // ignore
      continue;
    } else {
      line[pos++] = c;
    }
  }
  fclose(fp);

  printf("Part1: %d\n", count_tree);
  // printf("Part2: %d\n", correct2);
  return 0;
}
