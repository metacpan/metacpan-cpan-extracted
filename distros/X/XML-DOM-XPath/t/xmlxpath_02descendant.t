#!/usr/bin/perl -w
use strict; 

# $Id: xmlxpath_02descendant.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 4);

use XML::DOM::XPath;

ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok($t);

my @bbb = $t->findnodes('//BBB');
ok(@bbb, 5);

my @subbbb = $t->findnodes('//DDD/BBB');
ok(@subbbb, 3);

__DATA__
<AAA>
<BBB/>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB/></DDD></CCC>
</AAA>

