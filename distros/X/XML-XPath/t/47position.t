package main;

use strict;
use warnings;
use Data::Dumper;
use Test::More; # tests => 5;

#use XML::XPath;
use_ok("XML::XPath");

my $path = XML::XPath->new(ioref => \*DATA);

$path->createNode("/child::foo/child::bar/child::baz");
$path->setNodeText("/child::foo/child::bar/child::baz[position()=last()]", "blah");
$path->setNodeText("/child::foo/child::bar/child::baz[position()=last()]/attribute::id", "id0");

$path->createNode("/child::foo/child::bar/child::baz[position()=3]");
$path->setNodeText("/child::foo/child::bar/child::baz[position()=last()]", "blah 2");
$path->setNodeText("/child::foo/child::bar/child::baz[position()=last()]/\@id", "id1");

my $set = $path->find("/foo/bar/baz");
my @nodelist = $set->get_nodelist;

#print Dumper($nodelist[0]);
#print $nodelist[0]->toString, "\n";
#print $nodelist[1]->toString, "\n";
#print $nodelist[2]->toString, "\n";

ok(defined $nodelist[0]);
ok(defined $nodelist[1]);
ok(defined $nodelist[2]);

ok($nodelist[0]->toString =~ /id="id0"/);
ok(defined $nodelist[1] && $nodelist[1]->toString !~ /id/);
ok(defined $nodelist[2] && $nodelist[2]->toString =~ /id="id1"/);

$path->createNode("/child::foo/child::bar/child::baz[5]");
$set = $path->find("/foo/bar/baz");
@nodelist = $set->get_nodelist;

is(scalar(@nodelist), 5);

done_testing();

__DATA__
<?xml version="1.0" ?>
<instanceData>
</instanceData>