#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

// Why C is not cool? Because it does not zero the memory on heap!

typedef struct
{
  char *byr;
  char *iyr;
  char *eyr;
  char *hgt;
  char *hcl;
  char *ecl;
  char *pid;
  char *cid;
} passport_t;

typedef struct
{
  passport_t **passports;
  size_t size;
  size_t count;
} passports_t;

passports_t *init_passports()
{
  passports_t *p = malloc(sizeof(passports_t));
  p->passports = malloc(100 * sizeof(passport_t *)); // should check for NULL, but..
  p->size = 100;
  p->count = 0;
  return p;
}
void dealloc_passports(passports_t *p)
{
  for (int i = 0; i < p->count; i++) {
    free(p->passports[i]->byr);
    free(p->passports[i]->cid);
    free(p->passports[i]->ecl);
    free(p->passports[i]->eyr);
    free(p->passports[i]->hcl);
    free(p->passports[i]->hgt);
    free(p->passports[i]->iyr);
    free(p->passports[i]->pid);
    free(p->passports[i]);
  }
  free(p->passports);
  free(p);
}
uint8_t insert_passport(passports_t *book, passport_t *pass)
{
  size_t next = book->count;
  // printf("Inserting passport at ndx %ld : %p\n", next, (void*)pass);
  if (book->count == book->size)
  {
    book->passports = realloc(book->passports, sizeof(passport_t *) * (book->size + 100));
    book->size = book->size + 100;
  }
  book->passports[next] = pass;
  book->count++;
  return 1;
}

void set_passport_value(passport_t *passport, char *key, char *line, int len)
{
  // printf("set val for %s for pass %p\n", key, passport);
  char **dest;
  if (strcmp(key, "eyr") == 0)
    dest = &passport->eyr;
  else if (strcmp(key, "iyr") == 0)
    dest = &passport->iyr;
  else if (strcmp(key, "ecl") == 0)
    dest = &passport->ecl;
  else if (strcmp(key, "hgt") == 0)
    dest = &passport->hgt;
  else if (strcmp(key, "pid") == 0)
    dest = &passport->pid;
  else if (strcmp(key, "hcl") == 0)
    dest = &passport->hcl;
  else if (strcmp(key, "byr") == 0)
    dest = &passport->byr;
  else if (strcmp(key, "cid") == 0)
    dest = &passport->cid;
  else
  {
    printf("No match for %s", key);
    return;
  }
  char* val = malloc(sizeof(char) * (len + 1));
  memcpy(val, line, len);
  val[len] = '\0';
  *dest = val;
  // printf("\tinserted at %p:%s\n", (void*)dest, *dest);
}

