#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WWW::Search::AntikvariatJudaicaCZ;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 match\n";
        exit 1;
}
my $match = $ARGV[0];

# Object.
my $obj = WWW::Search->new('AntikvariatJudaicaCZ');
$obj->maximum_to_retrieve(1);

# Search.
$obj->native_query($match);
while (my $result_hr = $obj->next_result) {
       p $result_hr;
}

# Output:
# Usage: /tmp/1Ytv23doz5 match

# Output with 'Čapek' argument like:
# \ {
#     author      "Kolektiv autorů",
#     cover_url   "http://www.antikvariat-judaica.cz/sites/default/files/imagecache/product_list/2012-10/121003_29660_scan10055.jpg",
#     price       "100,00 Kč",
#     title       "J. B. Čapek. Jubilejní sborník 1903 - 2003.",
#     url         "http://antikvariat-judaica.cz//kniha/j-b-capek-jubilejni-sbornik-1903-2003"
# }