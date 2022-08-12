package VIC::PIC::P18F14K50;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P18F13K50';

# role CodeGen
has type => (is => 'ro', default => 'p18f14k50');
has include => (is => 'ro', default => 'p18f14k50.inc');
# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 8192, # words
        SRAM => 768,
        EEPROM => 256,
    }
});

has address => (is => 'ro', default => sub {
    {           # high, low
        isr => [ 0x0008, 0x0018 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x3FFF ],
    }
});

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
        common => [ [0x000, 0x05F], [0xF60, 0xFFF] ],
        remap => [],
    }
});
1;

__END__

=encoding utf8

=head1 NAME

VIC::PIC::P18F14K50

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
