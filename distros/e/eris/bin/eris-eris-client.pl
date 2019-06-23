#!perl
# PODNAME: eris-eris-client.pl
# ABSTRACT: Simple wrapper to spawn workers for handling syslog stream
## no critic (RequireEndWithOne)
use strict;
use warnings;

use FindBin;
use Getopt::Long::Descriptive;
use Path::Tiny;
use POE qw(
    Component::Client::eris
    Component::Client::TCP
    Component::WheelRun::Pool
    Wheel::ReadWrite
    Filter::Line
);
use POSIX qw(strftime);
use Ref::Util qw(is_hashref);
use Sys::Hostname qw(hostname);
use YAML qw();

my ($opt,$usage) = describe_options('%c - %o',
    [ 'config=s',          'Eris YAML config file, required', { validate => { "Must be a readable file." => sub { -r $_[0] } } } ],
    [ 'eris-host|eh=s',    'Eris Dispatcher Host, defaults to localhost' ],
    [ 'eris-port|ep=s',    'Eris Dispatcher Port, defaults to 9514' ],
    [ 'indexer=s',         'Script to run to handle indexing, defaults to the eris-es-indexer.pl script.' ],
    [ 'workers|w=i',       'Number of workers to run, default 4', { default => 4 }  ],
    [],
    [ 'stats-interval=i',   'Interval to send statistics, in seconds, default: 60', { default => 60 }],
    [ 'graphite-host|g=s',  'Graphite host to dispatch metrics to, default disabled' ],
    [ 'graphite-port|gp=s', 'Graphite port to dispatch metrics to, default 2003', { default => 2003 }],
    [ 'graphite-prefix=s',  'Graphite prefix, default: eris.client',              { default => "eris.client" }],
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
        stats    => {},
        hostname => hostname(),
    },
);

POE::Kernel->run();

sub main_stop {  }

sub main_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Set out alias
    $kernel->alias_set('main');

    # Load Config
    my $cfg = {};
    if( $opt->config ) {
        eval {
            $cfg = YAML::LoadFile( $opt->config );
            1;
        } or do {
            my $err = $@;
            warn sprintf "Failed loading %s: %s", $opt->config, $err;
        };
    }
    # Store the Config
    $heap->{cfg} = $cfg;

    # Startup the Eris Client
    my $eris_session = POE::Component::Client::eris->spawn(
        # Defaults
        Subscribe      => 'fullfeed',
        # Load the ConfigFile
        exists $cfg->{client} ? %{ $cfg->{client} } : (),
        # Some CLI Options take precedence
        $opt->eris_host ? ( RemoteAddress => $opt->eris_host ) : (),
        $opt->eris_port ? ( RemotePort    => $opt->eris_port ) : (),
        ReturnType     => 'string',
        MessageHandler => sub {
            $heap->{stats}{dispatched} ||= 0;
            $heap->{stats}{dispatched}++;
            $kernel->post( pool => dispatch => @_ );
        },
    );

    # Start the Graphite Handler
    if( $opt->graphite_host ) {
        $heap->{_graphite} = POE::Component::Client::TCP->new(
            Alias          => 'graphite',
            RemoteAddress  => $opt->graphite_host,
            RemotePort     => $opt->graphite_port,
            ConnectTimeout => 5,
            Connected      => sub {
                # let the parent know we're able to write
                $heap->{graphite} = 1;
            },
            ConnectError => sub {
                my ($op,$err_num,$err_str) = @_[ARG0..ARG2];
                delete $heap->{graphite} if exists $heap->{graphite};
                $heap->{stats}{graphite_errors} ||= 0;
                $heap->{stats}{graphite_errors}++;
                # Attempt to reconnect
                $kernel->delay( reconnect => 60 );
            },
            Disconnected => sub {
                $kernel->delay( reconnect => 60  );
            },
            Filter => "POE::Filter::Line",
            InlineStates => {
                send => sub {
                    $_[HEAP]->{server}->put($_[ARG0]);
                },
            },
            ServerInput => sub {
                # Shouldn't get any
                $_[HEAP]->{stats}{graphite_feedback} ||= 0;
                $_[HEAP]->{stats}{graphite_feedback}++;
            },
            ServerError => sub {
                $_[KERNEL]->yield( 'reconnect' );
            },
        );
    }

    # Figure out where we're installed
    my $bindir = path( "$FindBin::RealBin" );
    $heap->{workers} = POE::Component::WheelRun::Pool->spawn(
        Alias       => 'pool',
        PoolSize    => $opt->workers,
        Program     => $^X,
        ProgramArgs => [
            '--',
            $opt->indexer ? $opt->indexer : $bindir->child('eris-es-indexer.pl')->stringify,
            $opt->config ? ('--config', $opt->config ) : (),
            $opt->stats_interval ? ('--stats-interval', $opt->stats_interval ) : (),
        ],
        StdinFilter  => POE::Filter::Line->new(),
        StdoutFilter => POE::Filter::Reference->new(),
        # Handlers
        StatsHandler => sub {
            my ($stats) = @_;
            if( is_hashref($stats) ) {
                foreach my $k ( keys %$stats ) {
                    $heap->{stats}{$k} ||= 0;
                    $heap->{stats}{$k} += $stats->{$k};
                }
            }
            else {
                print STDERR "StatsHandler did not receive a hashref.\n";
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

    my $time  = time();
    my $stats = exists $heap->{stats} ? delete $heap->{stats} : {};
    printf "%s STATS: %s\n", strftime("%H:%M",localtime), join(', ', map { sprintf "%s=%s", $_, $stats->{$_} } sort keys %{ $stats });

    # Are we graphiting?
    if( exists $heap->{graphite} && $heap->{graphite} ) {
        foreach my $stat (keys %{ $stats }) {
            my $metric = join('.', $opt->graphite_prefix, $heap->{hostname}, $stat);
            $kernel->post( graphite => send => join " ", $metric, $stats->{$stat}, $time);
        }
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

version 0.008

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
