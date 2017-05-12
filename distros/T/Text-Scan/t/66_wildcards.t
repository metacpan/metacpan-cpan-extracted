#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 8 }

$ref = new Text::Scan;
$ref->usewild();

@termlist = ( 
	"banana boat * the mist",
	"pajamas are in",
	"pajamas * * * party",
	"pajamas are in the party at my house",
	"words",
	"words are words",
	"form",
	"form of an * waterslide",
	"tirewater",
	"tirewater * my soup",
	"telephone",
);
 
for my $term (@termlist) {
	$ref->insert($term, '');
}

$line = ( 
	"any business risk in the pajamas are in the party tomorrow with words to the contrary form of an ice weasel telephone tirewater in my soup jackass"
);

%answers = ( 
	"pajamas are in", 25,
	"pajamas are in the party", 25,
	"words", 64,
	"form", 86,
	"telephone", 108,
	"tirewater", 118,
	"tirewater in my soup", 118,
);

%result = $ref->mindex( $line );

# %result should be exactly %answers.

print "results contain ", scalar keys %result, " items\n";
print join("\n", keys %result), "\n";

ok( scalar keys %result, scalar keys %answers );

for my $i ( keys %answers ){
	ok( exists $result{$i} );
	print "$i\n";
}


