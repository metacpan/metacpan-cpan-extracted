#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 4 }

$ref = new Text::Scan;
$ref->usewild();

@termlist = ( 
	"marine corps expedition",
	"marine * * forces",
	"mso 456 us*",
	"mso 4* * * mso 5*",

);
 
for my $term (@termlist) {
	$ref->insert($term, 0);
}

@longlist = ( 
	"bla marine corps expeditionary forces bla",
	"bla bla mso 456 uss adroit mso 509 bla bla",
);

%answers = ( 
	"marine corps expeditionary forces", 0,
	"mso 456 uss", 0,
	"mso 456 uss adroit mso 509", 0,
);

for my $line ( @longlist ){
	push @result, $ref->scan( $line );
}
%result = @result;

# %result should be exactly %answers.

print "results contain ", scalar keys %result, " items\n";
print join("\n", keys %result), "\n";

ok( scalar keys %result, scalar keys %answers );

for my $i ( keys %answers ){
	ok( exists $result{$i} );
	print "$i\n";
}


