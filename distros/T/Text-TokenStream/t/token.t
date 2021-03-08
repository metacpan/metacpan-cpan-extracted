#!perl

use v5.12;
use warnings;

use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Text::TokenStream::Token;

{
    my $tok = Text::TokenStream::Token->new(
        type => 'sym',
        text => 'foo',
        position => 17,
    );

    is($tok->repr, 'Token type=sym position=17 cuddled=0 text=[foo]',
        'token repr with no arg');

    is($tok->repr(''), 'Token type=sym position=17 cuddled=0 text=[foo]',
        'token repr with empty arg');

    is($tok->repr('  '), '  Token type=sym position=17 cuddled=0 text=[foo]',
        'token repr with empty arg');

    is($tok->text_for_matching, 'foo', 'text_for_matching');

    ok($tok->matches('foo'), 'token matches text');
    ok($tok->matches(sub { $_[0]->type eq 'sym' }),
        'token matches code, using argument');

    local $_ = 'orig';
    ok($tok->matches(sub { $_->type eq 'sym' }),
        'token matches code, using default var');
    is($_, 'orig', 'code matching leaves default var unchanged');
}

had_no_warnings();
done_testing();
