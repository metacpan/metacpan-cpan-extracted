use strict;
use Test::Builder::Tester tests => 5;
use File::Spec;

use Test::Files;

my $test_file   = File::Spec->catfile( 't', '08comp_filt.t'    );
my $ok_pass_dat = File::Spec->catfile( 't', 'ok_pass.dat'      );
my $ok_diff_dat = File::Spec->catfile( 't', 'ok_pass.diff.dat' );
my $missing_dir = File::Spec->catdir ( 't', 'missing_dir'      );
my $absent_dir  = File::Spec->catdir ( 't', 'absent_dir'       );

#-----------------------------------------------------------------
# Compare (with a filter) file contents which
# are the same except for one small difference.
#-----------------------------------------------------------------

test_out("ok 1 - passing similar");
compare_filter_ok($ok_pass_dat, $ok_diff_dat, \&stripper, "passing similar");
test_test("failing file");

sub stripper {
    my $line = shift;
    $line    =~ s/is for .*//;
    return $line;
}

sub noop { return $_[0]; }

#-----------------------------------------------------------------
# Compare (with a filter) file contents when first file is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - first file missing");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir absent");
compare_filter_ok($missing_dir, $ok_pass_dat, \&noop, "first file missing");
test_test("first file missing");

#-----------------------------------------------------------------
# Compare (with a filter) file contents when second file is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - second file missing");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir absent");
compare_filter_ok($ok_pass_dat, $missing_dir, \&noop, "second file missing");
test_test("second file missing");

#-----------------------------------------------------------------
# Compare (with a filter) file contents when both files are missing.
#-----------------------------------------------------------------

test_out("not ok 1 - both files missing");
$line = line_num(+4);
test_diag("    Failed test ($test_file at line $line)",
"$absent_dir absent",
"$missing_dir absent");
compare_filter_ok($absent_dir,      $missing_dir, \&noop, "both files missing");
test_test("both files missing");

#-----------------------------------------------------------------
# Compare (with a filter) file contents when filter is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - failing no filter");
$line = line_num(+9);
test_diag("    Failed test ($test_file at line $line)",
'+---+--------------------+-------------------+',
'|   |Got                 |Expected           |',
'| Ln|                    |                   |',
'+---+--------------------+-------------------+',
'|  1|This file           |This file          |',
'*  2|is for 03ok_pass.t  |is for many tests  *',
'+---+--------------------+-------------------+'  );
compare_filter_ok($ok_pass_dat, $ok_diff_dat, \&noop, "failing no filter");
test_test("passing file");
