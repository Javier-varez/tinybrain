#include <tinybrain/sw/forth/debug.hh>
#include <tinybrain/sw/forth/semihosting.hh>

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>

#include <array>
#include <bit>

namespace tinybrain::sw::forth {
namespace {

enum class FindStatus : int32_t {
  NOT_FOUND = 0,
  IMMEDIATE = 1,
  NOT_IMMEDIATE = -1,
};

struct FindResult {
  FindStatus status;
  uintptr_t addr;
};

struct WordHeader final {
  uintptr_t previous_word;
  uint8_t flags_and_length;
  char name[];

  [[nodiscard]] uintptr_t next() const noexcept;

  [[nodiscard]] bool matches(const char *const otherBase,
                             const size_t otherBytes) const noexcept;

  [[nodiscard]] size_t bytes() const noexcept;

  [[nodiscard]] bool is_immediate() const noexcept;
  [[nodiscard]] bool is_hidden() const noexcept;
};

[[nodiscard]] size_t WordHeader::bytes() const noexcept {
  constexpr static size_t LEN_MASK = 0x1f;
  return flags_and_length & LEN_MASK;
}

[[nodiscard]] uintptr_t WordHeader::next() const noexcept {
  return previous_word;
}

bool WordHeader::matches(const char *const otherBase,
                         const size_t otherBytes) const noexcept {
  const size_t b = bytes();
  if (b != otherBytes) {
    return false;
  }

  return memcmp(otherBase, name, b) == 0;
}

[[nodiscard]] bool WordHeader::is_immediate() const noexcept {
  constexpr static uint8_t IMM_FLAG = 0x80;
  return (flags_and_length & IMM_FLAG) != 0;
}

[[nodiscard]] bool WordHeader::is_hidden() const noexcept {
  constexpr static uint8_t HIDDEN_FLAG = 0x20;
  return (flags_and_length & HIDDEN_FLAG) != 0;
}

constexpr static size_t MAX_LINE_LENGTH = 512u;
std::array<uint8_t, MAX_LINE_LENGTH> line_buffer{};
size_t line_rd_idx = 0u;
size_t line_wr_idx = 0u;

// Handles input/output until a full line is received, then returns control to
// the caller.
void do_input_output() noexcept {
  line_rd_idx = 0u;
  line_wr_idx = 0u;

  sys_writec('o');
  sys_writec('k');
  sys_writec(' ');

  char c;
  while ((c = sys_readc()) != '\r') {
    constexpr static char delete_key = 0x7f;
    constexpr static char backspace_key = 0x8;
    if (c == delete_key) {
      if (line_wr_idx > 0) {
        sys_writec(backspace_key);
        sys_writec(' ');
        sys_writec(backspace_key);
        line_wr_idx = line_wr_idx - 1;
      }
    } else {
      sys_writec(c);

      line_buffer[line_wr_idx] = c;
      line_wr_idx = (line_wr_idx + 1) % MAX_LINE_LENGTH;
    }
  }

  line_buffer[line_wr_idx] = '\n';
  line_wr_idx = (line_wr_idx + 1) % MAX_LINE_LENGTH;
  sys_writec('\n');
}

[[nodiscard]] uint8_t readc() noexcept {
  while (line_rd_idx == line_wr_idx) {
    do_input_output();
  }

  return line_buffer[line_rd_idx++];
}

} // namespace

extern "C" {

constexpr static size_t MAX_WORD_SIZE = 32;
std::array<uint8_t, MAX_WORD_SIZE> forth_word_buffer{};

[[nodiscard]] uint32_t forth_key_impl() noexcept { return readc(); }

[[nodiscard]] uint32_t forth_word_impl() noexcept {
  constexpr static uint32_t MASK = 32 - 1;

  char c;
  while (std::isspace(c = readc())) {
  }

  forth_word_buffer[0] = c;
  uint32_t size = 1;
  for (;;) {
    c = readc();
    if (std::isspace(c)) {
      break;
    }

    forth_word_buffer[size] = c;
    size = (size + 1) & MASK;
  }

  return size;
}

// Defined in forth.S
extern uint32_t forth_var_latest;

// See `FIND` in https://forth-standard.org/standard/core/FIND
[[nodiscard]] uint64_t forth_find_impl(const size_t nameBytes,
                                       const uintptr_t nameBase) noexcept {
  FindResult result{
      .status = FindStatus::NOT_FOUND,
      .addr = nameBase,
  };

  uintptr_t current_word = forth_var_latest;
  while (current_word != 0) {
    const WordHeader &header =
        *reinterpret_cast<const WordHeader *>(current_word);
    if (!header.is_hidden() &&
        header.matches(reinterpret_cast<const char *>(nameBase), nameBytes)) {
      result.addr = current_word;
      result.status = header.is_immediate() ? FindStatus::IMMEDIATE
                                            : FindStatus::NOT_IMMEDIATE;
      break;
    }

    current_word = header.next();
  }

  return std::bit_cast<uint64_t>(result);
}

[[nodiscard]] uint64_t forth_number_impl(const size_t wordBytes,
                                         const uintptr_t wordBase) noexcept {
  const char *const str = reinterpret_cast<const char *>(wordBase);

  struct Result final {
    int32_t number;
    uint32_t ok;
  };

  Result result{
      .number = 0,
      .ok = 0,
  };

  if (wordBytes == 0) {
    return std::bit_cast<uint64_t>(result);
  }

  size_t i = 0;
  int32_t sign = 1;
  if (str[i] == '-') {
    sign = -1;
    i++;
  }

  for (; i < wordBytes; i++) {
    if (str[i] < '0' || str[i] > '9') {
      return std::bit_cast<uint64_t>(result);
    }

    const int32_t cur = str[i] - '0';
    result.number = result.number * 10 + cur;
  }

  result.ok = 1;
  result.number *= sign;
  return std::bit_cast<uint64_t>(result);
}

void forth_dot_impl(const uint32_t value) {
  debug_print(value);
  debug_print("\n");
}

void forth_emit_impl(const uint32_t value) { sys_writec(value & 0xFF); }

void forth_unk_word(const size_t wordBytes, const uintptr_t wordBase) {
  debug_print("Unknown word \"");
  debug_print(reinterpret_cast<const char *>(wordBase), wordBytes);
  debug_print("\"\n");

  // Consume remaining input, to fall back into the prompt
  line_rd_idx = line_wr_idx;
}
}

} // namespace tinybrain::sw::forth
