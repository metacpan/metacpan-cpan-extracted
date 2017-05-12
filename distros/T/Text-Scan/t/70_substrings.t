#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 7 }

$ref = new Text::Scan;

@termlist = ( 
	'oceanographic information',
	'oceanographic',
	'oceanographic data',
	'oceanographic observations',
	'oceanographic fleet',
	'oceanographic survey ships',
	'oceanographic and hydrometeorological equipment',

);

my $document = "Besides mapping the ocean floor to update nautical charts, the Navy's oceanographic ships typically conduct sampling of the physical properties of the water column as well as the composition of the ocean floor, launch and recovery of instrument packages, acoustic property measurements, and process and analyze the data on board with the latest computer technology.
For the fledgling nation's newly established Navy, it was important to confirm the accuracy of the star positions that were listed in whatever almanac the Navy was using, and the time as kept by the ship's chronometer. The Depot took on the responsibility for oceanographic studies in 1854, and was renamed the U.S. Naval Observatory and Hydrographical Office; even earlier, though, its superintendent, Lt. Matthew Fontaine Maury, had started collecting critical oceanographic data on currents, tides, storms, sea temperatures, soundings, and sea creature and iceberg sightings. 
All the Navy's oceanographic survey ships carry the latest in over-the-side sensors and sampling equipment.  Naval oceanography supercomputing capabilities will be maintained to process more than 2 million meteorological and
oceanographic observations received each day. 

The Oceanographic Fleet For oceanographers, the sea itself is the laboratory, and the adequacy of ships used will significantly affect the oceanographer's ability to work at sea.
The teams depended on meteorological and oceanographic information available from satellite downlinks--both direct satellite visible and infrared photos and satellite data links of classified homepages with the latest forecasts and data.
The long-term tasks in this sphere shall be the preservation and
development of the research complex that ensures the development of
the russian fleet, the studies of marine medium, the resources and
space of the world's oceans, the development of research and pilot
fleets, guaranteed creation of marine navigation, geophysical,
fishing and other specialized maps and manuals for navigation in
all parts of the world's oceans, the creation of a federal marine
cartography foundation and a bank of computerized marine maps, and
the restoration of the base for the production of national
oceanographic and hydrometeorological equipment"; 

$document =~ s/[\r\n]+/ /g;
$document =~ s/\W/ /g;
$document = lc $document;

for my $term (@termlist) {
	$ref->insert($term, '');
}


%answers = ( 
	'oceanographic information' => 1,
	'oceanographic' => 1,
	'oceanographic data' => 1,
	'oceanographic observations' => 1,
	'oceanographic fleet' => 1,
	'oceanographic survey ships' => 1,
	'oceanographic and hydrometeorological equipment' => 1,

);

%result = $ref->scan( $document );


# %result should be exactly %answers.

print "results contain ", scalar keys %result, " items\n";
print join("\n", keys %result), "\n";

for my $i ( keys %answers ){
	ok(exists $result{$i} );
	print "$i\n";
}




