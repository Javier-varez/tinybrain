use stm32h5xx_hal::gpio::{AF12, Pin, Speed};
use stm32h5xx_hal::pac::FMC;
use stm32h5xx_hal::rcc::{ResetEnable, rec};

pub struct FmcPins {
    pub clk: Pin<'D', 3>,
    pub noe: Pin<'D', 4>,
    pub nwe: Pin<'D', 5>,
    pub ne1: Pin<'D', 7>,
    pub nadv: Pin<'B', 7>,
    pub d0: Pin<'D', 14>,
    pub d1: Pin<'D', 15>,
    pub d2: Pin<'D', 0>,
    pub d3: Pin<'D', 1>,
    pub d4: Pin<'E', 7>,
    pub d5: Pin<'E', 8>,
    pub d6: Pin<'E', 9>,
    pub d7: Pin<'E', 10>,
    pub d8: Pin<'E', 11>,
    pub d9: Pin<'E', 12>,
    pub d10: Pin<'E', 13>,
    pub d11: Pin<'E', 14>,
    pub d12: Pin<'E', 15>,
    // FMC D13/AD13 FIXME: DP8 conflicts with Virtual COM. Left floating for now
    // FMC D14/AD14 FIXME: PD9 conflicts with Virtual COM. Left floating for now
    // FMC D15/AD15 FIXME: PD10 is only in the morpho connector...
}

struct ConfiguredFmcPins {
    _clk: Pin<'D', 3, AF12>,
    _noe: Pin<'D', 4, AF12>,
    _nwe: Pin<'D', 5, AF12>,
    _ne1: Pin<'D', 7, AF12>,
    _nadv: Pin<'B', 7, AF12>,
    _d0: Pin<'D', 14, AF12>,
    _d1: Pin<'D', 15, AF12>,
    _d2: Pin<'D', 0, AF12>,
    _d3: Pin<'D', 1, AF12>,
    _d4: Pin<'E', 7, AF12>,
    _d5: Pin<'E', 8, AF12>,
    _d6: Pin<'E', 9, AF12>,
    _d7: Pin<'E', 10, AF12>,
    _d8: Pin<'E', 11, AF12>,
    _d9: Pin<'E', 12, AF12>,
    _d10: Pin<'E', 13, AF12>,
    _d11: Pin<'E', 14, AF12>,
    _d12: Pin<'E', 15, AF12>,
}

impl From<FmcPins> for ConfiguredFmcPins {
    fn from(value: FmcPins) -> Self {
        Self {
            _clk: value.clk.into_alternate::<12>().speed(Speed::VeryHigh),
            _noe: value.noe.into_alternate::<12>().speed(Speed::VeryHigh),
            _nwe: value.nwe.into_alternate::<12>().speed(Speed::VeryHigh),
            _ne1: value.ne1.into_alternate::<12>().speed(Speed::VeryHigh),
            _nadv: value.nadv.into_alternate::<12>().speed(Speed::VeryHigh),
            _d0: value.d0.into_alternate::<12>().speed(Speed::VeryHigh),
            _d1: value.d1.into_alternate::<12>().speed(Speed::VeryHigh),
            _d2: value.d2.into_alternate::<12>().speed(Speed::VeryHigh),
            _d3: value.d3.into_alternate::<12>().speed(Speed::VeryHigh),
            _d4: value.d4.into_alternate::<12>().speed(Speed::VeryHigh),
            _d5: value.d5.into_alternate::<12>().speed(Speed::VeryHigh),
            _d6: value.d6.into_alternate::<12>().speed(Speed::VeryHigh),
            _d7: value.d7.into_alternate::<12>().speed(Speed::VeryHigh),
            _d8: value.d8.into_alternate::<12>().speed(Speed::VeryHigh),
            _d9: value.d9.into_alternate::<12>().speed(Speed::VeryHigh),
            _d10: value.d10.into_alternate::<12>().speed(Speed::VeryHigh),
            _d11: value.d11.into_alternate::<12>().speed(Speed::VeryHigh),
            _d12: value.d12.into_alternate::<12>().speed(Speed::VeryHigh),
        }
    }
}

pub struct Fmc {
    _fmc: FMC,
    _pins: ConfiguredFmcPins,
}

impl Fmc {
    pub fn init(fmc: FMC, fmc_rec: rec::Fmc, pins: FmcPins) -> Self {
        // Enable and reset the FMC
        fmc_rec.enable().reset();

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
            w.cclken().set_bit();
            w.fmcen().set_bit()
        });

        // Configured according to table 207 of the TRM
        fmc.btr1().modify(|_, w| unsafe {
            w.busturn().bits(0);
            w.clkdiv().bits(0xf);
            w.datlat().bits(0);
            w.accmod().bits(0)
        });

        Fmc {
            _fmc: fmc,
            _pins: pins.into(),
        }
    }
}
