#![no_std]
#![no_main]

mod init;
use defmt_rtt as _;
use panic_probe as _;

use cortex_m_rt::entry;
use embedded_hal::{delay::DelayNs, digital::StatefulOutputPin};
use stm32h5xx_hal::{prelude::*, rcc::ResetEnable};

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

    let gpiob = p.GPIOB.split(ccdr.peripheral.GPIOB);
    let gpiod = p.GPIOD.split(ccdr.peripheral.GPIOD);
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

    let fmc = p.FMC;

    // Enable and reset the FMC
    ccdr.peripheral.FMC.enable().reset();

    // Configured according to table 206 of the TRM
    fmc.bcr1().modify(|_, w| unsafe {
        w.mbken().set_bit();
        w.muxen().set_bit();
        w.mtyp().bits(1);
        w.mwid().bits(1);
        w.faccen().set_bit();
        w.bursten().set_bit();
        w.waitpol().clear_bit();
        w.waitcfg().set_bit();
        w.wren().set_bit();
        w.waiten().clear_bit();
        w.extmod().clear_bit();
        w.asyncwait().clear_bit();
        w.cpsize().bits(0);
        w.cburstrw().set_bit();
        w.cclken().clear_bit();
        w.fmcen().set_bit()
    });

    // Configured according to table 207 of the TRM
    fmc.btr1().modify(|_, w| unsafe {
        w.busturn().bits(0);
        w.clkdiv().bits(0xf);
        w.datlat().bits(0);
        w.accmod().bits(0)
    });

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

    let mut value = 0u16;
    loop {
        leds.party();
        defmt::error!("Hello, world!");

        delay.delay_ms(100);
        unsafe { core::ptr::write_volatile(0x6000_0000 as *mut u16, value) };
        delay.delay_us(50);
        unsafe { core::ptr::read_volatile(0x6000_0000 as *mut u16) };

        value += 1;
    }
}
