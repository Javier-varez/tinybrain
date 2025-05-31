#![no_std]
#![no_main]

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

    // set voltage scale 0
    let pwr = p.PWR.constrain().vos0().freeze();

    // The nucleo board uses by default the MCO output of the STLINK v3 at 8 MHz.
    let rcc = p
        .RCC
        .constrain()
        .use_hse(8.MHz())
        .pll1_p_ck(250.MHz())
        .hclk(250.MHz())
        .sysclk(250.MHz())
        .freeze(pwr, &p.SBS);

    let gpiob = p.GPIOB.split(rcc.peripheral.GPIOB);
    let gpiod = p.GPIOD.split(rcc.peripheral.GPIOD);
    let gpiof = p.GPIOF.split(rcc.peripheral.GPIOF);
    let gpiog = p.GPIOG.split(rcc.peripheral.GPIOG);

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

    let mut delay = core_p.SYST.delay(&rcc.clocks);

    let fmc = p.FMC;

    // Enable and reset the FMC
    rcc.peripheral.FMC.enable().reset();

    // Configured according to table 206 of the TRM
    fmc.bcr1().write(|w| unsafe {
        w.mbken()
            .set_bit()
            .muxen()
            .set_bit()
            .mtyp()
            .bits(1)
            .mwid()
            .bits(1)
            .faccen()
            .set_bit()
            .bursten()
            .set_bit()
            .waitpol()
            .clear_bit()
            .waitcfg()
            .set_bit()
            .wren()
            .set_bit()
            .waiten()
            .clear_bit()
            .extmod()
            .clear_bit()
            .asyncwait()
            .clear_bit()
            .cpsize()
            .bits(0)
            .cburstrw()
            .set_bit()
            .cclken()
            .clear_bit()
            .fmcen()
            .set_bit()
    });

    // Configured according to table 207 of the TRM
    fmc.btr1().write(|w| unsafe {
        w.busturn()
            .bits(0)
            .clkdiv()
            .bits(0xf)
            .datlat()
            .bits(0)
            .accmod()
            .bits(0)
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
