#!/usr/bin/perl

use strict;
use WWW::HtmlUnit::Sweet;
use Test::More tests => 3;

my $agent = WWW::HtmlUnit::Sweet->new(
  url => 'file:t/02_hello_sweet.html'
);

my $result = $agent->asXml;

like $result, qr/<h1>\s*Hello!\s*<\/h1>/, 'Found printed Hello';

# Let's try out the ArrayList auto-convert
my $h1_tags = $agent->getElementsByTagName('h1');
my @x = @{ $h1_tags };
is scalar @x, 1, 'Found one thing in the de-refable array';
isa_ok $h1_tags->[0], 'WWW::HtmlUnit::com::gargoylesoftware::htmlunit::html::HtmlHeading1';

