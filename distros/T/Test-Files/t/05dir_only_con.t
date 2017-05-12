use Test::Builder::Tester tests => 6;
use File::Spec;

use Test::Files;

my $test_file   = File::Spec->catfile( 't', '05dir_only_con.t'       );
my $missing_dir = File::Spec->catdir ( 't', 'missing_dir'            );
my $lib_dir     = File::Spec->catdir ( 't', 'lib'                    );
my $simple_dir  = File::Spec->catdir ( 'Test', 'Simple'              );
my $catch_file  = File::Spec->catfile( 'Test', 'Simple', 'Catch.pm'  );
my $simple_file = File::Spec->catfile( 'Test', 'Simple', 'Simple.pm' );

#-----------------------------------------------------------------
# Exclusively compare file names in a directory to a list of files.
#-----------------------------------------------------------------

test_out("ok 1 - passing");
dir_only_contains_ok(
    $lib_dir, [ 'Test', $simple_dir, $catch_file ], "passing"
);
test_test("passing");

#-----------------------------------------------------------------
# Compare absent directory to list of files.
#-----------------------------------------------------------------

test_out("not ok 1 - missing dir");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir absent");
dir_only_contains_ok($missing_dir, [qw(some files)], "missing dir");
test_test("missing dir");

#-----------------------------------------------------------------
# Call dir_only_contains_ok with bad args (not an array ref).
#-----------------------------------------------------------------

test_out("not ok 1 - anon. array expected");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"dir_only_contains_ok requires array ref as second arg");
dir_only_contains_ok('t',             "simple_arg",     "anon. array expected");
test_test("anon. array expected");

#-----------------------------------------------------------------
# Exclusively compare file names in a direcory to a list which
# is missing one of the files.
#-----------------------------------------------------------------

test_out("not ok 1 - failing because of missing file");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"failed to see these: A");
dir_only_contains_ok(
    $lib_dir, [ 'A', 'Test', $simple_dir, $catch_file ],
    "failing because of missing file"
);
test_test("failing because of missing file");

#-----------------------------------------------------------------
# Exclusively compare file names in a directory to a list which
# has does not have one of those names.
#-----------------------------------------------------------------

test_out("not ok 1 - failing because of extra file");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"unexpectedly saw: $catch_file" );
dir_only_contains_ok(
    $lib_dir, [ 'Test', $simple_dir ], "failing because of extra file"
);
test_test("failing because of extra file");

#-----------------------------------------------------------------
# Exclusively compare file names in a directory to a list which
# is different.
#-----------------------------------------------------------------

test_out("not ok 1 - failing both");
$line = line_num(+4);
test_diag("    Failed test ($test_file at line $line)",
"failed to see these: A $simple_file",
"unexpectedly saw: $catch_file" );
dir_only_contains_ok(
    $lib_dir, [ 'A', 'Test', $simple_dir, $simple_file ], "failing both"
);
test_test("failing both");

