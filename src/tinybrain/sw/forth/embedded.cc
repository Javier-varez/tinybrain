#include <tinybrain/sw/forth/embedded.hh>

#include <tinybrain/sw/forth/semihosting.hh>

namespace tinybrain::sw::forth {

ForthFile::ForthFile(const std::span<const uint8_t> file_contents) noexcept
    : m_data{file_contents} {}

[[nodiscard]] uint8_t ForthFile::readc() noexcept {
  const uint8_t byte = m_data[0];
  m_data = m_data.subspan(1, m_data.size() - 1);
  return byte;
}

void ForthFile::writec(const uint8_t c) noexcept { sys_writec(c); }

void ForthFile::discard_line() noexcept {
  while (!is_eof() && m_data[0] != '\n') {
    static_cast<void>(readc());
  }
}

bool ForthFile::is_eof() noexcept { return m_data.size() == 0; }

} // namespace tinybrain::sw::forth
