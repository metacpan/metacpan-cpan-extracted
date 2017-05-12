#!/usr/bin/perl

# This test file was originally created by running Test::StubGenerator
# on itself.  Since most of the other tests already tested most everything
# else in the module, I just left the basic tests in, while also making
# sure the output matched what is expected.

use strict;
use warnings;

use Test::More tests => 10;

use lib '..';

BEGIN { use_ok('Test::StubGenerator'); }

ok(
    my $obj = Test::StubGenerator->new(
        {
            file       => 'blib/lib/Test/StubGenerator.pm',
            tidy       => 0,
        }
    ),
    'can eat own dogfood 1'
);
isa_ok( $obj, 'Test::StubGenerator', 'object $obj' );
can_ok(
    $obj,             '_assemble_tests',
    '_find',          '_find_package',
    '_find_subs',     '_generate_preamble',
    '_get_variables', '_handle_output',
    '_process_sub',   '_test_file_header',
    '_write_file',    'gen_testfile'
);

ok( my $got = $obj->gen_testfile(),
    'can call $obj->gen_testfile() without params' );

is( $got, return_expected(), 'can eat own dogfood 2' );

# Create some variables with which to test the Test::StubGenerator objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
my $test_file    = '';
my $package      = '';
my $sub          = '';
my $sub_ref      = '';
my $item_type    = '';
my $declarations = '';
my $tests        = '';
my $statement    = '';
my $vars_ref     = '';

ok( $obj->_generate_preamble($package), 'can call $obj->_generate_preamble()' );
ok( $obj->_generate_preamble(),
    'can call $obj->_generate_preamble() without params' );

ok( $obj->_assemble_tests( $package, $declarations, $tests ),
    'can call $obj->_assemble_tests()' );

ok( $obj->_test_file_header(),
    'can call $obj->_test_file_header() without params' );

sub return_expected {
    return <<'END_EXPECTED';
#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

use lib '..';

BEGIN { use_ok( 'Test::StubGenerator' ); }

ok( my $obj = Test::StubGenerator->new(), 'can create object Test::StubGenerator' );
isa_ok( $obj, 'Test::StubGenerator', 'object $obj' );
can_ok( $obj, '_assemble_tests', '_find', '_find_package', '_find_subs', '_generate_preamble', '_get_variables', '_handle_output', '_process_sub', '_test_file_header', '_write_file', 'gen_testfile' );

# Create some variables with which to test the Test::StubGenerator objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
my $package = '';
my $declarations = '';
my $tests = '';
my $sub_ref = '';
my $item_type = '';
my $statement = '';
my $vars_ref = '';
my $test_file = '';
my $sub = '';

# And now to test the methods/subroutines.
ok( $obj->_assemble_tests( $package, $declarations, $tests ), 'can call $obj->_assemble_tests()' );
ok( $obj->_assemble_tests(), 'can call $obj->_assemble_tests() without params' );

ok( $obj->_find( $sub_ref, $item_type ), 'can call $obj->_find()' );
ok( $obj->_find(), 'can call $obj->_find() without params' );

ok( $obj->_find_package(), 'can call $obj->_find_package() without params' );

ok( $obj->_find_subs(), 'can call $obj->_find_subs() without params' );

ok( $obj->_generate_preamble( $package ), 'can call $obj->_generate_preamble()' );
ok( $obj->_generate_preamble(), 'can call $obj->_generate_preamble() without params' );

ok( $obj->_get_variables( $statement, $vars_ref ), 'can call $obj->_get_variables()' );
ok( $obj->_get_variables(), 'can call $obj->_get_variables() without params' );

ok( $obj->_handle_output( $test_file ), 'can call $obj->_handle_output()' );
ok( $obj->_handle_output(), 'can call $obj->_handle_output() without params' );

ok( $obj->_process_sub( $sub ), 'can call $obj->_process_sub()' );
ok( $obj->_process_sub(), 'can call $obj->_process_sub() without params' );

ok( $obj->_test_file_header(), 'can call $obj->_test_file_header() without params' );

ok( $obj->_write_file( $test_file ), 'can call $obj->_write_file()' );
ok( $obj->_write_file(), 'can call $obj->_write_file() without params' );

ok( $obj->gen_testfile(), 'can call $obj->gen_testfile() without params' );


END_EXPECTED
}
