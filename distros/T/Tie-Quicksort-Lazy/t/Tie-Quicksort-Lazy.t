# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-Quicksort-Lazy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 25 };
use Tie::Quicksort::Lazy TRIVIAL => 2;
use sort 'stable';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @input = qw/ a b c d A B C D 1 2 3 4 /;
my @sorted_input = sort @input;
my @sorted_input2 = qw/ 1 2 3 4 a A b B c C d D/; 

tie my @sorted , Tie::Quicksort::Lazy, @input;
tie my @sorted2, Tie::Quicksort::Lazy::Stable, sub {uc($_[0]) cmp uc($_[1])  },@input;


while (@sorted){
  my ($this, $that) = ((shift @sorted),(shift @sorted_input));
  warn "test script got $this which should match $that\n";
  ok ($this eq $that);
};
while (@sorted2){
  my ($this, $that) = ((shift @sorted2),(shift @sorted_input2));
  warn "test script got $this which should match $that\n";
  ok ($this eq $that);
};

