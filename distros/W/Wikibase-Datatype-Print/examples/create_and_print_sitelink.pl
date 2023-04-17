#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Print::Sitelink;
use Wikibase::Datatype::Sitelink;

# Object.
my $obj = Wikibase::Datatype::Sitelink->new(
        'badges' => [
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q123',
                ),
        ],
        'site' => 'cswiki',
        'title' => decode_utf8('Hlavní strana'),
);

# Print.
print encode_utf8(Wikibase::Datatype::Print::Sitelink::print($obj))."\n";

# Output:
# Hlavní strana (cswiki) [Q123]