# $Id: xmlxpath_16axisprec_sib.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
use Test;
plan( tests => 7);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/AAA/XXX/preceding-sibling::*');
ok(@nodes, 1);
ok($nodes[0]->getName, "BBB");

@nodes = $t->findnodes( '//CCC/preceding-sibling::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '/AAA/CCC/preceding-sibling::*[1]');
ok($nodes[0]->getName, "XXX");

@nodes = $t->findnodes( '/AAA/CCC/preceding-sibling::*[2]');
ok($nodes[0]->getName, "BBB");

__DATA__
<AAA>
    <BBB>
        <CCC/>
        <DDD/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <DDD/>
            <CCC/>
            <FFF/>
            <FFF>
                <GGG/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
