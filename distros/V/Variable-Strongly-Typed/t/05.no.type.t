use Test::More tests => 3;

BEGIN {
    use_ok( 'Variable::Strongly::Typed' );
}

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

my $zany :TYPE('zany');

eval {
    $zany = 'der heck?';
};
ok($@, "It's not a zany!");

$zany = bless \my($anon_scalar), 'zany';
ok($zany->isa('zany'));

