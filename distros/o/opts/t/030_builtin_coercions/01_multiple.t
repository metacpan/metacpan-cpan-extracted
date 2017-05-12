use strict;
use warnings;
use opts;
use Test::More;

@ARGV = qw(--foo=3);
is_deeply [ 3 ], foo(), 'one Multiple';

@ARGV = qw(--foo=3 --foo=four);
is_deeply [ qw{ 3 four } ], foo(), 'two Multiple';

{
    no warnings 'qw';
    @ARGV = qw(--foo=3 --foo=four,five);
    is_deeply [ qw{ 3 four five } ], foo(), 'three Multiple';
}

done_testing;


sub foo {
    opts my $foo => 'Multiple';
    #is $foo->calc, 6;
    return $foo;
}

