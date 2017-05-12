#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 35 }

$ref = new Text::Scan;

@termlist = ( 
	"banana boat",
	"banana boat in the mist",
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
	$ref->insert($term, $term);
}

@texts = ( 
	"banana boat in the mist",
	"pajamas are in the party",
	"pajamas are in the party at my house",
	"words are words",
	"form of an ice waterslide",
	"tirewater in my soup",
	"tidewater shellfish",
	"telephone",
);

@longlist = (
	"banana boat", "banana boat",
	"banana boat in the mist", "banana boat in the mist",
	"pajamas are in", "pajamas are in",
	"pajamas are in the party", "pajamas are in the party",
	"pajamas are in", "pajamas are in",
	"pajamas are in the party", "pajamas are in the party",
	"pajamas are in the party at my house", "pajamas are in the party at my house",
	"words", "words",
	"words are words", "words are words",
	"words", "words",
	"form", "form",
	"form of an ice waterslide", "form of an ice waterslide",
	"tirewater", "tirewater",
	"tirewater in my soup", "tirewater in my soup",
	"tidewater", "tidewater",
	"tidewater shellfish", "tidewater shellfish",
	"telephone", "telephone"
);


#print STDERR join "\n", $ref->values();
#print STDERR "\n\n";

my @result = ();
for my $line ( @texts ){
	push @result, $ref->scan( $line );
}

# @result should be exactly @longlist.


ok( $#result, $#longlist );

for my $i ( 0..$#result ){
#print "$result[$i] == $longlist[$i]\n";
	ok($result[$i], $longlist[$i] );
}


