# $Id: xmlxpath_08name.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 5);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[name() = "BBB"]');
ok(@nodes, 5);

@nodes = $t->findnodes( '//*[starts-with(name(), "B")]');
ok(@nodes, 7);

@nodes = $t->findnodes( '//*[contains(name(), "C")]');
ok(@nodes, 3);

__DATA__
<AAA>
<BCC><BBB/><BBB/><BBB/></BCC>
<DDB><BBB/><BBB/></DDB>
<BEC><CCC/><DBD/></BEC>
</AAA>
