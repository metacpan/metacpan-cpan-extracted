# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WordNet-SenseRelate-WordToSet.t'

# $Id: WordNet-SenseRelate-WordToSet.t,v 1.4 2008/04/07 03:28:36 tpederse Exp $

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;

use_ok WordNet::SenseRelate::WordToSet;
use_ok WordNet::QueryData;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# set up a few different WordToSet Objects

$qd = WordNet::QueryData->new;
ok ($qd, "construct QueryData");

%options = (measure => 'WordNet::Similarity::lesk',
	       wordnet => $qd);

$mod = WordNet::SenseRelate::WordToSet->new (%options);
ok ($mod, "construct WordToSet object for lesk");

%options = (measure => 'WordNet::Similarity::jcn',
	       wordnet => $qd);

$modjcn = WordNet::SenseRelate::WordToSet->new (%options);
ok ($modjcn, "construct WordToSet object for jcn");

%options = (measure => 'WordNet::Similarity::wup',
	       wordnet => $qd);

$modwup = WordNet::SenseRelate::WordToSet->new (%options);
ok ($modwup, "construct WordToSet object for wup");

# --------------------------------------------------------
# java the language
# --------------------------------------------------------

$res = $mod->disambiguate (target => 'java',
			      context => [qw/programming_language applet web/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#3');
# --------------------------------------------------------

$res = $modwup->disambiguate (target => 'java',
			      context => [qw/programming_language applet web/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#3');

# --------------------------------------------------------

$res = $modjcn->disambiguate (target => 'java',
			      context => [qw/programming_language applet web/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#2');

# -------------------------------------------------------------------------
# java the beverage
# -------------------------------------------------------------------------

$res = $mod->disambiguate (target => 'java',
			      context => [qw/drink coffee beverage/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#2');

# -------------------------------------------------------------------------

$res = $modjcn->disambiguate (target => 'java',
			      context => [qw/drink coffee beverage/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#2');

# -------------------------------------------------------------------------

$res = $modwup->disambiguate (target => 'java',
			      context => [qw/drink coffee beverage/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'java#n#2');

# -------------------------------------------------------------------------
# sir winston churchill
# -------------------------------------------------------------------------

$res = $mod->disambiguate (target => 'winston_churchill',
			      context => [qw/england world_war_two/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'winston_churchill#n#1');

# -------------------------------------------------------------------------

$res = $modjcn->disambiguate (target => 'winston_churchill',
			      context => [qw/england world_war_two/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

# can't find anything because of jcn needing info content values
is ($best, '');

# -------------------------------------------------------------------------

$res = $modwup->disambiguate (target => 'winston_churchill',
			      context => [qw/england world_war_two/]);

$best_score = -100;
$best = '';
foreach $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
	$best_score = $res->{$key};
	$best = $key;
    }
}

is ($best, 'winston_churchill#n#1');



