# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl WordNet-Extend-Locate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('WordNet::Extend::Locate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

################ Load Locate

my $win = WordNet::Extend::Locate->new();
ok($win);

################# change current stop list to valid input.

$win->stopList("s/\b(the|is|at)\b/");

my @err = $win->getError();
ok($err[0] == 0);

################## change current stop list using invalid input.

$win->stopList("ffwwwss");

@err = $win->getError();
ok($err[0] == 1);

################### addCleanUp with valid input

$win->addCleanUp("s/the/one/g");

@err = $win->getError();
ok($err[0] == 0);

################### addCleanUp with invalid input

$win->addCleanUp("qwergad");

@err = $win->getError();
ok($err[0] == 1);

#################### run processLemma() before calling preProcessing()

my @inLemma = ("dog","noun","withdef.1","man's best friend", "");
$win->processLemma(\@inLemma);

@err = $win->getError();
ok($err[0] == 2);

###################### run locate() and processLemma() after calling preProcessing().
$win->preProcessing();

my @location = $win->locate("dog\tnoun\twithdef.1\tman\'s best friend");

@err = $win->getError();
ok($err[0] == 0);

$win->processLemma(\@inLemma);

@err = $win->getError();
ok($err[0] == 0);

#################### set scoring method to BwS and run

$win->setScoreMethod('BwS');

@location = $win->locate("dog\tnoun\twithdef.1\tman\'s best friend");

@err= $win->getError();
ok($err[0] == 0);

#################### set scoring method to sim and run

$win->setScoreMethod('Similarity');

@location = $win->locate("dog\tnoun\twithdef.1\tman\'s best friend");

@err= $win->getError();
ok($err[0] == 0);