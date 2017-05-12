#!perl -T

use warnings;
use strict;

use Test::More tests => 5;
use Test::XML;
use XML::Spice;

is_xml(
    qq(<tag>text</tag>),
    x("tag", sub { "text" }),
    "basic text substitution");

is_xml(
    qq(<tag><sub>thunk</sub></tag>),
    x("tag", sub { x("sub", "thunk") }),
    "tree substitution");

my $count = 0;
sub inc {
    return $count++;
}
is_xml(
    qq(<count><val>0</val><val>1</val><val>2</val></count>),
    x("count", map { x("val", \&inc) } (0..2)),
    "lazy evaluation");

sub deeper {
    return x("deeper");
}
is_xml(
    qq(<deep><deeper/></deep>),
    x("deep", sub { return \&deeper; }),
    "nested coderefs");

is_xml(
    qq(<foo bar='baz'/>),
    x("foo", sub { return { "bar" => "baz" }}),
    "coderefs can return attribute hashes");
