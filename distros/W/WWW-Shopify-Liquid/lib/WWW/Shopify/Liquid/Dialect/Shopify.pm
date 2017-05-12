#!/usr/bin/perl

use strict;
use warnings;


=head1 NAME

WWW::Shopify::Liquid::Dialect::Shopify - Emulates Shopify-like liquid as much as possible.

=cut

package WWW::Shopify::Liquid::Dialect::Shopify;
use base 'WWW::Shopify::Liquid';

sub load_modules {
	my ($self) = @_;
	$self->register_operator($_) for (grep { $_ !~ m/regex/i } findallmod WWW::Shopify::Liquid::Operator);
	$self->register_filter($_) for (findallmod WWW::Shopify::Liquid::Filter);
	$self->register_tag($_) for (findallmod WWW::Shopify::Liquid::Tag);
}

1;