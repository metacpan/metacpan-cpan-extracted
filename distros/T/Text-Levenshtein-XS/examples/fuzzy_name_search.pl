#
# This file is part of Text-Levenshtein-XS
#
# This software is copyright (c) 2016 by Nick Logan.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use Text::Levenshtein::XS qw/distance/;

my @names = ( 
    'Angela Smarts',
    'Angela Sharron',
    'Andrew North',
    'Andy North',
    'Andy Norths',
    'Ameila Anderson',
);

print "[NAMES]: " . join(', ',@names) . "\n\n";
print "Enter a name to fuzzy search against: ";
my $fuzzy_name = <>;
chomp($fuzzy_name);
print "\n";

my $best_match = "";
my $best_distance;

foreach my $name (@names) {
    my $distance = distance($fuzzy_name,$name);
    print "*$name - $distance\n";

    if( !defined $best_distance || $distance < $best_distance ) {
        $best_match = $name;
        $best_distance = $distance;
    }
}

print "\n\nDamerau-Levenshtein search result: " . $best_match . " with a distance of " . $best_distance . "\n";

1;