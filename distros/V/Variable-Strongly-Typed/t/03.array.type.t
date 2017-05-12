use Test::More tests => 9;

BEGIN {
    use_ok( 'Variable::Strongly::Typed' );
}

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

my @array_of_ints :TYPE('int');
my @array_of_files :TYPE('IO::File');

eval {
$array_of_ints[0] = 'sdklsdkl';
};
ok($@, "Can't assign string to int!");

$array_of_ints[23] = 2345;
is($array_of_ints[23], 2345);

eval {
push @array_of_ints, 23, 23, 'weioweio', 0;
};
ok($@, "Can't assign string to int!");

use_ok( 'IO::File' );
eval {
    unshift @array_of_files, 23, 23, 'weioweio', 0;
};
ok($@, "Can't assign non-IO::Files!");

unshift(@array_of_files, new IO::File);
is('IO::File', ref $array_of_files[0]);

sub add_int {
    qw(2 3 4);
}

@array_of_ints = add_int();
is($#array_of_ints, 2);

sub add_io_file {
    my $i = new IO::Handle;

    ($i);
}

eval {
    @array_of_files = add_io_file();
};
ok($@, "Can't assign array ref to IO::File array");

