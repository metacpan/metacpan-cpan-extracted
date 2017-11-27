# Creates a tag to be used in the system, much like a function call. Should probably disallow recursion in order to preserve the non-looping nature of liquid.

use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::CustomTag;
use parent 'WWW::Shopify::Liquid::Tag';

use Scalar::Util qw(blessed);

sub new {
	my ($package, $line, $tag, $arguments, $contents, $parser) = @_;
	if (!ref($package)) {
		my @arguments = @$arguments;
		my ($free) = grep { $_->{core} eq "free" } @arguments;
		my $self = bless {
			free => $free ? 1 : 0,
			name => $tag,
			contents => $contents
		}, $package;
		die new WWW::Shopify::Liquid::Exception("Cannot register custom tag " . $tag . ", would conflict with buildin tag.") if
			($parser->free_tags->{$tag} && !$parser->free_tags->{$tag}->isa('WWW::Shopify::Liquid::Tag::CustomTag')) ||
			($parser->enclosing_tags->{$tag} && !$parser->enclosing_tags->{$tag}->isa('WWW::Shopify::Liquid::Tag::CustomTag'));
		die new WWW::Shopify::Liquid::Exception("Recursion is disallowed in liquid.") unless int(grep { defined $_ && blessed($_) && $_->isa('WWW::Shopify::Liquid::Tag::CustomTag') && $tag && $_->name && $tag eq $_->name } $contents->tokens) == 0;
		push(@{$parser->{transient_elements}}, $self) if $parser->transient_custom_operations;
		$parser->custom_tags->{$self->name} = $self;
		return $self;
	} else {
		my $self = ref(shift)->SUPER::new(@_);
		$self->{stored_contents} = $self->{contents}->[0]->[0];
		$self->{contents} = $parser->custom_tags->{$self->{core}}->{contents};
		return $self;
	}
}

sub abstract { return !ref($_[0]); }
sub inner_halt_lexing { return 0; }
sub inner_ignore_whitespace { return 0; }
sub is_free { return $_[0]->{free} ? 1 : 0; }
sub is_enclosing { return !$_[0]->{free} ? 1 : 0; }
sub tags { return $_[0]->{name}; }
sub name { return $_[0]->{name}; }
sub ast { return $_[0]->{ast}; }
sub min_arguments { return $_[0]->{min_arguments} || 0; }
sub max_arguments { return $_[0]->{max_arguments}; }

sub optimize {
	return $_[0];
}

use Scalar::Util qw(blessed);
sub render {
	my ($self, $renderer, $hash) = @_;
	my @arguments = map { $_->render($renderer, $hash) } @{$self->{arguments}};
	$hash->{arguments} = \ @arguments;
	my $contents = $self->{stored_contents} && blessed($self->{stored_contents}) ? $self->{stored_contents}->render($renderer, $hash) : undef;
	$hash->{contents} = $contents;
	return $self->{contents}->render($renderer, $hash);
}


package WWW::Shopify::Liquid::Tag::CreateTag;
use parent 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { 2 }
sub max_arguments { 4 }

sub new {	
	my ($package, $line, $tag, $arguments, $contents, $parser) = @_;
	my $self = $package->SUPER::new($line, $tag, $arguments, $contents, $parser);
	$parser->parent->register_tag(WWW::Shopify::Liquid::Tag::CustomTag->new([], $arguments->[0]->{core}, $arguments, @{$contents->[0]}, $parser));
	return $self;
}

sub render { '' }

1;