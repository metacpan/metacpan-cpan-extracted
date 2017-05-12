#!perl -T

use warnings;
use strict;

use Test::More tests => 4;
use Test::XML;
use XML::Spice;

my @tests = (
    "namespaces as attributes",
    qq(<tag xmlns="foo"/>),
        sub {
            x("tag", { xmlns => "foo" });
        },

    "tag prefixes",
    qq(<p:tag xmlns:p="foo"/>),
        sub {
            x("tag", { xmlns => "foo" });
        },

    "attribute prefixes",
    qq(<tag xmlns:a="bar" a:attr="what"/>),
        sub {
            x("tag", { "xmlns:a" => "bar", "a:attr" => "what" });
        },

    "mixed tags and attributes",
    qq(<tag xmlns="foo" xmlns:p="bar"><p:tag/></tag>),
        sub {
            x("tag", { xmlns => "foo", "xmlns:p" => "bar" },
                x("p:tag"));
        },
);

while(@tests > 1) {
    my $desc = shift @tests;
    my $xml = shift @tests;
    my $gen = shift @tests;

    is_xml($xml, &{$gen}(), $desc);
}

diag("test set had leftover items, probable bug in $0") if @tests > 0;
