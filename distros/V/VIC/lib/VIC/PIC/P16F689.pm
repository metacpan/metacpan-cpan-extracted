package VIC::PIC::P16F689;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P16F687';

# role CodeGen
has type => (is => 'ro', default => 'p16f689');
has include => (is => 'ro', default => 'p16f689.inc');

# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 4096, # words
        SRAM => 256,
        EEPROM => 256,
    }
});
has address => (is => 'ro', default => sub {
    {
        isr => [ 0x0004 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x0FFF ],
    }
});

has banks => (is => 'ro', default => sub {
    {
        count => 4,
        size => 0x80,
        gpr => {
            0 => [ 0x020, 0x07F],
            1 => [ 0x0A0, 0x0EF],
            2 => [ 0x120, 0x16F],
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
        PORTA => [0x005, 0x105],
        TRISA => [0x085, 0x185],
        PORTB => [0x006, 0x106],
        TRISB => [0x086, 0x186],
        PORTC => [0x007, 0x107],
        TRISC => [0x087, 0x187],
        PCLATH => [0x00A, 0x08A, 0x10A, 0x18A],
        INTCON => [0x00B, 0x08B, 0x10B, 0x18B],
        PIR1 => [0x00C],
        PIE1 => [0x08C],
        EEDAT => [0x10C],
        EECON1 => [0x18C],
        PIR2 => [0x00D],
        PIE2 => [0x08D],
        EEADR => [0x10D],
        EECON2 => [0x18D], # not addressable apparently
        TMR1L => [0x00E],
        PCON => [0x08E],
        EEDATH => [0x10E],
        TMR1H => [0x00F],
        OSCCON => [0x08F],
        EEADRH => [0x10F],
        T1CON => [0x010],
        OSCTUNE => [0x090],
        SSPBUF => [0x013],
        SSPADD => [0x093],
        SSPCON => [0x014],
        SSPSTAT => [0x094],
        WPUA => [0x095],
        WPUB => [0x115],
        IOCA => [0x096],
        IOCB => [0x116],
        WDTCON => [0x097],
        RCSTA => [0x018],
        TXSTA => [0x098],
        VRCON => [0x118],
        TXREG => [0x019],
        SPBRG => [0x099],
        CM1CON0 => [0x119],
        RCREG => [0x01A],
        SPBRGH => [0x09A],
        CM2CON0 => [0x11A],
        BAUDCTL => [0x09B],
        CM2CON1 => [0x11B],
        ADRESH => [0x01E],
        ADRESL => [0x09E],
        ANSEL => [0x11E],
        SRCON => [0x19E],
        ADCON0 => [0x01F],
        ADCON1 => [0x09F],
        ANSELH => [0x11F],
    }
});

1;
__END__

=encoding utf8

=head1 NAME

VIC::PIC::P16F689

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
