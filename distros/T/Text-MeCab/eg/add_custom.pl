#!perl

# Example for adding to the mecab dictionary.
#
# Since this is just a toy example, it is assumed that the words you are
# adding to the dictionary area simply a names of people, and their
# corresponding phonetic representation.
#
#     eg/add_custom.pl 牧大輔 マキダイスケ /path/to/mecab-ipadic-source
#
# You should execute this script as superuser so that $dict->rebuild()
# can properly call 'make install'

use strict;
use warnings;
use utf8;
use blib;
use YAML;
use Path::Class::Dir;
use Path::Class::File;
use Text::MeCab::Dict;
use encoding 'utf-8';

my ($name, $yomi, $dict_source) = @ARGV;

my $dict = Text::MeCab::Dict->new(
    dict_source => $dict_source
);

my %args = (
    surface  => $name,
    original => $name,
    yomi     => $yomi,
    cost     => 3000,
    left_id  => 1291,
    right_id => 1291,
    pos       => '名詞',
    category1 => '固有名詞',
    category2 => '人名',
);
$dict->add(%args);

$dict->write('custom.csv');
$dict->rebuild();