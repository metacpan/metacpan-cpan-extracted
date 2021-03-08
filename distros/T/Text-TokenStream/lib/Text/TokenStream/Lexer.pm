package Text::TokenStream::Lexer;

use v5.12;
use Moo;

our $VERSION = '0.03';

use Carp qw(confess);
use List::Util qw(pairmap);
use Text::TokenStream::Types qw(Identifier LexerRule);
use Types::Standard qw(ArrayRef CycleTuple ScalarRef Str);

use namespace::clean;

has rules => (
    is => 'ro',
    isa => CycleTuple[Identifier, LexerRule],
    required => 1,
);

has whitespace => (
    is => 'ro',
    isa => ArrayRef[LexerRule],
    default => sub { [] },
);

has _whitespace_rx => (is => 'lazy', init_arg => undef, builder => sub {
    my ($self) = @_;
    my @whitespace = map ref() ? $_ : quotemeta, @{ $self->whitespace }
        or return qr/(*FAIL)/;
    local $" = '|';
    return qr/^(?:@whitespace)/;
});

has _rules_rx => (is => 'lazy', init_arg => undef, builder => sub {
    my ($self) = @_;
    my @annotated_rules = pairmap { qr/$b(*MARK:$a)/ }
        pairmap { $a => (ref $b ? $b : quotemeta $b) }
        @{ $self->rules }
            or return qr/(*FAIL)/;
    local $" = '|';
    qr/^(?|@annotated_rules)/;
});

sub skip_whitespace {
    my ($self, $str_ref) = @_;
    (ScalarRef[Str])->assert_valid($str_ref);

    my $ret = 0;
    my $whitespace_rx = $self->_whitespace_rx;
    $ret = 1 while $$str_ref =~ s/$whitespace_rx//;

    return $ret;
}

sub next_token {
    my ($self, $str_ref) = @_;
    (ScalarRef[Str])->assert_valid($str_ref);

    my $saw_whitespace = $self->skip_whitespace($str_ref);

    return undef if !length $$str_ref;

    if ($$str_ref !~ $self->_rules_rx) {
        my $text = substr $$str_ref, 0, 30;
        confess("No matching rule; next text is: $text");
    }

    my $type = our $REGMARK;
    my $captures = { %+ };
    my $text = substr($$str_ref, 0, $+[0], '');

    return {
        type => $type,
        captures => $captures,
        text => $text,
        cuddled => 0+!$saw_whitespace,
    };
}

1;
__END__

=head1 NAME

Text::TokenStream::Lexer - reusable lexer for token-stream scanning

=head1 SYNOPSIS

    my $lexer = Text::TokenStream::Lexer->new(
        whitespace => [qr/\s+/, qr/\# [^\n]* (?:\n|\z)/x],
        rules => [
            word => qr/\w+/,
            sym => qr/[^\w\s\#]+/,
        ],
    );

    my $token = $lexer->next_token(\$input_text);

=head1 DESCRIPTION

A lexer instance is constructed by specifying regexes that match
individual parts of the input text. Each regex is associated with
a token type that will be used to distinguish the tokens found.
The regexes are tried in the order they're given in the
C<< L</rules> >> attribute; this means, for example, that you can
have a C<keyword> rule that matches any of a list of specified
keywords, followed by an C<identifier> rule that matches arbitrary
identifiers, even if keywords have the same syntax as identifiers.

(In actual fact, the regexes are preprocessed into a form that the
regex engine can handle more easily, and only one regex match
operation is performed to extract each token. This should be
completely transparent to the caller.)

A lexer will attempt to skip whitespace before scanning each token;
to do that, it uses a separate set of regexes, in the
C<< L</whitespace> >> attribute.

=head1 CONSTRUCTOR

This class uses L<Moo>, and inherits the standard C<< L<new|Moo/new> >>
constructor.

=head1 ATTRIBUTES

=head2 C<rules>

Required; read-only. Array ref of (identifier, rule) pairs: each
rule is a regex (or a literal string), that will be matched at the
current position in the input, and the preceding
L<identifier|Text::TokenStream::Types/Identifier> will be used as the
I<type> of the token, if this rule matches.

If a rule regex has any named captures, the contents of those captures
will be preserved in the value returned by C<< L</next_token> >>.

The regexes will be implicitly anchored to the next match position in
the string being examined, so you should not add any initial anchor.

It is the caller's responsibility to ensure that the rules match every
possible input.

=head2 C<whitespace>

Read-only; defaults to empty array ref. Array ref of rule pairs, where each
rule is a regex (or literal string), that will be treated as whitespace.
It will typically be a good idea to include comments (if needed in your
language) in this attribute.

The regexes will be implicitly anchored to the next match position in
the string being examined, so you should not add any initial anchor.

=head1 OTHER METHODS

=head2 C<next_token>

Takes one argument, which is a reference to a string. First attempts to
C<< L</skip_whitespace> >> on the referenced string, and returns C<undef>
if the string is empty after any whitespace. Then attempts to match each
of the C<< L</rules> >> against the remaining part of the string. If no
rule matches, throws an exception. Otherwise, returns a hashref containing
the following elements:

=over 4

=item C<type>

The identifier corresponding to the rule that matched

=item C<text>

The text matched by the regex

=item C<cuddled>

A boolean value, true iff the token was not preceded by whitespace

=item C<captures>

A hashref of any named captures matched by the regex

=back

=head2 C<skip_whitespace>

Takes one argument, which is a reference to a string. If none of the
C<< L</whitespace> >> patterns match at the start of the referenced
string, returns false. Otherwise, removes as many leading whitespace
sequences as it can from the beginning of the referenced string, and
returns true.

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 Aaron Crane.

=head1 LICENCE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.
