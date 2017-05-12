use strict;
use Test::More;

my $url = $ENV{ OPENSEARCH_URL };
unless ( $url ) {
    Test::More->import( skip_all => "OPENSEARCH_URL not set" );
    exit;
}

# XXX This is not testing, but for debugging :)
plan 'no_plan';

use WWW::OpenSearch;

my $engine = WWW::OpenSearch->new( $url );
ok $engine;
ok $engine->description->shortname, $engine->description->shortname;

my $res = $engine->search( "iPod" );
ok $res;
ok $res->feed->title, $res->feed->title;
ok $res->feed->link,  $res->feed->link;
ok $res->pager->entries_per_page,
    "items per page " . $res->pager->entries_per_page;
ok $res->pager->total_entries, "total entries " . $res->pager->total_entries;
