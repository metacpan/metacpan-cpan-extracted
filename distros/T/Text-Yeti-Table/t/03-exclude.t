
use Mojo::Base -strict;
use Test::More;
use Test::Differences;
use List::Util 1.33 'all';

use Text::Yeti::Table qw(render_table);

sub render_to_string {
    open my $io, '>', \my $buf
      or die "Can't open in-core file: $!";
    render_table( @_, $io );
    return $buf;
}

{
    my @items = (    #
        { a => 1, b => 'x', c => undef, },
        { a => 2, b => 'y', c => undef },
    );

    my $spec = [
        'a', 'b',
        {   k => 'c',
            x => sub {
                all { $_ eq '<none>' } @{ $_[0] };
            }
        }
    ];

    eq_or_diff( render_to_string( \@items, $spec ), <<TABLE );
A   B
1   x
2   y
TABLE

    eq_or_diff( render_to_string( \@items, [ 'a', 'b', 'c' ] ), <<TABLE );
A   B   C
1   x   <none>
2   y   <none>
TABLE
}

{
    my @items = (    #
        { a => 1, b => 'x', c => 'ok', },
        { a => 2, b => 'y', c => undef },
    );

    my $spec = [
        'a', 'b',
        {   k => 'c',
            x => sub {
                all { $_ eq '<none>' } @{ $_[0] };
            }
        }
    ];

    eq_or_diff( render_to_string( \@items, $spec ), <<TABLE );
A   B   C
1   x   ok
2   y   <none>
TABLE
}

done_testing;
