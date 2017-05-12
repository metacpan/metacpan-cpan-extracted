#! perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::FakeXML');

open(my $fd, ">", \my $data);
my $o = Text::FakeXML->new(fh => $fd);

$o->xml_elt_open("foo", id => 456, tag => "");


is($data, "<foo id=\"456\" tag=\"\">\n");
