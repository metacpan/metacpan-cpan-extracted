use Test::More tests => 2;

BEGIN {
use_ok( 'Versionify::Dispatch' ) or BAIL_OUT(q{Can't even load the module});
}

diag( "Testing Versionify::Dispatch $Versionify::Dispatch::VERSION" );

my $dispatcher = Versionify::Dispatch->new();

isa_ok($dispatcher, 'Versionify::Dispatch', 'Create Versionify::Dispatch object');

