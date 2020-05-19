package Text::Amuse::Compile::Indexer::Specification;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef StrMatch HashRef/;
use Data::Dumper;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::Indexer::Specification - Class for LaTeX indexes

=head1 SYNOPSIS

Everything here is pretty much private and used by L<Text::Amuse::Compile::Indexer>

=head1 FUNCTIONS

=head2 explode_line

Tokenize a line, splitting in whitespace, word and non-word componentes.

=head1 ACCESSORS AND METHODS

=over 4

=item index_name

The index code. Must be ASCII, letters only.

=item index_label

The index title. Must be an escaped LaTeX string

=item patterns

The raw patterns, with C<pattern: label> sequence. They are LaTeX
strings.

=item matches

Lazily built, a sorted arrayref with hashrefs with the matching
specification. The pattern is tokenized.

=item total_found

Read-write accessor for counting (used by L<Text::Amuse::Compile::Indexer>)

=back



=cut



has index_name => (is => 'ro',
                   required => 1,
                   isa => StrMatch[qr{\A[a-z]+\z}],
                  );

has index_label => (is => 'ro',
                   required => 1,
                   isa => Str,
                  );

has patterns => (is => 'ro',
                 required => 1,
                 isa => ArrayRef[Str]);

has matches => (is => 'lazy', isa => ArrayRef[HashRef]);

has total_found => (is => 'rw', default => sub { 0 });

sub _build_matches {
    my $self = shift;
    my @patterns = @{$self->patterns};
    my @pairs;
    foreach my $str (@patterns) {
        my ($match, $label) = split(/\s*:\s*/, $str, 2);
        # default to label
        $label ||= $match;
        push @pairs, {
                      match => $match,
                      tokens => [ explode_line($match) ],
                      label => $label,
                     };
    }
    return [ sort { @{$b->{tokens}} <=> @{$a->{tokens}} or $a->{match} cmp $b->{match} } @pairs ];
}

sub explode_line {
    my $l = shift;
    return grep { length($_) } map { split(/(\s+)/, $_) } split(/\b/, $l);
}

1;
