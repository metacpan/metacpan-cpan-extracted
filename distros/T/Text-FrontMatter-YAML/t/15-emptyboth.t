use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_STRING = <<'END_INPUT';
---
---
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

##############################


my $yaml = $tfm->frontmatter_text;
is($yaml, '', 'empty yaml returned for file with both sections empty');


my $data = $tfm->data_text;
is($data, '', 'empty data returned for file with both sections empty');

done_testing();
1;
