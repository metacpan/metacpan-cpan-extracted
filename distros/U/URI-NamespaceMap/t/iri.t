use Test::More;

use strict;
use URI;
use utf8;

use_ok('URI::Namespace');
use_ok('URI::NamespaceMap');

my $ns = URI::Namespace->new( 'http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#' );
isa_ok( $ns, 'URI::Namespace' );
my $uri	= $ns->as_string;
is( $uri, 'http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#', 'expected IRI string for namespace' );

my $iri	= $ns->iri("納豆");
is($iri->as_string, "http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#納豆", 'expected IRI string');

my $uri	= $ns->uri("納豆");
is($uri->as_string, "http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#%E7%B4%8D%E8%B1%86", 'expected URI encoding of IRI string');

my $map	= URI::NamespaceMap->new();
$map->add_mapping( "食" => $ns );

is_deeply([$map->list_prefixes], ["食"], 'expected unicode namespace prefix in map');
is($map->namespace_uri('食')->as_string, 'http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#', 'expected namespacemap prefix URI string');

done_testing;
