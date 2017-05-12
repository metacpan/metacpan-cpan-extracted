# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl WordNet-Extend-Insert.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 9;
use_ok('WordNet::Extend::Insert');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

################ Load Insert

my $win = WordNet::Extend::Insert->new();
ok($win);

############### Load QueryData

use_ok('WordNet::QueryData');

my $wqd = WordNet::QueryData->new;
ok($wqd);

################# attach a new word to WordNet and verify gloss

my @in5 = ("crackberry","noun","withdef.5", "A BlackBerry, a handheld device considered addictive for its networking capability.");    

my @loc5 = ("withdef.5","capability#n#2");

$win->attach(\@in5, \@loc5);

$wqd = WordNet::QueryData->new;
my @query = $wqd->querySense("crackberry#n#1","glos");
my $stringQ = join(' ', @query);

ok($stringQ =~ /A BlackBerry, a handheld device considered addictive for its networking capability./);

################## check attach hype 

@query = $wqd->querySense("crackberry#n#1","hype");
$stringQ = join(' ', @query);
ok($stringQ eq "capability#n#2");

################## revert WordNet changes

$win->restoreWordNet();

my @err = $win->getError();
ok($err[0] == 0);

################### merge a new word into WordNet and verify synset and gloss
$win->merge(\@in5,\@loc5);

$wqd = WordNet::QueryData->new;

@query = $wqd->querySense("crackberry#n#1","glos");
$stringQ = join(' ', @query);
my @hypeData = $wqd->querySense("capability#n#2", "glos");
my $stringH = join(' ', @hypeData);
ok($stringQ eq "$stringH");

@query = $wqd->querySense("crackberry#n#1","syns");
$stringQ = join(' ', @query);
ok($stringQ =~ /crackberry\#n\#1/);

$win->restoreWordNet();
