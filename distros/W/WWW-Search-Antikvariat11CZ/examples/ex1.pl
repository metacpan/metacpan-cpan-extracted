#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WWW::Search::Antikvariat11CZ;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 match\n";
        exit 1;
}
my $match = $ARGV[0];

# Object.
my $obj = WWW::Search->new('Antikvariat11CZ');
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
#     author          "Karel Čapek",
#     category        "Pohádky / Dětské",
#     detailed_link   "http://antikvariat11.cz/kniha/capek-karel-devatero-pohadek-a-jeste-jedna-jako-privazek-od-josefa-capka-1977-319041",
#     illustrator     "Čapek, Josef",
#     image           "http://antikvariat11.cz/files/thumb_36885.png",
#     pages           "242 s.",
#     price           "55 Kč",
#     stay            "Výborná originální vazba",
#     title           "Devatero pohádek a ještě jedna jako přívažek od Josefa Čapka",
#     year_issued     1977
# }