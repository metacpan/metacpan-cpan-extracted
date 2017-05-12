use Test::More tests => 5;
BEGIN { use_ok('Tie::ExecHash') };

my %foo = ();
tie( %foo, 'Tie::ExecHash');

$foo{'bar'} = 1;

is( $foo{'bar'}, 1, "Regular assignments work" );

my $baz = "red";

$foo{'bar'} = [ sub { $baz = $_[0] }, sub { $baz } ];

is( $foo{'bar'}, 'red', "Magic assignment/getter pairs work work" );

$foo{'bar'} = "a suffusion of yellow";

is( $baz, 'a suffusion of yellow', "Magic assignment had expected side effects" );

delete $foo{'bar'};

ok( ! defined $baz, "Magic deletion had expected side effects" );
