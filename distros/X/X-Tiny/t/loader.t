use strict;
use warnings;

use Test::More;
plan tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use MyDist::X ();

my %lines;

sub do_it {
    $lines{'called'} = (caller 0)[2];

    $lines{'thrown'} = 1 + __LINE__;
    eval { die MyDist::X->create( 'BadArg', 'username', 'ha$ha' ) };

    ok(
        overload->can('StrVal'),
        'overload.pm is loaded after exception instantiation',
    );

    $lines{'propagate'} = 1 + __LINE__;
    die if $@;
}

eval { do_it() };

my $err = $@;

my $str = "" . $err;

SKIP: {
    if ( $^V le v5.8.9 ) {
        skip 'Perl 5.8 doesn’t like our lazy-load of overload.pm.', 4;
    }

    like(
        $str,
        qr<MyDist::X::BadArg>,
        'spewage contains exception class',
    );

    like(
        $str,
        qr<line \Q$lines{'called'}\E>,
        "caller line ($lines{'called'}) is in spewage",
    );

    like(
        $str,
        qr<line \Q$lines{'thrown'}\E>,
        "thrown line ($lines{'thrown'}) is in spewage",
    );

    like(
        $str,
        qr<propagated at .+ line \Q$lines{'propagate'}\E>,
        "propagation line ($lines{'propagate'}) is in spewage",
    );
}
