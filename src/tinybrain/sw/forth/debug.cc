#include <tinybrain/sw/forth/debug.hh>

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>

#include <array>
#include <bit>

namespace tinybrain::sw::forth {

extern "C" void sys_writec(uint8_t) noexcept;

void debug_print(const char *str) noexcept {
  while (*str != '\0') {
    sys_writec(*str);
    str++;
  }
}

void debug_print(const char *str, size_t size) noexcept {
  for (size_t i = 0; i < size; i++) {
    sys_writec(str[i]);
  }
}

void debug_print(uint32_t val) noexcept {
  sys_writec('0');
  sys_writec('x');
  for (size_t i = 0; i < sizeof(uint32_t) * 2; i++) {
    const uint32_t v = (val >> (sizeof(uint32_t) * 2 - 1 - i)) & 0xf;
    if (v >= 10) {
      sys_writec('A' + v - 10);
    } else {
      sys_writec('0' + v);
    }
  }
}
} // namespace tinybrain::sw::forth
