use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 40;

use XML::Atom::Categories;
use XML::Atom::Category;

my $categories = XML::Atom::Categories->new;
isa_ok $categories, 'XML::Atom::Categories';

$categories->fixed('yes');
is $categories->fixed, 'yes';
$categories->scheme('http://example.org/extra-cats/');
is $categories->scheme, 'http://example.org/extra-cats/';

my $category = XML::Atom::Category->new;
isa_ok $category, 'XML::Atom::Category';
ok $category->elem;

$category->scheme('http://example.org/extra-cats/');
is $category->scheme, 'http://example.org/extra-cats/';
$category->term('joke');
is $category->term, 'joke';

$categories->add_category($category);

$category = $categories->category;
isa_ok $category, 'XML::Atom::Category';
is $category->scheme, 'http://example.org/extra-cats/';
is $category->term, 'joke';

my $category2 = XML::Atom::Category->new;
$category2->scheme('http://example.org/extra-cats/');
$category2->term('serious');
$categories->add_category($category2);

my @category = $categories->category;
is scalar(@category), 2;
isa_ok $category[0], 'XML::Atom::Category';
is $category[0]->scheme, 'http://example.org/extra-cats/';
is $category[0]->term, 'joke';
isa_ok $category[1], 'XML::Atom::Category';
is $category[1]->scheme, 'http://example.org/extra-cats/';
is $category[1]->term, 'serious';

@category = $categories->categories;
is scalar(@category), 2;
isa_ok $category[0], 'XML::Atom::Category';
is $category[0]->scheme, 'http://example.org/extra-cats/';
is $category[0]->term, 'joke';
isa_ok $category[1], 'XML::Atom::Category';
is $category[1]->scheme, 'http://example.org/extra-cats/';
is $category[1]->term, 'serious';

my $xml = $categories->as_xml;
like $xml, qr!^<\?xml version="1.0" encoding="utf-8"\?>!i;

like $xml, qr!<categories xmlns="http://www.w3.org/2007/app"!;
like $xml, qr!fixed="yes"!;
like $xml, qr!scheme="http://example.org/extra-cats/"!;

my $ns_uri = $XML::Atom::Util::NS_MAP{ $XML::Atom::DefaultVersion };
like $xml, qr!<category xmlns="$ns_uri"!;
like $xml, qr!scheme="http://example.org/extra-cats/"!;
like $xml, qr!term="joke"!;
like $xml, qr!term="serious"!;

like $xml, qr!</categories>$!;

my $sample = "t/samples/sample.atomcat";
$categories = XML::Atom::Categories->new($sample);
isa_ok $categories, 'XML::Atom::Categories';

is $categories->fixed, 'yes';
is $categories->scheme, 'http://example.com/cats/big3';

@category = $categories->category;
is scalar(@category), 3;
is $category[0]->term, 'animal';
is $category[1]->term, 'vegetable';
is $category[2]->term, 'mineral';
