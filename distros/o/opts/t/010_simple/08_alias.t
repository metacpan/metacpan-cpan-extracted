use strict;
use warnings;
use opts;
use Test::More;

@ARGV = qw(--pi=3.14);
foo();
@ARGV = qw(--q=3.14);
foo();
done_testing;


sub foo {
    opts my $pi => { isa => 'Num', alias => 'q' };
    is $pi, 3.14;
}
