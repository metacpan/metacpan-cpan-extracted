package Text::TokenStream;

use v5.12;
use Moo;

our $VERSION = '0.04';

use List::Util qw(max);
use Types::Path::Tiny qw(Path);
use Types::Standard qw(ArrayRef Int Maybe ScalarRef Str);
use Text::TokenStream::Token;
use Text::TokenStream::Types qw(Lexer Position TokenClass);

use namespace::clean;

has input_name => (is => 'ro', isa => Maybe[Path], coerce => 1, default => undef);

has input => (is => 'ro', isa => Str, required => 1);

has lexer => (
    is => 'ro',
    isa => Lexer,
    required => 1,
    handles => { next_lexer_token => 'next_token' },
);

has token_class => (
    is => 'lazy',
    isa => TokenClass,
    builder => sub { 'Text::TokenStream::Token' },
);

has _pending => (is => 'ro', isa => ArrayRef, default => sub { [] });

has _input_ref => (is => 'lazy', isa => ScalarRef[Str], builder => sub {
    my ($self) = @_;
    my $copy = $self->input;
    return \$copy;
});

has current_position => (
    is => 'ro',
    writer => '_set_current_position',
    isa => Position,
    default => 0,
    init_arg => undef,
);

with qw(Text::TokenStream::Role::Stream);

sub next {
    my ($self) = @_;
    $self->fill(1) or return undef;
    my $tok = shift @{ $self->_pending };
    $self->_set_current_position( $tok->position + length($tok->text) );
    return $tok;
}

sub fill {
    my ($self, $n) = @_;

    my $input_ref = $self->_input_ref;
    my $input_len = length($self->input);

    my $pending = $self->_pending;
    while (@$pending < $n) {
        my $tok = $self->next_lexer_token($input_ref) // return 0;
        my $position = $input_len - length($$input_ref) - length($tok->{text});
        push @$pending, $self->create_token(%$tok, position => $position);
    }

    return 1;
}

sub create_token {
    my ($self, %data) = @_;
    return $self->token_class->new(%data);
}

sub peek {
    my ($self) = @_;
    $self->fill(1) or return undef;
    return $self->_pending->[0];
}

sub skip_optional {
    my ($self, $target) = @_;
    my $tok = $self->peek // return 0;
    return 0 if !$tok->matches($target);
    $self->next; # ignore return
    return 1;
}

sub looking_at {
    my ($self, @targets) = @_;

    $self->fill(scalar @targets) or return 0;

    my $pending = $self->_pending;
    for my $i (0 .. $#targets) {
        return 0 if !$pending->[$i]->matches($targets[$i]);
    }

    return 1;
}

sub next_of {
    my ($self, $target, $where) = @_;
    my $tok = $self->peek
        // $self->err(join ' ', "Missing token", grep defined, $where);
    $self->token_err($tok, join ' ', "Unexpected", $tok->type, "token", grep defined, $where)
        if !$tok->matches($target);
    return $self->next;
}

