#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Filter;
use base 'WWW::Shopify::Liquid::Element';

sub new { my $package = shift; return bless { line => shift, core => shift, operand => shift, arguments => [@_] }, $package; }
# Determines whether or not this acts as a variable with no arguments, when used in conjucntion to a dot on a variable.
sub transparent { return 0; }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub min_arguments { return 0; }
sub max_arguments { return undef; }
# Determines whether or not this filter is part of the base Shopify set. By default all filters, unless specified are considered extended.
sub extended { return 1; }
sub verify {
	my ($self) = @_;
	my $count = int(@{$self->{arguments}});
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self) if
		$count < $self->min_arguments || (defined $self->max_arguments && $count > $self->max_arguments);
}

sub tokens { return ($_[0], map { $_->tokens } (@{$_[0]->{arguments}}, $_[0]->{operand}->tokens)); }

sub render {
	my ($self, $renderer, $hash) = @_;	
	my $operand = !$self->is_processed($self->{operand}) ? $self->{operand}->render($renderer, $hash) : $self->{operand};
	my @arguments = map { !$self->is_processed($_) ? $_->render($renderer, $hash) : $_ } @{$self->{arguments}};
	return $self->operate($hash, $operand, @arguments);
}

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	$self->{operand} = $self->{operand}->optimize($optimizer, $hash) unless $self->is_processed($self->{operand});
	for (grep { !$self->is_processed($self->{arguments}->[$_]) } 0..int(@{$self->{arguments}})-1) {
		$self->{arguments}->[$_] = $self->{arguments}->[$_]->optimize($optimizer, $hash);
	}
	return $self if !$self->is_processed($self->{operand}) || int(grep { !$self->is_processed($_) } @{$self->{arguments}}) > 0;
	return $self->operate($hash, $self->{operand}, @{$self->{arguments}});
}


package WWW::Shopify::Liquid::Filter::Unknown;
use base 'WWW::Shopify::Liquid::Filter';

1;