#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 9;

use XML::Elemental;

my $p = XML::Elemental->parser;
open my $fh, 'test.xml';
my $doc = $p->parse_file($fh);
ok($doc, 'parse file return');

ok($doc->contents->[0] == $doc->root_element, 'root_element test');

my $dummy = XML::Elemental::Element->new;
my $root = $doc->root_element;
my $first_born = $root->contents->[0];

ok($root->in_element($doc), 'root element in doc');
ok($first_born->in_element($doc), 'first child of root in doc');
ok($first_born->in_element($root), 'first child is in root');
ok(!$first_born->in_element($dummy), 'first child is not in dummy');

my @ancestors = $first_born->ancestors;
ok(scalar @ancestors == 2, 'ancestor count');
ok($ancestors[0] == $root, 'root is first ancestor');
ok($ancestors[1] == $doc, 'doc is second ancestor');

1;