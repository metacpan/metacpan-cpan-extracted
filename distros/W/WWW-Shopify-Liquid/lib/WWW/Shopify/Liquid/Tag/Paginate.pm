#!/usr/bin/perl
use strict;
use warnings;

use WWW::Shopify::Liquid::Tag;

package WWW::Shopify::Liquid::Tag::Paginate;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	return '' unless int(@{$self->{arguments}}) > 0;
	my $result = $self->{arguments}->[0]->$action($pipeline, $hash);
	my ($string, $argument);
	if ($result && ref($result) && $result->isa('WWW::Shopify::Liquid::Operator::By')) {
		my $reference = $pipeline->variable_reference($hash, $result->{operands}->[0], 1);
		my $amount = $result->{operands}->[1]->$action($pipeline, $hash);
		$$reference = $self->paginate($hash, $reference, $amount);
		my $result = $self->{contents}->$action($pipeline, $hash);
		return $result;
	} else {
		return $self;
	}
}

sub paginate {
	my ($self, $hash, $variable_reference, $amount) = @_;
	return $self;
}

1;