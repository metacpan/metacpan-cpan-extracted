#!/usr/bin/perl

use strict;
use warnings;


=head1 NAME

WWW::Shopify::Liquid::Dialect::Shopify - Emulates Shopify-like liquid as much as possible.

=cut

package WWW::Shopify::Liquid::Dialect::Shopify;
use base 'WWW::Shopify::Liquid::Dialect';

use WWW::Shopify::Liquid::Dialect::Web;

sub apply {
	my ($self, $liquid) = @_;
	WWW::Shopify::Liquid::Dialect::Web->apply($liquid);
	$self->SUPER::apply($liquid);
}

1;