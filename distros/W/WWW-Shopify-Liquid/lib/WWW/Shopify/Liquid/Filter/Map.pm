#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Map;
use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { return 1; }
sub max_arguments { return 1; }


sub render {
	my ($self, $renderer, $hash) = @_;	
	my $operand = !$self->is_processed($self->{operand}) ? $self->{operand}->render($renderer, $hash) : $self->{operand};
	my @results = map { $self->{arguments}->[0]->render($renderer, { %$hash, op => $_ }) } (ref($operand) ? @$operand : $operand);
	return [@results];
}

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	$self->{operand} = $self->{operand}->optimize($optimizer, $hash) unless $self->is_processed($self->{operand});
	return $self;
}

1;