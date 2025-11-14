extern "C" int main() {
  volatile int i = 0;
  while (true) {
    i += 1;
  }

  return 0;
}
