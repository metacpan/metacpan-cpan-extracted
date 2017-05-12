package VIC::PIC::P16F627A;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use Moo;
extends 'VIC::PIC::Base';

# role CodeGen
has type => (is => 'ro', default => 'p16f627a');
has include => (is => 'ro', default => 'p16f627a.inc');

#role Chip
has f_osc => (is => 'ro', default => 4e6); # 4MHz internal oscillator
has pcl_size => (is => 'ro', default => 13); # program counter (PCL) size
has stack_size => (is => 'ro', default => 8); # 8 levels of 13-bit entries
has wreg_size => (is => 'ro', default => 8); # 8-bit register WREG
# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 1024, # words
        SRAM => 224,
        EEPROM => 128,
    }
});
has address => (is => 'ro', default => sub {
    {
        isr => [ 0x0004 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x03FF ],
    }
});

has pin_counts => (is => 'ro', default => sub { {
    pdip => 18, ## PDIP or DIP ?
    soic => 20,
    ssop => 20,
    qfn => 28,
    total => 20,
    io => 16,
}});

has banks => (is => 'ro', default => sub {
    {
        count => 4,
        size => 0x80,
        gpr => {
            0 => [ 0x020, 0x07F],
            1 => [ 0x0A0, 0x0EF],
            2 => [ 0x120, 0x14F],
        },
        # remapping of these addresses automatically done by chip
        common => [0x070, 0x07F],
        remap => [
            [0x0F0, 0x0FF],
            [0x170, 0x17F],
            [0x1F0, 0x1FF],
        ],
    }
});

has registers => (is => 'ro', default => sub {
    {
        INDF => [0x000, 0x080, 0x100, 0x180], # indirect addressing
        TMR0 => [0x001, 0x101],
        OPTION_REG => [0x081, 0x181],
        PCL => [0x002, 0x082, 0x102, 0x182],
        STATUS => [0x003, 0x083, 0x103, 0x183],
        FSR => [0x004, 0x084, 0x104, 0x184],
        PORTA => [0x005],
        TRISA => [0x085],
        PORTB => [0x006, 0x106],
        TRISB => [0x086, 0x186],
        PCLATH => [0x00A, 0x08A, 0x10A, 0x18A],
        INTCON => [0x00B, 0x08B, 0x10B, 0x18B],
        PIR1 => [0x00C],
        PIE1 => [0x08C],
        TMR1L => [0x00E],
        PCON => [0x08E],
        TMR1H => [0x00F],
        T1CON => [0x010],
        TMR2 => [0x011],
        T2CON => [0x012],
        PR2 => [0x092],
        CCPR1L => [0x015],
        CCPR1H => [0x016],
        CCP1CON => [0x017],
        RCSTA => [0x018],
        TXSTA => [0x098],
        TXREG => [0x019],
        SPBRG => [0x099],
        RCREG => [0x01A],
        EEDATA => [0x09A],
        EEADR => [0x09B],
        EECON1 => [0x09C],
        EECON2 => [0x09D], # not addressable apparently
        CMCON => [0x01F],
        VRCON => [0x09F],
    }
});

has pins => (is => 'ro', default => sub {
    my $h = {
        # number to pin name and pin name to number
        1 => [qw(RA2 AN2 Vref)],
        2 => [qw(RA3 AN3 CMP1)],
        3 => [qw(RA4 T0CKI CMP2)],
        4 => [qw(RA5 MCLR Vpp)],
        5 => [qw(Vss)],
        6 => [qw(RB0 INT)],
        7 => [qw(RB1 RX DT)],
        8 => [qw(RB2 TX CK)],
        9 => [qw(RB3 CCP1)],
        10 => [qw(RB4 PGM)],
        11 => [qw(RB5)],
        12 => [qw(RB6 T1OSO T1CKI PGC)],
        13 => [qw(RB7 T1OSI PGD)],
        14 => [qw(Vdd)],
        15 => [qw(RA6 OSC2 CLKOUT)],
        16 => [qw(RA7 OSC1 CLKIN)],
        17 => [qw(RA0 AN0)],
        18 => [qw(RA1 AN1)],
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
    }
});

