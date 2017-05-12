#!/usr/bin/perl -w
use strict;

use Test;
plan( tests => 15);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

my $node= $t->findvalue( '//attr:node/@attr:findme');
ok( $node, 'someval');

my @nodes;

# Do not set namespace prefixes - uses element context namespaces

@nodes = $t->findnodes('//foo:foo', $t); # should find foobar.com foos
ok( @nodes, 3);

@nodes = $t->findnodes('//goo:foo', $t); # should find no foos
ok( @nodes, 0);

@nodes = $t->findnodes('//foo', $t); # should find default NS foos
ok( @nodes, 2);

$node= $t->findvalue( '//*[@attr:findme]');
ok( $node, 'attr content');

ok( $t->findvalue('//attr:node/@attr:findme'), 'someval');

ok( $t->findvalue( '//toto'), 'tata');
ok( $t->findvalue( '//toto/@att'), 'tutu');

# Set namespace mappings.

$t->set_namespace("foo" => "flubber.example.com");
$t->set_namespace("goo" => "foobar.example.com");

@nodes = $t->findnodes('//foo:foo', $t); # should find flubber.com foos
ok( @nodes, 2);

@nodes = $t->findnodes('//goo:foo', $t); # should find foobar.com foos
ok( @nodes, 3);

@nodes = $t->findnodes('//foo', $t); # should find default NS foos
ok( @nodes, 2);

ok( $t->findvalue('//attr:node/@attr:findme'), 'someval');

ok( $t->findvalue( '//toto'), 'tata');
ok( $t->findvalue( '//toto/@att'), 'tutu');

__DATA__
<xml xmlns:foo="foobar.example.com"
    xmlns="flubber.example.com">
    <foo>
        <bar/>
        <foo/>
    </foo>
    <foo:foo>
        <foo:foo/>
        <foo:bar/>
        <foo:bar/>
        <foo:foo/>
    </foo:foo>
    <attr:node xmlns:attr="attribute.example.com"
        attr:findme="someval">attr content</attr:node >
    <toto att="tutu">tata</toto>
</xml>
