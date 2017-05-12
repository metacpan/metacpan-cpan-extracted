# $Id: xmlxpath_05attrib.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 6);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @ids = $t->findnodes( '//BBB[@id]');
ok(@ids, 2);

my @names = $t->findnodes( '//BBB[@name]');
ok(@names, 1);

my @attribs = $t->findnodes( '//BBB[@*]');
ok(@attribs, 3);

my @noattribs = $t->findnodes( '//BBB[not(@*)]');
ok(@noattribs, 1);

__DATA__
<AAA>
<BBB id='b1'/>
<BBB id='b2'/>
<BBB name='bbb'/>
<BBB/>
</AAA>
