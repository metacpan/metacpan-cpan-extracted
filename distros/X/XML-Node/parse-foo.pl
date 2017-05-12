#!/usr/bin/perl -w
use XML::Node;

$xml_node = XML::Node->new();

$xml_node->register( "foo", 'char' => \$variable );
$xml_node->register( "foo>bar", "start" => sub { print "foo-bar[start](relative)\n" } );
$xml_node->register( "foo>bar", "end" => sub { print "foo-bar[end](relative)\n" } );
$xml_node->register( ">foo>bar", "end" => sub { print "foo-bar[end](absolute)\n" } );
$xml_node->register( ">foo:type", "attr" => sub { print "foo-type[attr](absolute)\n" } );
$xml_node->register( "foo:type", "attr" => sub { print "foo-type[attr](relative)\n" } );

my $file = "foo.xml";

print "Processing file [$file]...\n";

open(FOO, $file);
$xml_node->parse(*FOO);
close(FOO);

print "<foo> has content: [$variable]\n";

