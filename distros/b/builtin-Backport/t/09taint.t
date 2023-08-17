#!./perl -T

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

# is_tainted
{
    use builtin qw( is_tainted );

    is(is_tainted($0), !!${^TAINT}, "\$0 is tainted (if tainting is supported)");
    ok(!is_tainted($1), "\$1 isn't tainted");

    # Invokes magic
    tie my $tied, FetchStoreCounter => (\my $fetchcount, \my $storecount);

    my $_dummy = is_tainted($tied);
    is($fetchcount, 1, 'is_tainted() invokes FETCH magic');

    $tied = is_tainted($0);
    is($storecount, 1, 'is_tainted() invokes STORE magic');

    is(prototype(\&builtin::is_tainted), '$', 'is_tainted prototype');
}

done_testing;
