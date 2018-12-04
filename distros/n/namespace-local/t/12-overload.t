#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Base;
    sub new { my $class = shift; bless {@_}, $class };
};

BEGIN {
    package My::Foo;
    # emulate use parent
    BEGIN { our @ISA = qw(My::Base) };
    use overload '""' => sub { 'foo' };
    use namespace::local -above;
}

my $foo = My::Foo->new;
is "$foo", "foo", "overload still orcs";

done_testing;
