#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;

BEGIN {
    use_ok ( 'Xen::Domain' ) or exit;
}

exit main();

sub main {
    my $domain = Xen::Domain->new(
        'name'  => 'lenny',
        'id'    => 1,
        'mem'   => 256,
        'vcpus' => 2,
        'state' => '-b----',
        'times' => 11.5,
    );
    
    can_ok($domain, qw(
        name
        id
        mem
        vcpus
        state
        times
    ));
    
    eq_or_diff(
        $domain,
        bless({
            'name'  => 'lenny',
            'id'    => 1,
            'mem'   => 256,
            'vcpus' => 2,
            'state' => '-b----',
            'times' => 11.5,
        }, 'Xen::Domain'),
        'check object constructor',
    );
    
    return 0;
}

