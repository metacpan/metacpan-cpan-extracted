package Test::RandomCheck::Types::Char;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Exporter qw(import);
use Test::RandomCheck::ProbMonad;

our @EXPORT = qw(char);

sub char () { Test::RandomCheck::Types::Char->new }

sub arbitrary { elements 'a' .. 'z', 'A' .. 'Z' }

sub memoize_key {
    my ($self, $c) = @_;
    $c;
}

1;
