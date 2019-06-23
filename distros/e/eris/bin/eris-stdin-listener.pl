#!perl
# PODNAME: eris-stdin-listener.pl
# ABSTRACT: Simple wrapper to spawn workers for handling syslog stream
## no critic (RequireEndWithOne)
use strict;
use warnings;

use FindBin;
use Hash::Merge::Simple qw(clone_merge);
use Getopt::Long::Descriptive;
use Path::Tiny;

use POE qw(
    Component::WheelRun::Pool
    Wheel::ReadWrite
    Filter::Line
);

my ($opt,$usage) = describe_options('%c - %o',
    [ 'config=s', 'Eris YAML config file, required', { required => 1, validate => { "Must be a readable file." => sub { -r $_[0] } } } ],
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

            syslog_input  => \&syslog_input,
            syslog_error  => \&syslog_error,
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

    # Handle to the syslog daemon
    $heap->{io} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        InputFilter  => POE::Filter::Line->new(),
        InputEvent   => 'syslog_input',
        ErrorEvent   => 'syslog_error',
    );

    my $bindir = path( "$FindBin::RealBin" );

    $heap->{workers} = POE::Component::WheelRun::Pool->spawn(
        Alias       => 'pool',
        Program     => $^X,
        ProgramArgs => [
            $bindir->child('eris-es-indexer.pl')->stringify,
            '--config', $opt->config,
        ],
        StdinFilter  => POE::Filter::Line->new(),
        StdoutFilter => POE::Filter::Reference->new(),
        StatsHandler => sub {
            my ($stats) = @_;
            if( is_hashref($stats) ) {
                $heap->{stats} = clone_merge( $stats, $heap->{stats} );
            }
        },
        StdoutHandler => sub {
            $kernel->yield(worker_stdout => @_);
        }
    );

    $kernel->delay(stats => 60);
}

sub main_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : {};

    if( exists $heap->{graphite} ) {
        # output to graphite
    }

    # Reschedule ourselves;
    $heap->{stats} = {};
    $kernel->delay( stats => 60 ) unless exists $heap->{_shutdown};
}

sub worker_stdout {
    my ($kernel,$heap,$stats) = @_[KERNEL,HEAP,ARG0];

    # Make sure we have stats
    return unless defined $stats && is_hashref($stats);

    # Aggregate stats from all our workers
    foreach my $s (keys %{ $stats }) {
        $heap->{stats}{$s} ||= 0;
        $heap->{stats}{$s} += $stats->{$s};
    }
}

sub syslog_input {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    $kernel->post( pool => dispatch => $msg );
}

sub syslog_error {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    delete $heap->{io};
    $heap->{_shutdown} = 1;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-stdin-listener.pl - Simple wrapper to spawn workers for handling syslog stream

=head1 VERSION

version 0.008

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
