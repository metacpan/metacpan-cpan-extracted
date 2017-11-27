#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Beautifier;
use base 'WWW::Shopify::Liquid::Pipeline';
use Scalar::Util qw(blessed);

sub new { my $package = shift; return bless { tag_enclosing => {}, @_ }, $package; }

sub register_tag {
	my ($self, $tag) = @_;
	$self->{tag_enclosing}->{$tag->name} = $tag->is_free ? 0 : 1;
}

sub beautify {
	my ($self, @tokens) = @_;
	# Essentially run through these and insert spaces whenever there's any whitespace.
	@tokens = grep { blessed($_) && !$_->isa('WWW::Shopify::Liquid::Token::Text::Whitespace') } @tokens;
	my @result;
	my $level = 0;
	my $modification = 0;
	for my $idx (0..$#tokens) {
		my $loop_mod = 0;
		my $token = $tokens[$idx];
		$modification = 0 if $level == 0 && $token->isa('WWW::Shopify::Liquid::Token::Text') && $token->{core} =~ m/\n/s;
		$level-- if $token->isa('WWW::Shopify::Liquid::Token::Tag') && ($token->{tag} =~ m/^end/ && $self->{tag_enclosing}->{do { my $a = $token->{tag}; $a =~ s/^end//; $a }});
		push(@result, WWW::Shopify::Liquid::Token::Text::Whitespace->new(undef, "\n")) if $idx > 0 && (!$tokens[$idx-1]->isa('WWW::Shopify::Liquid::Token::Text') || ($tokens[$idx-1]->{core} !~ m/\n\s*$/ && $tokens[$idx-1]->{core} !~ m/^\s*$/s)) && (!$tokens[$idx]->isa('WWW::Shopify::Liquid::Token::Text') || $tokens[$idx]->{core} !~ m/^\n/);
		$loop_mod = -1 if $token->isa('WWW::Shopify::Liquid::Token::Tag') && ($token->{tag} =~ m/(elsif|else)/);
		push(@result, WWW::Shopify::Liquid::Token::Text::Whitespace->new(undef, join("", ("\t" x ($level+$modification+$loop_mod))))) if $level+$modification+$loop_mod > 0;
		$modification = length($1) if $level == 0 && $token->isa('WWW::Shopify::Liquid::Token::Tag') && $idx > 0 && $tokens[$idx-1]->isa('WWW::Shopify::Liquid::Token::Text') && $tokens[$idx-1]->{core} =~ m/(\t*)$/;
		$level++ if $token->isa('WWW::Shopify::Liquid::Token::Tag') && $self->{tag_enclosing}->{$token->{tag}};
		push(@result, $token);
	}
	return @result;
}

sub compress {
	my ($self, @tokens) = @_;
	# Essentially run through these and insert spaces whenever there's any whitespace.
	@tokens = grep { blessed($_) && !$_->isa('WWW::Shopify::Liquid::Token::Text::Whitespace') } @tokens;
	return @tokens;
}

1;