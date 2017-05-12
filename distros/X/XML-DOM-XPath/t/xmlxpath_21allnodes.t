# $Id: xmlxpath_21allnodes.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 11);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//GGG/ancestor::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//GGG/descendant::*');
ok(@nodes, 3);

@nodes = $t->findnodes( '//GGG/following::*');
ok(@nodes, 3);
ok($nodes[0]->getName, "VVV");

@nodes = $t->findnodes( '//GGG/preceding::*');
ok(@nodes, 5);
ok($nodes[0]->getName, "BBB"); # document order, not HHH

@nodes = $t->findnodes( '//GGG/self::*');
ok(@nodes, 1);
ok($nodes[0]->getName, "GGG");

@nodes = $t->findnodes( '//GGG/ancestor::* | //GGG/descendant::* | //GGG/following::* | //GGG/preceding::* | //GGG/self::*');
ok(@nodes, 16);

__DATA__
<AAA>
    <BBB>
        <CCC/>
        <ZZZ/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <FFF>
                <HHH/>
                <GGG> <!-- Watch this node -->
                    <JJJ>
                        <QQQ/>
                    </JJJ>
                    <JJJ/>
                </GGG>
                <VVV/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
