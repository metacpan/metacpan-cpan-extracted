use FindBin;
use lib "$FindBin::Bin/../blib/arch/";
use lib "$FindBin::Bin/../blib/lib/";

use Test::More tests => 4;

use_ok( 'Wurst' );

is (func_int(), 42,"integer test");
is (func_float(), 3.125, "float test");
is (func_char(), "Hello from func_char", "char test");

if (func_int()!=42 or func_char() ne "Hello from func_char") {
    BAIL_OUT("XS Error");
}