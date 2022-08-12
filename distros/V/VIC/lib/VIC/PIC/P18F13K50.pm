package VIC::PIC::P18F13K50;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::Base';

# role CodeGen
has type => (is => 'ro', default => 'p18f13k50');
has include => (is => 'ro', default => 'p18f13k50.inc');

#role Chip
has f_osc => (is => 'ro', default => 4e6); # 4MHz internal oscillator
has pcl_size => (is => 'ro', default => 21); # program counter (PCL) size
has stack_size => (is => 'ro', default => 31); # 31 levels of 21-bit entries
has wreg_size => (is => 'ro', default => 8); # 8-bit register WREG
# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 4096, # words
        SRAM => 512,
        EEPROM => 256,
    }
});
has address => (is => 'ro', default => sub {
    {           # high, low
        isr => [ 0x0008, 0x0018 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x1FFF ],
    }
});

has pin_counts => (is => 'ro', default => sub { {
    pdip => 20, ## PDIP or DIP ?
    soic => 20,
    ssop => 20,
    qfn => 20,
    total => 20,
    io => 15,
}});

has banks => (is => 'ro', default => sub {
    {
        count => 16,
        size => 0x100,
        gpr => {
            0 => [ 0x000, 0x0FF],
            2 => [ 0x200, 0x2FF],
        },
        # remapping of these addresses automatically done by chip
        common => [ [0x000, 0x05F], [0xF60, 0xFFF] ],
        remap => [],
    }
});

has registers => (is => 'ro', default => sub {
    {
        TOSU => [0xFFF],
        TOSH => [0xFFE],
        TOSL => [0xFFD],
        STKPTR => [0xFFC],
        PCLATU => [0xFFB],
        PCLATH => [0xFFA],
        PCL => [0xFF9],
        TBLPTRU => [0xFF8],
        TBLPTRH => [0xFF7],
        TBLPTRL => [0xFF6],
        TABLAT => [0xFF5],
        PRODH => [0xFF4],
        PRODL => [0xFF3],
        INTCON => [0xFF2],
        INTCON2 => [0xFF1],
        INTCON3 => [0xFF0],
        INDF0 => [0xFEF],
        POSTINC0 => [0xFEE],
        POSTDEC0 => [0xFED],
        PREINC0 => [0xFEC],
        PLUSW0 => [0xFEB],
        FSR0H => [0xFEA],
        FSR0L => [0xFE9],
        WREG => [0xFE8],
        INDF1 => [0xFE7],
        POSTINC1 => [0xFE6],
        POSTDEC1 => [0xFE5],
        PREINC1 => [0xFE4],
        PLUSW1 => [0xFE3],
        FSR1H => [0xFE2],
        FSR1L => [0xFE1],
        BSR => [0xFE0],
        INDF2 => [0xFDF],
        POSTINC2 => [0xFDE],
        POSTDEC2 => [0xFDD],
        PREINC2 => [0xFDC],
        PLUSW2 => [0xFDB],
        FSR2H => [0xFDA],
        FSR2L => [0xFD9],
        STATUS => [0xFD8],
        TMR0H => [0xFD7],
        TMR0L => [0xFD6],
        T0CON => [0xFD5],
        OSCCON => [0xFD3],
        OSCCON2 => [0xFD2],
        WDTCON => [0xFD1],
        RCON => [0xFD0],
        TMR1H => [0xFCF],
        TMR1L => [0xFCE],
        T1CON => [0xFCD],
        TMR2 => [0xFCC],
        PR2 => [0xFCB],
        T2CON => [0xFCA],
        SSPBUF => [0xFC9],
        SSPADD => [0xFC8],
        SSPSTAT => [0xFC7],
        SSPCON1 => [0xFC6],
        SSPCON2 => [0xFC5],
        ADRESH => [0xFC4],
        ADRESL => [0xFC3],
        ADCON0 => [0xFC2],
        ADCON1 => [0xFC1],
        ADCON2 => [0xFC0],
        CCPR1H => [0xFBF],
        CCPR1L => [0xFBE],
        CCP1CON => [0xFBD],
        REFCON2 => [0xFBC],
        REFCON1 => [0xFBB],
        REFCON0 => [0xFBA],
        PSTRCON => [0xFB9],
        BAUDCON => [0xFB8],
        PWM1CON => [0xFB7],
        ECCP1AS => [0xFB6],
        TMR3H => [0xFB3],
        TMR3L => [0xFB2],
        T3CON => [0xFB1],
        SPBRGH => [0xFB0],
        SPBRG => [0xFAF],
        RCREG => [0xFAE],
        TXREG => [0xFAD],
        TXSTA => [0xFAC],
        RCSTA => [0xFAB],
        EEADR => [0xFA9],
        EEDATA => [0xFA8],
        EECON2 => [0xFA7],
        EECON1 => [0xFA6],
        IPR2 => [0xFA2],
        PIR2 => [0xFA1],
        PIE2 => [0xFA0],
        IPR1 => [0xF9F],
        PIR1 => [0xF9E],
        PIE1 => [0xF9D],
        OSCTUNE => [0xF9B],
        TRISC => [0xF94],
        TRISB => [0xF93],
        TRISA => [0xF92],
        LATC => [0xF8B],
        LATB => [0xF8A],
        LATA => [0xF89],
        PORTC => [0xF82],
        PORTB => [0xF81],
        PORTA => [0xF80],
        ANSELH => [0xF7F],
        ANSEL => [0xF7E],
        IOCB => [0xF7A],
        IOCA => [0xF79],
        WPUB => [0xF78],
        WPUA => [0xF77],
        SLRCON => [0xF76],
        SSPMASK => [0xF6F],
        CM1CON0 => [0xF6D],
        CM2CON1 => [0xF6C],
        CM2CON0 => [0xF6B],
        SRCON1 => [0xF69],
        SRCON0 => [0xF68],
        UCON => [0xF64],
        USTAT => [0xF63],
        UIR => [0xF63],
        UCFG => [0xF61],
        UIE => [0xF60],
        UEIR => [0xF5F],
        UFRMH => [0xF5E],
        UFRML => [0xF5D],
        UADDR => [0xF5C],
        UEIE => [0xF5B],
        UEP7 => [0xF5A],
        UEP6 => [0xF59],
        UEP5 => [0xF58],
        UEP4 => [0xF57],
        UEP3 => [0xF56],
        UEP2 => [0xF55],
        UEP1 => [0xF54],
        UEP0 => [0xF53],
    }
});

