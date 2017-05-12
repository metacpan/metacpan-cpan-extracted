#!/usr/bin/perl

# $Id: 20_publishers.t 40 2006-10-13 04:23:07Z  $

use strict;

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;
use WebService::ISBNDB::API::Publishers;

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

open my $fh, "< $dir/xml/Publishers-publisher_id=oreilly.xml"
   or die "Error opening test XML: $!";
my $body = join('', <$fh>);
close($fh);
my @cats = ($body =~ /Category category_id="(.*?)"/g);

# 12 is the number of predefined tests, while @cats defines the number of
# on-the-fly tests.
plan tests => 12 + @cats;

# Try creating a blank object, just to see what works:
my $publisher = WebService::ISBNDB::API::Publishers->new();
isa_ok($publisher, 'WebService::ISBNDB::API::Publishers');
# Check some defaults
is($publisher->get_protocol, 'REST', 'Default protocol set');
is($publisher->get_api_key, api_key(), 'Default API key');

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# Now use a real value. I like science, because I'm a nerd.
$publisher = WebService::ISBNDB::API::Publishers->new('oreilly');
isa_ok($publisher, 'WebService::ISBNDB::API::Publishers');
is($publisher->get_id, 'oreilly', 'ID');
like($publisher->get_name, '/^o\'reilly$/i', 'Name');
like($publisher->get_location, '/^Sebastopol, CA$/i', 'Location');

# Look at the categories
my $categories = $publisher->get_categories;
is(scalar(@$categories), scalar(@cats),
   'Categories count matches XML');
# Sub-tests for categories
for my $idx (0 .. $#$categories)
{
    is($categories->[$idx]->get_id, $cats[$idx], "ID of category $idx");
}

# Try it from the factory model of the parent class. I won't be repeating the
# category tests-- if the few here pass, I'm satisfied.
$publisher = WebService::ISBNDB::API->new(Publishers => 'oreilly');
isa_ok($publisher, 'WebService::ISBNDB::API::Publishers');
is($publisher->get_id, 'oreilly', 'ID');
like($publisher->get_name, '/^o\'reilly$/i', 'Name');
like($publisher->get_location, '/^Sebastopol, CA$/i', 'Location');

exit;
