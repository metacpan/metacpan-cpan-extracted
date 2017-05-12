use strict;
use warnings;
use Test::More;
use XML::XPath;
use XML::XPath::NodeSet;

my $sample = qq {<xml>  <tag>FOO</tag> <val>10</val> </xml> };
my $xp = XML::XPath->new(xml=>$sample);

ok($xp->find('/xml/tag'));

my $str_nodelist = $xp->find('/xml/tag');
ok($str_nodelist->isa('XML::XPath::NodeSet'));
ok($str_nodelist eq 'FOO');
ok($str_nodelist lt 'foo');
ok($str_nodelist gt 'bar');
ok($str_nodelist le 'FOO');
ok($str_nodelist ge 'FOO');
ok($str_nodelist ne 'BAR');

ok($xp->find('/xml/val'));

my $int_nodelist = $xp->find('/xml/val');
ok($int_nodelist->isa('XML::XPath::NodeSet'));
ok($int_nodelist->size == 1 );
ok($int_nodelist == 10 );
ok($int_nodelist != 20 );
ok($int_nodelist <= 10 );
ok($int_nodelist <  20 );
ok($int_nodelist >= 10 );
ok($int_nodelist >  1  );

done_testing();