package VIC::PIC::P18F242;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::Base';

# role CodeGen
has type => (is => 'ro', default => 'p18f242');
has include => (is => 'ro', default => 'p18f242.inc');

#role Chip
has f_osc => (is => 'ro', default => 4e6); # 4MHz internal oscillator
has pcl_size => (is => 'ro', default => 21); # program counter (PCL) size
has stack_size => (is => 'ro', default => 31); # 31 levels of 21-bit entries
has wreg_size => (is => 'ro', default => 8); # 8-bit register WREG
# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 8192, # words
        SRAM => 768,
        EEPROM => 256,
    }
});
has address => (is => 'ro', default => sub {
    {
                # high # low
        isr => [ 0x0008, 0x0018 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x3FFF ],
    }
});

has pin_counts => (is => 'ro', default => sub { {
    pdip => 28, ## PDIP or DIP ?
    soic => 28,
    total => 28,
    io => 22,
}});

has banks => (is => 'ro', default => sub {
    {
        count => 16,
        size => 0x100,
        gpr => {
            0 => [ 0x000, 0x0FF],
            1 => [ 0x100, 0x1FF],
            2 => [ 0x200, 0x2FF],
        },
        # remapping of these addresses automatically done by chip
        common => [ [0x000, 0x07F], [0xF80, 0xFFF] ],
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
        LVDCON => [0xFD2],
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
        CCPR1H => [0xFBF],
        CCPR1L => [0xFBE],
        CCP1CON => [0xFBD],
        CCPR2H => [0xFBC],
        CCPR2L => [0xFBB],
        CCP2CON => [0xFBA],
        TMR3H => [0xFB3],
        TMR3L => [0xFB2],
        T3CON => [0xFB1],
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
        TRISC => [0xF94],
        TRISB => [0xF93],
        TRISA => [0xF92],
        LATC => [0xF8B],
        LATB => [0xF8A],
        LATA => [0xF89],
        PORTC => [0xF82],
        PORTB => [0xF81],
        PORTA => [0xF80],
    }
});

has pins => (is => 'ro', default => sub {
    my $h = 
    {
        1 => [qw(MCLR Vpp)],
        2 => [qw(RA0 AN0)],
        3 => [qw(RA1 AN1)],
        4 => [qw(RA2 AN2 Vref-)],
        5 => [qw(RA3 AN3 Vref+)],
        6 => [qw(RA4 T0CKI)],
        7 => [qw(RA5 AN4 SS LVDIN)],
        8 => [qw(Vss)],
        9 => [qw(OSC1 CLKI)],
        10 => [qw(OSC2 CLKO RA6)],
        11 => [qw(RC0 T1OSO T1CKI)],
        12 => [qw(RC1 T1OSI CCP2)],
        13 => [qw(RC2 CCP1)],
        14 => [qw(RC3 SCK SCL)],
        15 => [qw(RC4 SDI SDA)],
        16 => [qw(RC5 SDO)],
        17 => [qw(RC6 TX CK)],
        18 => [qw(RC7 RX DT)],
        19 => [qw(Vss)],
        20 => [qw(Vdd)],
        21 => [qw(RB0 INT0)],
        22 => [qw(RB1 INT1)],
        23 => [qw(RB2 INT2)],
        24 => [qw(RB3 CCP2)],
        25 => [qw(RB4)],
        26 => [qw(RB5 PGM)],
        27 => [qw(RB6 PGC)],
        28 => [qw(RB7 PGD)],
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
        out => 'CLKO',
        in => 'CLKI',
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
        RA0 => ['PORTA', 'TRISA', 0],
        RA1 => ['PORTA', 'TRISA', 1],
        RA2 => ['PORTA', 'TRISA', 2],
        RA3 => ['PORTA', 'TRISA', 3], # input only
        RA4 => ['PORTA', 'TRISA', 4],
        RA5 => ['PORTA', 'TRISA', 5],
        RB0 => ['PORTB', 'TRISB', 0],
        RB1 => ['PORTB', 'TRISB', 1],
        RB2 => ['PORTB', 'TRISB', 2],
        RB3 => ['PORTB', 'TRISB', 3],
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
        RA0 => ['PORTA', 'TRISA', 0],
        RA1 => ['PORTA', 'TRISA', 1],
        RA2 => ['PORTA', 'TRISA', 2],
        RA3 => ['PORTA', 'TRISA', 3], # input only
        RA4 => ['PORTA', 'TRISA', 4],
        RA5 => ['PORTA', 'TRISA', 5],
        RB0 => ['PORTB', 'TRISB', 0],
        RB1 => ['PORTB', 'TRISB', 1],
        RB2 => ['PORTB', 'TRISB', 2],
        RB3 => ['PORTB', 'TRISB', 3],
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
            AN0  => [2, 0],
            AN1  => [3, 1],
            AN2  => [4, 2],
            AN3  => [5, 3],
            AN4  => [7, 4],
        }
});

has adc_channels => (is => 'ro', default => 5);
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
            AN4  => '0100',
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
        TMR0 => { reg => 'TMR0', freg => 'INTCON', flag => 'TMR0IF', enable => 'TMR0IE', ereg => 'INTCON' },
        TMR1 => { reg => ['TMR1H', 'TMR1L'], freg => 'PIR1', ereg => 'PIE1', flag => 'TMR1IF', enable => 'TMR1E' },
        TMR2 => { reg => 'TMR2', freg => 'PIR1', flag => 'TMR2IF', enable => 'TMR2IE', ereg => 'PIE1' },
        TMR3 => { reg => ['TMR3H', 'TMR3L'], freg => 'PIR2', ereg => 'PIE2', flag => 'TMR3IF', enable => 'TMR3E' },
        T0CKI => 6,
        T1OSO => 11,
        T1CKI => 11,
        T1OSI => 12,
    }
});

has ccp_pins => (is => 'ro', default => sub {
    {
        # multiple pins for multiplexing
        CCP2 => [12, 24],
        CCP1 => 13,
    }
});

#external interrupt
has eint_pins => (is => 'ro', default => sub {
    {
        INT0 => 21,
        INT1 => 22,
        INT2 => 23,
    }
});

has ioc_pins => (is => 'ro', default => sub {
    {
        RB4 => [25],
        RB5 => [26],
        RB6 => [27],
        RB7 => [28],
    }
});

has ioc_ports => (is => 'ro', default => sub {
    {
        FLAG => 'RBIF',
        ENABLE => 'RBIE',
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

my @rolenames = qw(CodeGen Operators Chip GPIO ADC ISR Timer Operations CCP
                    USART SPI I2C);
my @roles = map (("VIC::PIC::Roles::$_", "VIC::PIC::Functions::$_"), @rolenames);
with @roles;

sub list_roles {
    my @arr = grep {!/CodeGen|Oper|Chip|ISR/} @rolenames;
    return wantarray ? @arr : [@arr];
}

1;

=encoding utf8

=head1 NAME

VIC::PIC::P18F242

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
