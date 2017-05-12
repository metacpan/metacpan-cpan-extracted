use strict;
use warnings;
use opts;
use Test::More;

@ARGV = qw(--pi=3.14);
foo();
done_testing;


sub foo {
    opts my $pi => 'Num';
    is $pi, 3.14;
}
