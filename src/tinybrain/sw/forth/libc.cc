// This file contains a number of stubs for newlib, which complains if they are
// not implemented

#include <unistd.h>

extern "C" int _close(int) noexcept { return 0; }

extern "C" off_t _lseek(int, off_t, int) noexcept { return 0; }

extern "C" off_t _read(int, void *, size_t) noexcept { return 0; }

extern "C" off_t _write(int, void *, size_t) noexcept { return 0; }
