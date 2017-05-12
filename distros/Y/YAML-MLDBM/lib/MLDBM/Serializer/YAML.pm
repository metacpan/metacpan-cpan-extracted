package MLDBM::Serializer::YAML;
$VERSION = '0.10';
@ISA = qw(MLDBM::Serializer);

use strict;
use YAML '0.35';

sub serialize {
    local $YAML::UseVersion = 0;
    local $YAML::CompressSeries = 0;
    local $YAML::Indent = 1;
    local $YAML::SortKeys = 0;
    YAML::Dump($_[1]);
}

sub deserialize {
    YAML::Load($_[1]);
}

1;
