# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { 
  use Symbol qw( gensym );
  $num_tests = 0;
  $fh = gensym;
  open $fh, '+< t/words.txt' or die "unable to read word file: $!";  
  while(defined(my $line = <$fh>)) {
    $num_tests++;
  }
  seek $fh, 0, 0 or die "seek failed: $!";
  $num_tests *= 2;
  
  $| = 1; print "1..", $num_tests+1, "\n"; 
}
END {print "not ok 1\n" unless $loaded;}
use Text::DoubleMetaphone qw( double_metaphone );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 1;
while(defined(my $line = <$fh>)) {
  chomp $line;
  my($word, $m1, $m2) = split /,/, $line;
  $m1 = '' unless defined $m1;
  $m2 = '' unless defined $m2;
  $test++;
  my($c1, $c2) = double_metaphone( $word );
  $c1 = '' unless defined $c1;
  $c2 = '' unless defined $c2;
  if ($c1 ne $m1 or $c2 ne $m2) {
    print "not ok $test\n";
    # print STDERR "$word: '$c1' => '$m1', '$c2' => '$m1'\n";
  } else {
    print "ok $test\n";
  }
  $test++;
  $c1 = double_metaphone( $word );
  if ($c1 ne $m1) {
    print "not ok $test\n";
    # print STDERR "$word: '$c1' => '$m1'\n";
  } else {
    print "ok $test\n";
  }
}
