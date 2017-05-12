#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 25 }

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

$line = "any business risk in the pajamas are in the party tomorrow with words to the contrary form of an ice weasel telephone tirewater in my soup jackass";

%answers = ( 
	"business risk" => [4, ''],
	"pajamas are in" => [25, ''],
	"pajamas are in the party" => [25, ''],
	"words" => [64, ''],
	"form" => [86, ''],
	"telephone" => [108, ''],
	"tirewater" => [118, ''],
	"tirewater in my soup" => [118, '']
);

%result = map { $_->[0] => [ $_->[1], $_->[2] ]} $ref->multiscan( $line );

# %result should be exactly %answers.

print "results contain ", scalar keys %result, " items\n";

ok( scalar keys %result, scalar keys %answers );

for my $i ( keys %answers ){
	ok( exists $result{$i} );
	ok($result{$i}->[0], $answers{$i}->[0] );
	ok($result{$i}->[1], $answers{$i}->[1] );
}


