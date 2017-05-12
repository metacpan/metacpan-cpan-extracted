#!/usr/bin/env perl

# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 5 }

use XML::Parser::Wrapper;

my $doc = XML::Parser::Wrapper->new_doc('feed');

my $listing = $doc->add_kid('listing', { });
$listing->add_kid('id', undef, 'blah');

$listing = $doc->add_kid('listing', { foo => 'bar' });
$listing->add_kid('id', undef, 'bleh');
$listing->set_attr(type => 'old_listing');

my $new_doc = XML::Parser::Wrapper->new_doc('listing', { new => 'listing' });
my $id = $new_doc->add_kid('id', undef, 'new_kid');

$doc->add_kid($new_doc);

my $another_listing = $doc->add_kid('listing');
$another_listing->add_kid('id', undef, 'to be deleted');

my $xml = $doc->to_xml({ cdata => 5 });
ok($xml eq '<feed><listing><id>blah</id></listing><listing foo="bar" type="old_listing"><id>bleh</id></listing><listing new="listing"><id><![CDATA[new_kid]]></id></listing><listing><id><![CDATA[to be deleted]]></id></listing></feed>');

$another_listing->remove_kids;

$xml = $doc->to_xml;
ok($xml eq '<feed><listing><id>blah</id></listing><listing foo="bar" type="old_listing"><id>bleh</id></listing><listing new="listing"><id>new_kid</id></listing><listing/></feed>');

$id->set_text('used to be new');
    
$xml = $doc->to_xml;
ok($xml eq '<feed><listing><id>blah</id></listing><listing foo="bar" type="old_listing"><id>bleh</id></listing><listing new="listing"><id>used to be new</id></listing><listing/></feed>');

$id->set_text(undef);
    
$xml = $doc->to_xml;
ok($xml eq '<feed><listing><id>blah</id></listing><listing foo="bar" type="old_listing"><id>bleh</id></listing><listing new="listing"><id/></listing><listing/></feed>');

$doc->remove_kid('listing');
$xml = $doc->to_xml;
ok($xml eq '<feed><listing foo="bar" type="old_listing"><id>bleh</id></listing><listing new="listing"><id/></listing><listing/></feed>');
