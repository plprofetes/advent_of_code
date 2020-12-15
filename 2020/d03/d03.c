#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
// AoC tip - always read data from file to some struct!

// https://stackoverflow.com/questions/3087157/reading-a-file-with-variable-line-lengths-line-by-line-in-c
static int LINE_LENGTH = 31;

void clear_line(char *line)
{
  for (int i = 0; i < LINE_LENGTH; ++i)
    line[i] = 0;
}

typedef struct
{
  uint16_t width;
  uint16_t height;
  char *map;
  uint32_t size;
} map_t;

char map_contents(const map_t *mapref, uint16_t x, uint16_t y)
{
  if (x > mapref->width || y > mapref->height)
    return '\0';

  size_t pos = mapref->width * y + x;
  return mapref->map[pos];
}
void print_map(map_t *map)
{
  if (map == NULL)
    return;
  printf("Map has %d lines of %d chars. Allocated size: %d bytes\n", map->height, map->width, map->size);
  for (int line = 0; line < map->height; line++)
  {
    printf("%03d: ", line);
    for (int pos = 0; pos < map->width; pos++)
    {
      printf("%c", map_contents(map, pos, line));
    }
    printf("\n");
  }
}
map_t *load_file(const char *filename)
{
  // allocate each line, without line endings or EOFs
  // FIXME just read all the bytes directly to the map->map. No need to proxy it through this buffer!

  map_t *map = malloc(sizeof(map_t));
  map->size = 0;

  char buffer[256];
  size_t pos = 0;
  // Reuse buffer.
  FILE *fp = fopen(filename, "r");
  if (fp == 0)
  {
    printf("Cannot open file %s\n", filename);
    return (map_t *)NULL;
  }
  int lines = 0; //for the one with EOF at least
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
      lines++;
      if (map->size == 0)
      {
        // first line.
        map->width = pos;
        map->height = lines;
        map->map = malloc(sizeof(char) * map->width * 100);
        map->size = map->width * 100;
        printf("Allocated map: width %ld, lines %d, size: %d at %p\n", pos, lines, map->size, map->map);
      }
      else
      {
        if (lines == map->size / map->width)
        {
          // grow this
          printf("Reallocating map from %p, current size: %d\n", map->map, map->size);
          map->map = realloc(map->map, map->size + 100 * map->width);
          map->size += 100 * map->width;
          printf("Reallocated map to %p, current size: %d\n", map->map, map->size);
        }
      }
      // printf("copy buffer to map @ %p\n", map->map + sizeof(char) * (lines - 1) * map->width);
      memcpy(map->map + sizeof(char) * (lines - 1) * map->width, buffer, pos);
      map->height += 1;
      pos = 0; // no need to clear buffer, since all lines are the same length
    }
    else
    {
      buffer[pos] = c;
      pos++;
    }
  }
  fclose(fp);
  // print_map(map);
  return map;
}

uint64_t traverse(const map_t *map, uint8_t x, uint8_t y)
{
  uint64_t trees = 0;
  uint32_t offset = 0;

  for (int i = 0; i < map->height; i += y)
  {
    if (map_contents(map, offset, i) == '#')
      trees++;

    // printf("Line %d offset %d, hit: %c\n", i, offset, map_contents(map, offset, i));
    offset = (offset + x) % (map->width);
  }
  return trees;
}

int main(int argc, char **argv)
{

  printf("hello day3!\n");

  map_t *map = load_file("in.txt");
  if (map == NULL)
  {
    printf("Cannot open file in.txt. Exit!\n");
    exit(1);
  }

  uint64_t part1 = traverse(map, 3, 1); // 151
  printf("Part1: %ld\n", part1);

  uint64_t part2 = traverse(map, 1, 1);
  // printf("Part2(1,1) = %ld\n", part2);

  uint64_t partial = traverse(map, 3, 1);
  // printf("Part2(3,1) = %ld\n", partial);
  part2 *= partial;
  partial = traverse(map, 5, 1);
  // printf("Part2(5,1) = %ld\n", partial);
  part2 *= partial;
  partial = traverse(map, 7, 1);
  // printf("Part2(7,1) = %ld\n", partial);
  part2 *= partial;
  partial = traverse(map, 1, 2);
  // printf("Part2(1,2) = %ld\n", partial);
  part2 *= partial;
  printf("Part2: %ld\n", part2); // 7540141059

  free(map->map);
  free(map);
  return 0;
}

