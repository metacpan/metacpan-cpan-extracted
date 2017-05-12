#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 7;

use Worlogog::Incident -all => { -prefix => 'incident_' };
use Worlogog::Restart  -all => { -prefix => 'restart_' };

{
    package Base;

    sub new {
        my $class = shift;
        bless {@_}, $class
    }

    sub subclass {
        my $class = shift;
        for my $subclass (@_) {
            no strict 'refs';
            push @{$subclass . '::ISA'}, $class;
        }
    }
}

{
    package Exc;
    Base->subclass(__PACKAGE__);

    sub throw {
        my $self = shift;
        unless (ref $self) {
            $self = $self->new(@_);
        }
        die $self;
    }
}

Exc->subclass(qw(MalformedLogEntry InsufficientMoose ENOBEER));

{
    my ($not_here, $here);

    incident_handler_case {
        incident_error InsufficientMoose->new;
    } [
        InsufficientMoose => sub {
            $here = 1;
        },
        ENOBEER => sub {
            $not_here = 1;
        },
    ];

    is $here, 1;
    is $not_here, undef;
}

{
    my ($started, $restarted, $invoked_restart, $restart_value);

    my $risky_business = sub {
        restart_case {
            incident_error ENOBEER->new;
        } {
            use_me => sub {
                $invoked_restart++;
                $_[0]
            },
            shy_restart_case => sub {
                die "should not be called";
            },
        };
    };

    incident_handler_bind {
        $started = 1;
        $restart_value = $risky_business->();
        $restarted = 1;
    } [
        ENOBEER => sub {
            restart_invoke use_me => 'A strong beverage';
        },
    ];

    is $started, 1;
    is $restarted, 1;
    is $invoked_restart, 1;
    is $restart_value, 'A strong beverage';
}

{
    sub parse_log_entry {
        my ($entry) = @_;
        if ($entry =~ /(\d+-\d+-\d+) (\d+:\d+:\d+) (\w+) (.*)/) {
            return $1, $2, $3, $4;
        }
        restart_case {
            incident_error MalformedLogEntry->new(text => $entry);
        } {
            use_value => sub { $_[0] },
            log => sub {
                warn "*** Invalid entry: $entry";
                ()
            },
        };
    }

    my @logs = incident_handler_bind {
        [ parse_log_entry('2010-01-01 10:09:5 WARN Test') ],
        [ parse_log_entry('Oh no bad data') ],
        [ parse_log_entry('2010-10-12 12:11:03 INFO Notice it still carries on!') ],
    } [
        MalformedLogEntry => sub {
            restart_invoke use_value => 'hungry hungry hippos';
        },
    ];

    is_deeply \@logs, [
        [ '2010-01-01', '10:09:5', 'WARN', 'Test' ],
        [ 'hungry hungry hippos' ],
        [ '2010-10-12', '12:11:03', 'INFO', 'Notice it still carries on!']
    ];
}
