# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WordNet-SenseKey.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN {
require_ok( 'WordNet::QueryData' );
use_ok('WordNet::SenseKey');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# XXX hack alert! Hard-coded directory! Not sure how do deal with this!
#
my $wn = WordNet::QueryData->new("/usr/share/wordnet");
my $sk = WordNet::SenseKey->new($wn);

my $skey = "run%2:38:04::";
my $canon = $sk->get_canonical_sense("escape", $skey);

ok($canon eq "escape%2:38:02::", "canonical sense test");

my $snum = $sk->get_sense_num($skey);
my $sskey = $sk->get_sense_key($snum);
my $ssnum = $sk->get_sense_num($sskey);

ok($skey eq $sskey, "sense key test");
ok($snum eq $ssnum, "sense num test");

$canon = $sk->get_canonical_sense("easdfwerewtytyuiu", $skey);
ok(!defined($canon), "undefined canonical sense test");

$canon = $sk->get_canonical_sense("escape", "aswrtuofolr%2:38:02::");
ok(!defined($canon), "undefined canonical sense test 2");

$ssnum = $sk->get_sense_num("aswrtuofolr%2:38:02::");
$sskey = $sk->get_sense_key("qwerweuricyuc#v#2");
ok(!defined($ssnum), "undefined sense number test");
ok(!defined($sskey), "undefined sense key test");
