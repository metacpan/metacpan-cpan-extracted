use strict;

use Test::More;
use Text::FrontMatter::YAML;

##############################

my $EMPTY_STR = '';
my $NULL_VAR = undef;
my $UNDEF_VAR;

##############################


my $tfm = Text::FrontMatter::YAML->new( document_string => $EMPTY_STR );

my $yaml = $tfm->frontmatter_text;
is($yaml, undef, 'undef returned for empty string');

my $data = $tfm->data_text;
is($data, undef, 'undef returned for empty string');



$tfm = Text::FrontMatter::YAML->new( document_string => $NULL_VAR );

$yaml = $tfm->frontmatter_text;
is($yaml, undef, 'undef returned for null var');

$data = $tfm->data_text;
is($data, undef, 'undef returned for null var');



$tfm = Text::FrontMatter::YAML->new( document_string => $UNDEF_VAR );

$yaml = $tfm->frontmatter_text;
is($yaml, undef, 'undef returned for undef var');

$data = $tfm->data_text;
is($data, undef, 'undef returned for undef var');



done_testing();
1;
