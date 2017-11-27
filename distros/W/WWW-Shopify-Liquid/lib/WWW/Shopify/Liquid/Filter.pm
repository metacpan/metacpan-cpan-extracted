#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;
use WWW::Shopify::Liquid::Element;

package WWW::Shopify::Liquid::Filter;
use base 'WWW::Shopify::Liquid::Element';
sub subelements { qw(operand arguments) }

sub new { my $package = shift; my $parser = shift; return bless { line => shift, core => shift, operand => shift, arguments => [@_] }, $package; }
# Determines whether or not this acts as a variable with no arguments, when used in conjucntion to a dot on a variable.
sub transparent { return 0; }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub min_arguments { return 0; }
sub max_arguments { return undef; }
sub verify {
	my ($self) = @_;
	my $count = int(@{$self->{arguments}});
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, [$count, $self->min_arguments, $self->max_arguments]) if
		$count < $self->min_arguments || (defined $self->max_arguments && $count > $self->max_arguments);
}

sub tokens { 
	my ($self) = @_;
	return ($self, map { $self->is_processed($_) ? $_ : $_->tokens } (@{$_[0]->{arguments}}, $_[0]->{operand}));
}

sub process {
	my ($self, $hash, $action, $pipeline) = @_;		
	my ($operand, $arguments) = $self->process_subelements($hash, $action, $pipeline);
	return $self unless $self->is_processed($operand) && int(grep { !$self->is_processed($_) } @$arguments) == 0;
	return $self->operate($hash, $operand, @$arguments);
}

sub stringify {
	return $_[0]->{core};
}

package WWW::Shopify::Liquid::Filter::Unknown;
use base 'WWW::Shopify::Liquid::Filter';

# Don't optimize anything on unknown filters.
sub optimize { return $_[0]; }

1;