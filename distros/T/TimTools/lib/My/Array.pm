package My::Array;

use v5.32;
use Mojo::Base -strict;
use List::Util qw( max );

=head2 max_lengths

Returns an array of the lengths of
the longest strings per array.

Nice for making evenly spaced out tables.

=cut

sub max_lengths {
    my ( $s, $rows ) = @_;
    my $last_row    = $rows->$#*;
    my $last_column = $rows->[0]->$#*;

    my @max = map {
        my $col = $_;
        max map { length $rows->[$_][$col]; } 0 .. $last_row;
    } 0 .. $last_column;

    \@max;
}

1;
