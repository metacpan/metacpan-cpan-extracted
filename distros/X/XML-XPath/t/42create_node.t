use strict;
use warnings;
use Test::More tests => 2;
use XML::XPath;

my $xp1 = new XML::XPath(xml => '<?xml version="1.0" encoding="UTF-8" ?>
<n1:root xmlns:n1="http://n1.zzz.ru" xmlns:n2="http://n2.zzz.ru" xmlns:n3="http://n3.zzz.ru">
<n2:a></n2:a></n1:root>');

$xp1->createNode('/n1:root/n3:b/@aaa');
$xp1->setNodeText('/n1:root/n3:b/@aaa','aaa');
$xp1->createNode('/n1:root/n3:b/@ccc');
$xp1->setNodeText('/n1:root/n3:b/@ccc','ccc');
$xp1->createNode('/n1:root/n3:b');
$xp1->setNodeText('/n1:root/n3:b','xxx');

is($xp1->getNodeAsXML(), qq{<n1:root xmlns:n1="http://n1.zzz.ru" xmlns:n2="http://n2.zzz.ru" xmlns:n3="http://n3.zzz.ru">
<n2:a /><n3:b aaa="aaa" ccc="ccc">xxx</n3:b></n1:root>});

my $xp2 = new XML::XPath(xml => '<?xml version="1.0" encoding="UTF-8" ?>
<root><a></a></root>');

$xp2->createNode('/root/b/@aaa');
$xp2->setNodeText('/root/b/@aaa','aaa');
$xp2->createNode('/root/b/@ccc');
$xp2->setNodeText('/root/b/@ccc','ccc');
$xp2->setNodeText('/root/b','xxx');

is($xp2->getNodeAsXML(), q{<root><a /><b aaa="aaa" ccc="ccc">xxx</b></root>});
