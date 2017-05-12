#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $source =  '<div class="container"><div class="first"></div><div class="second"></div><div class="third"></div></div>';


my $j = j($source);
is $j->find(".second")->replace_with( "<h2>New</h2>" )->as_html, '<div class="second"/>', 'return removed';
is $j->as_html, '<div class="container"><div class="first"></div><h2>New</h2><div class="third"></div></div>', 'replaced one';

is j($source)->find("div")->replace_with( "<h2>New</h2>" )->end->as_html, '<div class="container"><h2>New</h2><h2>New</h2><h2>New</h2></div>', 'replaced multiple';

$j = j($source);
$j->find('.third')->replace_with($j->find('.first'));
is $j->as_html, '<div class="container"><div class="second"></div><div class="first"></div></div>', 'element as content';


$j = j('<div><foo/><bar/><baz/><boom/></div>');
$j->find('bar')->replace_with($j->find('foo, baz, boom'));
is $j->as_html, '<div><foo></foo><baz></baz><boom></boom></div>', 'multiple replacement content';


$j = j('<div><foo/><bar/><baz/><boom/></div>');
$j->find('bar')->replace_with([]);
is j('<div><foo/><bar/><baz/><boom/></div>')->find('bar')->replace_with([])->end->as_html, '<div><foo></foo><baz></baz><boom></boom></div>', 'zero replacement content';


$j = j($source);
$j->find('div')->replace_with(sub { sprintf "<p>was %s %d</p>", $_->tagname, $_[0] });
is $j->as_html, '<div class="container"><p>was div 0</p><p>was div 1</p><p>was div 2</p></div>', 'function as content';

is j($source)->replace_with('<nice />')->document->as_html, "<nice></nice>\n", 'on root node';

$j = j('<foo/><bar/><baz/>');
j($j->get(0))->replace_with('<nice/>');
is $j->document->as_html, "<nice></nice><bar></bar><baz></baz>\n", 'on root node - first child';


$j = j('<foo/><bar/><baz/>');
j($j->get(1))->replace_with('<nice/>');
is $j->document->as_html, "<foo></foo><nice></nice><baz></baz>\n", 'on root node - middle child';


$j = j('<foo/><bar/><baz/>');
j($j->get(2))->replace_with('<nice/>');
is $j->document->as_html, "<foo></foo><bar></bar><nice></nice>\n", 'on root node - last child';


$j = j('<foo/><bar/><baz/><boom/>')->document;
$j->find('bar')->replace_with($j->find('foo, baz, boom'));
is $j->as_html, "<foo></foo><baz></baz><boom></boom>\n", 'on root - multiple replacement';



done_testing;

