# $Id: xmlxpath_12axisdescendant.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
use Test;
plan( tests => 6);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/descendant::*');
ok(@nodes, 11);

@nodes = $t->findnodes( '/AAA/BBB/descendant::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//CCC/descendant::*');
ok(@nodes, 6);

@nodes = $t->findnodes( '//CCC/descendant::DDD');
ok(@nodes, 3);

__DATA__
<AAA>
<BBB><DDD><CCC><DDD/><EEE/></CCC></DDD></BBB>
<CCC><DDD><EEE><DDD><FFF/></DDD></EEE></DDD></CCC>
</AAA>
