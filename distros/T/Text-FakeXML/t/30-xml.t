#! perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::FakeXML');

open(my $fd, ">", \my $data);
my $o = Text::FakeXML->new(fh => $fd);

$o->xml_elt("foo", "b&<>le'ch");


is($data, "<foo>b&amp;&lt;&gt;le&apos;ch</foo>\n");
