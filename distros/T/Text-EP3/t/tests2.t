# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::EP3;
use Cwd;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$test = 1;

$o = Text::EP3->new;
$o->ep3_delimiter('#');
is($o->ep3_delimeter, '#');
$o->ep3_sync_lines(1);
$o->ep3_output_file("ep3.tstout");
$o->ep3_process("t/tests2a.tst");
close ($o->{Outfile_Handle});
select STDOUT;

open (INFILE, "ep3.tstout") || die "Can't get ep3.tstout";
is(&next_line, '# 1 "t/tests2a.tst" 1');
is(&next_line, '"this is line 1 of tests2a.tst"');
is(&next_line, '# 3 "'.cwd().'/t/tests2b.tst" 1');
is(&next_line, 'b "this is line 3 of tests2b.tst"');
is(&next_line, '# 1 "'.cwd().'/t/tests2c.tst" 1');
is(&next_line, 'c  "this is line 1 of tests2c.tst"');
is(&next_line, '# 5 "'.cwd().'/t/tests2b.tst" 2');
is(&next_line, 'b "this is line 5 of tests2b.tst"');
is(&next_line, '# 1 "'.cwd().'/t/tests2c.tst" 1');
is(&next_line, 'c  "this is line 1 of tests2c.tst"');
is(&next_line, '# 7 "'.cwd().'/t/tests2b.tst" 2');
is(&next_line, 'b "this is line 7 of tests2b.tst"');
is(&next_line, '# 3 "t/tests2a.tst" 2');
is(&next_line, '"this is line 3 of tests2a.tst"');
is(&next_line, '<undef>');

sub next_line {
    my $line = '';
    while (defined $line && $line eq '') { $line = readline(INFILE); chomp $line if defined $line; }
    $line = '<undef>' unless defined $line;    
    $line;
}

sub is {
    my ($got, $want) = @_;
    $test++;
    if ($got ne $want) {
        print "not ok $test # expected '$want', got '$got'\n";
    } else {
        print "ok $test\n";
    }
}