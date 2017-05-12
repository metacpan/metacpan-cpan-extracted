# $Id: xmlxpath_09string_length.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
use Test;
plan( tests => 5);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[string-length(name()) = 3]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[string-length(name()) < 3]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[string-length(name()) > 3]');
ok(@nodes, 3);

__DATA__
<AAA>
<Q/>
<SSSS/>
<BB/>
<CCC/>
<DDDDDDDD/>
<EEEE/>
</AAA>
