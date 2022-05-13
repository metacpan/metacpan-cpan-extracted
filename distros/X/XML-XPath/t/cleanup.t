#!/usr/bin/perl

use strict;
use warnings;

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use XML::XPath;
use XML::XPath::XMLParser;
$XML::XPath::SafeMode = 1;

my $data = join '', <DATA>;
no_leaks_ok{
    my $xp = XML::XPath->new(xml => $data);
    my ($root) = $xp->findnodes('/');
    $xp->cleanup;
}

__DATA__
<Shop id="mod3838" hello="you">
<Cart id="1" crap="crap">
        <Item id="11" crap="crap"/>
</Cart>
<Cart id="2" crap="crap"/>
</Shop>
