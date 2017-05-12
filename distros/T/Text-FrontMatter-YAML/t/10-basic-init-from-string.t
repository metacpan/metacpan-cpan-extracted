use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_STRING = <<'END_INPUT';
---
layout: frontpage
title: My New Site
---
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

##############################

ok(ref($tfm), 'new returned an object');

my $expected_yaml = <<'END_YAML';
layout: frontpage
title: My New Site
END_YAML

my $yaml = $tfm->frontmatter_text;
ok($yaml, 'frontmatter_text returned text');
is($yaml, $expected_yaml, "frontmatter_text returned correct text for filehandle");


my $expected_data = <<'END_DATA';
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_DATA

my $data = $tfm->data_text;
ok($data, 'data_text returned text');
is($data, $expected_data, "data_text returned correct text for filehandle");

my $full_document = $tfm->document_string;
is($full_document, $INPUT_STRING, "document string round-trips correctly");

done_testing();
1;
