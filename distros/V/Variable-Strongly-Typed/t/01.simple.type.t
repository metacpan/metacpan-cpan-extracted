use Test::More tests => 19;

BEGIN {
use_ok( 'Variable::Strongly::Typed' );
}

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

my $int :TYPE('int');
my $string :TYPE('string');
my $float :TYPE('float');
my $pi :TYPE('float');
my $bool :TYPE('bool');
my $scalar_ref :TYPE('SCALAR');
my $array_ref :TYPE('ARRAY');
my $hash_ref :TYPE('HASH');
my $io_file :TYPE('IO::File');  # only IO::File object

eval {
    $int = '2sdlk';
};
ok($@, "Cannot assign non-int to int!");

$int = 23;
is(23, $int);

eval {
    $string = {};
};
ok($@, "Cannot assign non-string to string!");

$string = 'howdy boyz';
is('howdy boyz', $string);

# croak!!
eval {
    $scalar_ref = 23;
};
ok($@, "Cannot assign non-scalar-ref to scalar ref!");

$scalar_ref = \44; 
is(44, $$scalar_ref);

eval {
    $array_ref = 44;
};
ok($@, "Cannot assign non-array-ref to array ref!");

$array_ref = [];
is('ARRAY', ref $array_ref);

eval {
    $hash_ref = 23;
};
ok($@, "Cannot assign non-hash-ref to hash ref!");

$hash_ref = { howdy => 'partner' };
is('HASH', ref $hash_ref);

use_ok( 'IO::File');
eval {
    $io_file = 23;
};
ok($@, "Cannot assign non-File::Find-ref to File::Find!");

$io_file = new IO::File;
ok('IO::File', ref $io_file);

eval {
    $float = "this ain't no float";
};
ok($@, "Can't assign string to float!");

$pi = 3.14159;
is(3.14159, $pi);

$float = sin(.5 * $pi);
ok($float, "sin .5 * $pi is darn close to one...");

$bool = 1;
is($bool, 1);

eval {
    $bool = 'what is this?';
};
ok($@, "String not a boolean value");

