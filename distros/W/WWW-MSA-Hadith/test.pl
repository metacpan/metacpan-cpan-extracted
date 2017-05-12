# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use WWW::MSA::Hadith;
use Data::Dumper;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


$| = 1;

my $obj = new WWW::MSA::Hadith();
ok($obj);

$obj->query('(paradise or heaven) and laugh and man and last');
ok($obj->query());

$obj->submit();

my $result = $obj->get_result();

ok($obj->read($result->{id}));

