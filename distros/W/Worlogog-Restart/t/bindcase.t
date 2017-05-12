#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 16;

use Worlogog::Restart -all => { -prefix => 'restart_' };

my $x;

$x = restart_case {
    restart_case {
        is_deeply [map $_->name, restart_compute], [qw(bar foo)];
        restart_invoke 'foo', 'C';
        ok 0;
        'B'
    } {
        bar => sub { ok 0; 'A' },
    }
} {
    foo => sub { ok 1; $_[0] },
};
is $x, 'C';

$x = restart_case {
    restart_bind {
        is_deeply [map $_->name, restart_compute], [qw(bar foo)];
        restart_invoke 'foo', 'C';
        ok 0;
        'B'
    } {
        bar => sub { ok 0; 'A' },
    }
} {
    foo => sub { ok 1; $_[0] },
};
is $x, 'C';

$x = restart_bind {
    restart_bind {
        is_deeply [map $_->name, restart_compute], [qw(bar foo)];
        is restart_invoke('foo', 'C'), 'D';
        'B'
    } {
        bar => sub { ok 0; 'A' },
    }
} {
    foo => sub { ok 1; is $_[0], 'C'; 'D' },
};
is $x, 'B';

$x = restart_bind {
    restart_case {
        is_deeply [map $_->name, restart_compute], [qw(bar foo)];
        is restart_invoke('foo', 'C'), 'D';
        'B'
    } {
        bar => sub { ok 0; 'A' },
    }
} {
    foo => sub { ok 1; is $_[0], 'C'; 'D' },
};
is $x, 'B';
