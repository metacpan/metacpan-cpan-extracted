# $Id: xmlxpath_15axisfol_sib.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 6);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/AAA/BBB/following-sibling::*');
ok(@nodes, 2);
ok($nodes[1]->getName, "CCC"); # test document order

@nodes = $t->findnodes( '//CCC/following-sibling::*');
ok(@nodes, 3);
ok($nodes[1]->getName, "FFF");

__DATA__
<AAA>
<BBB><CCC/><DDD/></BBB>
<XXX><DDD><EEE/><DDD/><CCC/><FFF/><FFF><GGG/></FFF></DDD></XXX>
<CCC><DDD/></CCC>
</AAA>
