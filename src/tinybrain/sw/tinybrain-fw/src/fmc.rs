use stm32h5xx_hal::pac::FMC;
use stm32h5xx_hal::rcc::{ResetEnable, rec};

pub fn init_fmc(fmc: &mut FMC, fmc_rec: rec::Fmc) {
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
}
