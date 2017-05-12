# $Id: xmlxpath_17axisfollowing.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/AAA/XXX/following::*');
ok(@nodes, 2);

@nodes = $t->findnodes( '//ZZZ/following::*');
ok(@nodes, 12);

__DATA__
<AAA>
<BBB>
    <CCC/>
    <ZZZ>
        <DDD/>
        <DDD>
            <EEE/>
        </DDD>
    </ZZZ>
    <FFF>
        <GGG/>
    </FFF>
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
