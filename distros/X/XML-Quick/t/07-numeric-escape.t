#!perl -T

use warnings;
use strict;

use Test::More;
use Test::XML;
use XML::Quick;

plan tests => 1;

my @data = join '', (map { chr($_) } (0x20 .. 0xd7ff));
is_well_formed_xml(xml({ tag => \@data }));
