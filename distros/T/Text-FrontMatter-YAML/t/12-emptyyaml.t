use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_STRING = <<'END_INPUT';
---
---
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

##############################

my $yaml = $tfm->frontmatter_text;
is($yaml, '', 'empty frontmatter returned for file with no yaml');


my $expected_data = <<'END_DATA';
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_DATA

my $data = $tfm->data_text;
is($data, $expected_data, 'data returned for file with no yaml');

done_testing();
1;
