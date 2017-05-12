package VIC::PIC::P18F452;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P18F442';

# role CodeGen
has type => (is => 'ro', default => 'p18f452');
has include => (is => 'ro', default => 'p18f452.inc');

# all memory is in bytes
has memory => (is => 'ro', default => sub {
    {
        flash => 16384, # words
        SRAM => 1536,
        EEPROM => 256,
    }
});

has address => (is => 'ro', default => sub {
    {
                # high # low
        isr => [ 0x0008, 0x0018 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x7FFF ],
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
            3 => [ 0x300, 0x3FF],
            4 => [ 0x400, 0x4FF],
            5 => [ 0x500, 0x5FF],
        },
        # remapping of these addresses automatically done by chip
        common => [ [0x000, 0x07F], [0xF80, 0xFFF] ],
        remap => [],
    }
});

1;

=encoding utf8

=head1 NAME

VIC::PIC::P18F452

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
