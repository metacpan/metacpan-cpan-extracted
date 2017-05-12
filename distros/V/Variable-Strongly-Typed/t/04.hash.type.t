use Test::More tests => 8;

BEGIN {
    use_ok( 'Variable::Strongly::Typed' );
}

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

my %hash_of_ints :TYPE('int');
my %hash_of_files :TYPE('IO::File');

eval {
$hash_of_ints{zot} = 'sdklsdkl';
};
ok($@, "Can't assign string to int!");

$hash_of_ints{crab} = 2345;
is($hash_of_ints{crab}, 2345);

eval {
    %hash_of_ints = ( lame => 23, game => 'weioweio', maim => 0 );
};
ok($@, "Can't assign string to int!");

$hash_of_ints{yowza} = 9923;
is(9923, $hash_of_ints{yowza});

use_ok( 'IO::File' );
eval {
    @hash_of_files{'mark', 'lark', 'zark'} = (23, 23, 'weioweio');
};
ok($@, "Can't assign non-IO::Files!");

$hash_of_files{new_one} =  new IO::File;
is('IO::File', ref $hash_of_files{new_one});

sub add_int {
    ('zot' => 23, 'flot' => '99');
}

%hash_of_ints = add_int();

