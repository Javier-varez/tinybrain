#![no_std]
#![no_main]

use defmt_rtt as _;
use panic_halt as _;

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

    // set voltage scale 1
    let pwr = p.PWR.constrain().vos1().freeze();

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

    loop {
        leds.party();
        delay.delay_ms(100);
        defmt::error!("Hello, world!");
    }
}
