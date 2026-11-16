#define _POSIX_C_SOURCE 200809L

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* SAM starts this with the system loader environment. Give only the
 * Flutter process its own loader and library search path. */
int main(void) {
  char directory[PATH_MAX];
  ssize_t length = readlink("/proc/self/exe", directory, sizeof(directory) - 1);
  if (length <= 0 || (size_t)length >= sizeof(directory) - 1) {
    fputs("Cannot resolve the application directory\n", stderr);
    return 1;
  }
  directory[length] = '\0';
  char *name = strrchr(directory, '/');
  if (!name) return 1;
  *name = '\0';
  if (chdir(directory) != 0) {
    perror("chdir");
    return 1;
  }

  unsetenv("LD_LIBRARY_PATH");
  unsetenv("LD_PRELOAD");
  unsetenv("LD_AUDIT");
  execl("/bin/sh", "sh", "./run-probe.sh", (char *)NULL);
  perror("exec run-probe");
  return 1;
}
