package VIC::PIC::P12F683;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::Base';

# role CodeGen
has type => (is => 'ro', default => 'p12f683');
has include => (is => 'ro', default => 'p12f683.inc');

#role Chip
has f_osc => (is => 'ro', default => 4e6); # 4MHz internal oscillator
has pcl_size => (is => 'ro', default => 13); # program counter (PCL) size
has stack_size => (is => 'ro', default => 8); # 8 levels of 13-bit entries
has wreg_size => (is => 'ro', default => 8); # 8-bit register WREG
# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 2048, # words
        SGPM => 128,
        EEPROM => 256,
    }
});
has address => (is => 'ro', default => sub {
    {
        isr => [ 0x0004 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x07FF ],
    }
});

has pin_counts => (is => 'ro', default => sub { {
    pdip => 8, ## PDIP or DIP ?
    soic => 8,
    dfn => 8, # like qfn but only 2 sides
    total => 8,
    io => 6,
}});

has banks => (is => 'ro', default => sub {
    {
        count => 2,
        size => 0x80,
        gpr => {
            0 => [ 0x020, 0x07F],
            1 => [ 0x0A0, 0x0BF],
        },
        # remapping of these addresses automatically done by chip
        common => [0x070, 0x07F],
        remap => [
            [0x0F0, 0x0FF],
        ],
    }
});

has registers => (is => 'ro', default => sub {
    {
        INDF => [0x000, 0x080], # indirect addressing
        TMR0 => [0x001],
        OPTION_REG => [0x081],
        PCL => [0x002, 0x082],
        STATUS => [0x003, 0x083],
        FSR => [0x004, 0x084],
        GPIO => [0x005],
        TRISIO => [0x085],
        PCLATH => [0x00A, 0x08A],
        INTCON => [0x00B, 0x08B],
        PIR1 => [0x00C],
        PIE1 => [0x08C],
        TMR1L => [0x00E],
        PCON => [0x08E],
        TMR1H => [0x00F],
        OSCCON => [0x08F],
        T1CON => [0x010],
        OSCTUNE => [0x090],
        TMR2 => [0x011],
        T2CON => [0x012],
        PR2 => [0x092],
        CCPR1L => [0x013],
        CCPR1H => [0x014],
        CCP1CON => [0x015],
        WPU => [0x095],
        IOC => [0x096],
        WDTCON => [0x018],
        CMCON0 => [0x019],
        VRCON => [0x099],
        CMCON1 => [0x01A],
        EEDAT => [0x09A],
        EEADR => [0x09B],
        EECON1 => [0x09C],
        EECON2 => [0x09D],
        ADRESH => [0x01E],
        ADRESL => [0x09E],
        ADCON0 => [0x01F],
        ANSEL => [0x09F],
    }
});

has pins => (is => 'ro', default => sub {
    my $h = {
        # number to pin name and pin name to number
        1 => [qw(Vdd)],
        2 => [qw(GP5 T1CKI OSC1 CLKIN)],
        3 => [qw(GP4 AN3 T1G OSC2 CLKOUT)],
        4 => [qw(GP3 MCLR Vpp)],
        5 => [qw(GP2 AN2 T0CKI INT COUT CCP1)],
        6 => [qw(GP1 AN1 CIN- Vref ICSPCLK)],
        7 => [qw(GP0 AN0 CIN+ ICSPDAT ULPWU)],
        8 => [qw(Vss)],
    };
    foreach my $k (keys %$h) {
        my $v = $h->{$k};
        foreach (@$v) {
            $h->{$_} = $k;
        }
    }
    return $h;
});

has clock_pins => (is => 'ro', default => sub {
    {
        out => 'CLKOUT',
        in => 'CLKIN',
    }
});

has oscillator_pins => (is => 'ro', default => sub {
    {
        1 => 'OSC1',
        2 => 'OSC2',
    }
});

has program_pins => (is => 'ro', default => sub {
    {
        clock => 'ICSPCLK',
        data => 'ICSPDAT',
    }
});

has io_ports => (is => 'ro', default => sub {
    {
        #port => tristate,
        GPIO => 'TRISIO',
    }
});

has input_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        GP0 => ['GPIO', 'TRISIO', 0],
        GP1 => ['GPIO', 'TRISIO', 1],
        GP2 => ['GPIO', 'TRISIO', 2],
        GP3 => ['GPIO', 'TRISIO', 3], # input only
        GP4 => ['GPIO', 'TRISIO', 4],
        GP5 => ['GPIO', 'TRISIO', 5],
    }
});

