use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_TEXT = <<END_DATA;
Four score and seven years ago our fathers brought forth on this continent
a new nation, conceived in liberty, and dedicated to the proposition that
all men are created equal.
END_DATA

my $tfm = Text::FrontMatter::YAML->new(
    data_text           => $INPUT_TEXT,
);

##############################

my $expected_doc = <<'END_DOCUMENT';
Four score and seven years ago our fathers brought forth on this continent
a new nation, conceived in liberty, and dedicated to the proposition that
all men are created equal.
END_DOCUMENT

my $doc = $tfm->document_string;
is($doc, $expected_doc,
    "no frontmatter arg produced no front matter section");



$tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => undef,
    data_text           => $INPUT_TEXT,
);

$doc = $tfm->document_string;
is($doc, $expected_doc,
    "undef frontmatter arg produced no front matter section");


# When you serialize an empty hashref (as below), YAML parsers will
# return "--- {}" as the complete YAML string. I don't think that's
# useful in this context, and we don't support that as input anyhow.
# Really, that opening triple-dashed line isn't the YAML opening
# marker per the spec, but just a signal that what follows is YAML.
#
# Who knows what the future holds, so I'm leaving this all as
# undefined behavior for now.

# my $expected_empty_yaml = "---\n---\n$INPUT_TEXT";
# 
# $tfm = Text::FrontMatter::YAML->new(
#     frontmatter_hashref => {},
#     data_text           => $INPUT_TEXT,
# );
# 
# $doc = $tfm->document_string;
# is($doc, $expected_empty_yaml, "document_string has... what?");


done_testing();
1;
