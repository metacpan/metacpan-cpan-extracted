#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::FulfillmentOrder::Destination;
use parent 'WWW::Shopify::Model::Address';

use Clone qw(clone);

my $fields = undef;
sub fields {
	my $self = shift;
	return $fields if $fields;
	$fields = clone($self->SUPER::fields);
	return $fields;
}
sub parent { return 'WWW::Shopify::Model::Order::FulfillmentOrder'; }

1;
