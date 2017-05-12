#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WWW::Search::MelcerCZ;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 match\n";
        exit 1;
}
my $match = $ARGV[0];

# Object.
my $obj = WWW::Search->new('MelcerCZ');
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
#     author      "Čapek Karel",
#     cover_url   "http://melcer.cz//img/books/images_big/142829.jpg",
#     info        "obálky a typo Zdenek Seydl, 179 + 156 stran, původní brože 8°, stav velmi dobrý",
#     price       "97.00 Kč",
#     publisher   "Československý spisovatel",
#     title       "Povídky z jedné a druhé kapsy (2 svazky)",
#     url         "http://melcer.cz//index.php?akc=detail&idvyrb=53259&hltex=%C8apek&autor=&nazev=&odroku=&doroku=&vydavatel=",
#     year        1967
# }