#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

BEGIN {
    $^V ge v5.36.0 or
        plan skip_all => "builtin::is_bool requires Perl v5.36 or later";
}

package FetchStoreCounter {
    sub TIESCALAR { my ($class, @args) = @_; bless \@args, $class }

    sub FETCH { my ($self) = @_; $self->[0]->$*++ }
    sub STORE { my ($self) = @_; $self->[1]->$*++ }
}

# is_bool
{
    use builtin qw( true false is_bool );

    ok(is_bool(true), 'true is bool');
    ok(is_bool(false), 'false is bool');
    ok(!is_bool(undef), 'undef is not bool');
    ok(!is_bool(1), '1 is not bool');
    ok(!is_bool(""), 'empty is not bool');

    my $truevar  = (5 == 5);
    my $falsevar = (5 == 6);

    ok(is_bool($truevar), '$truevar is bool');
    ok(is_bool($falsevar), '$falsevar is bool');

    ok(is_bool(is_bool(true)), 'is_bool true is bool');
    ok(is_bool(is_bool(123)),  'is_bool false is bool');

    # Invokes magic

    tie my $tied, FetchStoreCounter => (\my $fetchcount, \my $storecount);

    my $_dummy = is_bool($tied);
    is($fetchcount, 1, 'is_bool() invokes FETCH magic');

    $tied = is_bool(false);
    is($storecount, 1, 'is_bool() invokes STORE magic');

    is(prototype(\&builtin::is_bool), '$', 'is_bool prototype');
}

done_testing;
