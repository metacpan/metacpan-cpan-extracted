# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Image is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package App::MathImage::Regexp::Common::OEIS;
use 5.005;
use strict;
use Carp;

# no import(), don't want %RE or builtins, and will call pattern() by full name
use Regexp::Common ();

use vars '$VERSION';
$VERSION = 110;

## no critic (RequireInterpolationOfMetachars)

# uncomment this to run the ### lines
# use Smart::Comments;


# "[:digit:]" available in perl 5.6
# "0-9"       in perl 5.005 and earlier
use constant _DIGIT => do {
  local $^W = 0;
  eval q{'0' =~ /[[:digit:]]/ ? '[:digit:]' : '0-9'}
    || die "Oops, eval for [:digit:] error: ",$@;
};

# A123456 or A1234567
#
Regexp::Common::pattern
  (name   => ['OEIS','anum'],
   create => '(?k:A(?k:['._DIGIT().']{6,7}))');

# Regexp::Common::pattern
#   (name   => ['OEIS','bfile'],
#    create => '(?k:b(?k:['._DIGIT().']{6,7})\.txt)');

1;
__END__

=for stopwords Ryde

=head1 NAME

App::MathImage::Regexp::Common::OEIS -- regexps for some OEIS things

=for test_synopsis my ($str)

=head1 SYNOPSIS

 use Regexp::Common 'OEIS', 'no_defaults';
 if ($str =~ /$RE{OEIS}{anum}/) {
    # ...
 }

=head1 DESCRIPTION

I<Experimental ...>

This module is regexps for some things related to Sloane's Online
Encyclopedia of Integer Sequences

=over

http://oeis.org

=back

See L<Regexp::Common> for basic operation of C<Regexp::Common>.

=head2 Patterns

=over

=item C<$RE{OEIS}{anum}>

Match an OEIS A-number, either 6 or 7 digits

    A000040
    A0234567

The C<-keep> option captures are

    $1    whole string "A000040"
    $2    number part "000040"

A minimum of 6 digits are required, so for example "A123" is not an
A-number.

As of Nov 2013 there are about 220,000 A-numbers in use so 6 digits suffice.
Rumour has it the plan is to go 7 digits when a million sequences is reached
and the regexp here anticipates that.

=back

=cut

# =head1 IMPORTS
#
# This module should be loaded through the C<Regexp::Common> mechanism, see
# L<Regexp::Common/Loading specific sets of patterns.>.  Remember that loading
# a non-builtin pattern like this module also loads all the builtin patterns.
#
#     # OEIS plus all builtins
#     use Regexp::Common 'OEIS';
#
# If you want only C<$RE{OEIS}> then add C<no_defaults> (or a specific set of
# desired builtins).
#
#     # OEIS alone
#     use Regexp::Common 'OEIS', 'no_defaults';

=head1 SEE ALSO

L<Regexp::Common>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see <http://www.gnu.org/licenses/>.

=cut
