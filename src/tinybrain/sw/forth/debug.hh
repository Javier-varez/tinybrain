#pragma once

#include <cstdint>
#include <cstdlib>

namespace tinybrain::sw::forth {

void debug_print(const char *str) noexcept;
void debug_print(const char *str, size_t size) noexcept;
void debug_print(uint32_t val) noexcept;

} // namespace tinybrain::sw::forth
