use Test::Builder::Tester tests => 5;
use Test::More;
use File::Spec;

use Test::Files;

my $test_file    = File::Spec->catfile( 't', '06compare_dirs.t'        );
my $missing_dir  = File::Spec->catdir ( 't', 'missing_dir'             );
my $lib_dir      = File::Spec->catdir ( 't', 'lib'                     );
my $lib_fail_dir = File::Spec->catdir ( 't', 'lib_fail'                );
my $lib_pass_dir = File::Spec->catdir ( 't', 'lib_pass'                );
my $time_dir     = File::Spec->catdir ( 't', 'time'                    );
my $time3_dir    = File::Spec->catdir ( 't', 'time3'                   );
my $catch        = File::Spec->catfile(
    't', 'lib', 'Test', 'Simple', 'Catch.pm'
);
my $catch_fail   = File::Spec->catfile(
    't', 'lib_fail', 'Test', 'Simple', 'Catch.pm'
);
my $t1           = File::Spec->catfile( 't', 'time', 't1'              );
my $t2           = File::Spec->catfile( 't', 'time', 't2'              );
my $t3           = File::Spec->catfile( 't', 'time', 't3'              );

#-----------------------------------------------------------------
# Compare file contents in directories which are the same.
#-----------------------------------------------------------------

test_out("ok 1 - passing");
compare_dirs_ok($lib_dir,         $lib_pass_dir,    "passing");
test_test("passing");

#-----------------------------------------------------------------
# Compare file contents in a missing directory to an extant
# directory.
#-----------------------------------------------------------------

test_out("not ok 1 - missing first dir");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir is not a valid directory");
compare_dirs_ok($missing_dir, $lib_dir,         "missing first dir");
test_test("missing first dir");

#-----------------------------------------------------------------
# Compare file contents in a directory to a missing directory.
#-----------------------------------------------------------------

test_out("not ok 1 - missing second dir");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir is not a valid directory");
compare_dirs_ok($lib_dir,         $missing_dir, "missing second dir");
test_test("missing second dir");

#-----------------------------------------------------------------
# Compare file contents in a directory to a file contents in
# another directory where one pair of files differ.
#-----------------------------------------------------------------

SKIP: {
skip "test only for unix, i.e. not for $^O", 1 unless ( $^O =~ /nix|nux|solaris/ );
test_out("not ok 1 - failing due to text diff");
$line = line_num(+17);
test_diag(
"    Failed test ($test_file at line $line)",
'+---+-----------------------------------+---+---------------------------------+',
"|   |$catch         |   |$catch_fail  |",
'| Ln|                                   | Ln|                                 |',
'+---+-----------------------------------+---+---------------------------------+',
'| 12|$t->failure_output($err_fh);       | 12|$t->failure_output($err_fh);     |',
'| 13|$t->todo_output($err_fh);          | 13|$t->todo_output($err_fh);        |',
'| 14|                                   | 14|                                 |',
'* 15|sub caught { return($out, $err) }  * 15|sub caught {                     *',
'|   |                                   * 16|    return($out, $err)           *',
'|   |                                   * 17|}                                *',
'| 16|                                   | 18|                                 |',
'| 17|sub PRINT  {                       | 19|sub PRINT  {                     |',
'| 18|    my $self = shift;              | 20|    my $self = shift;            |',
'+---+-----------------------------------+---+---------------------------------+');
compare_dirs_ok($lib_dir, $lib_fail_dir, "failing due to text diff");
test_test("failing due to text diff");
}

#-----------------------------------------------------------------
# Compare file contents in directories with different files.
#-----------------------------------------------------------------

test_out("not ok 1 - failing due to structure diff");
$line = line_num(+5);
test_diag("    Failed test ($test_file at line $line)",
          "$t1 absent",
          "$t2 absent",
          "$t3 absent");
compare_dirs_ok($time3_dir, $time_dir, "failing due to structure diff");
test_test("failing due to structure diff");

