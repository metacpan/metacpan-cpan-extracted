# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::EP3;
use Verilog;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$tests = 6;
$o = new Text::EP3;
for ($i = 2; $i <= $tests; $i++) {
    $o->ep3_output_file("ep3.tstout");
    $o->ep3_process("ep3.tst",$i);
    close ($o->{Outfile_Handle});
    select STDOUT;
    checkout($i);
}

sub checkout {
   my $test = shift;
   open (INFILE, "ep3.tstout") || die "Can't get ep3.tstout";
   @file = <INFILE>;
   if ($#file != 0) {
      print "not okA $test\n"; 
      return (0);
   }
   if ($file[0] !~ /ok\s*$test/) {
      print "not okB $test\n"; 
      return(0);
   }
   print "ok $test\n";
   return($test);
}
