#pragma once

#include <array>
#include <cstdint>
#include <cstdlib>

namespace tinybrain::sw::forth {

class ForthIo {
public:
  // Reads a single character, with a blocking interface
  [[nodiscard]] virtual uint8_t readc() noexcept = 0;

  // Writes a character to the output device
  virtual void writec(const uint8_t v) noexcept = 0;

  virtual void discard_line() noexcept = 0;

  [[nodiscard]] virtual bool is_eof() noexcept = 0;

  virtual ~ForthIo() = default;
};

class Stdio final : public ForthIo {
public:
  Stdio() noexcept = default;

  Stdio(const Stdio &) noexcept = default;
  Stdio(Stdio &&) noexcept = default;
  Stdio &operator=(const Stdio &) noexcept = default;
  Stdio &operator=(Stdio &&) noexcept = default;

  ~Stdio() noexcept final = default;

  [[nodiscard]] uint8_t readc() noexcept final;

  void writec(const uint8_t v) noexcept final;

  void discard_line() noexcept final;

  [[nodiscard]] bool is_eof() noexcept final;

private:
};

} // namespace tinybrain::sw::forth
