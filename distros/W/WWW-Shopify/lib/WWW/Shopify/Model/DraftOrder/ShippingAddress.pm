#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::DraftOrder::ShippingAddress;
use parent 'WWW::Shopify::Model::Address';

sub identifier { qw() }
use Clone qw(clone);

my $fields = undef;
sub fields {
	my $self = shift;
	return $fields if $fields;
	$fields = clone($self->SUPER::fields);
	# We don't have these for some reason.
	delete $fields->{id};
	delete $fields->{default};
	return $fields;
}
sub parent { return 'WWW::Shopify::Model::DraftOrder'; }
sub creation_filled { qw(); }

1;
