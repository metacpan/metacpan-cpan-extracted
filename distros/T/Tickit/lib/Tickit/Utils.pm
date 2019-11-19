#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2016 -- leonerd@leonerd.org.uk

package Tickit::Utils;

use strict;
use warnings;

our $VERSION = '0.68';

use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(
   string_count
   string_countmore

   textwidth

   chars2cols
   cols2chars

   substrwidth

   align

   bound

   distribute
);

# XS code comes from Tickit itself
require Tickit;

=head1 NAME

C<Tickit::Utils> - utility functions for C<Tickit>

=head1 DESCRIPTION

This module provides a number of utility functions used across C<Tickit>.

=cut

=head1 FUNCTIONS

=head2 string_count

   $bytes = string_count( $str, $pos, $limit )

Given a string in C<$str> and a L<Tickit::StringPos> instance in C<$pos>,
updates the counters in C<$pos> by counting the string, and returns the number
of bytes consumed. If C<$limit> is given, then it will count no further than
any of the limits given.

=head2 string_countmore

   $bytes = string_countmore( $str, $pos, $limit )

Similar to C<string_count> but will not zero the counters before it begins.
Counters in C<$pos> will still be incremented.

=head2 textwidth

   $cols = textwidth( $str )

Returns the number of screen columns consumed by the given (Unicode) string.

=cut

# Provided by XS

=head2 chars2cols

   @cols = chars2cols( $text, @chars )

Given a list of increasing character positions, returns a list of column
widths of those characters. In scalar context returns the first columns width.

=cut

# Provided by XS

=head2 cols2chars

   @chars = cols2chars( $text, @cols )

Given a list of increasing column widths, returns a list of character
positions at those widths. In scalar context returns the first character
position.

=cut

# Provided by XS

=head2 substrwidth

   $substr = substrwidth $text, $startcol

   $substr = substrwidth $text, $startcol, $widthcols

   $substr = substrwidth $text, $startcol, $widthcols, $replacement

Similar to C<substr>, but counts start offset and length in screen columns
instead of characters

=cut

sub substrwidth
{
   if( @_ > 2 ) {
      my ( $start, $end ) = cols2chars( $_[0], $_[1], $_[1]+$_[2] );
      if( @_ > 3 ) {
         return substr( $_[0], $start, $end-$start, $_[3] );
      }
      else {
         return substr( $_[0], $start, $end-$start );
      }
   }
   else {
      my $start = cols2chars( $_[0], $_[1] );
      return substr( $_[0], $start );
   }
}

=head2 align

   ( $before, $alloc, $after ) = align( $value, $total, $alignment )

Returns a list of three integers created by aligning the C<$value> to a
position within the C<$total> according to C<$alignment>. The sum of the three
returned values will always add to total.

If the value is not larger than the total then the returned allocation will be
the entire value, and the remaining space will be divided between before and
after according to the given fractional alignment, with more of the remainder
being allocated to the C<$after> position in proportion to the alignment.

If the value is larger than the total, then the total is returned as the
allocation and the before and after positions will both be given zero.

=cut

sub align
{
   my ( $value, $total, $alignment ) = @_;

   return ( 0, $total, 0 ) if $value >= $total;

   my $spare = $total - $value;
   my $before = int( $spare * $alignment );

   return ( $before, $value, $spare - $before );
}

=head2 bound

   $val = bound( $min, $val, $max )

Returns the value of C<$val> bounded by the given minimum and maximum. Either
limit may be left undefined, causing no limit of that kind to be applied.

=cut

sub bound
{
   my ( $min, $val, $max ) = @_;
   $val = $min if defined $min and $val < $min;
   $val = $max if defined $max and $val > $max;
   return $val;
}

=head2 distribute

   distribute( $total, @buckets )

Given a total amount of quota, and a list of buckets, distributes the quota
among the buckets according to the values given in them.

Each value in the C<@buckets> list is a C<HASH> reference which will be
modified by the function. On entry, the following keys are inspected.

=over 8

=item base => INT

If present, this bucket shall be a flexible bucket containing initially this
quantity of quota, but may be allocated more, or less, depending on the value
of the C<expand> key, and how much spare is remaining.

=item expand => INT

For a C<base> flexible bucket, the relative distribution of C<expand> value
among the flexible buckets determines how the spare quota is distributed among
them. If absent, defaults to 0.

=item fixed => INT

If present, this bucket shall be of the exact fixed size given.

=back

On return, the bucket hashes will be modified to contain two more keys:

=over 8

=item value => INT

The amount of quota allocated to this bucket. For C<fixed> buckets, this will
be the fixed value. For C<base> buckets, this may include extra spare quota
distributed in proportion to the C<expand> value, or may be reduced in order
to fit the total.

=item start => INT

Gives the cumulative amount of quota allocated to each previous bucket. The
first bucket's C<start> value will be 0, the second will be the C<value>
allocated to the first, and so on.

=back

The bucket hashes will not otherwise be modified; the caller may place any
extra keys in the hashes as required.

=cut

sub _assert_int
{
   my ( $name, $value ) = @_;
   $value == int $value or croak "'$name' value must be an integer";
   return $value;
}

sub distribute
{
   my ( $total, @buckets ) = @_;

   _assert_int total => $total;

   my $base_total = 0;
   my $expand_total = 0;
   my $fixed_total = 0;

   foreach my $b ( @buckets ) {
      if( defined $b->{base} ) {
         $base_total   += _assert_int base => $b->{base};
         $expand_total += _assert_int expand => $b->{expand} || 0;
      }
      elsif( defined $b->{fixed} ) {
         $fixed_total += _assert_int fixed => $b->{fixed};
      }
   }

   my $allocatable = $total - $fixed_total;
   my $spare = $allocatable - $base_total;

   if( $spare >= 0 ) {
      my $err = 0;

      # This algorithm tries to allocate spare quota roughly evenly to the
      # buckets. It keeps track of rounding errors in $err, to ensure that
      # rounding-down-to-int() errors don't leave us some spare amount

      my $current = 0;

      foreach my $b ( @buckets ) {
         die "ARG: ran out of quota" if( $current > $total );

         my $amount;
         if( defined $b->{base} ) {
            my $extra = 0;
            if( $expand_total ) {
               $extra = $spare * ( $b->{expand} || 0 );

               # Avoid floating point divisions
               $err += $extra % $expand_total;
               $extra = do { use integer; $extra / $expand_total };

               $extra++, $err -= $expand_total if $err >= $expand_total;
            }

            $amount = $b->{base} + $extra;
         }
         elsif( defined $b->{fixed} ) {
            $amount = $b->{fixed};
         }

         if( $current + $amount > $total ) {
            $amount = $total - $current; # All remaining space
         }

         $b->{start} = $current;
         $b->{value} = $amount;

         $current += $amount;
      }
   }
   elsif( $allocatable > 0 ) {
      # Divide it best we can

      my $err = 0;

      my $current = 0;

      foreach my $b ( @buckets ) {
         my $amount;

         if( defined $b->{base} ) {
            $amount = $b->{base} * $allocatable / $base_total;

            $err += $amount - int($amount);
            $amount++, $err-- if $err >= 1;

            $amount = int($amount);
         }
         elsif( defined $b->{fixed} ) {
            $amount = $b->{fixed};
         }

         $b->{start} = $current;
         $b->{value} = $amount;

         $current += $amount;
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
