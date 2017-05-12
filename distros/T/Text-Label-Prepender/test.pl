# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Text::Label::Prepender;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

  my $prepender = Text::Label::Prepender->new ( 
    initial_label => '.', # initial label
    separator     => '/',   # output between label and data line
    label_char    => ':',  # the character signifying a line is a label
   ) ;
      

my @input = qw(aaa bbb ccc one one/hump: ddd eee fff two/hump: ggg hhh iii);

for (@input) {
    
    if (my $processed = $prepender->process($_)) {
       print $processed, "\n";
    }

}
