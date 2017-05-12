
# $Id: WordNet-SenseRelate-AllWords.t,v 1.20 2009/04/02 13:03:07 kvarada Exp $

# DO NOT ADD NEW TESTS TO THIS .t FILE unless you test with version
# 2.0 and 2.1. If you have new tests, please create a new .t file
# and check that the version is at least whatever version you were
# using, then when a new version comes out we can go back and check
# to see if they have changed

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WordNet-SenseRelate.t'

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# get the WordNet hash codes 

use WordNet::SenseRelate::AllWords;
use WordNet::QueryData;
use WordNet::Tools;

my $qd = WordNet::QueryData->new;
my $wntools = WordNet::Tools->new($qd);
my $wnHashCode = -1;
$wnHashCode = $wntools->hashCode();

#########################

# set WordNet version constants - these are hashcodes obtained
# from WordNet::Tools because WordNet doesn't keep track of it's
# version reliably

use constant WNver20 => 'US9EUGPpJj2jVr+fRrZqQX6vcGs';
use constant WNver21 => 'LL1BZMsWkr0YOuiewfbiL656+Q4';
use constant WNver30 => 'eOS9lXC6GvMWznF1wkZofDdtbBU';

use Test::More;
if ( !($wnHashCode eq WNver20) &&
     !($wnHashCode eq WNver21) &&
     !($wnHashCode eq WNver30)) {
        plan skip_all => 'WordNet version is not 2.0 2.1 3.0 -> skip tests';
     }
else {
        plan tests => 30;
     }

# =============================================================
# if we are testing, print out some info about the WordNet version

isnt ($wnHashCode, -1);
diag ("WordNet hash : $wnHashCode");

my $wnpath = 'dummypath';
$wnpath = $qd->dataPath();
isnt($wnpath,'dummypath');  # found wordnet path
diag ("WordNet path : $wnpath");

# =============================================================

# now we can assume that we are using WordNet version 2.0 or better
# the tests in this file were originally developed for version 2.0
# if results change with new versions of WordNet, add a specific
# test for that new version and provide a new result otherwise, assume 
# that results don't change from 2.0.

# WordNet versions less than 2.0 will still run through these tests
# the results might vary and we might see failures as a result
# but that's probably better than just skipping the tests

my @context = ('my/PRP$', 'cat/NN', 'is/VBZ', 'a/DT', 'wise/JJ', 'cat/NN');

$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
				     wntools => $wntools,
				     measure => 'WordNet::Similarity::lesk',
				     pairScore => 1,
				     contextScore => 1);
ok ($obj);

# =============================================================
# start testing sense tags as returned by disambiguate
# these are in wps form (i.e., cat#n#1) and both the results
# and the sense numbers are potentially WordNet version dependent
# if we detect that a test result changes due to a WordNet
# version change, then we can add a version specific test for
# that case 
# =============================================================

my @res = $obj->disambiguate (window => 5,
			      tagged => 1,
			      context => [@context]);

no warnings 'qw';
my @expected = qw/my#CL cat#n#7 be#v#1 a#CL wise#a#1 cat#n#7/;

is ($#res, $#expected);

for my $i (0..$#expected) {
	is ($res[$i], $expected[$i]);
}

undef $obj;

# this test and others like it fail badly with measures other than 
# lesk...

$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
				     wntools => $wntools,
				     measure => 'WordNet::Similarity::wup',
				     pairScore => 0,
				     contextScore => 0);
ok ($obj);

# try it with tracing on
$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
				  wntools => $wntools,
				  measure => 'WordNet::Similarity::lesk',
				  trace => 1,
				  );

ok ($obj);

undef @res;

@res = $obj->disambiguate (window => 2,
			   tagged => 1,
			   context => [@context]);

my $str = $obj->getTrace ();

ok ($str);

@expected = qw/my#CL cat#n#NR be#v#1 a#CL wise#a#1 cat#n#7/;

for my $i (0..$#expected) {
	is ($res[$i], $expected[$i]);
}


# check that physics#n stays as physics#n not physic#n in wnformat mode

@context = qw/physics#n not#r medicine#n/;
@expected = qw/physics#n#1 not#r#1 medicine#n#2/;

$obj = $obj->new (wordnet => $qd,
		  wntools => $wntools,
                  measure => 'WordNet::Similarity::lesk',
                  wnformat => 1);

@res = $obj->disambiguate (window => 3, tagged => 0, context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

# test fixed mode
@context = qw/brick building fire burn/;

# this test case changes results with version 3.0 of WordNet

# this is what is expected with 2.0 or 2.1 :

if (($wnHashCode eq WNver21) || ($wnHashCode eq WNver20)) {
	@expected = qw/brick#n#1 building#n#1 fire#n#3 burn#n#3/;
	}

# in 3.0 it shifts to fire#n#2, which is what we have below
# if we see that this is 3.0 we'll change the expected result :

elsif ($wnHashCode eq WNver30) {
	@expected = qw/brick#n#1 building#n#1 fire#n#2 burn#n#3/;
	}

else {
	@expected = qw/brick#n#1 building#n#1 fire#n#2 burn#n#3/;
	diag ("wnHashCode : $wnHashCode ne 2.0 2.1 3.0 ??"); 
	}

$obj = $obj->new (wordnet => $qd,
		  wntools => $wntools,	
		  measure => 'WordNet::Similarity::lesk');

@res = $obj->disambiguate (window => 4, tagged => 0,
                           scheme => 'fixed', context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

# create a test case to make sure that we don't explode if window size 
# is omitted - the only required parameter should be context, fixes
# bug reported for 0.07 

@context = qw/winter spring summer fall/;

@expected = qw/winter#n#1 spring#n#1 summer#n#1 fall#n#1/;

$obj = $obj->new (wordnet => $qd,
		  wntools => $wntools,
		  measure => 'WordNet::Similarity::lesk');

@res = $obj->disambiguate (context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

