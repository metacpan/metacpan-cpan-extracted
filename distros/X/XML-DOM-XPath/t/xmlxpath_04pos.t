# $Id: xmlxpath_04pos.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my $first = $t->findvalue( '/AAA/BBB[1]/@id');
ok($first, "first");

my $last = $t->findvalue( '/AAA/BBB[last()]/@id');
ok($last, "last");

__DATA__
<AAA>
<BBB id="first"/>
<BBB/>
<BBB/>
<BBB id="last"/>
</AAA>
