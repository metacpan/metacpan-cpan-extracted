# $Id: xmlxpath_06attrib_val.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 5);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//BBB[@id = "b1"]');
ok(@nodes, 1);

@nodes = $t->findnodes( '//BBB[@name = "bbb"]');
ok(@nodes, 1);

@nodes = $t->findnodes( '//BBB[normalize-space(@name) = "bbb"]');
ok(@nodes, 2);

__DATA__
<AAA>
<BBB id='b1'/>
<BBB name=' bbb '/>
<BBB name='bbb'/>
</AAA>