has pins => (is => 'ro', default => sub {
    my $h = {
        # number to pin name and pin name to number
        1 => [qw(Vdd)],
        2 => [qw(RA5 IOCA5 OSC1 CLKIN)],
        3 => [qw(RA4 AN3 IOCA3 OSC2 CLKOUT)],
        4 => [qw(RA3 IOCA3 MCLR Vpp)],
        5 => [qw(RC5 CCP1 P1A T0CKI)],
        6 => [qw(RC4 P1B C12OUT SRQ)],
        7 => [qw(RC3 AN7 P1C C12IN3- PGM)],
        8 => [qw(RC6 AN8 SS T13CKI T1OSCI)],
        9 => [qw(RC7 AN9 SDO T1OSCO)],
        10 => [qw(RB7 IOCB7 TX CK)],
        11 => [qw(RB6 IOCB6 SCK SCL)],
        12 => [qw(RB5 AN11 IOCB5 RX DT)],
        13 => [qw(RB4 AN10 IOCB4 SDI SDA)],
        14 => [qw(RC2 AN6 P1D C12IN2- CVref INT2)],
        15 => [qw(RC1 AN5 C12IN1- INT1 Vref-)],
        16 => [qw(RC0 AN4 C12IN+ INT0 Vref+)],
        17 => [qw(VUSB)],
        18 => [qw(RA1 IOCA1 D- PGC)],
        19 => [qw(RA0 IOCA0 D+ PGD)],
        20 => [qw(Vss)],
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
        in => 'OSC1',
        out => 'OSC2',
    }
});

has program_pins => (is => 'ro', default => sub {
    {
        clock => 'PGC',
        data => 'PGD',
        enable => 'PGM',
    }
});

has io_ports => (is => 'ro', default => sub {
    {
        #port => tristate,
        PORTA => 'TRISA',
        PORTB => 'TRISB',
        PORTC => 'TRISC',
    }
});

has input_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        RA0 => ['PORTA', 'TRISA', 0], # input only
        RA1 => ['PORTA', 'TRISA', 1], # input only
        RA3 => ['PORTA', 'TRISA', 3], # input only
        RA4 => ['PORTA', 'TRISA', 4],
        RA5 => ['PORTA', 'TRISA', 5],
        RB4 => ['PORTB', 'TRISB', 4],
        RB5 => ['PORTB', 'TRISB', 5],
        RB6 => ['PORTB', 'TRISB', 6],
        RB7 => ['PORTB', 'TRISB', 7],
        RC0 => ['PORTC', 'TRISC', 0],
        RC1 => ['PORTC', 'TRISC', 1],
        RC2 => ['PORTC', 'TRISC', 2],
        RC3 => ['PORTC', 'TRISC', 3],
        RC4 => ['PORTC', 'TRISC', 4],
        RC5 => ['PORTC', 'TRISC', 5],
        RC6 => ['PORTC', 'TRISC', 6],
        RC7 => ['PORTC', 'TRISC', 7],
    }
});

has output_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        RA4 => ['PORTA', 'TRISA', 4],
        RA5 => ['PORTA', 'TRISA', 5],
        RB4 => ['PORTB', 'TRISB', 4],
        RB5 => ['PORTB', 'TRISB', 5],
        RB6 => ['PORTB', 'TRISB', 6],
        RB7 => ['PORTB', 'TRISB', 7],
        RC0 => ['PORTC', 'TRISC', 0],
        RC1 => ['PORTC', 'TRISC', 1],
        RC2 => ['PORTC', 'TRISC', 2],
        RC3 => ['PORTC', 'TRISC', 3],
        RC4 => ['PORTC', 'TRISC', 4],
        RC5 => ['PORTC', 'TRISC', 5],
        RC6 => ['PORTC', 'TRISC', 6],
        RC7 => ['PORTC', 'TRISC', 7],
    }
});

