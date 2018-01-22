
use Mojo::Base -strict;
use Test::More;
use Test::Differences;

use Text::Yeti::Table qw(render_table);

sub render_to_string {
    open my $io, '>', \my $buf
      or die "Can't open in-core file: $!";
    render_table( @_, $io );
    return $buf;
}

{
    my @items = (    #
        { a => 1, b => 'x' },
        { a => 2, b => 'y' },
    );

    eq_or_diff( render_to_string( \@items, [ 'a', 'b' ] ), <<TABLE );
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
    my @items = (
        {   key1 => 'value11',
            key2 => 'value21',
            key3 => 'value31'
        }
    );
    my $spec = [ 'key1', 'key2', 'key3' ];

    eq_or_diff( render_to_string( \@items, $spec ), <<TABLE );
KEY1      KEY2      KEY3
value11   value21   value31
TABLE
}

{
    my @items = (
        {   name => 'catalog',
            id =>
              '34159a6075976c264811b2bb395e3357928a2b52f953871600412785ed601f41',
            node    => 'dev89',
            address => '172.0.0.1',
            tags    => [ 'devel', 'v0.1' ]
        }
    );

    my $spec
      = [ 'name', 'id', 'node', 'address', [ 'tags', sub {"@{$_[0]}"} ] ];

    eq_or_diff( render_to_string( \@items, $spec ), <<TABLE );
NAME      ID                                                                 NODE    ADDRESS     TAGS
catalog   34159a6075976c264811b2bb395e3357928a2b52f953871600412785ed601f41   dev89   172.0.0.1   devel v0.1
TABLE
}

{
    my @items = (
        {   ServiceName => 'consul',
            ServiceID   => 'e59689eb-7b58',
            Node        => 'consul22',
            Datacenter  => 'LAX'
        }
    );

    my $spec
      = [ 'ServiceName', 'ServiceID', 'Node', [ 'Datacenter', undef, 'DC' ] ];

    eq_or_diff( render_to_string( \@items, $spec ), <<TABLE );
SERVICE NAME   SERVICE ID      NODE       DC
consul         e59689eb-7b58   consul22   LAX
TABLE
}

done_testing;
