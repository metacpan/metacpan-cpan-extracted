#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::And;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('&&', 'and'); }
sub priority { return 3; }
use Scalar::Util qw(blessed);

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	die new WWW::Shopify::Liquid::Exception("Cannot optimize without a valid optimizer.") 
		unless $optimizer && blessed($optimizer) && $optimizer->isa('WWW::Shopify::Liquid::Optimizer');
	my @ops = @{$self->{operands}};
	$ops[$_] = $ops[$_]->optimize($optimizer, $hash) for (grep { !$self->is_processed($ops[$_]) } (0..$#ops));
	
	if (int(grep { !$self->is_processed($_) } @ops) > 0) {
		# This is false, if any of the arguments are false.
		return 0 if (int(grep { $self->is_processed($_) && !$_ } @ops) > 0);
		# All processed arguments, then should be eliminated, because they must be true.
		@ops = grep { !$self->is_processed($_) } @ops;
		return $ops[0] if (int(@ops) == 1);
		$self->{operands} = \@ops;
		return $self;
	}
	$optimizer->security->check_operate($self, $hash, "optimize", @ops);
	return $self->operate($hash, "optimize", @ops);
}

sub operate { return $_[3] && $_[4]; }

1;