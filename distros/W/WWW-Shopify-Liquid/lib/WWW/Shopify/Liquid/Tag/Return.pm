#!/usr/bin/perl
use strict;
use warnings;

# This is to be used with the renderer and custom tags. 
package WWW::Shopify::Liquid::Tag::Return;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub min_arguments { return 1; }

sub render {
	my ($self, $renderer, $hash) = @_;
	my $arguments = $self->{arguments}->[0];
	$arguments = $arguments->render($renderer, $hash) if !$self->is_processed($arguments);
	$renderer->{return_value} = $arguments;
	return '';
}

1;