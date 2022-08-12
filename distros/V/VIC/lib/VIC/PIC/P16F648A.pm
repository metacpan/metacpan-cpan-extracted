package VIC::PIC::P16F648A;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P16F627A';

# role CodeGen
has type => (is => 'ro', default => 'p16f648a');
has include => (is => 'ro', default => 'p16f648a.inc');

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

1;
__END__

=encoding utf8

=head1 NAME

VIC::PIC::P16F648A

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
