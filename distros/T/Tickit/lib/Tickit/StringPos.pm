#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2016 -- leonerd@leonerd.org.uk

package Tickit::StringPos;

use strict;
use warnings;

our $VERSION = '0.66';

# XS code comes from Tickit itself
require Tickit;

=head1 NAME

C<Tickit::StringPos> - store string position counters

=head1 SYNOPSIS

 use Tickit::StringPos;
 use Tickit::Utils qw( string_count );

 my $pos = Tickit::StringPos->zero;
 string_count( "Here is a message", $pos );

 print "The message consumes ", $pos->columns, " columns\n";

=head1 DESCRIPTION

Instances in this object class store four position counters that relate to
counting strings.

The C<bytes> member counts UTF-8 bytes which encode individual codepoints. For
example the Unicode character U+00E9 is encoded by two bytes 0xc3, 0xa9; it
would increment the bytes counter by 2 and the C<codepoints> counter by 1.

The C<codepoints> member counts individual Unicode codepoints.

The C<graphemes> member counts whole composed graphical clusters of
codepoints, where combining accents which count as individual codepoints do
not count as separate graphemes. For example, the codepoint sequence U+0065
U+0301 would increment the C<codepoint> counter by 2 and the C<graphemes>
counter by 1.

The C<columns> member counts the number of screen columns consumed by the
graphemes. Most graphemes consume only 1 column, but some are defined in
Unicode to consume 2.

Instances are also used to store count limits, where any memeber may be set
to -1 to indicate no limit in that counter.

=cut

=head1 CONSTRUCTORS

=head2 zero

   $pos = Tickit::StringPos->zero

Returns a new instance with all counters set to zero.

=head2 limit_bytes

=head2 limit_codepoints

=head2 limit_graphemes

=head2 limit_columns

   $pos = Tickit::StringPos->limit_bytes( $bytes )

   $pos = Tickit::StringPos->limit_codepoints( $codepoints )

   $pos = Tickit::StringPos->limit_graphemes( $graphemes )

   $pos = Tickit::StringPos->limit_columns( $columns )

Return a new instance with one counter set to the given limit and the other
three counters set to -1.

=cut

=head1 METHODS

=head2 bytes

=head2 codepoints

=head2 graphemes

=head2 columns

   $bytes = $pos->bytes

   $codepoints = $pos->codepoints

   $graphemes = $pos->graphemes

   $columns = $pos->columns

Return the current value the counters.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
