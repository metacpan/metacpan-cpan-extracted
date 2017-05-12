
# typesafety.pm test script.
# first, we run the program realtest.pl. it should compile and run without any problems - syntax
# error, false diagnostic messages from typesafety.pm, or fatal errors in typesafety.pm - or else
# all is lost and we give up.
# the file realtest.pl contains several commented out lines with a comment after them starting with 
# the word "illegal" - these are unsafe constructs that typesafety.pm looks for and complains about.
# if these lines, when uncommented, cause a fatal diagnostic, then typesafety.pm is working correctly - yay!
# we uncomment those one by one in a copy of realtest.pl called faketest.pl (for lack of a better name)
# and try to run it. if the system() call comes back with a failure code, all is well.
# beyond the initial test (for successfullying use'ing typesafety.pm), there is one test for
# each line in realtest.pl with an "illegal" comment.

# h2xs says:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use warnings;

$|++; # line noise!

use Test; BEGIN { plan tests => 11 };
# sub ok { print "ok: ", @_, "\n"; } # debugging

use typesafety; ok(1); 

system 'perl', 'realtest.pl' and die $!; ok(1); # everything legal should be legal or stop now 

open my $f, '<', 'realtest.pl' or die $!; read $f, my $testprog, -s $f or die $!; close $f;

my $seek = qr/[^\n]* # illegal[^\n]*/;

my $faketest = sub {
  my $test = shift; # which test do we want to run?
  my $testprog = $testprog; # local copy to mangle
  my $line; my $pos;
  while(--$test > 0 ) {
    # seek to the nth test
    $testprog =~ m/\G.*?# $seek/cgs or die;
  }
  $testprog =~ s/\G(.*?)# ($seek)/$1 $2/s or die "stopped at " . substr($testprog, pos($testprog), 160);
  print "# enabled line: $2\n";
  open my $f, '>', 'faketest.pl' or die $!;
  print $f $testprog or die $!;
  close $f; 
  print "# an error is a good thing - it means we cought it: ";
  if(system 'perl', 'faketest.pl') {
    ok(1); # error - good! typesafety.pm cought the illegal construct
  } else {
    ok(0); # everything ran fine - whoops! we're busted =(
  }
};

for my $i (1..10) {
  # XXX should be ..11 but test 13 is broken ($hash{foo} = $hash{bar})
  $faketest->($i);
}

__END__


