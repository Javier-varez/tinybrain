# Tinybrain

**Tinybrain** is a computer. A computer with a small, tiny, brain. The project evolved from the idea of 
drastically simplyfing the computer systems of today, trying to relive the simplicity and elegance 
of legacy computer designs.

## Nostalgia in a box

Let's start by examining what desireable characteriscics has been lost over time in the computing 
systems we use today:
- **Simplicity**: early computers were simple, even by mere necessity of the available technology 
of the day.
- **Legacy-free**: Back in the 70's and the 80's, humanity had not had a chance to build the vast amount of 
computer infrastructure that is used in computers today. This made early developments feel like _greenfield_ 
projects, not limited by the choices of the past, or by obsolete infrastructure.
- **Holistic design**: An addition to being legacy-free, these systems were entirely designed for their purpose. 
There was largely no reused software, immutable interfaces or any other similar concerns. Building a 
computer felt much like working on a blank canvas. Every piece that was added had a purpose.

## Architecture 

**Note**: The content in this section is speculative at the moment. It represents what I am considering building at the moment and not what is currently already built.

### Building blocks

- STM32 MCU as the tiny brain.
- FPGA fabric for the virtual memory subsystem:
    - Large storage
    - DRAM dimms, maybe pluggable. Wanna have unified storage really.
- Add-in cards attached to the FPGA, making the hardware interfaces flexible (possibly storage 
  connected in these cards).
- FPGA might wanna have cores loaded dynamically based on attached cards.
- Graphics? I think a tty-based solution would be ok for me. 
- Store small OS in the MCU flash:
    - Maybe make it Open Firmware compliant, with a forth interpreter :D
    - UART exposed on the MCU itself. 
    - This way we can make the OF interface accessible even if storage is not present or the FPGA 
      fabric does not work.

What do I want:
- Large storage support (NVMe? Probably better something simpler).
- Networking via ethernet.
- USB device support.
- Keyboard, no mouse needed

### Firmware Architecture

- Just enough to boot from flash of the STM32, initialize the FPGA and load the OS from non-volatile 
memory.
- Firmware should attest the FPGA bitstream, as well as the OS image being loaded.

### OS Architecture

- **Scheduler**: Preemptive , round robin of non-blocked tasks.
- **Memory management**: slab allocation for in-kernel data structures.
- **File system**: Look into ZFS and build something similar.
- **Terminal-based**: I want TUIs and CLIs, with the possibility to add images.
- **Async first**: Lots of software is blocking, let's have an API that focuses on not blocking processes 
  if not needed.

Applications I'd like to have: 
- Text-editor
- curl-like utility
- Maybe add posix compliant interface? Make ports of other software possible?
