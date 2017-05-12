#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'XML::XPath' }

my $path = XML::XPath->new(ioref => \*DATA);

$path->createNode("/child::foo/child::bar/child::baz");

#
# test unabbreviated syntax
#
$path->setNodeText("/child::foo/child::bar/child::baz/attribute::id", "id1");
my $set = $path->find("/foo/bar/baz");
my @nodelist = $set->get_nodelist;
ok($nodelist[0]->toString =~ /id="id1"/);

#
# test abbreviated syntax
#
$path->setNodeText("/foo/bar/baz/\@id", "id2");
$set = $path->find("/foo/bar/baz");
@nodelist = $set->get_nodelist;
ok($nodelist[0]->toString =~ /id="id2"/);


__DATA__
<?xml version="1.0" ?>
<instanceData>
</instanceData>
