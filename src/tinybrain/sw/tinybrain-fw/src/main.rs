#![no_std]
#![no_main]

mod fmc;
mod init;

use defmt_rtt as _;
use panic_probe as _;

use cortex_m_rt::entry;
use embedded_hal::delay::DelayNs;
use stm32h5xx_hal::prelude::*;

#[entry]
fn main() -> ! {
    let p = stm32h5xx_hal::pac::Peripherals::take().unwrap();
    let core_p = stm32h5xx_hal::pac::CorePeripherals::take().unwrap();

    let mut flash = p.FLASH;
    let mut icache = p.ICACHE;
    let mut dcache = p.DCACHE;

    let mut mpu = core_p.MPU;

    init::init_flash(&mut flash);
    init::init_caches(&mut icache, &mut dcache);
    init::init_mpu(&mut mpu);
    let ccdr = init::init_clock(p.RCC, p.PWR, &p.SBS);

    let gpiob = p.GPIOB.split(ccdr.peripheral.GPIOB);
    let gpiod = p.GPIOD.split(ccdr.peripheral.GPIOD);
    let gpioe = p.GPIOE.split(ccdr.peripheral.GPIOE);

    let _fmc = fmc::Fmc::init(
        p.FMC,
        ccdr.peripheral.FMC,
        fmc::FmcPins {
            clk: gpiod.pd3,
            noe: gpiod.pd4,
            nwe: gpiod.pd5,
            ne1: gpiod.pd7,
            nadv: gpiob.pb7,
            d0: gpiod.pd14,
            d1: gpiod.pd15,
            d2: gpiod.pd0,
            d3: gpiod.pd1,
            d4: gpioe.pe7,
            d5: gpioe.pe8,
            d6: gpioe.pe9,
            d7: gpioe.pe10,
            d8: gpioe.pe11,
            d9: gpioe.pe12,
            d10: gpioe.pe13,
            d11: gpioe.pe14,
            d12: gpioe.pe15,
        },
    );

    let mut delay = core_p.SYST.delay(&ccdr.clocks);

    let mut seed = 0;
    loop {
        write_mem(seed);
        read_mem(seed);
        seed = seed.wrapping_add(1);

        delay.delay_ms(100);
    }
}

const BASE_ADDR: usize = 0x6000_0000;
const NUM_ADDRESSES: usize = 0x100;

// At the moment only 13 bits of address/data are connected
const MASK: u16 = 0x1fff;

fn write_mem(seed: u16) {
    for offset in 0..NUM_ADDRESSES {
        let addr = BASE_ADDR + 2 * offset;
        let value = (seed + offset as u16) & MASK;

        // SAFETY: Address and alignment are guaranteed to be valid for u16
        unsafe { core::ptr::write_volatile(addr as *mut u16, value) };
    }
}

fn read_mem(seed: u16) {
    let mut failed = false;

    for offset in 0..NUM_ADDRESSES {
        let addr = BASE_ADDR + 2 * offset;
        let expected = (seed + offset as u16) & MASK;

        // SAFETY: Address and alignment are guaranteed to be valid for u16
        let val = unsafe { core::ptr::read_volatile(addr as *mut u16) } & MASK;

        if val != expected {
            defmt::error!("Error at {}: {} != {}", offset, val, expected);
            failed = true;
        }
    }

    if !failed {
        defmt::info!("Memory Ok!");
    }
}
