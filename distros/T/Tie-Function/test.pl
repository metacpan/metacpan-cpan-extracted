# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Tie::Function;
ok(1); # If we made it this far, we're ok.

#########################

  tie my %a, Tie::Function => sub{join '_'x$_[0],qw/( | )/};
  # split on $; to recover multiple arguments
  tie my %times, Tie::Function => sub{
	$_[0] * $_[1]
  };
  # print "3 times 5 is $times{3,5}\n"

ok($a{3} eq q/(___|___)/);

   print "\nsmall: $a{1}\n\nmedium: $a{2}\n\nwide: $a{3}\n\n"; 
   
ok($times{27,53} == 27 * 53);