has output_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        GP0 => ['GPIO', 'TRISIO', 0],
        GP1 => ['GPIO', 'TRISIO', 1],
        GP2 => ['GPIO', 'TRISIO', 2],
        GP4 => ['GPIO', 'TRISIO', 4],
        GP5 => ['GPIO', 'TRISIO', 5],
    }
});

has analog_pins => (is => 'ro', default => sub {
        {
            # use ANSEL for pins AN0-AN7 and ANSELH for AN8-AN11
            #pin => number, bit
            AN0  => [7, 0],
            AN1  => [6, 1],
            AN2  => [5, 2],
            AN3  => [3,  3],
        }
});

has adc_channels => (is => 'ro', default => 4);
has adcs_bits  => (is => 'ro', default => sub {
    {
        2 => '000',
        4 => '100',
        8 => '001',
        16 => '101',
        32 => '010',
        64 => '110',
        internal => '111',
    }
});
has adc_chs_bits => (is => 'ro', default => sub {
        {
            #pin => chsbits
            AN0  => '0000',
            AN1  => '0001',
            AN2  => '0010',
            AN3  => '0011',
        }
});

has timer_prescaler => (is => 'ro', default => sub {
    {
        2 => '000',
        4 => '001',
        8 => '010',
        16 => '011',
        32 => '100',
        64 => '101',
        128 => '110',
        256 => '111',
    }
});

has wdt_prescaler => (is => 'ro', default => sub {
    {
        1 => '000',
        2 => '001',
        4 => '010',
        8 => '011',
        16 => '100',
        32 => '101',
        64 => '110',
        128 => '111',
    }
});

has timer_pins => (is => 'ro', default => sub {
    {
        TMR0 => { reg => 'TMR0', flag => 'T0IF', enable => 'T0IE', freg => 'INTCON', ereg => 'INTCON' },
        TMR1 => { reg => ['TMR1H', 'TMR1L'], freg => 'PIR1', ereg => 'PIE1', flag => 'TMR1IF', enable => 'TMR1E' },
        TMR2 => { reg => 'TMR2', freg => 'PIR1', flag => 'TMR2IF', enable => 'TMR2IE', ereg => 'PIE1' },
        T0CKI => 5,
        T1CKI => 2,
        T1G => 3,
    }
});

has ccp_pins => (is => 'ro', default => sub {
    {
        CCP1 => 'CCP1',
    }
});

#external interrupt
has eint_pins => (is => 'ro', default => sub {
    {
        INT => 5,
    }
});

has ioc_pins => (is => 'ro', default => sub {
    {
        GP0 => [7, 'IOC0', 'IOC'],
        GP1 => [6, 'IOC1', 'IOC'],
        GP2 => [5, 'IOC2', 'IOC'],
        GP3 => [4, 'IOC3', 'IOC'],
        GP4 => [3, 'IOC4', 'IOC'],
        GP5 => [2, 'IOC5', 'IOC'],
    }
});

has ioc_ports => (is => 'ro', default => sub {
    {
        GPIO => 'IOC',
        FLAG => 'GPIF',
        ENABLE => 'GPIE',
    }
});

has cmp_input_pins => (is => 'ro', default => sub {
    {
        'CIN+' => 'CIN+',
        'CIN-' => 'CIN-',
    }
});

has cmp_output_pins => (is => 'ro', default => sub {
    {
        COUT => 'COUT',
    }
});

has chip_config => (is => 'ro', default => sub {
    {
        on_off => {
            MCLRE => 0,
            WDT => 0,
            PWRTE => 0,
            CP => 0,
            BOREN => 0,
            IESO => 0,
            FCMEN => 0,
        },
        f_osc => {
            INTRC_OSC => 0,
        },
    }
});

my @rolenames = qw(CodeGen Operators Chip GPIO ADC ISR Timer Operations CCP Comparator);
my @roles = map (("VIC::PIC::Roles::$_", "VIC::PIC::Functions::$_"), @rolenames);
with @roles;

sub list_roles {
    my @arr = grep {!/CodeGen|Oper|Chip|ISR/} @rolenames;
    return wantarray ? @arr : [@arr];
}

1;
__END__

=encoding utf8

=head1 NAME

VIC::PIC::P12F683

=head1 SYNOPSIS

A class that describes the code to be generated for each specific
microcontroller that maps the VIC syntax back into assembly. This is the
back-end to VIC's front-end.

=head1 DESCRIPTION

INTERNAL CLASS.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
