use strict;
use Test::More;

use Text::FrontMatter::YAML;

#############################

my $INPUT_STRING = <<'END_INPUT';
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

#############################

my $yaml = $tfm->frontmatter_text;
is($yaml, undef, 'undef frontmatter returned for file with no yaml');

my $data = $tfm->data_text;
is($data, $INPUT_STRING, 'data text returned for file with no yaml');

done_testing();
1;
