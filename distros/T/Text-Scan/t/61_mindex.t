#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 17 }

$ref = new Text::Scan;

@termlist = ( 
	"banana boat in the mist",
	"business risk",
	"pajamas are in",
	"pajamas are in the party",
	"pajamas are in the party at my house",
	"words",
	"words are words",
	"form",
	"form of an ice waterslide",
	"tirewater",
	"tirewater in my soup",
	"tidewater",
	"tidewater shellfish",
	"telephone",
	"telephone me"
);
 
for my $term (@termlist) {
	$ref->insert($term, '');
}

@longlist = ( 
	"any business risk in the pajamas are in the party tomorrow with words to the contrary form of an ice weasel telephone tirewater in my soup jackass"
);

@answers = ( 
	"business risk", 4,
	"pajamas are in", 25,
	"pajamas are in the party", 25,
	"words", 64,
	"form", 86,
	"telephone", 108,
	"tirewater", 118,
	"tirewater in my soup", 118
);

for my $line ( @longlist ){
	push @result, $ref->mindex( $line );
}

# @result should be exactly @answers.

print "results contain ", scalar @result, " items\n";
print join("\n", @result), "\n";

ok( $#result == $#answers );

for my $i ( 0..$#answers ){
	ok($result[$i] eq $answers[$i] );
	print "($result[$i] cmp $answers[$i])\n";
}


