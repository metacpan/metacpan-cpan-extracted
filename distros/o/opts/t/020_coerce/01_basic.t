use strict;
use warnings;
use opts;
use Test::More;

{
    package Foo;

    sub new {
        bless { _value => $_[1] }, 'Foo';
    }

    sub calc { shift->{_value} * 2 }

    1;
}

opts::coerce 'Foo' => 'Int' => sub { Foo->new($_[0]) };

@ARGV = qw(--foo=3);
foo();
done_testing;


sub foo {
    opts my $foo => 'Foo';
    is $foo->calc, 6;
}
