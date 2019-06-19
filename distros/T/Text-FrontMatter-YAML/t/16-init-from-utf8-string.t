use strict;

use Test::More;

use Text::FrontMatter::YAML;

use utf8;

##############################

my $INPUT_STRING = <<'END_INPUT';
---
title: “Iñtërnâtiônàlizætiøn”
tagline: “Iñtërnâtiônàlizætiøn”
date: 2013-11-03 12:29
---
It's all about “Iñtërnâtiônàlizætiøn”, innit?
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

##############################

ok(ref($tfm), 'new returned an object');

my $expected_yaml = <<'END_YAML';
title: “Iñtërnâtiônàlizætiøn”
tagline: “Iñtërnâtiônàlizætiøn”
date: 2013-11-03 12:29
END_YAML

my $yaml = $tfm->frontmatter_text;
is($yaml, $expected_yaml, "frontmatter_text returned correct text for filehandle");


my $expected_data = <<'END_DATA';
It's all about “Iñtërnâtiônàlizætiøn”, innit?
END_DATA

my $data = $tfm->data_text;
is($data, $expected_data, "data_text returned correct text for filehandle");

my $full_document = $tfm->document_string;
is($full_document, $INPUT_STRING, "document string round-trips correctly");

done_testing();
1;
