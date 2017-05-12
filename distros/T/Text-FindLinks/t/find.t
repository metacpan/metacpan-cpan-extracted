#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Text::FindLinks 'find_links';

my $text = <<"CUT";
Okay, so here’s a little search engine at www.google.com you
might know. The thing you have just seen was a simple schema-less
URL inside a text. A bit harder is stopping the URL matcher before
punctuation: www.slashdot.org, like this.
CUT

my @expected = qw|
    www.google.com
    www.slashdot.org
    |;

my @found = find_links(text => $text);
is_deeply \@found, \@expected, 'Finding URLs in text';
