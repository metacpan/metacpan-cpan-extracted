use strict;

use Test::More;

use Text::FrontMatter::YAML;

##############################

my $INPUT_STRING = <<'END_INPUT';
---
title: A document
author: Aaron Hall
organization: None
END_INPUT

my $tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );

##############################

my $expected_yaml = <<'END_YAML';
title: A document
author: Aaron Hall
organization: None
END_YAML

my $yaml = $tfm->frontmatter_text;
is($yaml, $expected_yaml, 'yaml returned for file with no data section');


my $data = $tfm->data_text;
is($data, undef, 'undef data returned for file with no data section');

done_testing();
1;
