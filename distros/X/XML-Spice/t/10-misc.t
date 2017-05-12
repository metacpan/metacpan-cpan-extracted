#!perl -T

use warnings;
use strict;

use Test::More tests => 8;
use Test::XML;
use XML::Spice;

is_xml(x("foo", "bar", x("what", "lol")),
       x("foo", undef, "bar", x("what", "lol", ""), undef),
        "undefs and empty strings are silently ignored");

is_xml(x("foo", [ "bar", [ x("baz", "quux"), "what" ], "lol" ]),
       x("foo", "bar", x("baz", "quux"), "what", "lol"),
       "array refs get flattened");

is_xml(x("foo", { "bar" => "baz" }, { "what" => "lol" }),
       x("foo", { "bar" => "baz", "what" => "lol" }),
       "attribute hashes get combined");

is_xml(x("foo", { "bar" => "baz" }, { "what" => undef }),
       x("foo", { "bar" => "baz" }),
       "and undef values get ignored");

is_xml(x("foo", { "bar" => "baz" }, { "bar" => undef }),
       x("foo"),
       "or cause a previously-supplied attribute to be removed");


my $count = 0;
sub inc {
    return $count++;
}
my $xml = x("foo", \&inc);
my $x0 = "".$xml;

is_xml(q(<foo>0</foo>),
       $xml,
       "return is cached after initial stringification");
is_xml(q(<foo>0</foo>),
       $xml,
       "and continues to be");

$xml->forget;

is_xml(q(<foo>1</foo>),
       $xml,
       "but gets re-evaluated after forgetting the cached value");
       
