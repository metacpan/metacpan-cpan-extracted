#!/usr/bin/perl

use strict;
use warnings;

# Used in our AST to keep things simple; represents the concatenation of text and other stuff.
# Making this a many-dimensional operator, so that we avoid going too far down the callstack rabbithole.
package WWW::Shopify::Liquid::Operator::Concatenate;
use base 'WWW::Shopify::Liquid::Operator';
use Scalar::Util qw(blessed);
sub symbol { return ('~'); }
sub arity { return "nary"; }
sub priority { return 9; }
sub operate {
	my ($self, $hash, $action, @ops) = @_;
	$ops[$_] = '' for (grep { !defined $ops[$_] } 0..$#ops);
	
	return join("", grep { defined $_ } @ops);
}

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my @ops = @{$self->{operands}};
	for my $idx (0..$#ops) {
		eval {
			$ops[$idx] = $ops[$idx]->$action($pipeline, $hash) unless $self->is_processed($ops[$idx]);
			$self->{operands}->[$idx] = $ops[$idx] if $action eq "optimize";
		};
		if (my $exp = $@) {
			$exp->initial_render(@ops[0..($idx-1)]) if $idx > 0 && blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control');
			if (blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control::Pause')) {
				$exp->register_value($self->{operands}->[$_], $ops[$_]) for (0..($idx-1));
			}
			die $exp;
		}
	}
	
	if (int(grep { !$self->is_processed($_) } @ops) > 0 && $action eq "optimize") {
		my $result;
		my @new_ops;
		for (map { blessed($_) && $_->isa('WWW::Shopify::Liquid::Operator::Concatenate') ? (@{$_->{operands}}) : ($_) } @ops) {
			if ($self->is_processed($_)) {
				$result .= $_ if defined $_;
			} else {
				push(@new_ops, $result);
				$result = '';
				push(@new_ops, $_);
			}
			
		}
		push(@new_ops, $result) if $result ne '';
		$self->{operands} = \@new_ops;
		return $self;
	}
	
	return $self->operate($hash, $action, @ops);
}

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	my $result = $self->SUPER::optimize($optimizer, $hash);
	$self->{operands} = [grep { !$self->is_processed($_) || (defined $_ && $_ ne '') } @{$self->{operands}}];
	return $self->{operands}->[0] if int(@{$self->{operands}}) == 1;
	return $result;
}

sub new { 
	my $package = shift;
	my $line = shift;
	my $core = shift;
	my $self = bless { line => $line, core => $core, operands => undef }, $package;
	$self->{operands} = [@_] if int(@_) >= 1;
	return $self;
}

1;