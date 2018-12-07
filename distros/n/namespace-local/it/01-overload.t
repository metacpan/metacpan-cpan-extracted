#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    # TODO remove this block
    # this test keeps failing on freebsd-i386-int64 for no apparent reason
    # so try to collect some debugging info...
    use Carp;
    $SIG{__DIE__} = sub {
        diag ( Carp::longmess( "FATAL: $_[0]" ) );
    };
};

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
is "$foo", "foo", "overload still works";

done_testing;
