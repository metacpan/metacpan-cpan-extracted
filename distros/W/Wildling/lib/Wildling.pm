package Wildling;

use strict;
use warnings;

use Wildling::Generator;

our $VERSION = '2.0.7';

# Out-of-range get() / exhausted next() return undef (not the string "false").
# Empty-string combinations are defined and distinct from the sentinel.
sub is_false {
    my ($value) = @_;
    return !defined($value);
}

sub create {
    my ( $patterns, $dictionaries ) = @_;
    return Wildling::Client->new( $patterns, $dictionaries );
}

package Wildling::Client;

use strict;
use warnings;

sub new {
    my ( $class, $patterns, $dictionaries ) = @_;
    $dictionaries ||= {};
    $patterns     ||= [];

    my @generators =
      map { Wildling::Generator->new( $_, $dictionaries ) } @$patterns;
    my $pattern_count = 0;
    $pattern_count += $_->count() for @generators;

    return bless {
        dictionaries   => $dictionaries,
        generators     => \@generators,
        pattern_count  => $pattern_count,
        internal_index => 0,
    }, $class;
}

sub index {
    my ($self) = @_;
    return $self->{internal_index};
}

sub count {
    my ($self) = @_;
    return $self->{pattern_count};
}

sub reset {
    my ($self) = @_;
    $self->{internal_index} = 0;
    return;
}

sub next {
    my ($self) = @_;
    return if $self->{internal_index} == $self->{pattern_count};
    $self->{internal_index} += 1;
    return $self->get( $self->{internal_index} - 1 );
}

sub generators {
    my ($self) = @_;
    return $self->{generators};
}

sub get {
    my ( $self, $index ) = @_;
    return
      if $index > $self->{pattern_count} - 1 || $index < 0;

    my $segment_index = 0;
    for my $generator ( @{ $self->{generators} } ) {
        my $pattern_index = $index - $segment_index;
        return $generator->get($pattern_index)
          if $pattern_index < $generator->count();
        $segment_index += $generator->count();
    }
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Wildling - pattern based string generator

=head1 SYNOPSIS

    use Wildling;

    my $w = Wildling::create(
        ['Year 19##'],
        { colors => [qw(red blue)] },   # optional named dictionaries
    );

    while ( defined( my $value = $w->next() ) ) {
        print "$value\n";
    }

    $w->reset();
    print $w->get(0), "\n";   # first combination
    print $w->count(), "\n";  # total combinations

=head1 DESCRIPTION

Wildling expands patterns with a shared wildcard grammar into every
combination. Useful for wordlists, domain brainstorming, test data, and
similar generation tasks.

This is the Perl port of the multi-language
L<wildling|https://github.com/dotmonk/wildling> project. Pattern syntax and
CLI behaviour match the other ports; see the project docs:

=over 4

=item *

L<https://dotmonk.github.io/wildling/syntax.html> — pattern syntax

=item *

L<https://dotmonk.github.io/wildling/sandbox.html> — browser sandbox

=item *

L<https://github.com/dotmonk/wildling/tree/main/perl> — this port

=back

The CLI ships as F<bin/wildling.pl> (C<wildling.pl> after install).

=head1 FUNCTIONS

=head2 create(\@patterns, \%dictionaries?)

Returns a C<Wildling::Client> that enumerates all combinations of the given
patterns. C<%dictionaries> maps names used by C<%{'name'}> tokens to
arrayrefs of words. Omit or pass C<undef> for no dictionaries.

=head2 is_false($value)

True when C<$value> is C<undef> — the sentinel for exhausted C<next()> /
out-of-range C<get()>. Empty string combinations are defined and are
B<not> false in this sense.

=head1 METHODS

These methods are on the object returned by C<create>.

=head2 next()

Next combination, or C<undef> when exhausted.

=head2 get($index)

Combination at C<$index> (0-based), or C<undef> if out of range.

=head2 count()

Total number of combinations.

=head2 reset()

Rewind the C<next()> cursor to the start.

=head2 index()

Current C<next()> cursor position (number of values already yielded).

=head2 generators()

Arrayref of internal per-pattern generators (advanced use).

=head1 SEE ALSO

L<https://dotmonk.github.io/wildling/>,
L<https://metacpan.org/dist/Wildling>

=head1 AUTHOR

Magnus Weinberg E<lt>magnus.weinberg@gmail.comE<gt>

=head1 LICENSE

MIT. See the F<LICENSE> file in the distribution.

=cut
