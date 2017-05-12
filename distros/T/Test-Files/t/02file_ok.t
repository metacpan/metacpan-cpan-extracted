use strict;

use Test::Builder::Tester tests => 5;
use File::Spec;

use Test::Files;

my $test_file    = File::Spec->catfile( 't', '02file_ok.t' );
my $missing_file = File::Spec->catfile( 't', 'missing' );
my $ok_pass_file = File::Spec->catfile( 't', 'ok_pass.dat' );

#-----------------------------------------------------------------
# Compare text to a file with same text.
#-----------------------------------------------------------------

test_out("ok 1 - passing text");
file_ok($ok_pass_file, <<"EOF", "passing text");
This file
is for 03ok_pass.t
EOF
test_test("passing text");

#-----------------------------------------------------------------
# Compare text to a missing file.
#-----------------------------------------------------------------

test_out("not ok 1 - absent file");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
          "$missing_file absent");
file_ok("$missing_file", "This file is really absent", "absent file");
test_test("absent file");

#-----------------------------------------------------------------
# Compare text to a file with different text.
#-----------------------------------------------------------------

test_out("not ok 1 - failing text");
$line = line_num(+9);
test_diag("    Failed test ($test_file at line $line)",
'+---+----------------------+-----------+',
'|   |Got                   |Expected   |',
'| Ln|                      |           |',
'+---+----------------------+-----------+',
'|  1|This file             |This file  |',
'*  2|is for 03ok_pass.t\n  |is wrong   *',
'+---+----------------------+-----------+'  );
file_ok($ok_pass_file, "This file\nis wrong", "failing text");
test_test("failing text");

#-----------------------------------------------------------------
# file_filter_ok with missing file
#-----------------------------------------------------------------

test_out("not ok 1 - absent filtered file");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
          "$missing_file absent");
file_filter_ok(
        "$missing_file",
        "This file is really absent",
        \&stip_num,
        "absent filtered file",
);
test_test("absent filtered file");

#-----------------------------------------------------------------
# Compare file to string with filter.
#-----------------------------------------------------------------

test_out("ok 1 - passing filtered text");
file_filter_ok($ok_pass_file, <<"EOF", \&strip_num, "passing filtered text");
This file
is for ok_pass.t
EOF
test_test("passing filtered text");

sub strip_num {
    my $line = shift;
    $line    =~ s/\d+//;

    return $line;
}
