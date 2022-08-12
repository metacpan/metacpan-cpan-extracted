package VIC::PIC::P18LF14K50;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Moo;
extends 'VIC::PIC::P18F14K50';

# role CodeGen
has type => (is => 'ro', default => 'p18lf14k50');
has include => (is => 'ro', default => 'p18lf14k50.inc');
1;

__END__

=encoding utf8

=head1 NAME

VIC::PIC::P18LF14K50

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