int valid_passports_count(const passports_t *book)
{
  uint32_t sum = 0;
  for (int i = 0; i < book->count; i++)
  {
    // printf("[%00d] check pass %p\n", i, book->passports[i] );
    if (
        book->passports[i]->byr != NULL 
        && book->passports[i]->ecl != NULL 
        && book->passports[i]->eyr != NULL 
        && book->passports[i]->hcl != NULL 
        && book->passports[i]->hgt != NULL 
        && book->passports[i]->iyr != NULL 
        && book->passports[i]->pid != NULL
    )  {
      sum++;
    }
  }
  return sum;
}
int valid_passports2_count(const passports_t *book)
{
  uint32_t sum = 0;
  for (int i = 0; i < book->count; i++)
  {
    // int v = 0;
    passport_t *p = book->passports[i];
    // printf("[%00d] check pass %p\n", i, book->passports[i] );
    if (
        p->byr != NULL 
        && p->ecl != NULL 
        && p->eyr != NULL 
        && p->hcl != NULL 
        && p->hgt != NULL 
        && p->iyr != NULL 
        && p->pid != NULL
    )  {
      int byr = atoi(p->byr);
      if (byr >= 1920 && byr <=2002) {
        int iyr = atoi(p->iyr);
        if (iyr >= 2010 && iyr <= 2020) {
          int eyr = atoi(p->eyr);
          if (eyr >= 2020 && eyr <= 2030) {
            if (
              strcmp("amb", p->ecl) == 0 
              || strcmp("blu", p->ecl) == 0 
              || strcmp("brn", p->ecl) == 0 
              || strcmp("gry", p->ecl) == 0 
              || strcmp("grn", p->ecl) == 0 
              || strcmp("hzl", p->ecl) == 0 
              || strcmp("oth", p->ecl) == 0  
            ) {
              int val = atoi(p->hgt);
              int valid_hgt = 0;
              if (strstr(p->hgt, "cm") != NULL) {
                if (val >= 150 && val <=193)
                  valid_hgt = 1;
              } else {
                if (val >= 59 && val <=76)
                  valid_hgt = 1;
              }
              if (valid_hgt) {
                if (p->hcl[0] == '#' && strlen(p->hcl) == 7) {
                  int valid_hcl = 1;
                  for(int j = 1; j < 7; j++) {
                    if (!isxdigit(p->hcl[j])) {
                      valid_hcl = 0;
                      break;
                    }
                  }
                  if (valid_hcl) {
                    if (strlen(p->pid)==9) {
                      int valid_pid = 1;
                      for (int j = 0; j<9; j++) {
                        if (!isdigit(p->pid[j])) {
                          valid_pid = 0;
                          break;
                        }
                      }
                      if (valid_pid)
                      {
                        // printf("%d is valid!\n", i);
                        sum+=1;
                        // v=1;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    // if (!v) {
    //   printf("%d was invalid!\n", i);
    // }
  }
  return sum;
}

static int LINE_LENGTH = 200;
void clear_line(char *line)
{
  for (int i = 0; i < LINE_LENGTH; ++i)
    line[i] = 0;
}

typedef enum stage
{
  NEW_PASSPORT,
  MAYBE_NEXT,
  KEY,
  VAL
} stage_t;

int main(int argc, char **argv)
{
  printf("hello day4!\n");

  FILE *fp = fopen("in.txt", "r");
  if (fp == 0)
  {
    printf("Cannot open file in.txt\n");
    exit(1);
  }

  passports_t *book = init_passports(); // add passports here
  stage_t step = KEY;
  char *line = malloc(sizeof(char) * LINE_LENGTH);
  int pos = 0;
  int c;
  passport_t *curr = malloc(sizeof(passport_t));
  char *key = malloc(sizeof(char) * 4);
  strcpy(key, "   ");
  // read the input file
  while (1)
  {
    c = getc(fp);
    // printf("%d: Got %c\n", step, c);
    if (c == EOF)
    {
      if (step == VAL)
        set_passport_value(curr, key, line, pos);
        // finish the value, submit the passport
      insert_passport(book, curr);
      break;
    }
    if (c == '\n')
    {
      if (step == MAYBE_NEXT)
      {
        // yes, double \n
        // finish the value and submit the passport
        insert_passport(book, curr);
        
        // reset stuff
        step = NEW_PASSPORT;
        pos = 0;
      }
      else if (step == VAL)
      {
        // finalize val
        set_passport_value(curr, key, line, pos);
        // maybe that's it?
        step = MAYBE_NEXT;
        clear_line(line);
        pos = 0;
      }
      continue; //more than 1 newline may be consumed.
    }
    else if (c == '\r')
    {
      // ignore
      continue;
    }

    line[pos++] = c;
    switch (step)
    {
    case NEW_PASSPORT:
      curr = malloc(sizeof(passport_t));
      curr->byr = curr->cid = curr->ecl = curr->eyr = curr->hcl = curr ->hgt = curr->iyr = curr->pid = 0;
      step = KEY;
      break;
    case KEY:
      if (c == ':')
      {
        memcpy(key, line, 3);
        step = VAL;
        clear_line(line);
        pos = 0;
      }
      else
      {
        // letter copied to line
      }
      break;
    case VAL:
      if (c == ' ')
      {
        // printf("About to set value of pass %p to key %s\n", curr, key);
        set_passport_value(curr, key, line, pos - 1);
        step = KEY;
        clear_line(line);
        pos = 0;
      }
      // if c == \n is handled above
      break;
    case MAYBE_NEXT:
      step = KEY;
      // data already copied, continue in that state
      break;
    default:
      break;
    }
  }
  fclose(fp);
  free(key);
  free(line);
  printf("Part1: %d\n", valid_passports_count(book));  // 254
  printf("Part2: %d\n", valid_passports2_count(book)); // 184
  // printf("Part2: %d\n", correct2);

  dealloc_passports(book);
  return 0;
}
