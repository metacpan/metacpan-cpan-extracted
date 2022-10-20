#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Mediainfo;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Mediainfo::print($obj))."\n";

# Output:
# Id: M10031710
# Title: File:Douglas adams portrait cropped.jpg
# NS: 6
# Last revision id: 617544224
# Date of modification: 2021-12-30T08:38:29Z
# Label: Portrait of Douglas Adams (en)
# Statements:
#   P180: Q42 (normal)