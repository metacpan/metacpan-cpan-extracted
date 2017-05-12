use strict;
use Test::Builder::Tester tests => 5;
use Test::More;
use File::Spec;

use Test::Files;

my $test_file    = File::Spec->catfile( 't', '07comp_dir_f.t'          );
my $missing_dir  = File::Spec->catdir ( 't', 'missing_dir'             );
my $time_dir     = File::Spec->catdir ( 't', 'time'                    );
my $time2_dir    = File::Spec->catdir ( 't', 'time2'                   );
my $lib_fail_dir = File::Spec->catdir ( 't', 'lib_fail'                );
my $stamp1       = File::Spec->catfile( 't', 'time', 'time_stamp.dat'  );
my $stamp2       = File::Spec->catfile( 't', 'time2', 'time_stamp.dat' );

#-----------------------------------------------------------------
# Compare (with a filter) file contents in directories which
# are the same.
#-----------------------------------------------------------------

test_out("ok 1 - passing");
compare_dirs_filter_ok($time_dir, $time2_dir, \&four_to_one, "passing");
test_test("passing");

sub four_to_one {
    my $line =  shift;
    $line    =~ s/4/1/;
    return $line;
}

#-----------------------------------------------------------------
# Compare (with a filter) file contents in directories when
# first directory is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - missing first dir");
my $line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir is not a valid directory");
compare_dirs_filter_ok($missing_dir, $time_dir, sub{}, "missing first dir");
test_test("missing first dir");

#-----------------------------------------------------------------
# Compare (with a filter) file contents in directories when
# second directory is missing.
#-----------------------------------------------------------------

test_out("not ok 1 - missing second dir");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"$missing_dir is not a valid directory");
compare_dirs_filter_ok($time_dir, $missing_dir, sub{}, "missing second dir");
test_test("missing second dir");

#-----------------------------------------------------------------
# Compare (with a filter) file contents in directories when
# filter is not supplied (or is not a code ref).
#-----------------------------------------------------------------

test_out("not ok 1 - missing coderef");
$line = line_num(+3);
test_diag("    Failed test ($test_file at line $line)",
"Third argument to compare_dirs_filter_ok must be a code reference (or undef)");
compare_dirs_filter_ok($time_dir, $lib_fail_dir,    "missing coderef");
test_test("missing coderef");

#-----------------------------------------------------------------
# Compare (with a filter) file contents in directories when
# filter is does nothing and files differ slightly.
#-----------------------------------------------------------------

SKIP: {
skip "test only for unix, i.e. not for $^O", 1 unless ( $^O =~ /nix|nux|solaris/ );
test_out("not ok 1 - failing noop filter");
$line = line_num(+10);
test_diag("    Failed test ($test_file at line $line)",
'+---+----------------------------------------------------------+----------------------------------------------------------+',
"|   |$stamp1                                     |$stamp2                                    |",
'| Ln|                                                          |                                                          |',
'+---+----------------------------------------------------------+----------------------------------------------------------+',
'|  1|This file                                                 |This file                                                 |',
'|  2|is for 03ok_pass.t                                        |is for 03ok_pass.t                                        |',
'*  3|Touched on: Wed Oct 15 12:38:12 CDT 2003, this afternoon  |Touched on: Wed Oct 15 12:38:42 CDT 2003, this afternoon  *',
'+---+----------------------------------------------------------+----------------------------------------------------------+');
compare_dirs_filter_ok($time_dir, $time2_dir, \&noop, "failing noop filter");
test_test("failing noop filter");
}

sub noop {
    return $_[0];
}
