#!/usr/bin/perl

# $Id: 10_categories.t 40 2006-10-13 04:23:07Z  $

use strict;

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;
use WebService::ISBNDB::API::Categories;

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

open my $fh, "< $dir/xml/Categories-category_id=science.xml"
   or die "Error opening test XML: $!";
my $body = join('', <$fh>);
close($fh);
my $element_count = ($body =~ /element_count="(\d+)"/)[0];
my @subcats = ($body =~ /SubCategory id="(.*?)"/g);

# 16 is the number of predefined tests, while @subcats defines the number of
# on-the-fly tests.
plan tests => 16 + 3*@subcats;

# Try creating a blank object, just to see what works:
my $category = WebService::ISBNDB::API::Categories->new();
isa_ok($category, 'WebService::ISBNDB::API::Categories');
# Check some defaults
is($category->get_protocol, 'REST', 'Default protocol set');
is($category->get_api_key, api_key(), 'Default API key');

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# Now use a real value. I like science, because I'm a nerd.
$category = WebService::ISBNDB::API::Categories->new('science');
isa_ok($category, 'WebService::ISBNDB::API::Categories');
is($category->get_id, 'science', 'ID');
is($category->get_parent, '', 'Parent ID');
is($category->get_summary, '', 'Summary');
is($category->get_depth, 0, 'Depth');
is($category->get_element_count, $element_count, 'Element count');

# Look at the sub-categories
my $subcategories = $category->get_sub_categories;
is(scalar(@$subcategories), scalar(@subcats),
   'Subcategories count matches XML');
# Three sub-tests per sub-category
for my $idx (0 .. $#$subcategories)
{
    is($subcategories->[$idx]->get_id, $subcats[$idx], "ID of sub-cat $idx");
    is($subcategories->[$idx]->get_parent->get_id, 'science',
       "Sub-cat $idx parent ID");
    is($subcategories->[$idx]->get_depth, 1, "Sub-cat $idx depth");
}

# Try it from the factory model of the parent class. I won't be repeating the
# sub-category tests-- if the few here pass, I'm satisfied.
$category = WebService::ISBNDB::API->new(Categories => 'science');
isa_ok($category, 'WebService::ISBNDB::API::Categories');
is($category->get_id, 'science', 'ID');
is($category->get_parent, '', 'Parent ID');
is($category->get_summary, '', 'Summary');
is($category->get_depth, 0, 'Depth');
is($category->get_element_count, $element_count, 'Element count');

exit;
