
use strict;
use warnings;

package WWW::Shopify::Liquid::Element;

sub verify { return 1; }

sub subelements { qw(); }

sub tokens {
	my ($self) = @_;
	return ($self, map { $self->is_processed($_) ? $_ : $_->tokens } map { ref($_) eq 'ARRAY' ? @$_ : $_ } map { $self->{$_} } $self->subelements);
}

sub operate { return $_[0]; }

sub render_subelement($$$\$) {
	my ($self, $renderer, $hash, $element) = @_;
	my $value;
	if (ref($element) eq 'ARRAY') {
		$value = [];
		eval {
			push(@$value, $self->is_processed($_) ? $_ : ($renderer->state && $renderer->state->{values}->{$_} ? delete $renderer->state->{values}->{$_} : $_->render($renderer, $hash))) for (@$element);
		};
		if (my $exp = $@) {
			$exp->value($element, $value) if blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control::Pause');
			die $exp;
		}
	} else {
		$value = !$self->is_processed($$element) ? ($$element)->render($renderer, $hash) : $$element;
	}
	return $value;
}

sub optimize_subelement($$$\$) {
	my ($self, $optimizer, $hash, $element) = @_;
	my $value;
	if (ref($element) eq 'ARRAY') {
		for my $idx (0..(int(@$element)-1)) {
			my $inner = $element->[$idx];
			$element->[$idx] = !$self->is_processed($inner) ? $inner->optimize($optimizer, $hash) : $inner;
		}
	} else {
		$value = !$self->is_processed($$element) ? ($$element)->optimize($optimizer, $hash) : $$element;
		$$element = $value;
		$element = $$element;
	}
	return $element;
}

sub process_subelement {
	my ($self, $hash, $action, $pipeline, $element) = @_;
	$action .= "_subelement";
	return $self->$action($pipeline, $hash, $element);
}

sub process_subelements { 
	my ($self, $hash, $action, $pipeline) = @_;
	return map { $self->process_subelement($hash, $action, $pipeline, ref($self->{$_}) eq 'ARRAY' ? $self->{$_} : (\$self->{$_})) } $self->subelements;
}

sub render { 
	my $self = shift;
	my $renderer = shift;
	return delete $renderer->state->{values}->{$self} if $renderer->state && exists $renderer->state->{values}->{$self};
	my $return = eval { $self->process(@_, "render", $renderer); };
	my $exp = $@;
	if ($exp) {
		die $exp if (blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control'));
		if ($renderer->{silence_exceptions}) {
		} elsif ($renderer->{wrap_exceptions}) {
			die $exp if blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Renderer::Wrapped');
			die new WWW::Shopify::Liquid::Exception::Renderer::Wrapped($self, $exp);
		} elsif ($renderer->{print_exceptions}) {
			return blessed($exp) && $exp->can('english') ? $exp->english : "$exp";
		} else {
			die $exp;
		}
	}
	return undef if $exp || !$self->is_processed($return) || !defined $return;
	return $return;
}

sub get_parameter {
	my ($self, $name, @arguments) = @_;
	my ($arg) = grep { ref($_) && ref($_) eq 'HASH' && int(keys(%$_)) == 1 && exists $_->{$name} } @arguments;
	return $arg ? $arg->{$name} : undef;
}

sub optimize {
	my $self = shift;
	my $optimizer = shift;
	die new WWW::Shopify::Liquid::Exception($self, "Cannot optimize without a valid optimizer.") 
		unless $optimizer && blessed($optimizer) && $optimizer->isa('WWW::Shopify::Liquid::Optimizer');
	return $self->process(@_, "optimize", $optimizer);
}
sub process { return $_[0]; }
# Determines whether or not the element is part of the strict subset of liquid that Shopify uses.
sub is_strict { return 0; }

use Scalar::Util qw(looks_like_number blessed);

sub is_processed { return WWW::Shopify::Liquid::Pipeline->is_processed($_[1]); }
sub ensure_numerical { 
	return $_[1] if defined $_[1] && looks_like_number($_[1]); 
	return $_[1] if ref($_[1]) && ref($_[1]) eq "DateTime";
	return 0;
}

1;