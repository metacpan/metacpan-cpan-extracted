#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::NoteAttribute;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"value" => new WWW::Shopify::Field::String::Words(1, 10)};
}
sub singular { return "note_attribute"; }
sub identifier { return "name"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
