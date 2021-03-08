package Text::TokenStream::Token;

use v5.12;
use Moo;

our $VERSION = '0.03';

use Carp qw(confess);
use Text::TokenStream::Types qw(Identifier Position);
use Types::Standard qw(Bool HashRef Str);

use namespace::clean;

has type => (is => 'ro', isa => Identifier, required => 1);
has text => (is => 'ro', isa => Str, required => 1);
has captures => (is => 'ro', isa => HashRef[Str], default => sub { +{} });
has cuddled => (is => 'ro', isa => Bool, default => 0);
has position => (is => 'ro', isa => Position, required => 1);

sub text_for_matching { shift->text }

sub matches {
    my ($self, $target) = @_;
    return $self->text_for_matching eq $target if Str->check($target);
    return !!grep $target->($_), $self;
}

sub repr {
    my ($self, $indent) = @_;

    return sprintf '%sToken type=%s position=%d cuddled=%d text=[%s]',
        $indent // '', $self->type, $self->position, $self->cuddled, $self->text;
}

1;
__END__

=head1 NAME

Text::TokenStream::Token - class to model scanned tokens

=head1 SYNOPSIS

    my $token = Text::TokenStream::Token->new(
        type => 'identifier',
        text => 'hello',
        position => $position,
    );

=head1 DESCRIPTION

This class represents tokens that L<Text::TokenStream> finds in its input.

=head1 CONSTRUCTOR

This class uses L<Moo>, and inherits the standard C<< L<new|Moo/new> >>
constructor.

=head1 ATTRIBUTES

=head2 C<captures>

A hashref of parts of the input text; defaults to an empty hashref;
read-only. Can be used to model the structure of individual tokens
with greater precision.

=head2 C<cuddled>

A boolean; default false; read-only. Indicates whether this token occurred
with no preceding whitespace.

=head2 C<position>

A non-negative integer; required; read-only. The 0-based offset from the
start of the input where the token was found.

=head2 C<text>

Any string; required; read-only. The literal text matched by the relevant rule.

=head2 C<type>

A non-empty string containing only C<qr/\w/a> characters, that does not
begin with a digit; required; read-only. Used to distinguish types of token.

=head1 OTHER METHODS

=head2 C<matches>

Takes one argument, either a string or a coderef. If it's a string, returns
the result of comparing the token's C<< L</text_for_matching> >> against it
with C<eq>. If it's a coderef, runs the coderef in scalar context, with the
token instance as its first argument, and additionally with C<$_> set to the
token instance, and returns a boolean indicating whether the coderef returned
a truthy value.

=head2 C<repr>

Takes no arguments. Returns a string representation of the token, suitable
for debugging.

=head2 C<text_for_matching>

Takes no arguments. Returns the same as C<< L</text> >> (but can be
overridden in subclasses, for example to return a case-folded version
of the text for some or all tokens).

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 Aaron Crane.

=head1 LICENCE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.
