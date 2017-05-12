use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 16;

use XML::Atom::Collection;
use XML::Atom::Workspace;

my $workspace = XML::Atom::Workspace->new;
isa_ok $workspace, 'XML::Atom::Workspace';

$workspace->title('Foo Bar');
is $workspace->title, 'Foo Bar';

my $collection = XML::Atom::Collection->new;
$collection->href('http://example.org/reilly/main');
$workspace->add_collection($collection);

$collection = $workspace->collection;
isa_ok $collection, 'XML::Atom::Collection';
is $collection->href, 'http://example.org/reilly/main';

my $collection2 = XML::Atom::Collection->new;
$collection2->href('http://example.org/reilly/sub');
$workspace->add_collection($collection2);

my @collection = $workspace->collection;
is scalar(@collection), 2;
is $collection[0]->href, 'http://example.org/reilly/main';
is $collection[1]->href, 'http://example.org/reilly/sub';

@collection = $workspace->collections;
is scalar(@collection), 2;
is $collection[0]->href, 'http://example.org/reilly/main';
is $collection[1]->href, 'http://example.org/reilly/sub';

my $xml = $workspace->as_xml;
my $ns_uri = $XML::Atom::Util::NS_MAP{ $XML::Atom::DefaultVersion };
like $xml, qr!<workspace xmlns="http://www.w3.org/2007/app"(?: xmlns:atom="$ns_uri")?!;
like $xml, qr!<atom:title xmlns:atom="$ns_uri">Foo Bar</atom:title>!;
like $xml, qr!<collection(?: xmlns="http://www.w3.org/2007/app")?!;
like $xml, qr!href="http://example.org/reilly/main"!;
like $xml, qr!href="http://example.org/reilly/sub"!;
like $xml, qr!</workspace>$!;
