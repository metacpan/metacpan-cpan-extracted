#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'XML::XPath' }

my $xp = XML::XPath->new(ioref => *DATA);
isa_ok($xp, 'XML::XPath');

my $text;
$text = $xp->getNodeText('//BBB[@id = "b1"]');
ok((defined $text), "text is defined for id that exists");
is($text, 'Foo');

$text = $xp->getNodeText('//BBB[@id = "b2"]');
ok((defined $text && ($text eq '')), "text is defined as '' (empty string) for id that does not exist");

__DATA__
<AAA>
<BBB id='b1'>Foo</BBB>
</AAA>
