#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator;
use base 'WWW::Shopify::Liquid::Element';
sub new { 
	my $package = shift;
	my $self = bless { line => shift, core => shift, operands => undef }, $package;
	$self->{operands} = [@_] if int(@_) >= 1;
	return $self;
}
sub operands { my $self = shift; $self->{operands} = [@_]; return $self->{operands}; }
sub subelements { qw(operands); }

sub arity { return "binary"; }
sub fixness { return "infix"; }

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my ($ops) = $self->process_subelements($hash, $action, $pipeline);
	return $self unless int(grep { !$self->is_processed($_) } @$ops) == 0;
	$pipeline->security->check_operate($self, $hash, $action, @$ops);
	return $self->operate($hash, $action, @$ops);
}
sub priority { return 0; }
# If we require a grouping, it means that it must be wrapped in parentheses, due to how Shopify works. Only relevant for reconversion.
sub requires_grouping { return 0; }

1;