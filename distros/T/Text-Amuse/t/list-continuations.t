#!perl

use strict;
use warnings;
use File::Spec::Functions qw/catfile/;
use Text::Amuse::Document;
use Text::Amuse::Element;
use Data::Dumper;
use Test::More tests => 19;

my $doc = Text::Amuse::Document->new(file => catfile(qw/t testfiles enumerations.muse/));

ok $doc->_list_index_map;
is $doc->_list_index_map->{'a'}, 1;
is $doc->_list_index_map->{'i'}, 1;
is $doc->_list_index_map->{'v'}, 5;
is $doc->_list_index_map->{'x'}, 10;
is $doc->_list_index_map->{'l'}, 50;
is $doc->_list_index_map->{'A'}, 1;
is $doc->_list_index_map->{'I'}, 1;
is $doc->_list_index_map->{'V'}, 5;
is $doc->_list_index_map->{'X'}, 10;
is $doc->_list_index_map->{'L'}, 50;
is $doc->_get_start_list_index('A'), 1;
is $doc->_get_start_list_index('a'), 1;
is $doc->_get_start_list_index('L'), 50;
is $doc->_get_start_list_index('LLL'), 0;
is $doc->_get_start_list_index('iiii'), 0;

my $el = Text::Amuse::Element->new($doc->_parse_string(" d. test\n"));
is $el->start_list_index, 4;
$el->start_list_index(10);
is $el->start_list_index, 10;
ok(scalar($doc->elements));

