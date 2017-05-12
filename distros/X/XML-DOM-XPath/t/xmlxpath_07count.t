# $Id: xmlxpath_07count.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 7);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[count(BBB) = 2]');
ok($nodes[0]->getName, "DDD");

@nodes = $t->findnodes( '//*[count(*) = 2]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[count(*) = 3]');
ok(@nodes, 2);
ok($nodes[0]->getName, "AAA");
ok($nodes[1]->getName, "CCC");

__DATA__
<AAA>
<CCC><BBB/><BBB/><BBB/></CCC>
<DDD><BBB/><BBB/></DDD>
<EEE><CCC/><DDD/></EEE>
</AAA>
