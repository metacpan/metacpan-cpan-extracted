#!perl -T

use warnings;
use strict;

use Test::More tests => 16;
use Test::XML;
use XML::Spice;

my @tests = (
    "single tag",
    qq(<tag/>),
        sub {
            x("tag");
        },

    "single tag, single subtag",
    qq(<tag><sub/></tag>),
        sub {
            x("tag",
                x("sub"));
        },

    "multiple subtags, single level",
    qq(<meta><foo/><bar/><baz/></meta>),
        sub {
            x("meta",
                x("foo"),
                x("bar"),
                x("baz"));
        },

    "two levels of subtags",
    qq(<one><two><three/></two><four><five><six/></five></four></one>),
        sub {
            x("one",
                x("two",
                    x("three")),
                x("four",
                    x("five",
                        x("six"))));
        },

    "single tag with attributes",
    qq(<tag foo="bar" baz="quux"/>),
        sub {
            x("tag", { foo => "bar", baz => "quux" });
        },

    "subtag with attributes",
    qq(<tag><subtag foo="bar" baz="quux"/></tag>),
        sub {
            x("tag",
                x("subtag", { foo => "bar", baz => "quux" }));
        },

    "different tags with different attributes",
    qq(<tag level="1"><subtag level="2"/></tag>),
        sub {
            x("tag", { level => 1 },
                x("subtag", { level => 2 }));
        },

    "something arrayish",
    qq(<perlzoo><animal type="camel"/><animal type="llama"/><animal type="dog"/></perlzoo>),
        sub {
            x("perlzoo",
                x("animal", { type => "camel" }),
                x("animal", { type => "llama" }),
                x("animal", { type => "dog" }));
        },

    "single tag with text",
    qq(<tag>value</tag>),
        sub {
            x("tag", "value");
        },

    "subtag with text",
    qq(<tag><sub>value</sub></tag>),
        sub {
            x("tag",
                x("sub", "value"));
        },

    "arrayish text",
    qq(<words><weird>foo</weird><weird>bar</weird><weird>baz</weird></words>),
        sub {
            x("words",
                x("weird", "foo"),
                x("weird", "bar"),
                x("weird", "baz"));
        },

    "more than one text bit",
    qq(<text>together we make a sentence</text>),
        sub {
            x("text", "together we make ", "a sentence");
        },

    "text mixed with subtags",
    qq(<p>this text is <b>bold</b>, while this is <i>italicised</i>.</p>),
        sub {
            x("p",
                "this text is ",
                x("b", "bold"),
                ", while this is ",
                x("i", "italicised"),
                ".");
        },
    
    "escaping",
    qq(<escapes>&amp;&lt;&gt;&quot;</escapes>),
        sub {
            x("escapes", '&<>"');
        },

    "numeric escaping",
    qq(<escapes>).join('', (map { sprintf '&#%d;', $_ } (0x20 .. 0xd7ff))).qq(</escapes>),
        sub {
            x("escapes",  join '', (map { chr($_) } (0x20 .. 0xd7ff)));
        },

    "0 as cdata works",
    qq(<foo>0</foo>),
        sub {
            x("foo", 0);
        },
);

while(@tests > 1) {
    my $desc = shift @tests;
    my $xml = shift @tests;
    my $gen = shift @tests;

    is_xml($xml, &{$gen}(), $desc);
}

diag("test set had leftover items, probable bug in $0") if @tests > 0;
