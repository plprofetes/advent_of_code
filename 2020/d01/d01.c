#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef enum stage
{
  LO,
  HI,
  LTR,
  PASS
} stage_t;

typedef struct
{
  uint_least8_t lo;
  uint_least8_t hi;
  char letter;
} rule_t;

static int LINE_LENGTH = 50;

void clear_line(char *line)
{
  for (int i = 0; i < LINE_LENGTH; ++i)
    line[i] = 0;
}

int valid_pass(rule_t *r, char *line, int length)
{
  // printf("checking if %c exists from %d to %d times in %p\n", r->letter, r->lo, r->hi, &line);
  int count = 0;
  for (int i = 0; i < length; ++i)
  {
    if (line[i] == r->letter)
      ++count;
  }
  return count >= r->lo && count <= r->hi;
}

int valid_pass2(rule_t *r, char *line, int length)
{
  // lo +1 is the first index, hi + 1 is the second index.
  // printf("checking if %c=%c xor %c=%c\n", r->letter, line[r->lo - 1], r->letter, line[r->hi - 1]);
  return (r->letter == line[r->lo - 1]) ^ (r->letter == line[r->hi - 1]);
}

int main(int argc, char **argv)
{
  printf("hello day2!\n");

  FILE *fp = fopen("in.txt", "r");
  if (fp == 0)
  {
    printf("Cannot open file in.txt\n");
    exit(1);
  }

  char line[LINE_LENGTH];
  int pos = 0;
  int c;

  rule_t curr = {.hi = 0, .lo = 0};
  stage_t step = LO;
  int correct = 0;
  int correct2 = 0;

  while (1)
  {
    c = getc(fp);
    // printf("%d\n", c);
    if (c == '\n' || c == EOF)
    {
      // verify password
      if (valid_pass(&curr, line, pos))
        correct += 1;
      if (valid_pass2(&curr, line, pos))
        correct2 += 1;

      if (c == EOF)
        break;

      // reset stuff
      step = LO;
      pos = 0;
    }
    else if (c == '\r')
    {
      // ignore
      continue;
    }

    line[pos++] = c;
    switch (step)
    {
    case LO:
      if (c == '-')
      {
        //we're done
        curr.lo = atoi(line);
        step = HI;
        clear_line(line);
        pos = 0;
      }
      break;
    case HI:
      if (c == ' ')
      {
        curr.hi = atoi(line);
        step = LTR;
        clear_line(line);
        pos = 0;
      }
      break;
    case LTR:
      if (c == ':')
      {
        curr.letter = line[0];
        step = PASS;
        clear_line(line);
        pos = 0;
      }
      break;
    case PASS:
      if (c == ' ')
      {
        pos = 0; // rewrite this
      }          // sooner or later we'll get into \n or EOF. Check pass there.
      break;
    default:
      break;
    }
  }
  fclose(fp);

  printf("Part1: %d\n", correct);
  printf("Part2: %d\n", correct2);
  return 0;
}
