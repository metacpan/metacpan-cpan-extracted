# $Id: xmlxpath_26predicate.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @bbb = $t->findnodes( '//a/b[2]');
ok(@bbb, 2);

@bbb = $t->findnodes( '(//a/b)[2]');
ok(@bbb, 1);

__DATA__
<xml>
    <a>
        <b>some 1</b>
        <b>value 1</b>
    </a>
    <a>
        <b>some 2</b>
        <b>value 2</b>
    </a>
</xml>
