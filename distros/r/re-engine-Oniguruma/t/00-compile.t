use Test::More tests => 2;

my $pkg = 're::engine::Oniguruma';
use_ok( $pkg );
isa_ok( bless( [] => $pkg ), 'Regexp' );

diag( "Testing re::engine::Oniguruma $re::engine::Oniguruma::VERSION" );
