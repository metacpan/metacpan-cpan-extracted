# $Id: xmlxpath_22name_select.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[name() = /AAA/SELECT]');
ok(@nodes, 2);
ok($nodes[0]->getName, "BBB");

__DATA__
<AAA>
<SELECT>BBB</SELECT>
<BBB/>
<CCC/>
<DDD>
<BBB/>
</DDD>
</AAA>
