=head1 Name

qbit::Array - Functions to manipulate arrays.

=cut

package qbit::Array;
$qbit::Array::VERSION = '2.8';
use strict;
use warnings;
use utf8;

use base qw(Exporter);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      in_array arrays_intersection arrays_difference array_uniq
      array_n_min array_min array_n_max array_max
      array_avg
      );
    @EXPORT_OK = @EXPORT;
}

=head1 Functions

=head2 in_array

B<Arguments:>

=over

=item

B<$elem> - scalar;

=item

B<$array> - array ref.

=back

B<Return value:> boolean.

=cut

sub in_array($$) {
    my ($elem, $array) = @_;

    my %hs;
    @hs{@$array} = ();

    return exists $hs{$elem};
}

=head2 arrays_intersection

B<Arguments:>

=over

=item

B<$array_ref1>;

=item

B<$array_ref2>;

=item

B<...>;

=item

B<$array_refN>.

=back

B<Return value:> array ref, intersection of all arrays (unique values).

=cut

sub arrays_intersection(@) {
    my %hs = ();
    foreach my $array (map {array_uniq($_)} @_) {
        exists($hs{$_}) ? ($hs{$_}++) : ($hs{$_} = 1) for @$array;
    }

    return [grep {$hs{$_} == @_} keys %hs];
}

=head2 arrays_difference

B<Arguments:>

=over

=item

B<$array1> - array ref, minuend;

=item

B<$array2> - array ref, subtrahend.

=back

B<Return value:> array ref.

=cut

sub arrays_difference($$) {
    my ($array1, $array2) = @_;

    my %hs;
    @hs{@$array2} = ();

    return [grep {!exists($hs{$_})} @$array1];
}

=head2 array_uniq

B<Arguments:>

=over

=item

B<@array> - each element may be array ref or scalar.

=back

B<Return value:> array ref, unique values from all arrays.

=cut

sub array_uniq(@) {
    my %hs;
    @hs{ref($_) eq 'ARRAY' ? grep {defined($_)} @$_ : ($_)} = () for @_;
    return [keys %hs];
}

=head2 array_n_min

B<Arguments:>

=over

=item

B<@array> - array of numbers.

=back

B<Return value:> number, min value (numeric comparasion).

=cut

sub array_n_min(@) {
    my $min = $_[0];
    foreach (@_) {
        $min = $_ if $min > $_;
    }
    return $min;
}

=head2 array_min

B<Arguments:>

=over

=item

B<@array> - array of strings.

=back

B<Return value:> string, min value (string comparasion).

=cut

sub array_min(@) {
    my $min = $_[0];
    foreach (@_) {
        $min = $_ if $min gt $_;
    }
    return $min;
}

=head2 array_n_max

B<Arguments:>

=over

=item

B<@array> - array of numbers.

=back

B<Return value:> number, max value (numeric comparasion).

=cut

sub array_n_max(@) {
    my $max = $_[0];
    foreach (@_) {
        $max = $_ if $max < $_;
    }
    return $max;
}

=head2 array_max

B<Arguments:>

=over

=item

B<@array> - array of strings.

=back

B<Return value:> string, max value (string comparasion).

=cut

sub array_max(@) {
    my $max = $_[0];
    foreach (@_) {
        $max = $_ if $max lt $_;
    }
    return $max;
}

=head2 array_avg

B<Arguments:>

=over

=item

B<@array> - array of numbers.

=back

B<Return value:> number, average value.

=cut

sub array_avg(@) {
    my $sum = 0;
    $sum += $_ foreach @_;
    return $sum / @_;
}

1;
