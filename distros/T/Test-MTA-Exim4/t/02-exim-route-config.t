#!/usr/bin/perl

use FindBin qw($Bin);
use Test::More 'no_plan';

BEGIN {
    use_ok('Test::MTA::Exim4');
}

my $exim_path = "$Bin/scripts/fake_exim";

my $exim = Test::MTA::Exim4->new( { exim_path => $exim_path, debug => 1 } );
ok( $exim, 'Created exim test object' );
$exim->config_ok;

# simple delivery checks
$exim->routes_ok('test@example.com');
$exim->discards_ok('test@discard.com');
$exim->undeliverable_ok('test@undeliverable.com');
$exim->routes_ok('multiple4@example.com');
$exim->routes_ok('multiple4@local.com');

# same checks in more complex form...
$exim->routes_as_ok(
    'test@example.com',
    {   router    => 'smart_route',
        transport => 'remote_smtp',
        discarded => 0,
        ok        => 1
    }
);
$exim->routes_as_ok( 'test@discard.com', { discarded => 1, ok => 1 } );
$exim->routes_as_ok( 'test@undeliverable.com', { ok => 0 } );
$exim->routes_as_ok(
    'multiple4@example.com',
    [   {   router    => 'smart_route',
            transport => 'remote_smtp'
        },
        {   router    => 'smart_route',
            transport => 'remote_smtp'
        },
        {   router    => 'smart_route',
            transport => 'remote_smtp'
        },
        {   router    => 'smart_route',
            transport => 'remote_smtp'
        },
    ]
);
$exim->routes_as_ok(
    'multiple4@local.com',
    [   { transport => 'local_delivery' },
        { transport => 'local_delivery' },
        { transport => 'local_delivery' },
        { transport => 'local_delivery' },
    ]
);
