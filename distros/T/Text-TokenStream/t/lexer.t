#!perl

use v5.12;
use warnings;

use Test::More;
use Test::Fatal qw(exception);
use Test::Warnings qw(had_no_warnings :no_end_test);

use Text::TokenStream::Lexer;

{
    my $lexer = Text::TokenStream::Lexer->new(rules => []);
    my $exn = exception { $lexer->next_token(\(my $s = 'nope')) };
    like($exn, qr/^No matching rule; next text is: nope\b/,
         'empty rules handled appropriately');
}

my $lexer = Text::TokenStream::Lexer->new(
    whitespace => [
        qr/\s+/, # actual whitespace
        qr{//[^\n]*\n}, # C99 comment to end-of-line
        qr{/\* .*? \*/}xms, # C89 bracketed comment
    ],
    rules => [
        keyword => qr/(?:break|case|continue|do|else|goto|if|switch|while)\b/,
        identifier => qr/(?!\d) \w+/x,
        eq => '(==)',
        opening => qr/[\(\[\{]/,
        closing => qr/[\}\]\)]/,
        oct => qr/0[0-7]*\b/,
        hex => qr/0[xX][\da-f]+\b/,
        dec => qr/[1-9]\d*\b/,
        str => qr/" (?<contents> [^\"\\]*) "/x,
        sym => qr/[^\s\w]+/,
    ],
);

sub token {
    my ($type, $text, $cuddled, %captures) = @_;
    return {
        type => $type,
        text => $text,
        cuddled => $cuddled // 0,
        captures => \%captures,
    };
}

{
    my $source = <<'EOF';
{
    goto Yeet; // comment here
    /* don't comment out revision-controlled code, people!
    for (int i = 0;  i < len;  i++) {
        printf("elem %d: %s\n", i, elem[i]);
    }
    */
    if (x (==) "foo" || n >= arr[0x1f]) {
        break ;
    }
}
EOF

    my $orig_source = $source;
    is_deeply($lexer->next_token(\$source), token(opening => '{', 1),
        "next_token finds first token");

    (my $modified_source = $orig_source) =~ s/^\{//;
    is($source, $modified_source, "next_token removes matched text");

    my @tokens = (
        token(keyword => 'goto'),
        token(identifier => 'Yeet'),
        token(sym => ';', 1),
        token(keyword => 'if'),
        token(opening => '('),
        token(identifier => 'x', 1),
        token(eq => '(==)'),
        token(str => q["foo"], 0, contents => 'foo'),
        token(sym => '||'),
        token(identifier => 'n'),
        token(sym => '>='),
        token(identifier => 'arr'),
        token(opening => '[', 1),
        token(hex => '0x1f', 1),
        token(closing => ']', 1),
        token(closing => ')', 1),
        token(opening => '{'),
        token(keyword => 'break'),
        token(sym => ';'),
        token(closing => '}'),
        token(closing => '}'),
    );

    my @got;
    while (my $tok = $lexer->next_token(\$source)) {
        push @got, $tok;
    }

    is_deeply( \@got, \@tokens, 'tokens are as expected' );
    is( $source, '', 'source is then truncated' );
}

had_no_warnings();
done_testing();
