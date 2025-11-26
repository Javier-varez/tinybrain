#include <tinybrain/sw/forth/semihosting.hh>

namespace tinybrain::sw::forth {

extern "C" void enter_forth() noexcept;

extern "C" int main() noexcept {
  enter_forth();

  while (true) {
    sys_exit();
  }
  return 0;
}

} // namespace tinybrain::sw::forth
