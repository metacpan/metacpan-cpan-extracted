#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 2 }

$infile = $ARGV[0] || '';

$ref = new Text::Scan;

@termlist1 = (
	"colts",
	"colt",
	"cold",
	"cobble",
	"cor",
	"cart",
	"cat"
);

@termlist2 = ( 
	"aient",
	"ais",
	"ait",
	"ai",
	"ant",
	"assent",
	"asses",
	"asse",
	"assiez",
	"assions",
	"as",
	"a",
	"ent",
	"eraient",
	"erais",
	"erait",
	"erai",
	"eras",
	"era",
	"erez",
	"eriez",
	"erions",
	"erons",
	"eront",
	"er",
	"es",
	"ez",
	"e",
	"iez",
	"ions",
	"ons",
	"âmes",
	"âtes",
	"ât",
	"èrent",
	"ées",
	"ée",
	"és",
	"é"
);

for( @termlist1, @termlist2 ){
	$ref->insert($_, $_);
}

if( $infile ){
	while(<>){
		chomp;
		$ref->insert( (split(/\t/))[0,1] );
	}
}

print "States: ", $ref->states,
	"\nTransitions: ", $ref->transitions,
	"\nTerminals: ", $ref->terminals, "\n";

@keys = $ref->keys();

#print "Done traversing\n";
#print join "\n", @keys;
#print "\n";

ok( ! $ref->serialize("testdump") );

#print "Done serializing\n";

@keys2 = $ref->keys();

ok(@keys == @keys2);

#print "New keys:\n";
#print join "\n", @keys2;
#print "\n";

exit 0;