has input_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        RA0 => ['PORTA', 'TRISA', 0],
        RA1 => ['PORTA', 'TRISA', 1],
        RA2 => ['PORTA', 'TRISA', 2],
        RA3 => ['PORTA', 'TRISA', 3],
        RA4 => ['PORTA', 'TRISA', 4],
        RA5 => ['PORTA', 'TRISA', 5], # input only
        RA6 => ['PORTA', 'TRISA', 6],
        RA7 => ['PORTA', 'TRISA', 7],
        RB0 => ['PORTB', 'TRISB', 0],
        RB1 => ['PORTB', 'TRISB', 1],
        RB2 => ['PORTB', 'TRISB', 2],
        RB3 => ['PORTB', 'TRISB', 3],
        RB4 => ['PORTB', 'TRISB', 4],
        RB5 => ['PORTB', 'TRISB', 5],
        RB6 => ['PORTB', 'TRISB', 6],
        RB7 => ['PORTB', 'TRISB', 7],
    }
});

has output_pins => (is => 'ro', default => sub {
    {
        #I/O => [port, tristate, bit]
        RA0 => ['PORTA', 'TRISA', 0],
        RA1 => ['PORTA', 'TRISA', 1],
        RA2 => ['PORTA', 'TRISA', 2],
        RA3 => ['PORTA', 'TRISA', 3],
        RA4 => ['PORTA', 'TRISA', 4],
        RA6 => ['PORTA', 'TRISA', 6],
        RA7 => ['PORTA', 'TRISA', 7],
        RB0 => ['PORTB', 'TRISB', 0],
        RB1 => ['PORTB', 'TRISB', 1],
        RB2 => ['PORTB', 'TRISB', 2],
        RB3 => ['PORTB', 'TRISB', 3],
        RB4 => ['PORTB', 'TRISB', 4],
        RB5 => ['PORTB', 'TRISB', 5],
        RB6 => ['PORTB', 'TRISB', 6],
        RB7 => ['PORTB', 'TRISB', 7],
    }
});

has analog_pins => (is => 'ro', default => sub { {} });

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
        TMR0 => { reg => 'TMR0', freg => 'INTCON', flag => 'T0IF', enable => 'T0IE', ereg => 'INTCON' },
        TMR1 => { reg => ['TMR1H', 'TMR1L'], freg => 'PIR1', ereg => 'PIE1', flag => 'TMR1IF', enable => 'TMR1IE' },
        TMR2 => { reg => 'TMR2', freg => 'PIR1', flag => 'TMR2IF', ereg => 'PIE1', enable => 'TMR2IF' },
        # timer 0 clock input
        T0CKI => 3,
        # timer 1 clock input
        T1CKI => 12,
        # timer oscillator input
        T1OSI => 13,
        # timer oscillator output
        T1OSO => 12,
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
        INT => 6,
    }
});

has ioc_pins => (is => 'ro', default => sub {
    {
        ## there is no special IOC register, so use nothing
        RB4 => [10],
        RB5 => [11],
        RB6 => [12],
        RB7 => [13],
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

sub usart_baudrates {
    carp "Unimplemented";
    return;
}

has cmp_output_pins => (is => 'ro', default => sub {
    {
        CMP1 => 'CMP1',
        CMP2 => 'CMP2',
    }
});

has cmp_input_pins => (is => 'ro', default => sub {
    {
        AN0 => 'AN0',
        AN1 => 'AN1',
        AN2 => 'AN2',
        AN3 => 'AN3',
    }
});

my @rolenames = qw(CodeGen Operators Chip GPIO ISR Timer Operations CCP USART Comparator);
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

VIC::PIC::P16F627A

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
