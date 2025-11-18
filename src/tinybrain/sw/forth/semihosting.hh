#pragma once

#include <cstdint>

namespace tinybrain::sw::forth {

extern "C" [[nodiscard]] uint8_t sys_readc() noexcept;

extern "C" void sys_writec(const uint8_t byte) noexcept;

extern "C" [[noreturn]] void sys_exit() noexcept;

} // namespace tinybrain::sw::forth
