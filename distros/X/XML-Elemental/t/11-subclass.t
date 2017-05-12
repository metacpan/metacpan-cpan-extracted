#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 10;

use XML::Elemental;

my $objects = {
               Document   => 'T::Document',
               Element    => 'T::Element',
               Characters => 'T::Characters'
};

my $p = XML::Elemental->parser($objects);
open my $fh, 'test.xml';
my $doc = $p->parse_file($fh);
ok($doc, 'parse file return');

ok(ref $doc eq 'T::Document', 'parse_file returns subclass document object');
my $root = $doc->contents->[0];
ok(ref($root) eq 'T::Element', 'root element is T::Element');
my $i = 1;
map {
    ok(ref($_) eq 'T::Element' || ref($_) eq 'T::Characters',
        'object test ' . $i++)
} @{$root->contents};
