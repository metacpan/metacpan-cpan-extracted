#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 9;

use Worlogog::Incident -all => { -prefix => 'incident_' };
use Worlogog::Restart  -all => { -prefix => 'restart_' };

sub factorial {
    my ($x) = @_;
    unless ($x =~ /^[0-9]+\z/) {
        incident_error "$x is not a valid argument to factorial";
    }
    my $r = 1;
    $r *= $_ for 2 .. $x;
    $r
}

is factorial(5), 120;

is eval { factorial(-1) }, undef;
like $@, qr/^\Q-1 is not a valid argument to factorial/;

is +(incident_handler_case {
    factorial(-1)
} sub {
    my ($incident) = @_;
    sub { length $incident }
}), 39;

sub real_sqrt {
    my ($n) = @_;
    if ($n < 0) {
        $n = -$n;
        incident_cerror "Tried to take sqrt(-$n)";
    }
    sqrt $n
}

is real_sqrt(4), 2;
is eval { real_sqrt(-9) }, undef;
like $@, qr/^\QTried to take sqrt(-9)/;

is +(incident_handler_bind {
    real_sqrt(-9)
} sub {
    restart_invoke 'continue';
}), 3;

is +(restart_case {
    incident_handler_bind {
        incident_error "Foo.";
    } sub {
        restart_invoke my_restart => 7;
    };
} {
    my_restart => sub { $_[0] },
}), 7;
