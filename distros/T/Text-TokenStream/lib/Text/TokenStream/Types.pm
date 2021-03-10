package Text::TokenStream::Types;

use v5.12;
use warnings;

our $VERSION = '0.04';

use Type::Utils qw(as class_type coerce declare from role_type where via);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Standard qw(ClassName Str RegexpRef);

use Type::Library -base, -declare => qw(
    Identifier
    Lexer
    LexerRule
    Position
    Stream
    Token
    TokenClass
    TokenStream
);

declare Identifier, as Str, where { /^ (?![0-9]) [0-9a-zA-Z_]+ \z/x };
declare Position, as PositiveOrZeroInt;

declare TokenClass, as ClassName,
    where { $_->isa('Text::TokenStream::Token') };

declare LexerRule, as RegexpRef|Str;

role_type Stream, { role => 'Text::TokenStream::Role::Stream' };

class_type Lexer, { class => 'Text::TokenStream::Lexer' };
class_type Token, { class => 'Text::TokenStream::Token' };
class_type TokenStream, { class => 'Text::TokenStream' };

1;
__END__

=head1 NAME

Text::TokenStream::Types - types used by Text::TokenStream et al

=head1 SYNOPSIS

    use Text::TokenStream::Types qw(Stream);

=head1 TYPES

=head2 C<Identifier>

A string that matches internal-identifier syntax: non-empty, contains
only C<qr/\w/a> characters, and doesn't start with a digit.

=head2 C<Lexer>

An instance of L<Text::TokenStream::Lexer>.

=head2 C<LexerRule>

A C<< L<RegexpRef|Types::Standard/Moose-like> >> or a string.

=head2 C<Position>

An alias for
C<< L<PositiveOrZeroInt|Types::Common::Numeric/Types> >>.

=head2 C<Stream>

An instance that composes L<Text::TokenStream::Role::Stream>.

=head2 C<Token>

An instance of L<Text::TokenStream::Token>.

=head2 C<TokenClass>

The name of a class that inherits from L<Text::TokenStream::Token>.

=head2 C<TokenStream>

An instance of L<Text::TokenStream>.

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 Aaron Crane.

=head1 LICENCE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.
