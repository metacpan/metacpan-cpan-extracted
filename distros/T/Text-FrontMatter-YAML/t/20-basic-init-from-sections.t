use strict;

use Test::More;
use version;

use Text::FrontMatter::YAML;

##############################

my $INPUT_HASH = {
    title => 'The first sentence of the "Gettysburg Address"',
    author => 'Abraham Lincoln',
    date => 18631119
};

my $INPUT_TEXT = <<END_DATA;
Four score and seven years ago our fathers brought forth on this continent
a new nation, conceived in liberty, and dedicated to the proposition that
all men are created equal.
END_DATA

my $tfm = Text::FrontMatter::YAML->new(
    frontmatter_hashref => $INPUT_HASH,
    data_text           => $INPUT_TEXT,
);

##############################

ok(ref($tfm), 'new returned an object');


my $data = $tfm->data_text;
is($data, $INPUT_TEXT, "data_text round-tripped correctly");

my $hash = $tfm->frontmatter_hashref;
is_deeply($hash, $INPUT_HASH, "frontmatter_hashref round-tripped correctly");

##############################

# Here we check that the document is composited correctly. Unfortunately,
# that depends on details of YAML::Tiny's return format. The quoting
# style changed in 1.57. For now, I'm adding version-specific tests to
# check both styles.
#
# YAML::Tiny currently returns hash keys in sorted order. If that ever
# changes I'll have to deal with that too.

my $_expected_doc_old = <<'END_DOCUMENT';
---
author: 'Abraham Lincoln'
date: 18631119
title: "The first sentence of the \"Gettysburg Address\""
---
Four score and seven years ago our fathers brought forth on this continent
a new nation, conceived in liberty, and dedicated to the proposition that
all men are created equal.
END_DOCUMENT

my $_expected_doc_1_57 = <<'END_DOCUMENT';
---
author: 'Abraham Lincoln'
date: 18631119
title: 'The first sentence of the "Gettysburg Address"'
---
Four score and seven years ago our fathers brought forth on this continent
a new nation, conceived in liberty, and dedicated to the proposition that
all men are created equal.
END_DOCUMENT

my $expected_doc;
if (version->parse($YAML::Tiny::VERSION) >= version->parse('1.57')) {
    note("Got YAML::Tiny $YAML::Tiny::VERSION -- new quoting style");
    $expected_doc = $_expected_doc_1_57;
}
else {
    note("Got YAML::Tiny $YAML::Tiny::VERSION -- old quoting style");
    $expected_doc = $_expected_doc_old;
}

my $doc = $tfm->document_string;
is($doc, $expected_doc, "document_string returned joined document");

done_testing();
1;
