use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_HASH = {
    Alaska    => "Juneau",
    Delaware  => "Dover",
    Kansas    => "Topeka",
    Wisconsin => "Madison",
};

my $tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => $INPUT_HASH,
);

##############################

my $expected_doc = <<'END_DOCUMENT';
---
Alaska: Juneau
Delaware: Dover
Kansas: Topeka
Wisconsin: Madison
END_DOCUMENT

my $doc = $tfm->document_string;
is($doc, $expected_doc,
    "no data arg produced no data section");



$tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => $INPUT_HASH,
    data_text => undef,
);

$doc = $tfm->document_string;
is($doc, $expected_doc,
    "undef data arg produced no data section");

$tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => $INPUT_HASH,
    data_text           => '',
);

$expected_doc = "$expected_doc---\n";
$doc = $tfm->document_string;
is($doc, $expected_doc,
    "empty data arg produced empty data section");

done_testing;
1;
