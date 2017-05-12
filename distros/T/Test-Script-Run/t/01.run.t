use strict;
use warnings;

use Test::More tests => 38;
use Test::Script::Run ':all';
use File::Spec;

run_not_ok( 'not_exist.pl', 'run not exist script');
is( last_script_exit_code, 127, 'last exit code is 127' );

run_ok( 'test.pl', 'run test.pl' );
is( last_script_stdout, "out line 1\nout line 2", 'last stdout' );
is( last_script_stderr, "err line 1\nerr line 2", 'last stderr' );
is( last_script_exit_code, 0, 'last exit code' );

is_script_output(
    'test.pl', ['out', 'err'],
    [ 'out' ],
    [ 'err' ],
    'is_script_output'
);

is( last_script_stdout, "out", 'last stdout' );
is( last_script_stderr, "err", 'last stderr' );
is( last_script_exit_code, 0, 'last exit code' );

is_script_output(
    'test.pl', [],
    [ 'out line 1', 'out line 2' ],
    [ 'err line 1', 'err line 2' ],
    'is_script_output'
);
is( last_script_stdout, "out line 1\nout line 2", 'last stdout' );
is( last_script_stderr, "err line 1\nerr line 2", 'last stderr' );
is( last_script_exit_code, 0, 'last exit code' );

run_output_matches(
    'test.pl', [],
    [ 'out line 1', 'out line 2' ],
    [ 'err line 1', 'err line 2' ],
    'run_output_matches'
);

run_output_matches_unordered(
    'test.pl', [],
    [ 'out line 2', 'out line 1' ],
    [ 'err line 2', 'err line 1' ],
    'run_output_matches_unordered'
);

my ( $return, $stdout, $stderr ) = run_script('test.pl');
ok( $return, "return is true" );
is( $stdout, "out line 1\nout line 2", 'stdout is set' );
is( $stderr, "err line 1\nerr line 2", 'stderr is set' );

( $return, $stdout, $stderr ) =
  run_script( 'test.pl', [ "print arg1", 'warn arg2' ] );
ok( $return, "return is true" );
is( $stdout, 'print arg1', 'stdout is set' );
is( $stderr, 'warn arg2',  'stderr is set' );

my ( $out, $err );
( $return, $stdout, $stderr ) =
  run_script( 'test.pl', [ 'print arg1', 'warn arg2' ], \$out, \$err );
ok( $return,  "return is true" );
ok( !$stdout, 'stdout is not set' );
ok( !$stderr, 'stderr is not set' );
is( $out, 'print arg1', 'out is set' );
is( $err, 'warn arg2',  'err is set' );

run_not_ok('test_die.pl', 'test_die dies');
run_not_ok('test_not_exist', 'test_not_exist');

my $dir_t = Test::Script::Run::_updir( $0 );
like( $dir_t, qr!\bt\b!, 'dir_t contains t' );
my $sbin_script = File::Spec->catfile( $dir_t, 'sbin', 'test_sbin.pl' );
run_ok( $sbin_script, 'sbin script' );
( $return, $stdout ) = run_script( $sbin_script );
ok( $return, 'return of sbin_script' );
is( $stdout, 'test_sbin_script', 'stdout of sbin_script' );


run_ok( 'test_script.pl', 'run test_script.pl' );
is( last_script_stdout, "out line 1\nout line 2", 'last stdout' );
is( last_script_stderr, "err line 1\nerr line 2", 'last stderr' );
is( last_script_exit_code, 0, 'last exit code' );

is_script_output(
    'test.pl', ['out', 'err'],
    [ 'out' ],
    [ 'err' ],
    'is_script_output'
);
