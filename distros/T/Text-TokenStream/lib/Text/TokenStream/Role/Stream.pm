package Text::TokenStream::Role::Stream;

use v5.12;
use Moo::Role;

our $VERSION = '0.04';

use namespace::clean;

requires qw(
    current_position
    err
    fill
    looking_at
    next
    next_of
    peek
    skip_optional
    token_err
);

sub collect_all {
    my ($self) = @_;

    my @ret;
    while (my $tok = $self->next) {
        push @ret, $tok;
    }

    return @ret;
}

sub collect_upto {
    my ($self, $target) = @_;

    my @ret;
    while (my $tok = $self->peek) {
        last if $tok->matches($target);
        push @ret, $self->next;
    }

    return @ret;
}

1;
__END__

=head1 NAME

Text::TokenStream::Role::Stream - role for token-stream classes

=head1 SYNOPSIS

    # In some kind of parser class:
    has stream => (
        is => 'ro',
        handles => 'Text::TokenStream::Role::Stream',
    );

=head1 DESCRIPTION

This role requires and/or implements methods that provide the machinery
for scanning an input string into tokens. It exists as a role so that a
parser class can easily delegate those methods to a stream instance.

See L<Text::TokenStream>.

=head1 PROVIDED METHODS

=head2 C<collect_all>

Takes no arguments. Returns a list of all remaining tokens found in the
input.

=head2 C<collect_upto>

Takes a single argument indicating a token to match, as with
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>.
Scans through the input until it finds a token that matches the argument,
and returns a list of all tokens I<before> the matching one. If no
remaining token in the input matches the argument, behaves as
C<< L</collect_all> >>.

=head1 REQUIRED METHODS

=head2 C<current_position>

Should take no arguments, and return the current input position.

=head2 C<err>

Should take any number of arguments, and throw an exception that reports
an error at the current position.

=head2 C<fill>

Should take a non-negative integer argument, and fill the internal buffer
with that many tokens (or as many as are available), and return true iff
that succeeded.

=head2 C<looking_at>

Should take any number of arguments for
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>,
fill the internal buffer with the right number of elements (returning
false if there aren't enough), and return true if each token is matched by
the corresponding argument.

=head2 C<next>

Should take no elements, and return the next token (or undef if no more
elements are available), advancing the current position.

=head2 C<next_of>

Should take an argument for
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>,
ensure that there is at least one token remaining and that it matches that
argument (reporting an error if not), and return that token, advancing
the current position.

=head2 C<peek>

Should take no elements, and return the next token if one exists, without
advancing the current position.

=head2 C<skip_optional>

Should take an argument for
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>,
and if there's another token that matches it, advance past that token, and
return true; otherwise, it should return false.

=head2 C<token_err>

Should take a token, and any number of arguments, and throw an exception
that reports an error at the position of the token.

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 Aaron Crane.

=head1 LICENCE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.
