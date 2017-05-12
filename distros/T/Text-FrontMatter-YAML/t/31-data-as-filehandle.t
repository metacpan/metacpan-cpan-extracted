use strict;
use Test::More;

use Text::FrontMatter::YAML;

#################################

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

#################################

my $expected_data = <<'END_DATA';
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_DATA

my $fh = $tfm->data_fh;
ok(ref($fh) eq 'GLOB', 'data_fh returned a filehandle');


my $output;
while (defined(my $line = <$fh>)) {
    $output .= $line;
}

is($output, $expected_data, 'filehandle outputs correct data');

my $fh2 = $tfm->data_fh;
my $fh3 = $tfm->data_fh;
isnt($fh2, $fh3, 'data_fh returns a new filehandle on each call');


# test that a generated filehandle does the right thing when there's
# a defined-but-empty data section

$INPUT_STRING = <<'END_INPUT';
---
---
END_INPUT

$tfm = Text::FrontMatter::YAML->new( document_string => $INPUT_STRING );
my $empty_fh = $tfm->data_fh;

$output = '';
ok(eof($empty_fh), 'data_fh immediately EOFs for empty data section');
while (defined(my $line = <$empty_fh>)) {
    $output .= $line;
}
is($output, '', 'data_fh returns no data for empty data section');


done_testing();
