use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/RSS.pm',
    'lib/XML/RSS/Private/Output/Base.pm',
    'lib/XML/RSS/Private/Output/Roles/ImageDims.pm',
    'lib/XML/RSS/Private/Output/Roles/ModulesElems.pm',
    'lib/XML/RSS/Private/Output/V0_9.pm',
    'lib/XML/RSS/Private/Output/V0_91.pm',
    'lib/XML/RSS/Private/Output/V1_0.pm',
    'lib/XML/RSS/Private/Output/V2_0.pm',
    't/0.9-generate.t',
    't/0.9-parse.t',
    't/0.9-strict.t',
    't/0.91-parse.t',
    't/00-compile.t',
    't/1.0-gen-errors-on-missing-fields.t',
    't/1.0-generate.t',
    't/1.0-parse-2.t',
    't/1.0-parse-exotic.t',
    't/1.0-parse.t',
    't/1.0-to-2.0.t',
    't/2.0-generate.t',
    't/2.0-modules.t',
    't/2.0-parse-2.t',
    't/2.0-parse-cloud.t',
    't/2.0-parse-self.t',
    't/2.0-parse.t',
    't/2.0-permalink.t',
    't/2.0-wo-title.t',
    't/add-item-insert-vs-append.t',
    't/auto_add_modules.t',
    't/charset1.t',
    't/data/1.0/rss1.0.exotic.rdf',
    't/data/1.0/with_content.rdf',
    't/data/2.0/empty-desc.rss',
    't/data/2.0/no-desc.rss',
    't/data/2.0/sf-hs-with-lastBuildDate.rss',
    't/data/2.0/sf-hs-with-pubDate.rss',
    't/data/freshmeat.rdf',
    't/data/merlyn1.rss',
    't/data/rss-permalink.xml',
    't/enclosures-multi.t',
    't/enclosures.t',
    't/enclosures2.t',
    't/encode-output.t',
    't/encoding.t',
    't/generated/placeholder.txt',
    't/guid.t',
    't/load.t',
    't/render-upon-init.t',
    't/rss2-gt-encoding.t',
    't/rss2-nested-custom-tag.t',
    't/save-while-in-taint-mode.t',
    't/subcategory.t',
    't/test-generated-items.t',
    't/version.t',
    't/xml-base.t',
    't/xml-header.t'
);

notabs_ok($_) foreach @files;
done_testing;
