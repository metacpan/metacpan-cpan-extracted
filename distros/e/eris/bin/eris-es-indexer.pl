#!perl
# PODNAME: eris-es-indexer.pl
# ABSTRACT: Sample implementation using the eris toolkit to index data to elasticsearch
## no critic (RequireEndWithOne)
use strict;
use warnings;

use Getopt::Long::Descriptive;
use Path::Tiny;
sub POE::Kernel::ASSERT_DEFAULT { 1 }
use POE qw(
    Component::ElasticSearch::Indexer
    Wheel::ReadWrite
    Filter::Line
    Filter::Reference
);
use YAML qw();

# Load the eris libraries
use eris::log::contextualizer;
use eris::schemas;

# Options
my ($opt,$usage) = describe_options('%c - %o',
    [ 'config:s', 'Config file, required.', { callbacks => { "Must be a readable file" => sub { -r $_[0] } } } ],
    [ 'stats-interval:i',   'Interval in seconds to send statistics, default: 60', { default => 60 }],
    [ 'flush-interval|F:i', 'Interval in seconds to flush the queue to thebulk handler, default: 10', { default => 10 } ],
    [ 'flush-size|S:i',     'Override the default FlushSize from POE::Component::ElasticSearch::Indexer' ],
    [],
    [ 'help',  'Display this help' ],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

# Load the Configuration
my $config = {};
if( $opt->config ) {
    eval {
        $config = YAML::LoadFile( $opt->config );
        1;
    } or do {
        my $err = $@;
        die sprintf "Failed loading your requested config %s: %s",
            $opt->config, $@;
    };
}
# Instantiate our object
my $eris = eris::log::contextualizer->new(
    config => $config,
);
my $schemas = eris::schemas->new(
    exists $config->{schemas} ? ( %{ $config->{schemas} } ) : (),
);

# POE Sessions
my $main_session = POE::Session->create(
        inline_states => {
            _start       => \&main_start,
            _stop        => \&main_stop,
            _child       => \&main_child,
            stats        => \&main_stats,
            syslog_input => \&syslog_input,
            syslog_error => \&syslog_error,
            es_bulk      => \&es_bulk,
        },
        heap => {
            bulk_queue    => [],
        },
);

POE::Kernel->run();
exit 0;

sub main_stop {
    $poe_kernel->post( es => 'shutdown' );
}

sub main_child {
    my ($kernel,$heap,$reason,$child) = @_[KERNEL,HEAP,ARG0,ARG1];

    my $stat = "child_$reason";
    $heap->{stats}{$stat} ||= 0;
    $heap->{stats}{$stat}++;
}

sub main_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Set our alias
    $kernel->alias_set('main');

    # Handle to the syslog daemon
    $heap->{io} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        InputEvent   => 'syslog_input',
        InputFilter  => POE::Filter::Line->new(),
        OutputFilter => POE::Filter::Reference->new(),
        ErrorEvent   => 'syslog_error',
    );

    # Handle ElasticSearch Indexing
    $heap->{indexer} = POE::Component::ElasticSearch::Indexer->spawn(
        Alias => 'es',
        StatsInterval => $opt->stats_interval,
        StatsHandler => sub {
            my ($stats) = @_;
            foreach my $k ( keys %{ $stats } ) {
                $heap->{stats}{$k} ||= 0;
                $heap->{stats}{$k} += $stats->{$k};
            }
        },
        $config->{elasticsearch} ? %{ $config->{elasticsearch} } : (),
        # Allow to override if specififed
        $opt->flush_size     ? (FlushSize => $opt->flush_size) : (),
        $opt->flush_interval ? (FlushInterval => $opt->flush_interval) : (),
    );
}

sub main_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : {};

    # Send the stats upstream
    $heap->{io}->put( $stats );

    # Reset the stats
    $heap->{stats} = {};
    $kernel->delay( stats => $opt->stats_interval );
}

sub syslog_input {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];

    return unless defined $msg;
    return unless length $msg;

    # Parse to a eris::log object
    my $log = $eris->parse($msg);
    # Transform into a bulk request data blob
    my @bulk_data = $schemas->as_bulk( $log );

    if( @bulk_data ) {
        $heap->{stats}{queued} ||= 0;
        $heap->{stats}{queued} += @bulk_data;

        # on the first batch, make sure we schedule a run
        $kernel->delay_add( es_bulk => $opt->flush_interval / 2 )
            unless @{ $heap->{bulk_queue} };

        # Add the data
        push @{ $heap->{bulk_queue} }, @bulk_data;
    }
    else {
        $heap->{stats}{no_schema} ||= 0;
        $heap->{stats}{no_schema}++;
    }

    if( @{ $heap->{bulk_queue} } > 10 ) {
        $kernel->yield('es_bulk');
    }
}

sub es_bulk {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Grab the batch
    my $batch = delete $heap->{bulk_queue};
    $heap->{bulk_queue} = [];

    return unless scalar @{ $batch };

    # Reschedule if necessary
    $kernel->delay( es_bulk => $opt->flush_interval / 2 );

    # Pass along to the indexer
    $kernel->post( es => queue => $batch );
}

sub syslog_error {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    delete $heap->{io};
    $kernel->post( es => 'shutdown' );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-es-indexer.pl - Sample implementation using the eris toolkit to index data to elasticsearch

=head1 VERSION

version 0.008

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
