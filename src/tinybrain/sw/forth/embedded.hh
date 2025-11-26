#pragma once

#include <tinybrain/sw/forth/io.hh>

#include <span>

namespace tinybrain::sw::forth {

class ForthFile final : public ForthIo {
public:
  explicit ForthFile(const std::span<const uint8_t> file_contents) noexcept;

  ForthFile(const ForthFile &) noexcept = default;
  ForthFile(ForthFile &&) noexcept = default;
  ForthFile &operator=(const ForthFile &) noexcept = default;
  ForthFile &operator=(ForthFile &&) noexcept = default;

  ~ForthFile() noexcept final = default;

  [[nodiscard]] uint8_t readc() noexcept final;

  void writec(const uint8_t v) noexcept final;

  void discard_line() noexcept final;

  [[nodiscard]] bool is_eof() noexcept final;

private:
  std::span<const uint8_t> m_data;
};
} // namespace tinybrain::sw::forth
