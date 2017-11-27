#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Debugger::Breakpoint;

sub new {
	my ($package) = shift;
	my $hash = shift;
	$hash = {} unless $hash;
	return bless {
		%$hash
	}, $package;
}

sub line { return $_[0]->{line}; }
sub file { return $_[0]->{file}; }


# Provides a low-level debugging interface to liquid.

package WWW::Shopify::Liquid::Debugger;

sub new { return bless { 
	renderer => $_[1],
	breakpoints => [],
	
	break_line => undef,
	current_line => undef
}, $_[0]; }

use Scalar::Util qw(blessed reftype weaken);
use List::MoreUtils qw(uniq);

my @active_debuggers = ();
my $hooked_packages = {};

sub dump {
	my ($self, $item, $level) = @_;
	$level = 0 unless $level;
	my $tab = "\t";
	my $tabs = join("", ($tab x $level));
	my $accumulator = '';
	if (reftype($item)) {
		if (reftype($item) eq 'HASH') {
			if (blessed($item)) {
				$accumulator .= do { my $a = ref($item); $a =~ s/WWW::Shopify::Liquid::(Tag|Token|Operator):://; uc($a) } . "\n";
			} else {
				$accumulator .= $tabs . ref($item) . "\n";
			}
			
			my @keys = grep { $_ ne "line" } keys(%$item);
			if (int(@keys) > 1) {
				for (sort(@keys)) {
					$accumulator.= "$tabs$tab" . $self->dump($item->{$_}, $level+1);
				}
			} elsif (int(@keys) > 0) {
				$accumulator.= "$tabs$tab" . $self->dump($item->{$keys[0]}, $level+1);
			}
			
		} elsif (reftype($item) eq 'ARRAY') {
			$accumulator .= "\n";
			$accumulator .= "$tabs$tab" . $self->dump($_, $level+1) for (grep { defined $_ } @$item);
			$accumulator .= "$tabs\n";
		}
	} else {
		return "null" unless defined $item;
		return "'" . $item . "'\n";
	}
	return $accumulator;
}

sub add_breakpoint {
	my ($self, $context, $line) = @_;
	push(@{$self->{breakpoints}}, WWW::Shopify::Liquid::Debugger::Breakpoint->new({ line => $line, file => $context }));
}

sub remove_breakpoint {
	my ($self, $context, $line) = @_;
	$self->{breakpoints} = [grep { $_->line != $line || $_->file ne $context } @{$self->{breakpoints}}];
	
}


sub render {
	my ($self, $hash, $ast) = @_;
	my $debugger = $self;
	# Only breakpoint on tags.
	my @tags = grep { $_->isa('WWW::Shopify::Liquid::Tag') } $ast->tokens;
	# For every tag in here, modify the in-memory package, such that when render is called, before we call render, we call our new breakpoint method.
	for (uniq(grep { !$hooked_packages->{$_} } map { ref($_) } @tags)) {
		no strict 'refs';
		no warnings 'redefine';
		no warnings 'closure';
		
		my $qualified = $_ . "::render";
		my $original = *{$qualified}{CODE};
		$hooked_packages->{$_} = 1;
		if ($original) {
			eval ("package $_;
			sub render {
				WWW::Shopify::Liquid::Debugger->package_step(\$_[0]);
				\$original->(\@_);
			}");
			if (my $exp = $@) {
				die $exp;
			}
		} else {
			eval ("package $_;
			sub render {
				WWW::Shopify::Liquid::Debugger->package_step(\$_[0]);
				shift->SUPER::render(\@_);
			}");
		}
	}
	push(@active_debuggers, $self);
	my @results = $self->{renderer}->render($hash, $ast);
	@active_debuggers = grep { $_ != $self } @active_debuggers;
	return @results if wantarray;
	return $results[0];
	
}

sub package_step {
	my ($self, $element) = @_;
	$_->step($element) for (@active_debuggers);
}


sub step {
	my ($self, $element) = @_;
	$self->{current_line} = $element->{line};
	if (int(grep { $element->{line} && $element->{line}->[3] && $_->file eq $element->{line}->[3] && $element->{line}->[0] == $_->line } @{$self->{breakpoints}}) > 0) {
		$self->break($element);
	}
	if ($self->{break_line} && $element->{line} && $element->{line} >= $self->{break_line}) {
		$self->{break_line} = undef;
		$self->break($element);
	}
}

sub continue {
	my ($self) = @_;
}


sub next_line {
	my ($self) = @_;
	$self->{break_line} = $self->{current_line}+1;
	$self->continue;
}


sub break {
	my ($self) = @_;
}

sub variable {
	my ($self) = @_;
	
}


1;