#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Case;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub new { 
	my $package = shift;
	my $self = bless {
		line => shift,
		core => shift,
		arguments => shift,
		paths => undef,
		else => undef
	}, $package;
	$self->interpret_inner_tokens(@{$_[0]});
	return $self;
}
sub inner_tags { return qw(when else); }
# Used to tell the parser to discard all whitespace tags whilst at the inner tag level.
sub inner_ignore_whitespace { return 1; }
use List::Util qw(first);
sub interpret_inner_tokens {
	my ($self, @tokens) = @_;
	# Comes in [], [tag, other_path], [tag, other_path], ...
	my $token = shift(@tokens);
	die new WWW::Shopify::Liquid::Exception::Parser($self, "Case statements must start with a when statement.") if int(@$token) > 0;
	for (0..$#tokens) {
		$token = $tokens[$_];
		die new WWW::Shopify::Liquid::Exception::Parser($self, "Requires a constant when using a when statement.") if $token->[0]->tag eq "when" &&
			(!$token->[0]->{arguments}->[0] || (
				ref($token->[0]->{arguments}->[0]) ne "WWW::Shopify::Liquid::Token::String" &&
				ref($token->[0]->{arguments}->[0]) ne "WWW::Shopify::Liquid::Token::Number")
			);
		die new WWW::Shopify::Liquid::Exception::Parser($self, "Else statements can only be used in the last block of a case statement.") if
			$token->[0]->tag eq "else" && $_ < $#tokens;
		if ($token->[0]->tag eq "when") {
			$self->{paths}->{$token->[0]->{arguments}->[0]->{core}} = $token->[1];
		}
		else {
			$self->{else} = $token->[1];
		}
	}
}

sub render {
	my ($self, $renderer, $hash) = @_;
	my $arguments = $self->{arguments}->[0];
	$arguments = $arguments->render($renderer, $hash) if !$self->is_processed($arguments);
	my $path = $self->{paths}->{$arguments} ? $self->{paths}->{$arguments} : $self->{else};
	$path = $path->render($renderer, $hash) if $path && !$self->is_processed($path);
	return defined $path ? $path : '';
}

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	$self->{arguments}->[0] = $self->{arguments}->[0]->optimize($optimizer, $hash) if !$self->is_processed($self->{arguments}->[0]);
	my $key = $self->{arguments}->[0];
	if ($self->is_processed($key)) {
		my $path = exists $self->{paths}->{$key} ? $self->{paths}->{$key} : $self->{else};
		return $self->is_processed($path) ? $path : $path->optimize($optimizer, $hash);
	}
	else {
		$self->{else} = $self->{else}->optimize($optimizer, $hash) if !$self->is_processed($self->{else});
		for (grep { $self->is_processed($self->{paths}->{$_}) } keys(%{$self->{paths}})) {
			$self->{paths}->{$_} = $self->{paths}->{$_}->optimize($optimizer, $hash);
		}
	}
	return $self;
}

1;