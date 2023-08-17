#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

package FetchStoreCounter {
    sub TIESCALAR { my ($class, @args) = @_; bless \@args, $class }

    sub FETCH { my ($self) = @_; ${ $self->[0] }++ }
    sub STORE { my ($self) = @_; ${ $self->[1] }++ }
}

# ceil, floor
{
    use builtin qw( ceil floor );

    cmp_ok(ceil(1.5), '==', 2, 'ceil(1.5) == 2');
    cmp_ok(floor(1.5), '==', 1, 'floor(1.5) == 1');

    # Invokes magic

    tie my $tied, FetchStoreCounter => (\my $fetchcount, \my $storecount);

    my $_dummy = ceil($tied);
    is($fetchcount, 1, 'ceil() invokes FETCH magic');

    $tied = ceil(1.1);
    is($storecount, 1, 'ceil() TARG invokes STORE magic');

    $fetchcount = $storecount = 0;
    tie $tied, FetchStoreCounter => (\$fetchcount, \$storecount);

    $_dummy = floor($tied);
    is($fetchcount, 1, 'floor() invokes FETCH magic');

    $tied = floor(1.1);
    is($storecount, 1, 'floor() TARG invokes STORE magic');

    is(prototype(\&builtin::ceil), '$', 'ceil prototype');
    is(prototype(\&builtin::floor), '$', 'floor prototype');
}

done_testing;
