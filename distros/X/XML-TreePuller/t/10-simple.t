#!/usr/bin/env perl

use Test::More tests => 9;

use strict;
use warnings;

use XML::TreePuller;

my $puller = XML::TreePuller->new(location => 't/data/10-smallelement.xml');
ok(defined($puller));

$puller->iterate_at('/element' => 'subtree');

my $element = $puller->next;
ok(defined($element) && ref($element) eq 'XML::TreePuller::Element');
ok($element->attribute('one') eq '1');
ok($element->attribute('two') eq '2');

my $foo = $element->get_elements('foo');
my $baz = $element->get_elements('baz');
ok(defined($foo));
ok(defined($baz));

ok($foo->text eq 'bar');
ok($baz->text eq 'biddle');

ok(! defined($puller->next));