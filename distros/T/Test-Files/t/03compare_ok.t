use strict;

use Test::Builder::Tester tests => 5;
use File::Spec;

use Test::Files;

my $test_file    = File::Spec->catfile( 't', '03compare_ok.t'   );
my $missing_file = File::Spec->catfile( 't', 'missing'          );
my $pass_file    = File::Spec->catfile( 't', 'ok_pass.dat'      );
my $absent_file  = File::Spec->catfile( 't', 'absent'           );
my $same_file    = File::Spec->catfile( 't', 'ok_pass.same.dat' );
my $diff_file    = File::Spec->catfile( 't', 'ok_pass.diff.dat' );

#-----------------------------------------------------------------
# Compare two files with the same content.
#-----------------------------------------------------------------

test_out("ok 1 - passing file");
compare_ok($pass_file, $same_file, "passing file");
test_test("passing file");

#-----------------------------------------------------------------
# Compare missing file to a file which is exists.
#-----------------------------------------------------------------

test_out("not ok 1 - first file missing");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_file absent");
compare_ok($missing_file,    $pass_file,       "first file missing");
test_test("first file missing");

#-----------------------------------------------------------------
# Compare file to a file which is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - second file missing");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_file absent");
compare_ok($pass_file, $missing_file,          "second file missing");
test_test("second file missing");

#-----------------------------------------------------------------
# Compare two files, both of which are missing.
#-----------------------------------------------------------------

test_out("not ok 1 - both files missing");
$line = line_num(+4);
test_diag("    Failed test ($test_file at line $line)",
"$absent_file absent",
"$missing_file absent");
compare_ok($absent_file,      $missing_file,          "both files missing");
test_test("both files missing");

#-----------------------------------------------------------------
# Compare two files with the different content.
#-----------------------------------------------------------------

test_out("not ok 1 - failing file");
$line = line_num(+9);
test_diag("    Failed test ($test_file at line $line)",
'+---+--------------------+-------------------+',
'|   |Got                 |Expected           |',
'| Ln|                    |                   |',
'+---+--------------------+-------------------+',
'|  1|This file           |This file          |',
'*  2|is for 03ok_pass.t  |is for many tests  *',
'+---+--------------------+-------------------+'  );
compare_ok($pass_file, $diff_file, "failing file");
test_test("failing file");

