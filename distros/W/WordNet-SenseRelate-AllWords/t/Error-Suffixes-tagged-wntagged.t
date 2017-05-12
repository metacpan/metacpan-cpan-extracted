# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WordNet-SenseRelate.t'

use WordNet::SenseRelate::AllWords;
use WordNet::QueryData;
use WordNet::Tools;
use Test::More;
use File::Spec;
no warnings 'qw';

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
        plan tests => 41;
     }

my $default_stoplist_raw_txt = File::Spec->catfile ('web','cgi-bin','allwords','user_data','default-stoplist-raw.txt');
ok (-e $default_stoplist_raw_txt);

# =============================================================

# now we can assume that we are using WordNet version 3.0 or better
# the tests in this file were originally developed for version 3.0
# if results change with new versions of WordNet, add a specific
# test for that new version and provide a new result otherwise, assume 
# that results don't change from 3.0.

# WordNet versions less than 3.0 will still run through these tests
# the results might vary and we might see failures as a result
# but that's probably better than just skipping the tests

# These test cases are related to tagged text error handling

# Check for invalid tag

$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
				     wntools => $wntools,	
				     measure => 'WordNet::Similarity::lesk',
				     pairScore => 1,
				     contextScore => 1);
ok ($obj);

@context = qw/The\/DT star\/NN married\/VBD qn\/DT astronomer\/NN .\/./;

@expected = qw/The#CL star#n#1 marry#v#1 qn#CL astronomer#n#1 .#IT/;

@res = $obj->disambiguate (window => 3,
			   tagged => 1,
			   context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}
undef $obj;

# Check if wonderful#a is not considered as a stopword if 'a' is contained in the stoplist
$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
					    wntools => $wntools,
				  	    measure => 'WordNet::Similarity::lesk',
					    stoplist => $default_stoplist_raw_txt,
					    pairScore => 0.0,
					    contextScore => 0.0,
                                            wnformat => 1);

@context = qw/math#n is#v a wonderful#a subject#n/;

@expected = qw/math#n#1 is#v#NR a#o wonderful#a#1 subject#n#4/;

@res = $obj->disambiguate (window => 3,
			   tagged => 0,
			   context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

undef @res;
undef $obj;

# Check if no tag is detected in wntagged text

@context = qw/The king#n and queen#n went on a trip#n to visit#v their subjects#n/;

@expected = qw/The#NT king#n#9 and#NT queen#n#7 went#NT on#NT a#NT trip#n#1 to#NT visit#v#1 their#NT subjects#n#NR/;

$obj = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
					    wntools => $wntools,
				  	    measure => 'WordNet::Similarity::lesk',
	   				    pairScore => 0.0,
					    contextScore => 0.0,
                                            wnformat => 1);
ok ($obj);

@res = $obj->disambiguate (window => 3,
			   tagged => 0,
			   context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

undef @res;

# check if multiple #s and a missing word cause a problem
@context = qw/i##nn wonder if this will cause #problems#a#a/;

@expected = qw/i##nn#IT wonder#NT if#NT this#NT will#NT cause#NT #problems#a#a#MW/;

@res = $obj->disambiguate (window => 3,
			   tagged => 0,
			   context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

undef @res;

# check for no relatedness found with the surrounding words
@context = qw/the dog #n is a friend#n of mine/;

@expected = qw/the#NT dog#NT #n#MW is#NT a#NT friend#n#NR of#NT mine#NT/;

@res = $obj->disambiguate (window => 3,
			   tagged => 0,
			   context => [@context]);

for my $i (0..$#expected) {
    is ($res[$i], $expected[$i]);
}

undef @res;

