#!perl

use v5.12;
use warnings;

use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Text::TokenStream::Token;
use Text::TokenStream::Types qw(Identifier TokenClass);

ok(Identifier->check($_), "identifier '$_' is an Identifier")
    for qw(foo _bar one2one_);

ok(! Identifier->check($_), "symbol '$_' is not an Identifier")
    for '', qw(! 2bad);

@Test_::TokenSubclass::ISA = 'Text::TokenStream::Token';
ok(TokenClass->check('Test_::TokenSubclass'),
    'subclass of token class is a TokenClass');

had_no_warnings();
done_testing();
