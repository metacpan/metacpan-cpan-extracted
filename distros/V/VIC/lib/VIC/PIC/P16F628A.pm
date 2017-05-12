package VIC::PIC::P16F628A;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P16F627A';
# role CodeGen
has 'type' => (is => 'ro', default => 'p16f628a');
has 'include' => (is => 'ro', default => 'p16f628a.inc');
has 'memory' => (is => 'ro', default => sub {
    {
        flash => 2048, # words
        SRAM => 224,
        EEPROM => 128,
    }
});
has 'address' => (is => 'ro', default => sub {
    {
        isr => [ 0x0004 ],
        reset => [ 0x0000 ],
        range => [ 0x0000, 0x07FF ],
    }
});

1;
__END__

=encoding utf8

=head1 NAME

VIC::PIC::P16F628A

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
