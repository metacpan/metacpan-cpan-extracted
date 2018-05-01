# -*- Perl -*-

package Unix::OpenBSD::Random;

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/arc4random arc4random_buf arc4random_uniform/;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'Unix::OpenBSD::Random', $VERSION );

# see Random.xs for the code

1;
__END__

=head1 NAME

Unix::OpenBSD::Random - interface to arc4random(3) on OpenBSD

=head1 SYNOPSIS

  use Unix::OpenBSD::Random qw(arc4random arc4random_uniform);

  my $x = arc4random();
  my $y = arc4random(2);    # coinflip

=head1 DESCRIPTION

This module is a wafer-thin wraper around the L<arc4random(3)> library
function on OpenBSD. Other OS have this function call though may require
L<arc4random_stir(3)> or such calls that this module does not support.

=head1 FUNCTIONS

=over 4

=item B<arc4random>

Returns an integer in the C<uint32_t> range.

=item B<arc4random_buf> I<length>

Returns a string filled with the given number of bytes of random data.
This string may contain non-printable or even C<NUL> characters so might
best be converted to some other form before being displayed or used
where such characters may cause problems.

  my $buf = arc4random_buf(8);

  printf "%vx\n", $buf;

  my $string = unpack "H*", $buf;

Will throw an exception if the I<length> is outside the range of a
C<size_t>.

Note that this interface has been made more Perl-like than the C version
C<arc4random_buf(buf, nbytes)>.

=item B<arc4random_uniform> I<upper_bound>

Returns an integer no more than the I<upper_bound>. Avoids modulo bias.
Will throw an exception if I<upper_bound> is outside the range of
allowed values for C<uint32_t>.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-unix-openbsd-random at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Unix-OpenBSD-Random>.

Patches might best be applied towards:

L<https://github.com/thrig/Unix-OpenBSD-Random>

=head2 Known Issues

The newly being written thing and lack of testing on 32-bit systems.
Lack of XS skill on the part of the author.

C<arc4random_uniform> accepts C<0> as an upper bound (and
C<arc4random_buf> a length of C<0>). If this is a problem add a check
before calling into this module.

=head1 SEE ALSO

L<https://man.openbsd.org/arc4random.3>

L<https://www.openbsd.org/papers/eurobsdcon2014_arc4random/mgp00001.html>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
