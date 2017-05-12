#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WWW::Search::ValentinskaCZ;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 match\n";
        exit 1;
}
my $match = $ARGV[0];

# Object.
my $obj = WWW::Search->new('ValentinskaCZ');
$obj->maximum_to_retrieve(1);

# Search.
$obj->native_query($match);
while (my $result_hr = $obj->next_result) {
       p $result_hr;
}

# Output like:
# Usage: /tmp/1Ytv23doz5 match

# Output with 'Čapek' argument like:
# \ {
#     author   "Larbaud, Valery; obálka: J. Čapek",
#     image    "http://www.valentinska.cz/image/cache/data/valentinska/book_144061_1-1024x1024.jpg",
#     price    "450Kč",
#     title    "A. O. Barnbooth. Jeho důvěrný deník",
#     url      "http://www.valentinska.cz/144061-a-o-barnbooth-jeho-duverny-denik"
# }