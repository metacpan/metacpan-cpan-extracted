#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Globecoordinate;

# Object.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
        'value' => [49.6398383, 18.1484031],
);

# Get globe.
my $globe = $obj->globe;

# Get longitude.
my $longitude = $obj->longitude;

# Get latitude.
my $latitude = $obj->latitude;

# Get precision.
my $precision = $obj->precision;

# Get type.
my $type = $obj->type;

# Get value.
my $value_ar = $obj->value;

# Print out.
print "Globe: $globe\n";
print "Latitude: $latitude\n";
print "Longitude: $longitude\n";
print "Precision: $precision\n";
print "Type: $type\n";
print 'Value: '.(join ', ', @{$value_ar})."\n";

# Output:
# Globe: Q2
# Latitude: 49.6398383
# Longitude: 18.1484031
# Precision: 1e-07
# Type: globecoordinate
# Value: 49.6398383, 18.1484031