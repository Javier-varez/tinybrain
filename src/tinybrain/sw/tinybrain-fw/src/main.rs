#![no_std]
#![no_main]

mod fmc;
mod init;

use defmt_rtt as _;
use panic_probe as _;

use cortex_m_rt::entry;
use embedded_hal::{delay::DelayNs, digital::StatefulOutputPin};
use stm32h5xx_hal::prelude::*;

struct Leds<T: StatefulOutputPin> {
    green: T,
    yellow: T,
    red: T,
}

impl<T: StatefulOutputPin> Leds<T> {
    pub fn party(&mut self) {
        self.red.toggle().unwrap();
        self.green.toggle().unwrap();
        self.yellow.toggle().unwrap();
    }
}

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

    let mut fmc = p.FMC;
    fmc::init_fmc(&mut fmc, ccdr.peripheral.FMC);

    let gpiob = p.GPIOB.split(ccdr.peripheral.GPIOB);
    let gpiod = p.GPIOD.split(ccdr.peripheral.GPIOD);
    let gpioe = p.GPIOE.split(ccdr.peripheral.GPIOE);
    let gpiof = p.GPIOF.split(ccdr.peripheral.GPIOF);
    let gpiog = p.GPIOG.split(ccdr.peripheral.GPIOG);

    let green_led = gpiob
        .pb0
        .into_push_pull_output()
        .speed(stm32h5xx_hal::gpio::Speed::Low)
        .erase();

    let yellow_led = gpiof
        .pf4
        .into_push_pull_output()
        .speed(stm32h5xx_hal::gpio::Speed::Low)
        .erase();

    let red_led = gpiog
        .pg4
        .into_push_pull_output()
        .speed(stm32h5xx_hal::gpio::Speed::Low)
        .erase();

    let mut leds = Leds {
        green: green_led,
        yellow: yellow_led,
        red: red_led,
    };

    let mut delay = core_p.SYST.delay(&ccdr.clocks);

    // FMC clk pin
    let _pd3_af12 = gpiod
        .pd3
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC NOE
    let _pd4_af12 = gpiod
        .pd4
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC NWE
    let _pd5_af12 = gpiod
        .pd5
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC NE1
    let _pd7_af12 = gpiod
        .pd7
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC NADV
    let _pb7_af12 = gpiob
        .pb7
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D0/AD0
    let _pd14_af12 = gpiod
        .pd14
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D1/AD1
    let _pd15_af12 = gpiod
        .pd15
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D2/AD2
    let _pd0_af12 = gpiod
        .pd0
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D3/AD3
    let _pd1_af12 = gpiod
        .pd1
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D4/AD4
    let _pe7_af12 = gpioe
        .pe7
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D5/AD5
    let _pe8_af12 = gpioe
        .pe8
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D6/AD6
    let _pe9_af12 = gpioe
        .pe9
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D7/AD7
    let _pe10_af12 = gpioe
        .pe10
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D8/AD8
    let _pe11_af12 = gpioe
        .pe11
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D9/AD9
    let _pe12_af12 = gpioe
        .pe12
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D10/AD10
    let _pe13_af12 = gpioe
        .pe13
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D11/AD11
    let _pe14_af12 = gpioe
        .pe14
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D12/AD12
    let _pe15_af12 = gpioe
        .pe15
        .into_alternate::<12>()
        .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D13/AD13
    // FIXME: conflicts with Virtual COM. Left floating for now
    // let _pd8_af12 = gpiod
    //     .pd8
    //     .into_alternate::<12>()
    //     .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D14/AD14
    // FIXME: conflicts with Virtual COM. Left floating for now
    // let _pd9_af12 = gpiod
    //     .pd9
    //     .into_alternate::<12>()
    //     .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    // FMC D15/AD15
    // FIXME: only in morpho connector...
    // let _pd10_af12 = gpiod
    //     .pd10
    //     .into_alternate::<12>()
    //     .speed(stm32h5xx_hal::gpio::Speed::VeryHigh);

    let mut seed = 0;
    loop {
        leds.party();

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
