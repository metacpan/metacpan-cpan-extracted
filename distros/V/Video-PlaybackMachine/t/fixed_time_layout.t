# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Video::PlaybackMachine::TimeLayout::FixedTimeLayout') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

MAIN:
{

  my $layout = Video::PlaybackMachine::TimeLayout::FixedTimeLayout->new(15);
  is($layout->min_time(), 15);
  is($layout->preferred_time(1), 15);
  is($layout->preferred_time(2049), 15);
}
