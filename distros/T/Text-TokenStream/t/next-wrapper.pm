#!perl

use v5.12;
use warnings;

use Test::Fatal qw(exception);
use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Text::TokenStream::Lexer;

my $lexer = Text::TokenStream::Lexer->new(
    whitespace => [qr/\s+/],
    rules => [ ident => qr/\w+/x, sym => qr/[^\s\w]+/ ],
);

{
    package Test_::TokenStream;
    use Moo;
    extends 'Text::TokenStream';
    has all_toks => (is => 'ro', default => sub { [] });
    around next => sub {
        my ($orig, $self) = @_;
        my $tok = $self->$orig // return undef;
        push @{ $self->all_toks }, $tok;
        return $tok;
    }
    no Moo;
}

sub token {
    my ($type, $text, $position, $cuddled) = @_;
    return Text::TokenStream::Token->new(
        type => $type,
        text => $text,
        position => $position,
        cuddled => $cuddled || 0,
    );
}

{
    my $stream = Test_::TokenStream->new(input => 'foo +');
    ok( $stream->skip_optional('foo'), 'skip_optional ident' );
    is_deeply($stream->all_toks, [token(ident => 'foo', 0)],
        'all_toks has skip_optional return');
    is($stream->next_of('+'), token(sym => '+', 4), 'next_of sym');
    is_deeply($stream->all_toks,
        [token(ident => 'foo', 0), token(sym => '+', 4)],
        'all_toks has skip_optional return');
}

had_no_warnings();
done_testing();

