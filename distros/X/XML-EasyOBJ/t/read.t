
use strict;
use Test;
use XML::EasyOBJ;
use FindBin qw/$Bin/;

BEGIN { plan tests => 8 }

ok( my $doc = XML::EasyOBJ->new( "$Bin/read.xml" ) );
ok( my @maps = $doc->MAP, 6 );

ok( $doc->MAP(2)->KINGDOM(0)->NAME->getString, 'The Church of the Anhk' );
ok( my @regions = $doc->MAP(2)->KINGDOM(0)->DIPLOMACY->REGION, 2 );
ok( $regions[0]->getString, 'EBRA' );
ok( $regions[1]->getString, 'ULM' );

my $counter = 0;
foreach my $m ( $doc->MAP ) {
	foreach my $k ( $m->KINGDOM ) {
		$counter++;
	}
}
ok( $counter, 43 );

ok( $doc->MAP->KINGDOM(2)->DIPLOMACY->getString, qr/^\s*Vught \(ne\), Wijk \(ne\)\s*WIJK\s*VUGHT\s*$/s );
