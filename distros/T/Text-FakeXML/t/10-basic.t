#! perl

use strict;
use warnings;
use Test::More tests => 5;

use_ok('Text::FakeXML');

{   open(my $fd, ">", \my $data);
    my $o = Text::FakeXML->new(fh => $fd);
    ok($o, "object");
    is(ref($o), "Text::FakeXML",  "Text::FakeXML");
    $o->xml_elt("foo");
    is($data, "<foo />\n");
}

{   open(my $fd, ">", \my $data);
    my $o = Text::FakeXML->new(fh => $fd);

    $o->xml_elt("foo", "bar");
    is($data, "<foo>bar</foo>\n");
}
