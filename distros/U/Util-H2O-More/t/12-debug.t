#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Util::H2O::More qw/ddd dddie/;

{
    my $stderr = q{};

    {
        local *STDERR;
        open STDERR, q{>}, \$stderr or die qq{Could not redirect STDERR: $!};
        ddd( { foo => q{bar} }, [ 1, 2, 3 ] );
    }

    like $stderr, qr/foo/, q{ddd dumps a HASH reference to STDERR};
    like $stderr, qr/bar/, q{ddd dump contains the HASH value};
    like $stderr, qr/1.*2.*3/s, q{ddd dumps each supplied reference};
}

{
    my $stderr = q{};

    throws_ok {
        local *STDERR;
        open STDERR, q{>}, \$stderr or die qq{Could not redirect STDERR: $!};
        dddie( { foo => q{bar} } );
    }
    qr/^died due to use of dddie/,
    q{dddie dies with its documented fatal message after dumping its arguments};
    like $stderr, qr/foo/, q{dddie dumps its argument to STDERR before dying};
    like $stderr, qr/bar/, q{dddie dump contains the expected value};
}

done_testing;

