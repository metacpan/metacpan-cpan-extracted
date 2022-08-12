use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;

package VIC::PIC::Roles::CodeGen;
{
    use Moo::Role;
    requires qw(type org include chip_config get_chip_config code_config
      validate validate_modifier_operator update_code_config
      list_roles is_variable
    );
}

package VIC::PIC::Roles::Operators;
{
    use Moo::Role;
    requires qw(
      op_assign op_assign_wreg rol ror op_shl op_shr shl shr op_not
      op_comp op_add_assign_literal op_add_assign op_sub_assign
      op_mul_assign op_div_assign op_mod_assign op_bxor_assign
      op_band_assign op_bor_assign op_shl_assign op_shr_assign
      op_inc op_dec op_add op_sub op_mul op_div op_mod op_bxor
      op_band op_bor op_eq op_lt op_ge op_ne op_le op_gt op_and
      op_or op_sqrt break continue store_array store_string
      store_table op_tblidx op_stridx op_arridx store_bytes
    );
}

package VIC::PIC::Roles::Chip;
{
    use Moo::Role;

    requires qw(f_osc pcl_size stack_size wreg_size
      memory address banks registers address_bits
      pins clock_pins oscillator_pins program_pins);

    # useful for checking if a chip is PDIP or SOIC or SSOP or QFN
    # maybe extracted to a separate role defining chip type but not yet
    requires qw(pin_counts);
}

package VIC::PIC::Roles::GPIO;
{
    use Moo::Role;

    # input_pins is a list of input pins.
    # output pins is a list of output pins.
    # Bi-directional pins will be in both lists
    # analog_pins are a list of analog_pins
    requires qw(input_pins output_pins io_ports
      analog_pins get_input_pin get_output_pin);
    requires qw(digital_output digital_input analog_input write read setup);
}

package VIC::PIC::Roles::ADC;
{
    use Moo::Role;

    requires qw(adc_enable adc_disable adc_read adc_channels adcs_bits
    adc_chs_bits analog_pins);
}

package VIC::PIC::Roles::Timer;
{
    use Moo::Role;

    requires qw(timer_enable timer_disable timer timer_prescaler
    wdt_prescaler timer_pins);
}

package VIC::PIC::Roles::ISR;
{
    use Moo::Role;

    requires qw(eint_pins ioc_pins);
    requires qw(isr_entry isr_exit isr_var isr_timer isr_ioc);
}

package VIC::PIC::Roles::CCP;
{
    use Moo::Role;
    requires qw(ccp_pins);
}

package VIC::PIC::Roles::ECCP;
{
    use Moo::Role;
    requires qw(eccp_pins pwm_single pwm_halfbridge pwm_fullbridge);
}

package VIC::PIC::Roles::Operations;
{
    use Moo::Role;
    requires qw(delay delay_ms delay_us delay_s debounce);
}

package VIC::PIC::Roles::USART;
{
    use Moo::Role;
    requires qw(usart_pins usart_write usart_read usart_setup usart_baudrates);
}

package VIC::PIC::Roles::SPI;
{
    use Moo::Role;
    requires qw(spi_pins selector_pins);
}

package VIC::PIC::Roles::I2C;
{
    use Moo::Role;
    requires qw(i2c_pins selector_pins);
}

package VIC::PIC::Roles::Comparator;
{
    use Moo::Role;
    requires qw(cmp_output_pins cmp_input_pins);
}

package VIC::PIC::Roles::PSP;
{
    use Moo::Role;
    requires qw(psp_pins);
}

package VIC::PIC::Roles::SRLatch;
{
    use Moo::Role;
    requires qw(srlatch);
}

package VIC::PIC::Roles::USB;
{
    use Moo::Role;
    requires qw(usb_pins);
}

package VIC::PIC::Roles::Power;
{
    use Moo::Role;
    requires qw(sleep);
}

1;
__END__
