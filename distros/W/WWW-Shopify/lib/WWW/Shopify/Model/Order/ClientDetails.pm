#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::ClientDetails;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; }
BEGIN { $fields = {
	"accept_language" => new WWW::Shopify::Field::String(),
	"browser_ip" => new WWW::Shopify::Field::String::IPAddress(),
	"session_hash" => new WWW::Shopify::Field::String("[0-9A-F]{32}"),
	"user_agent" => new WWW::Shopify::Field::Text()
}; }
sub singular { return 'client_details'; }
sub plural { return 'client_details'; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }
sub is_single { 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
