#! perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::FakeXML');

open(my $fd, ">", \my $data);
my $o = Text::FakeXML->new(indent => "xxx", level => 1, fh => $fd);

$o->xml_elt_open("bar");
$o->xml_elt("foo", "blech");
$o->xml_elt_close("bar");


is($data, "xxx<bar>\nxxxxxx<foo>blech</foo>\nxxx</bar>\n");
