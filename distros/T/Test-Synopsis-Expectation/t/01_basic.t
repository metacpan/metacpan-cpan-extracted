#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;
synopsis_ok(*DATA);
done_testing;

__DATA__
=head1 NAME

basic - It's basic

=head1 SYNOPSIS

    my $sum;
    $sum = 1; # => 1
    ++$sum;   # => is 2
    ++$sum;   #=>is 3

    use PPI::Tokenizer;
    my $tokenizer = PPI::Tokenizer->new(\'code'); # => isa 'PPI::Tokenizer'

    my $str = 'Hello, I love you'; # => like qr/ove/

    my $obj = {
        foo => ["bar", "baz"],
    }; # => is_deeply { foo => ["bar", "baz"] }

    $sum; # => success

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
