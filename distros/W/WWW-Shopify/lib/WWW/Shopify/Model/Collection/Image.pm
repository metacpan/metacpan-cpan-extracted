#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Collection::Image;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(min => '2010-01-01 00:00:00', max => 'now'),
	"src" =>  new WWW::Shopify::Field::String::URL::Shopify(),
	"attachment" => new WWW::Shopify::Field::String::Base64()
}; }
sub get_fields { return qw(created_at src); }
sub creation_minimal { return qw(attachment); }
sub creation_filled { return qw(src created_at); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
