#include <array>
#include <cctype>
#include <cstdint>
#include <cstdlib>

namespace tinybrain::forth {

extern "C" {

constexpr static size_t MAX_WORD_SIZE = 32;
std::array<uint8_t, MAX_WORD_SIZE> forth_word_buffer{};

[[nodiscard]] uint8_t sys_readc() noexcept;

[[nodiscard]] uint32_t forth_key_impl() noexcept { return sys_readc(); }

[[nodiscard]] uint32_t forth_word_impl() noexcept {
  constexpr static uint32_t MASK = 32 - 1;

  char c;
  while (std::isspace(c = sys_readc())) {
  }

  forth_word_buffer[0] = c;
  uint32_t size = 1;
  for (;;) {
    c = sys_readc();
    if (std::isspace(c)) {
      break;
    }

    forth_word_buffer[size] = c;
    size = (size + 1) & MASK;
  }

  return size;
}
}

} // namespace tinybrain::forth
