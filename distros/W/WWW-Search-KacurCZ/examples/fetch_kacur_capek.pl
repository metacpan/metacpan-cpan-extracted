#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use WWW::Search::KacurCZ;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 match\n";
        exit 1;
}
my $match = $ARGV[0];

# Object.
my $obj = WWW::Search->new('KacurCZ');
$obj->maximum_to_retrieve(1);

# Search.
$obj->native_query($match);
while (my $result_hr = $obj->next_result) {
       p $result_hr;
}

# Output:
# Usage: /tmp/1Ytv23doz5 match

# Output with 'Čapek' argument:
# \ {
#     author          "Guillaume Apollinaire",
#     cover_url       "http://kacur.cz/data/USR_001_OBRAZKY/small_196566.JPG",
#     old_price       "2 000 Kč",
#     price           "1 000 Kč",
#     publisher       "Symposion",
#     title           "Kacíř a spol"
#     url             "http://kacur.cz/index.asp?menu=1123&record=140698",
# }