has analog_pins => (is => 'ro', default => sub {
        {
            # use ANSEL for pins AN0-AN7 and ANSELH for AN8-AN11
            #pin => number, bit
            AN3  => [3,  3],
            AN4  => [16, 4],
            AN5  => [15, 5],
            AN6  => [14, 6],
            AN7  => [ 7, 7],
            AN8  => [ 8, 8],
            AN9  => [ 9, 9],
            AN10 => [13, 10],
            AN11 => [12, 12],
        }
});

has adc_channels => (is => 'ro', default => 9);
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
            AN3  => '0011',
            AN4  => '0100',
            AN5  => '0101',
            AN6  => '0110',
            AN7  => '0111',
            AN8  => '1000',
            AN9  => '1001',
            AN10 => '1010',
            AN11 => '1011',
            DAC => '1110',
            FVR => '1111',
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
        TMR0 => { reg => ['TMR0H', 'TMR0L'], flag => 'TMR0IF',
                  enable => 'TMR0IE', freg => 'INTCON', ereg => 'INTCON' },
        TMR1 => { reg => ['TMR1H', 'TMR1L'], flag => 'TMR1IF',
                    enable => 'TMR1IE', freg => 'PIR1', ereg => 'PIE1' },
        TMR2 => { reg => 'TMR2', flag => 'TMR2IF',
                    enable => 'TMR2IE', freg => 'PIR1', ereg => 'PIE1' },
        TMR3 => { reg => ['TMR3H', 'TMR3L'], flag => 'TMR3IF',
                    enable => 'TMR3IE', freg => 'PIR2', ereg => 'PIE2' },
        T0CKI => 5,
        T13CKI => 8,
        T1OSCI => 8,
        T1OSCO => 9,
    }
});

has eccp_pins => (is => 'ro', default => sub {
    {   # pin => pin_no, tris, bit
        P1D => [14, 'TRISC', 2],
        P1C => [7, 'TRISC', 3],
        P1B => [6, 'TRISC', 4],
        P1A => [5, 'TRISC', 5],
        CCP1 => [5, 'TRISC', 5],
    }
});

#external interrupt
has eint_pins => (is => 'ro', default => sub {
    {
        INT0 => 16,
        INT1 => 15,
        INT2 => 14,
    }
});

has ioc_pins => (is => 'ro', default => sub {
    {
        RA0 => [19, 'IOCA0', 'IOCA'],
        RA1 => [18, 'IOCA1', 'IOCA'],
        RA3 => [4,  'IOCA3', 'IOCA'],
        RA4 => [3,  'IOCA4', 'IOCA'],
        RA5 => [2,  'IOCA5', 'IOCA'],
        RB4 => [13, 'IOCB4', 'IOCB'],
        RB5 => [12, 'IOCB5', 'IOCB'],
        RB6 => [11, 'IOCB6', 'IOCB'],
        RB7 => [10, 'IOCB7', 'IOCB'],
    }
});

has ioc_ports => (is => 'ro', default => sub {
    {
        PORTA => 'IOCA',
        PORTB => 'IOCB',
        FLAG => 'RABIF',
        ENABLE => 'RABIE',
    }
});

has usart_pins => (is => 'ro', default => sub {
    {
        async_in => 'RX',
        async_out => 'TX',
        sync_clock => 'CK',
        sync_data => 'DT',
        #TODO
        rx_int => {},
        tx_int => {},
        # this defines the port names that the user can use
        # validly. The port names define whether the user wants to use them in
        # synchronous or asynchronous mode
        UART => 'async',
        USART => 'sync',
    }
});

sub usart_baudrates {}

has selector_pins => (is => 'ro', default => sub {
    {
        'spi_or_i2c' => 'SS',
    }
});

has spi_pins => (is => 'ro', default => sub {
    {
        data_out => 'SDO',
        data_in => 'SDI',
        clock => 'SCK',
    }
});

has i2c_pins => (is => 'ro', default => sub {
    {
        data => 'SDA',
        clock => 'SCL',
    }
});

has cmp_input_pins => (is => 'ro', default => sub {
    {
        'C12IN+' => 'C12IN+',
        'C12IN1-' => 'C12IN1-',
        'C12IN2-' => 'C12IN2-',
        'C12IN3-' => 'C12IN3-',
    }
});

has cmp_output_pins => (is => 'ro', default => sub {
    {
        C12OUT => 'C12OUT',
        CVref => 'CVref',
    }
});

has usb_pins => (is => 'ro', default => sub {
    {
        'D+' => 'D+',
        'D-' => 'D-',
        'VUSB' => 'VUSB',
    }
});

has srlatch => (is => 'ro', default => sub {
    {
        'SRQ' => 'SRQ',
    }
});

my @rolenames = qw(CodeGen Operators Chip GPIO ADC ISR Timer Operations ECCP
                    USART SPI I2C Comparator USB SRLatch);
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

VIC::PIC::P18F13K50

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
