#include <tinybrain/sw/forth/io.hh>

#include <tinybrain/sw/forth/semihosting.hh>

#include <array>
#include <cstdint>
#include <cstdlib>

namespace tinybrain::sw::forth {

namespace {
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

} // namespace

[[nodiscard]] uint8_t Stdio::readc() noexcept {
  while (line_rd_idx == line_wr_idx) {
    do_input_output();
  }

  return line_buffer[line_rd_idx++];
}

void Stdio::writec(const uint8_t c) noexcept { sys_writec(c); }

void Stdio::discard_line() noexcept {
  // Consume remaining input, to fall back into the prompt
  line_rd_idx = line_wr_idx;
}

bool Stdio::is_eof() noexcept {
  // stdio never ends
  return false;
}

} // namespace tinybrain::sw::forth
