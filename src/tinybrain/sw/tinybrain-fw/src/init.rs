use stm32h5xx_hal::pac::{DCACHE, FLASH, ICACHE};

/// Enable ART flash prefetch
pub fn init_flash(flash: &mut FLASH) {
    flash.acr().modify(|_, w| w.prften().set_bit());
}

/// Enables instruction and data chaches
pub fn init_caches(icache: &mut ICACHE, dcache: &mut DCACHE) {
    icache.cr().modify(|_r, w| w.en().set_bit());
    dcache.cr().modify(|_r, w| w.en().set_bit());
}
