#!/usr/bin/env perl
# PODNAME: eris-eris-client.pl
# ABSTRACT: Simple wrapper to spawn workers for handling syslog stream
use strict;
use warnings;

use FindBin;
use Hash::Merge::Simple qw(clone_merge);
use Getopt::Long::Descriptive;
use Path::Tiny;
use POE qw(
    Component::Client::eris
    Component::WheelRun::Pool
    Wheel::ReadWrite
    Filter::Line
);
use POSIX qw(strftime);
use Ref::Util qw(is_hashref);

my ($opt,$usage) = describe_options('%c - %o',
    [ 'config:s',          'Eris YAML config file, required', { validate => { "Must be a readable file." => sub { -r $_[0] } } } ],
    [ 'workers|w:i',       'Number of workers to run, default 4', { default => 4 }  ],
    [ 'stats-interval:i',  'Interval to send statistics, in seconds, default: 60', { default => 60 }],
    [],
    [ 'help',  'Display this help' ],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

my $main_session = POE::Session->create(
    inline_states => {
        _start => \&main_start,
        _stop  => \&main_stop,
        stats  => \&main_stats,
        worker_stdout => \&worker_stdout,
    },
    heap => {
        stats => {},
    },
);

POE::Kernel->run();

sub main_stop {  }

sub main_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Set out alias
    $kernel->alias_set('main');

    # Startup the Eris Client
    my $eris_session = POE::Component::Client::eris->spawn(
        Subscribe      => 'fullfeed',
        ReturnType     => 'string',
        MessageHandler => sub {
            $heap->{stats}{dispatched} ||= 0;
            $heap->{stats}{dispatched}++;
            $kernel->post( pool => dispatch => @_ );
        },
    );

    # Figure out where we're installed
    my $bindir = path( "$FindBin::RealBin" );
    $heap->{workers} = POE::Component::WheelRun::Pool->spawn(
        Alias       => 'pool',
        PoolSize    => $opt->workers,
        Program     => $^X,
        ProgramArgs => [
            '--',
            $bindir->child('eris-es-indexer.pl')->stringify,
            $opt->config ? ('--config', $opt->config ) : (),
            $opt->stats_interval ? ('--stats-interval', $opt->stats_interval ) : (),
        ],
        StdinFilter  => POE::Filter::Line->new(),
        StdoutFilter => POE::Filter::Reference->new(),
        # Handlers
        StatsHandler => sub {
            my ($stats) = @_;
            if( is_hashref($stats) ) {
                foreach my $k ( $stats ) {
                    $heap->{stats}{$k} ||= 0;
                    $heap->{stats}{$k} += $stats->{$k};
                }
            }
            else {
                printf STDERR "StatsHandler did not receive a hashref.\n";
            }
        },
        StdoutHandler => sub {
            $kernel->post( main => worker_stdout => @_);
        },
        StderrHandler => sub {
            printf STDERR "[worker_stderr] %s\n", $_ for @_;
        },
    );

    $kernel->delay(stats => $opt->stats_interval);
}

sub main_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : {};

    printf "%s STATS: %s\n", strftime("%H:%M",localtime), join(', ', map { sprintf "%s=%s", $_, $stats->{$_} } sort keys %{ $stats });
    if( exists $heap->{graphite} ) {
        # output to graphite
    }

    # Reschedule ourselves;
    $heap->{stats} = {};
    $kernel->delay( stats => $opt->stats_interval ) unless exists $heap->{_shutdown};
}

sub worker_stdout {
    my ($kernel,$heap,$stats) = @_[KERNEL,HEAP,ARG0];

    # Make sure we have stats
    if( is_hashref($stats) ) {
        # Aggregate stats from all our workers
        foreach my $s (keys %{ $stats }) {
            $heap->{stats}{$s} ||= 0;
            $heap->{stats}{$s} += $stats->{$s};
        }
    }
    else {
        printf STDERR "Received bad data from the client\n%s\n", ref($stats) ? ref($stats) : $stats;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-eris-client.pl - Simple wrapper to spawn workers for handling syslog stream

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
