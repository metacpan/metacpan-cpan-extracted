package Text::Context;

use strict;
use warnings;

use UNIVERSAL::require;

our $VERSION = "3.7";

=head1 NAME

Text::Context - Handle highlighting search result context snippets

=head1 SYNOPSIS

  use Text::Context;

  my $snippet = Text::Context->new($text, @keywords);

  $snippet->keywords("foo", "bar"); # In case you change your mind

  print $snippet->as_html;
  print $snippet->as_text;

=head1 DESCRIPTION

Given a piece of text and some search terms, produces an object
which locates the search terms in the message, extracts a reasonable-length
string containing all the search terms, and optionally dumps the string out
as HTML text with the search terms highlighted in bold.

=head2 new

Creates a new snippet object for holding and formatting context for
search terms.

=cut

sub new {
	my ($class, $text, @keywords) = @_;
	my $self = bless { text => $text, keywords => [] }, $class;
	$self->keywords(@keywords);
	return $self;
}

=head2 keywords

Accessor method to get/set keywords. As the context search is done
case-insensitively, the keywords will be lower-cased.

=cut

sub keywords {
	my ($self, @keywords) = @_;
	$self->{keywords} = [ map { s/\s+/ /g; lc $_ } @keywords ] if @keywords;
	return @{ $self->{keywords} };
}

=begin maintenance

=head2 prepare_text

Turns the text into a set of Paragraph objects, collapsing multiple
spaces in the text and feeding the paragraphs, in order, onto the
C<text_a> member.

=head2 para_class

The Paragraph class to use. This defaults to 'Text::Context::Para'

=end maintenance

=cut

sub para_class { "Text::Context::Para" }

sub prepare_text {
	my $self = shift;
	my @paras = split /\n\n/, $self->{text};
	for (0 .. $#paras) {
		my $x = $paras[$_];
		$x =~ s/\s+/ /g;
		$self->para_class->require;
		push @{ $self->{text_a} }, $self->para_class->new($x, $_);
	}
}

=begin maintenance

=head2 permute_keywords

This is very clever. To determine which keywords "apply" to a given
paragraph, we first produce a set of all possible keyword sets. For
instance, given "a", "b" and "c", we want to produce

    a b c
    a b 
    a   c
    a
      b c
      b
        c

We do this by counting in binary, and then mapping the counts onto
keywords.

=end maintenance

=cut

sub permute_keywords {
	my $self = shift;
	my @permutation;
	for my $bitstring (1 .. (2**@{ $self->{keywords} }) - 1) {
		my @thisperm;
		for my $bitmask (0 .. @{ $self->{keywords} } - 1) {
			push @thisperm, $self->{keywords}[$bitmask]
				if $bitstring & 2**$bitmask;
		}
		push @permutation, \@thisperm;
	}
	return reverse @permutation;
}

=begin maintenance

=head2 score_para / get_appropriate_paras

Now we want to find a "score" for this paragraph, finding the best set
of keywords which "apply" to it. We favour keyword sets which have a
large number of matches (obviously a paragraph is better if it matches
"a" and "c" than if it just matches "a") and with multi-word keywords.
(A paragraph which matches "fresh cheese sandwiches" en bloc is worth
picking out, even if it has no other matches.)

=end maintenance

=cut

sub score_para {
	my ($self, $para) = @_;
	my $content = $para->{content};
	my %matches;

	# Do all the matching of keywords in advance of the boring
	# permutation bit
	for my $word (@{ $self->{keywords} }) {
		my $word_score = 0;
		$word_score += 1 + ($content =~ tr/ / /) if $content =~ /\b\Q$word\E\b/i;
		$matches{$word} = $word_score;
	}

	#XXX : Possible optimization: Give up if there are no matches

	for my $wordset ($self->permute_keywords) {
		my $this_score = 0;
		$this_score += $matches{$_} for @$wordset;
		$para->{scoretable}[$this_score] = $wordset if $this_score > @$wordset;
	}
	$para->{final_score} = $#{ $para->{scoretable} };
}

sub _set_intersection {
	my %union;
	my %isect;
	for (@_) { $union{$_}++ && ($isect{$_} = $_) }
	return values %isect;
}

sub _set_difference {
	my ($a, $b) = @_;
	my %seen;
	@seen{@$b} = ();
	return grep { !exists $seen{$_} } @$a;
}

sub get_appropriate_paras {
	my $self = shift;
	my @app_paras;
	my @keywords = @{ $self->{keywords} };
	my @paras    =
		sort { $b->{final_score} <=> $a->{final_score} } @{ $self->{text_a} };
	for my $para (@paras) {
		my @words = _set_intersection($para->best_keywords, @keywords);
		if (@words) {
			@keywords = _set_difference(\@keywords, \@words);
			$para->{marked_words} = \@words;
			push @app_paras, $para;
			last if !@keywords;
		}
	}
	$self->{app_paras} = [ sort { $a->{order} <=> $b->{order} } @app_paras ];
	return @{ $self->{app_paras} };
}

=head2 paras

    @paras = $self->paras($maxlen)

Return shortened paragraphs to fit together into a snippet of at most
C<$maxlen> characters.

=cut

sub paras {
	my $self = shift;
	my $max_len = shift || 80;
	$self->prepare_text;
	$self->score_para($_) for @{ $self->{text_a} };
	my @paras = $self->get_appropriate_paras;
	return unless @paras;

	# XXX: Algorithm may get better here by considering number of marked
	# up words as weight
	return map { $_->slim($max_len / @paras) } $self->get_appropriate_paras;
}

=head2 as_text

Calculates a "representative" string which contains
the given search terms. If there's lots and lots of context between the
terms, it's replaced with an ellipsis.

=cut

sub as_text {
	return join " ... ", map { $_->as_text } $_[0]->paras;
}

=head2 as_html([ start => "<some tag>", end => "<some end tag>" ])

Markup the snippet as a HTML string using the specified delimiters or
with a default set of delimiters (C<E<lt>span class="quoted"E<gt>>).

=cut

sub as_html {
	my $self = shift;
	my %args = @_;

	my ($start, $end) = @args{qw(start end)};
	return join " ... ", map { $_->marked_up($start, $end) } $self->paras;
}

=head1 AUTHOR

Original author: Simon Cozens

Current maintainer: Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Text-Context@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2005 Kasei

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
