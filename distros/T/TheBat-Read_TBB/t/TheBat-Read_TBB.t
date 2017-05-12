# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-JSpline.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('TheBat::Read_TBB') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


  # use TheBat::Read_TBB;
  my %ref; my $ky;


  while(&Read_TBB("t/messages.tbb",\%ref)) {
    foreach $ky (keys %ref) {
      # diag( "$ky:\t" . $ref{$ky} . "\n" );
    }
    ok($ref{'md5hex'} eq '4bc49ef41afd01b08f3a480a6dce6068');
  }
  exit 0;