sub _err {
    my ($self, $token, @message) = @_;
    my $position = $token ? $token->position : $self->current_position;
    my $marker = '^' x max(6, map length($_->text), grep defined, $token);
    my $input = $self->input;
    my $prefix = substr $input, 0, $position;
    (my $line_prefix = $prefix) =~ s/^.*\n//s;
    (my $space_prefix = $line_prefix) =~ tr/\t/ /c;
    (my $line_suffix = substr $input, $position) =~ s/\r?\n.*//s;
    my $line_number = 1 + ($prefix =~ tr/\n//);
    my $column_number = 1 + length $line_prefix;
    my $input_name = $self->input_name;
    my $file_line = defined $input_name ? "File $input_name, line" : "Line";
    @message = q[Something's wrong] if !@message;
    my $message = join '', (
        "SORRY! $file_line $line_number, column $column_number: ", @message, "\n",
        $line_prefix, $line_suffix, "\n",
        $space_prefix, $marker, "\n",
    );
    die $message;
}

sub token_err { shift->_err(       @_) }
sub       err { shift->_err(undef, @_) }

1;
__END__

=head1 NAME

Text::TokenStream - lexer to break text up into user-defined tokens

=head1 SYNOPSIS

    my $lexer = Text::TokenStream::Lexer->new(
        whitespace => [qr/\s+/],
        rules => [
            word => qr/\w+/,
            sym => qr/[^\w\s]+/,
        ],
    );

    my $stream = Text::TokenStream->new(
        lexer => $lexer,
        input => "foo *",
    );

    my $tok1 = $stream->next; # --> "word" token containing "foo"
    my $tok2 = $stream->next; # --> "sym" token containing "*"

=head1 DESCRIPTION

This class is part of a collection of classes that act together to I<lex>
(aka I<scan>) an input text into a stream of I<tokens>.

This I<token stream> class provides the stream interface, along with a notion
of the "current position" in the input text, and position-aware error
reporting. It composes L<Text::TokenStream::Role::Stream>; that role lists
the methods this class provides (so that you can easily write a parser
class that C<< L<has|Moo/has> >> a token stream which in turn C<handles>
the tokenizer methods).

The basic lexer machinery is found in L<Text::TokenStream::Lexer>; it is
separated out from the token stream so that it can be reused across many
inputs.

Tokens are instances of a class, L<Text::TokenStream::Token> by default.

=head1 CONSTRUCTOR

This class uses L<Moo>, and inherits the standard C<< L<new|Moo/new> >>
constructor.

=head1 ATTRIBUTES

=head2 C<lexer>

An instance of L<Text::TokenStream::Lexer>; required; read-only. Will
be used to find tokens in the input.

=head2 C<input>

C<< L<Str|Types::Standard/Moose-like> >>; required; read-only. The text
that will be lexed into a stream of tokens.

=head2 C<input_name>

A C<< L<Maybe|Types::Standard/Moose-like>[L<Path|Types::Path::Tiny/Path>] >>;
read-only. Can be coerced from a string. If a defined value is present, it
should contain the name of the file that the input was read from, and that
name will be used in any error messages.

=head2 C<token_class>

The name of a class that inherits from L<Text::TokenStream::Token>;
defaults to L<Text::TokenStream::Token> itself; read-only. Tokens found
in the input will be constructed as instances of this class.

=head1 OTHER METHODS

=head2 C<collect_all>

Takes no arguments. Returns a list of all remaining tokens found in the
input.

In the current implementation, this method is provided by
L<Text::TokenStream::Role::Stream>.

=head2 C<collect_upto>

Takes a single argument indicating a token to match, as with
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>.
Scans through the input until it finds a token that matches the argument,
and returns a list of all tokens I<before> the matching one. If no remaining
token in the input matches the argument, behaves as C<< L</collect_all> >>.

In the current implementation, this method is provided by
L<Text::TokenStream::Role::Stream>.

=head2 C<create_token>

Takes a listified hash of token attributes, and creates a token instance.
The token object is created by calling:

    $self->token_class->new(%data);

If you have particularly complex needs, you may wish to override this
method in a subclass.

=head2 C<current_position>

Takes no arguments. Returns the 0-based position of the first input
character that hasn't yet been returned by C<< L</next> >>.

=head2 C<err>

Takes multiple arguments, that are concatenated into an error message.
(If no arguments are supplied, acts as if you'd supplied the string
C<"Something's wrong">.) Throws an exception, reporting the locus of
the error as the current input position (using 1-based line and column
numbers).

=head2 C<fill>

Takes a single positive-integer argument. Attempts to fill an internal
buffer of already-lexed tokens so that it contains that many tokens.
Returns a boolean that is true iff there were enough tokens to do that.

=head2 C<looking_at>

Takes zero or more arguments, each of which indicates a token to match, as with
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>.
Returns a boolean that is true iff there's at least one more token in the
input, and it matches the argument.

=head2 C<next>

Takes no arguments. Returns the next token found in the input, and advances
the current position past it; if no tokens remain, returns C<undef>. The
token instance is created by C<< L</create_token> >>.

=head2 C<next_of>

Takes a single argument indicating a token to match, as with
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>,
and an optional string argument describing the current position (for
example, C<"in expression">, or C<"after keyword">). If there are no more
tokens in the input, reports an error at the current position, using
C<< L</err> >>. Otherwise, if the next token doesn't match the argument,
reports an error at the position of that token, using C<< L</token_err> >>.
Otherwise, the next token matches what is being looked for, so that token
is returned.

=head2 C<peek>

Takes no arguments. Returns the next token that would be returned by
C<< L</next> >>, but doesn't advance the current input position, and
a subsequent C<< L</next> >> call will return the same token.

An internal buffer is used to ensure that every token is lexed only once.

=head2 C<skip_optional>

Takes a single argument indicating a token to match, as with
C<< L<Text::TokenStream::Token#matches|Text::TokenStream::Token/matches> >>.
If there are no more tokens in the input, or the next token doesn't match
the argument, returns false; otherwise, advances past the next token, and
returns true.

=head2 C<token_err>

Takes a token as an argument, followed by multiple arguments that are
concatenated into an error message. (If no non-token arguments are
supplied, acts as if you'd supplied the string C<"Something's wrong">.)
Throws an exception, reporting the locus of the error as the position
of the token (using 1-based line and column numbers).

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 Aaron Crane.

=head1 LICENCE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.
