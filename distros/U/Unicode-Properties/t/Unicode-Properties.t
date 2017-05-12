#!perl

use Test::More tests => 7;
use utf8;

# Grab this from the module itself.

BEGIN {
	use_ok( 'Unicode::Properties' );
}

use Unicode::Properties 'uniprops';

ok (!defined (uniprops()), 'empty input undefined output');

sub doit
{
    my ($char, $expected, $testname) = @_;
    print join (", ",uniprops($char)),"\n";
    ok (join (',', uniprops($char)) eq $expected, $testname);
}


doit ('A',"ASCII,Alphabetic,Any,Assigned,IDContinue,IDStart,InBasicLatin,Latin,Uppercase",'ASCII A properties');
doit ('AGGRO',"ASCII,Alphabetic,Any,Assigned,IDContinue,IDStart,InBasicLatin,Latin,Uppercase",'Truncate long strings');
doit ('☺',"Any,Assigned,Common,InMiscellaneousSymbols",
      'Unicode smiley properties');
doit ('あ',"Alphabetic,Any,Assigned,Hiragana,IDContinue,IDStart,InHiragana",
      "Hiragana A properties");
SKIP: {
    skip 'Pre-5.0.0 version of Unicode', 1,
	unless Unicode::Properties::versionok ("5.0.0");
    doit ('ᬉ',"Alphabetic,Any,Assigned,Balinese,IDContinue,IDStart,InBalinese","Balinese for 5.0.0");
}
