# Creates a tag to be used in the system, much like a function call. Should probably disallow recursion in order to preserve the non-looping nature of liquid.

use strict;
use warnings;



package WWW::Shopify::Liquid::Filter::CustomFilter;
use parent 'WWW::Shopify::Liquid::Filter';

sub new {
	my ($package, $parser, $line, $core, $operand, @arguments) = @_;
	if (!ref($package)) {
		my $self = bless {
			name => $core,
			contents => $arguments[0]
		}, $package;
		die new WWW::Shopify::Liquid::Exception("Cannot register custom filter " . $core . ", would conflict with buildin filter.") if
			$parser->filters->{$core} && !$parser->filters->{$core}->isa('WWW::Shopify::Liquid::Filter::CustomFilter');
		die new WWW::Shopify::Liquid::Exception("Recursion is disallowed in liquid.") unless int(grep { $_->isa('WWW::Shopify::Liquid::Filter::CustomFilter') && $_->name && $core eq $_->name } $arguments[0]->tokens) == 0;
		$parser->custom_filters->{$self->name} = $self;
		push(@{$parser->{transient_elements}}, $self) if $parser->transient_custom_operations;
		return $self;
	} else {
		my $self = ref(shift)->SUPER::new(@_);
		$self->{contents} = $parser->custom_filters->{$self->{core}}->{contents};
		return $self;
	}
}

sub abstract { return !ref($_[0]); }
sub tags { return $_[0]->{name}; }
sub name { return $_[0]->{name}; }
sub min_arguments { return $_[0]->{min_arguments} || 0; }
sub max_arguments { return $_[0]->{max_arguments}; }

# No optimization permitted for now.
sub optimize {
	return $_[0];
}

sub render {
	my ($self, $renderer, $hash) = @_;	
	my $operand = !$self->is_processed($self->{operand}) ? $self->{operand}->render($renderer, $hash) : $self->{operand};
	my @arguments = map { !$self->is_processed($_) ? $_->render($renderer, $hash) : $_ } @{$self->{arguments}};
	my $contents = $self->{contents};
	$hash->{arguments} = \@arguments;
	$hash->{operand} = $operand;
	$contents->render($renderer, $hash);
	if ($renderer->{return_value}) {
		my $value = delete $renderer->{return_value};
		return $value;
	}
	return undef;
}

package WWW::Shopify::Liquid::Tag::CreateFilter;
use parent 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { 2 }
sub max_arguments { 4 }

sub new {	
	my ($package, $line, $tag, $arguments, $contents, $parser) = @_;
	my $self = $package->SUPER::new($line, $tag, $arguments, $contents, $parser);
	$parser->parent->register_filter(WWW::Shopify::Liquid::Filter::CustomFilter->new($parser, [], $arguments->[0]->{core}, $arguments, @{$contents->[0]}));
	return $self;
}

sub render { '' }

1;