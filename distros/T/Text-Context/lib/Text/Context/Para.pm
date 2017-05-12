package Text::Context::Para;

=head1 NAME

Text::Context::Para - A paragraph in context

=head1 DESCRIPTION

This is a paragraph being used by Text::Context.

=cut

use strict;
use warnings;

use HTML::Entities;
use Text::Context::EitherSide qw(get_context);

use constant DEFAULT_START_TAG => '<span class="quoted">';
use constant DEFAULT_END_TAG   => "</span>";

=head1 CONSTRUCTOR

=head2 new

	my $para = Text::Context::Para->new($content, $order);

=cut

sub new {
	my ($class, $content, $order) = @_;
	return bless {
		content      => $content,
		scoretable   => [],
		marked_words => [],
		final_score  => 0,
		order        => $order
	}, $class;
}

=head1 METHODS

=head2 best_keywords / slim 

=head2 as_text / marked_up

You can override DEFAULT_START_TAG and DEFAULT_END_TAG. These default to
<span class="quoted"> and </span>

=cut


sub best_keywords {
	my $self = shift;
	return @{ $self->{scoretable}->[-1] || [] };
}

sub slim {
	my ($self, $max_weight) = @_;
	$self->{content} =~ s/^\s+//;
	$self->{content} =~ s/\s+$//;
	return $self if length $self->{content} <= $max_weight;
	my @words = split /\s+/, $self->{content};
	for (reverse(0 .. @words / 2)) {
		my $trial = get_context($_, $self->{content}, @{ $self->{marked_words} });
		if (length $trial < $max_weight) {
			$self->{content} = $trial;
			return $self;
		}
	}
	$self->{content} = join " ... ", @{ $self->{marked_words} };
	return $self;    # Should not happen.
}

sub as_text { return $_[0]->{content} }

sub marked_up {
	my $self      = shift;
	my $start_tag = shift || DEFAULT_START_TAG;
	my $end_tag   = shift || DEFAULT_END_TAG;
	my $content   = $self->as_text;

	# Need to escape entities in here.
	my $re        = join "|", map { qr/\Q$_\E/i } @{ $self->{marked_words} };
	my $re2       = qr/\b($re)\b/i;
	my @fragments = split /$re2/i, $content;
	my $output;
	for my $orig_frag (@fragments) {
		my $frag = encode_entities($orig_frag);
		if ($orig_frag =~ /$re2/i) {
			$frag = $start_tag . $frag . $end_tag;
		}
		$output .= $frag;
	}
	return $output;
}

1;
