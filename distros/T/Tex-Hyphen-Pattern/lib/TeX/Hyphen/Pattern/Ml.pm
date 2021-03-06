## no critic qw(RequirePodSections)    # -*- cperl -*-
# This file is auto-generated by the Perl TeX::Hyphen::Pattern Suite hyphen
# pattern catalog generator. This code generator comes with the
# TeX::Hyphen::Pattern module distribution in the tools/ directory
#
# Do not edit this file directly.

package TeX::Hyphen::Pattern::Ml 0.100;
use strict;
use warnings;
use 5.014000;
use utf8;

use Moose;

my $pattern_file = q{};
while (<DATA>) {
    $pattern_file .= $_;
}

sub data {
    return $pattern_file;
}

sub version {
    return $TeX::Hyphen::Pattern::Ml::VERSION;
}

1;
## no critic qw(RequirePodAtEnd RequireASCII ProhibitFlagComments)

=encoding utf8

=head1 C<Ml> hyphenation pattern class

=head1 SUBROUTINES/METHODS

=over 4

=item $pattern-E<gt>data();

Returns the pattern data.

=item $pattern-E<gt>version();

Returns the version of the pattern package.

=back

=head1 Copyright

The copyright of the patterns is not covered by the copyright of this package
since this pattern is generated from the source at
L<svn://tug.org/texhyphen/trunk/hyph-utf8/tex/generic/hyph-utf8/patterns/tex/hyph-ml.tex>

The copyright of the source can be found in the DATA section in the source of
this package file.

=cut

__DATA__
% These patterns originate from
%    http://git.savannah.gnu.org/cgit/smc/hyphenation.git/tree/)
% and have been adapted for hyph-utf8 (for use in TeX).
%
%  Hyphenation for Malayalam
%  Copyright (C) 2008-2010 Santhosh Thottingal <santhosh.thottingal@gmail.com>
%
%  This library is free software; you can redistribute it and/or
%  modify it under the terms of the GNU Lesser General Public
%  License as published by the Free Software Foundation;
%  version 3 or later version of the License.
%
%  This library is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%  Lesser General Public License for more details.
%
%  You should have received a copy of the GNU Lesser General Public
%  License along with this library; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
%
\patterns{
% GENERAL RULE
% Do not break either side of ZERO-WIDTH JOINER  (U+200D)
2‍2
% Break on both sides of ZERO-WIDTH NON JOINER  (U+200C)
1‌1
% Break before or after any independent vowel.
1അ1
1ആ1
1ഇ1
1ഈ1
1ഉ1
1ഊ1
1ഋ1
1ൠ1
1ഌ1
1ൡ1
1എ1
1ഏ1
1ഐ1
1ഒ1
1ഓ1
1ഔ1
% Break after any dependent vowel, but not before.
ാ1
ി1
ീ1
ു1
ൂ1
ൃ1
െ1
േ1
ൈ1
ൊ1
ോ1
ൌ1
ൗ1
% Break before or after any consonant.
1ക
1ഖ
1ഗ
1ഘ
1ങ
1ച
1ഛ
1ജ
1ഝ
1ഞ
1ട
1ഠ
1ഡ
1ഢ
1ണ
1ത
1ഥ
1ദ
1ധ
1ന
1പ
1ഫ
1ബ
1ഭ
1മ
1യ
1ര
1റ
1ല
1ള
1ഴ
1വ
1ശ
1ഷ
1സ
1ഹ
% Do not break before anusvara, visarga
2ഃ1
2ം1
% Do not break either side of virama (may be within conjunct).
2്2
% Do not break left side of chillu
ന്2
ര്2
ള്2
ല്2
ക്2
ണ്2
2ന്‍
2ല്‍
2ള്‍
2ണ്‍
2ര്‍
2ക്‍
2ൺ
2ൻ
2ർ
2ൽ
2ൾ
2ൿ
}

