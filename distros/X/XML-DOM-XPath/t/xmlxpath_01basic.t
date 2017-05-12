#!/usr/bin/perl -w
use strict;

# $Id: xmlxpath_01basic.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $


use Test;
plan( tests => 5);
use XML::DOM::XPath;
ok(1);
my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 
ok($t);

my @root = $t->findnodes('/AAA');
ok(@root, 1);

my @ccc = $t->findnodes('/AAA/CCC');
ok(@ccc, 3);

my @bbb = $t->findnodes('/AAA/DDD/BBB');
ok(@bbb, 2);

__DATA__
<AAA>
    <BBB/>
    <CCC/>
    <BBB/>
    <CCC/>
    <BBB/>
    <!-- comment -->
    <DDD>
        <BBB/>
        Text
        <BBB/>
    </DDD>
    <CCC/>
</AAA>
