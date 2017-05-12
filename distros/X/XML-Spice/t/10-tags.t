#!perl -T

use warnings;
use strict;

use Test::More tests => 22;
use Test::XML;
use XML::Spice qw( html body p ul li );
import XML::Spice; # get x() as well

is_xml(html(), x("html"), "same output for 'html'");
is_xml(body(), x("body"), "same output for 'body'");
is_xml(p(),    x("p"),    "same output for 'p'");
is_xml(ul(),   x("ul"),   "same output for 'ul'");
is_xml(li(),   x("li"),   "same output for 'li'");

is_xml(html("foo"), x("html", "foo"), "same output for 'html' with text");
is_xml(body("foo"), x("body", "foo"), "same output for 'body' with text");
is_xml(p("foo"),    x("p", "foo"),    "same output for 'p' with text");
is_xml(ul("foo"),   x("ul", "foo"),   "same output for 'ul' with text");
is_xml(li("foo"),   x("li", "foo"),   "same output for 'li' with text");

my $attrs = { foo => "bar" };
is_xml(html($attrs), x("html", $attrs), "same output for 'html' with attributes");
is_xml(body($attrs), x("body", $attrs), "same output for 'body' with attributes");
is_xml(p($attrs),    x("p", $attrs),    "same output for 'p' with attributes");
is_xml(ul($attrs),   x("ul", $attrs),   "same output for 'ul' with attributes");
is_xml(li($attrs),   x("li", $attrs),   "same output for 'li' with attributes");

is_xml(html($attrs, "foo"),
       x("html", $attrs, "foo"), "same output for 'html' with text and attributes");
is_xml(body($attrs, "foo"),
       x("body", $attrs, "foo"), "same output for 'body' with text and attributes");
is_xml(p($attrs, "foo"),
       x("p", $attrs, "foo"),    "same output for 'p' with text and attributes");
is_xml(ul($attrs, "foo"),
       x("ul", $attrs, "foo"),   "same output for 'ul' with text and attributes");
is_xml(li($attrs, "foo"),
       x("li", $attrs, "foo"),   "same output for 'li' with text and attributes");

is_xml(
    html(
        body(
            p({ class => "yellow" }, "words:",
                ul(
                    li("foo"),
                    li("bar"), 
                    li("baz"))))),
    x("html",
        x("body",
            x("p", { class => "yellow" }, "words:",
                x("ul",
                    x("li", "foo"),
                    x("li", "bar"),
                    x("li", "baz"))))),
    "same output for document");

is_xml(
    html(
        body(
            x("h1", { style => "color: blue;" }, "my life"),
            p("its great"))),
    x("html",
        x("body",
            x("h1", { style => "color: blue;" }, "my life"),
            x("p", "its great"))),
    "same output for document with mixed tag/x calls");
