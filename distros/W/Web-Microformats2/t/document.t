use warnings;
use strict;
use Test::More;

use_ok ("Web::Microformats2");

my $json = <<'END';
{
    "items": [{
        "type": ["h-entry"],
        "properties": {
            "url": ["http://microformats.org/2012/06/25/microformats-org-at-7"],
            "name": ["microformats.org at 7"],
            "content": [{
               "value": "Last week the microformats.org community \n            celebrated its 7th birthday at a gathering hosted by Mozilla in \n            San Francisco and recognized accomplishments, challenges, and \n            opportunities.\n\n        The microformats tagline “humans first, machines second” \n            forms the basis of many of our \n            principles, and \n            in that regard, we’d like to recognize a few people and \n            thank them for their years of volunteer service",
                "html": "\n        <p class=\"p-summary\">Last week the microformats.org community \n            celebrated its 7th birthday at a gathering hosted by Mozilla in \n            San Francisco and recognized accomplishments, challenges, and \n            opportunities.</p>\n\n        <p>The microformats tagline “humans first, machines second” \n            forms the basis of many of our \n            <a href=\"http://microformats.org/wiki/principles\">principles</a>, and \n            in that regard, we’d like to recognize a few people and \n            thank them for their years of volunteer service </p>\n"
            }],
            "summary": ["Last week the microformats.org community \n            celebrated its 7th birthday at a gathering hosted by Mozilla in \n            San Francisco and recognized accomplishments, challenges, and \n            opportunities."],
            "updated": ["2012-06-25 17:08:26"],
            "author": [{
                "value": "Tantek",
                "type": ["h-card"],
                "properties": {
                    "name": ["Tantek"],
                    "url": ["http://tantek.com/"]
                }
            }]
        }
    }],
    "rels": {},
    "rel-urls": {}
}
END

my $doc = Web::Microformats2::Document->new_from_json( $json );

is ($doc->count_top_level_items, 1, "Correct number of top-level items.");

my $item = $doc->get_first( 'h-entry' );
ok ($item->has_type('h-entry'), 'Item has expected type');
ok ($item->has_type('entry'), 'Item has expected type (after dropping an h)');
is ($item->get_property('name'), 'microformats.org at 7',
    'Item has a properpty with a simple value',
);
ok (defined ($item->get_property('content')->{value}),
    'Item has a property with a non-sub-item complex value',
);
ok ($item->get_property('author')->has_type('h-card'),
    'Item has a correctly nested sub-item');

my @types = $item->all_types;
is (scalar @types, 1, 'all_types: Correct number of types.');
is ($types[0], 'h-entry', 'all_types: Correct type value.');
my @short_types = $item->all_types( no_prefixes => 1 );
is ($short_types[0], 'entry', 'all_types: Correct short-type value.');

my $raw_doc = $doc->as_raw_data;
is ($raw_doc->{items}->[0]->{type}->[0], 'h-entry', 'Raw data looks good.');

done_testing();
