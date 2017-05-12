use strict;
use warnings;
use Test::More;
use Test::ttserver;

my $port = 101976;

my $ttserver = Test::ttserver->new(undef, 
    port   => $port,
) or plan 'skip_all' => $Test::ttserver::errstr;

plan 'tests' => 6;

ok( $ttserver, 'bind on port ' . $port );

my @ttserver = map {
    my $ttserver = Test::ttserver->new(undef, 
        port  => $port + $_,
    );
    ok( $ttserver, 'bind on port ' . ($port + $_) );
    $ttserver;
} (1 .. 3);

cmp_ok( @ttserver, '==', 3, 'multi instance' );

is_deeply(
    [ map $_->port, @ttserver ],
    [qw(101977 101978 101979)],
    'port number'
);
