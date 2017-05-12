# $Id: xmlxpath_10pipe.t,v 1.2 2004/07/21 12:21:31 mrodrigu Exp $

use Test;
plan( tests => 6);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//CCC | //BBB');
ok(@nodes, 3);
ok($nodes[0]->getName, "BBB"); # test document order

@nodes = $t->findnodes( '/AAA/EEE | //BBB');
ok(@nodes, 2);

@nodes = $t->findnodes( '/AAA/EEE | //DDD/CCC | /AAA | //BBB');
ok(@nodes, 4);

__DATA__
<AAA>
<BBB/>
<CCC/>
<DDD><CCC/></DDD>
<EEE/>
</AAA>
