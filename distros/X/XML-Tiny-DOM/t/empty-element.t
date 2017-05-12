use strict;
$^W=1;

use Test::More tests => 4;

use XML::Tiny::DOM;

my $c = XML::Tiny::DOM->new('t/empty-element.xml');
ok($c->empty eq '', "empty elements return an empty string");
eval { no warnings;''.$c->notempty };
ok($@ =~ /can't stringify/i, "but if a element contains just a element it can't be stringified");
ok($c->textplustag eq 'bar', "text + element stringifies to text");
ok($c->tagplustext eq 'bar', "element + text stringifies to text");
