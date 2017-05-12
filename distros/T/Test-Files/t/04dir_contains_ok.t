use Test::Builder::Tester tests => 4;
use File::Spec;

use Test::Files;

my $test_file   = File::Spec->catfile( 't', '04dir_contains_ok.t'    );
my $missing_dir = File::Spec->catdir ( 't', 'missing_dir'            );
my $tlib_dir    = File::Spec->catdir ( 't', 'lib'                    );
my $simple_dir  = File::Spec->catdir ( 'Test', 'Simple'              );
my $catch_file  = File::Spec->catfile( 'Test', 'Simple', 'Catch.pm'  );
my $simple_file = File::Spec->catfile( 'Test', 'Simple', 'Simple.pm' );

#-----------------------------------------------------------------
# Compare file names in a directory to a list of those files.
#-----------------------------------------------------------------

test_out("ok 1 - passing");
dir_contains_ok(
    $tlib_dir, ['Test', $simple_dir, $catch_file], "passing"
);
test_test("passing");

#-----------------------------------------------------------------
# Compare directory to a directory which is absent.
#-----------------------------------------------------------------

test_out("not ok 1 - missing dir");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir absent");
dir_contains_ok($missing_dir, [qw(some files)], "missing dir");
test_test("missing dir");

#-----------------------------------------------------------------
# Call dir_contains_ok with bad argument (not an array ref).
#-----------------------------------------------------------------

test_out("not ok 1 - anon. array expected");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"dir_contains_ok requires array ref as second arg");
dir_contains_ok('t',             "simple_arg",     "anon. array expected");
test_test("anon. array expected");

#-----------------------------------------------------------------
# Compare file names in a directory to a list which differs.
#-----------------------------------------------------------------

test_out("not ok 1 - failing");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"failed to see these: A $simple_file");
dir_contains_ok(
    $tlib_dir, ['A', 'Test', $simple_dir, $simple_file], "failing"
);
test_test("failing");
