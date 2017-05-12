#!/usr/bin/env perl

use Test::More tests => 9;

use strict;
use warnings;

use XML::TreePuller;

my $xml = XML::TreePuller->new(location => 't/data/50-wikiexample.xml');
my @results;
$xml->iterate_at('/wiki/siteinfo/namespaces/namespace' => 'short');

while(defined(my $element = $xml->next)) {
	ok(ref($element) eq 'XML::TreePuller::Element');
	push(@results, $element);
}

ok($results[0]->text eq 'Special');
ok($results[1]->text eq '');
ok($results[2]->text eq 'Talk');

ok($results[0]->attribute('key') == -1);
ok($results[1]->attribute('key') == 0);
ok($results[2]->attribute('key') == 1);