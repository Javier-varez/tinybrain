#![allow(dead_code)]

use stm32h5xx_hal::prelude::*;
use stm32h5xx_hal::{
    pac::{DCACHE, FLASH, ICACHE, MPU, PWR, RCC, SBS},
    rcc::Ccdr,
};

/// Enable ART flash prefetch
pub fn init_flash(flash: &mut FLASH) {
    flash.acr().modify(|_, w| w.prften().set_bit());
}

/// Enables instruction and data chaches
pub fn init_caches(icache: &mut ICACHE, dcache: &mut DCACHE) {
    icache.cr().modify(|_r, w| w.en().set_bit());
    dcache.cr().modify(|_r, w| w.en().set_bit());
}

/// Initializes the MPU. Makes the FMC region at 0x6000_0000 non-cacheable to make it debuggable
/// for now
pub fn init_mpu(mpu: &mut MPU) {
    // SAFETY: Region 0 is a valid index
    unsafe { mpu.rnr.write(0) };

    #[repr(u32)]
    enum Shareability {
        None = 0,
        Outer,
        Inner,
    }

    #[repr(u32)]
    enum Ap {
        RwPriv = 0,
        RwAny,
        RoPriv,
        RoAny,
    }

    const FMC_BASE: u32 = 0x6000_0000;
    const SH_OFFSET: usize = 3;
    const AP_OFFSET: usize = 1;
    const XN_OFFSET: usize = 0;

    // SAFETY: Region settings are valid for the FMC external memory region
    unsafe {
        mpu.rbar.write(
            FMC_BASE
                | ((Ap::RwPriv as u32) << AP_OFFSET)
                | (0 << XN_OFFSET)
                | ((Shareability::Outer as u32) << SH_OFFSET),
        )
    };

    const FMC_LIMIT: u32 = 0xA000_0000;
    const EN_OFFSET: usize = 0;
    const ATTR_INDEX_OFFSET: usize = 1;
    const PXN_OFFSET: usize = 4;

    // SAFETY: Region limits are guaranteed to be valid
    unsafe {
        mpu.rlar
            .write(FMC_LIMIT | (0 << PXN_OFFSET) | (0 << ATTR_INDEX_OFFSET) | (1 << EN_OFFSET))
    };

    // SAFETY: Region attributes are valid for the external memory attached to FMC
    const OUTER_OFFSET: usize = 4;
    const INNER_OFFSET: usize = 0;
    const NORMAL_MEM_NON_CHACHEABLE: u32 = 0b0100;
    unsafe {
        mpu.mair[0].write(
            NORMAL_MEM_NON_CHACHEABLE << OUTER_OFFSET | NORMAL_MEM_NON_CHACHEABLE << INNER_OFFSET,
        )
    };

    // SAFETY: The effect of setting this register is memory-safe.
    unsafe {
        mpu.ctrl.modify(|v| {
            // Make unmapped regions fall back to the default map.
            // Only in privileged mode.
            const PRIVDEFENA: u32 = 0x04;
            // Enable MPU
            const ENABLE: u32 = 0x01;
            v | PRIVDEFENA | ENABLE
        })
    };
}

/// Initializes the clock tree
pub fn init_clock(rcc: RCC, pwr: PWR, sbs: &SBS) -> Ccdr {
    // set voltage scale 0
    let pwr = pwr.constrain().vos0().freeze();

    // The nucleo board uses by default the MCO output of the STLINK v3 at 8 MHz as the HSE.
    rcc.constrain()
        .use_hse(8.MHz())
        .pll1_p_ck(250.MHz())
        .hclk(250.MHz())
        .sysclk(250.MHz())
        .freeze(pwr, sbs)
}
