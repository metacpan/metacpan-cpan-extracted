#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test::More;

BEGIN { use_ok 'XML::LibXML::jQuery' }


isa_ok \&j, 'CODE', 'j() exported';

# parse / as_html
my $source = '<div><h1>foo</h1></div>';
my $j = j($source);
isa_ok $j->{nodes}[0], 'XML::LibXML::Element', 'node';

# ignores implicit <html>
is $j->as_html, $source, 'parsed output is the same as input';
is $j->document->as_html, "$source\n", 'parsed document output is the same as input';

# returns tags from implicit <head>
$source = '<title>head tag</title><div>body tag</div>';
is j($source)->as_html, $source, 'parsers returns tags from implicit <head>';

# keep text and comments
$source = '<title>head tag</title><!-- foo --><div>body tag</div><!-- bar --> some text';
is j($source)->serialize, $source, 'parser keeps text and comments';

# includes DOCTYPE if its not implicit
$source = "<!DOCTYPE html>\n<html><body><header>html5</header></body></html>\n";
is ref j($source)->get(0), 'XML::LibXML::Element';
is j($source)->document->as_html, $source, 'parser keeps DOCTYPE if its not implicit';

# has <html> but no DOCTYPE
$source = "<html><body><header>html5</header></body></html>\n";
is ref j($source)->get(0), 'XML::LibXML::Element';
is j($source)->document->as_html, $source, 'has <html> but no DOCTYPE';

# keep text and comments
$source = "some\n text\n";
is j($source)->serialize, $source, 'text only';

# comment only
$source = "<!-- some comment -->";
is j($source)->serialize, $source, 'comment only';





# get
isa_ok $j->get(0), 'XML::LibXML::Element', 'get()';

# tagname
is $j->tagname, 'div', 'tagname()';

# first / last
is j('<div id="first"></div><div id="second"></div>')->first->as_html, '<div id="first"></div>', 'first';
is j('<div id="first"></div><div id="second"></div>')->last->as_html, '<div id="second"></div>', 'last';

done_testing;



sub debug_parser {
    j('<div />');

    diag "With doctype: ". ref $XML::LibXML::jQuery::PARSER->parse_html_string("<!DOCTYPE html>\n<html><body><header>html5</header></body></html>\n");
    diag "With <html> (no doctype): ". ref $XML::LibXML::jQuery::PARSER->parse_html_string("<html><body><header>html5</header></body></html>\n");
    diag "<title> and text: ". ref $XML::LibXML::jQuery::PARSER->parse_html_string('<title>head tag</title><!-- foo --><div>body tag</div><!-- bar --> some text');
    diag "<div> and text: ". ref $XML::LibXML::jQuery::PARSER->parse_html_string('<div>head tag</div><!-- foo --><div>body tag</div><!-- bar --> some text');
    diag "div>h1: ". ref $XML::LibXML::jQuery::PARSER->parse_html_string('<div><h1>foo</h1></div>');



}























