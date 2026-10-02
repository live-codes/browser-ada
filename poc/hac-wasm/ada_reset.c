#include <stdio.h>

/* Emscripten's libc keeps the end-of-file indicator on the stdin FILE across
 * calls. When a run reads standard input up to EOF, every later run would see
 * EOF immediately (and GNAT's Text_IO would raise End_Error). Clearing the
 * error/EOF state before each run lets the next run read a fresh stdin. */
void
ada_reset_stdin (void)
{
  clearerr (stdin);
}
