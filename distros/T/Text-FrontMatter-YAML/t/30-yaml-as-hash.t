use Test::More;

use Text::FrontMatter::YAML;

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

my $expected_yaml = {
    layout => 'frontpage',
    title  => 'My New Site',
};

my $gotyaml = $tfm->frontmatter_hashref;
is_deeply($gotyaml, $expected_yaml,
    "frontmatter_hashref returned correct hash");

done_testing();
