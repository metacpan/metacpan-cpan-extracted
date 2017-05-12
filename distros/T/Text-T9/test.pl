# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Text::T9;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my @words = qw( this is just a simple kiss test lips here how );

for my $num ( qw( 5477 8447 746753 469 ) )
  {
  print "$num: ";
  print "$_ " for( t9_find_words( $num, \@words ) );
  print "\n";
  }

ok(1); # If we made it this far, we're ok.

