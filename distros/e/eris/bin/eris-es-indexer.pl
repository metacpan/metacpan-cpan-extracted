#!/usr/bin/env perl
# PODNAME: eris-es-indexer.pl
# ABSTRACT: Sample implementation using the eris toolkit to index data to elasticsearch
## no critic (RequireEndWithOne)
use strict;
use warnings;

use Data::GUID qw(guid_string);
use Getopt::Long::Descriptive;
use HTTP::Request;
use JSON::MaybeXS;
use Path::Tiny;
use POE qw(
    Component::Client::HTTP
    Wheel::ReadWrite
    Filter::Line
    Filter::Reference
);
use POSIX qw(strftime);
use YAML qw();

# Hack for Dev
use FindBin;
use lib "$FindBin::RealBin/../lib";

use eris::log::contextualizer;
use eris::schemas;

# Options
my ($opt,$usage) = describe_options('%c - %o',
    [ 'config:s', 'Config file, required.', { callbacks => { "Must be a readable file" => sub { -r $_[0] } } } ],
    [ 'stats-interval:i',   'Interval in seconds to send statistics, default: 60', { default => 60 }],
    [ 'flush-interval|F:i', 'Interval in seconds to flush the bulk queue, default: 15', { default => 15 } ],
    [ 'es-version|esv:i',   'ElasticSearch Major Version to use for Mappings, default: 5', { default => 5 } ],
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
my %CONFIG = (
    # Defaults
    es_addr          => 'http://localhost:9200',
    es_mapping_name  => 'syslog',
    # Overrides
    %{ $config },
);
# Instantiate our object
my $eris = eris::log::contextualizer->new(
    config => $config,
);
my $schemas = eris::schemas->new(
    exists $config->{schemas} ? ( config => $config->{schemas} ) : (),
);

# POE Sessions
my $http_session = POE::Component::Client::HTTP->spawn(
    Alias   => 'ua',
    Timeout => 60,
);
my $main_session = POE::Session->create(
        inline_states => {
            _start => \&main_start,
            _stop  => \&main_stop,
            stats  => \&main_stats,

            syslog_input => \&syslog_input,
            syslog_error => \&syslog_error,

            # ElasticSearch Stuff
            es_bulk               => \&es_bulk,
            es_bulk_resp          => \&es_bulk_resp,
            es_check_mapping      => \&es_check_mapping,
            es_check_mapping_resp => \&es_check_mapping_resp,
            es_mapping            => \&es_mapping,
            es_mapping_resp       => \&es_mapping_resp,
        },
        heap => {
            %CONFIG,
            es_ready         => 0,
            stats            => {},
            bulk_queue       => [],
            batch_size       => {},
        },
);

POE::Kernel->run();

sub main_stop {  }

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

    # Run things at intervals
    $kernel->delay( es_bulk => $opt->flush_interval );
    $kernel->delay( stats => $opt->stats_interval );

    # Handle the Mapping bits?
    $kernel->yield('es_check_mapping');
}

sub main_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : {};

    # Collection of the outstanding batches
    foreach my $id ( keys %{ $heap->{batch_size} } ) {
        $stats->{pending} ||= 0;
        $stats->{pending} += $heap->{batch_size}{$id};
    }

    # Send the stats upstream
    #printf STDERR "%s STATS: %s\n", strftime('%T', localtime), join(', ', map { "$_=$stats->{$_}" } sort keys %{ $stats });
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
        push @{ $heap->{bulk_queue} }, @bulk_data;
    }
    else {
        $heap->{stats}{no_schema} ||= 0;
        $heap->{stats}{no_schema}++;
    }
}

sub syslog_error {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    delete $heap->{io};
}

sub es_check_mapping {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $mapping_name = sprintf "%s_mapping", $heap->{es_mapping_name};

    my $req = HTTP::Request->new(GET => sprintf("%s/_template/",$heap->{es_addr}));
    $kernel->post( ua => request => es_check_mapping_resp => $req, $mapping_name );
}

sub es_check_mapping_resp {
    my ($kernel,$heap,$reqs,$resps) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Check Mapping Name Against Return
    my $name = $reqs->[1];

    my $mappings = {};
    eval {
        $mappings = decode_json($resps->[0]->content);
        1;
    } or do {
        printf STDERR "Invalid JSON from the _template end-point.\n";
    };

    if( exists $mappings->{$name} ) {
        $heap->{es_ready} = 1;
        print STDERR "[mapping_exists] Worker ready to index data\n";
    }
    else {
        printf STDERR "Mapping missing, going to attempt creation.\n";
        $kernel->yield( 'es_mapping' );
    }
}

sub es_mapping {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my %mapping = (
        2 => {
            template => "$heap->{es_mapping_name}-*",
            settings => {
                'index.query.default_field' => 'message',
                'index.mapping.ignore_malformed' => 'yes',
            },
            mappings => {
                _default_ => {
                    _all => { enabled => 'false' },
                    dynamic_templates => [
                        { geoip_template => {
                            match   => '*_geoip',
                            mapping => {
                                type  => 'object',
                                enable => 'true',
                                dynamic => 'false',
                                properties => {
                                    city        => { type => 'string', index => 'not_analyzed' },
                                    country     => { type => 'string', index => 'not_analyzed' },
                                    continent   => { type => 'string', index => 'not_analyzed' },
                                    postal_code => { type => 'string', index => 'not_analyzed' },
                                    location    => { type => 'geopoint', lat_lon => 'true' },
                                }
                            },
                        }},
                        { ip_template => {
                            match   => '*_ip',
                            mapping => {
                                type             => 'ip',
                                ignore_malformed => 'true',
                                index            => 'analyzed',
                                doc_values       => 'true',
                            },
                            fields => {
                                raw => {
                                    mapping => {
                                        type => 'string',
                                        index => 'not_analyzed',
                                    }
                                }
                            }
                        }},
                        { string_template => {
                            match_mapping_type => 'string',
                            mapping => {
                                type         => 'string',
                                index        => 'not_analyzed',
                                ignore_above => 256,
                            }
                        }},
                    ],
                    properties => {
                        timing => {
                            type => 'nested',
                            dynamic => 'false',
                            properties => {
                                phase => { type => 'string', index => 'not_analyzed', ignore_above => 80 },
                                seconds => { type => 'float' },
                            }
                        },
                        'timestamp' => {
                            type       => 'date',
                            format     => 'dateTime',
                            index      => 'not_analyzed',
                            doc_values => 'true',
                        },
                        message => {
                            type => 'string',
                            index => 'analyzed',
                            ignore_above => 4096,
                            analyzer => 'whitespace',
                        },
                        raw => {
                            type => 'string',
                            index => 'false',
                        }
                    }
                }
            }
        },
        5 => {
            template => "$heap->{es_mapping_name}-*",
            settings => {
                'index.query.default_field' => 'message',
                'index.mapping.ignore_malformed' => 'yes',
            },
            mappings => {
                _default_ => {
                    _all => { enabled => 'false' },
                    dynamic_templates => [
                        { geoip_template => {
                            match   => '*_geoip',
                            mapping => {
                                type  => 'object',
                                enable => 'true',
                                dynamic => 'false',
                                properties => {
                                    city        => { type => 'keyword' },
                                    country     => { type => 'keyword' },
                                    continent   => { type => 'keyword' },
                                    postal_code => { type => 'keyword' },
                                    location    => { type => 'geopoint', lat_lon => 'true' },
                                }
                            },
                        }},
                        { ip_template => {
                            match   => '*_ip',
                            mapping => {
                                type             => 'ip',
                                ignore_malformed => 'true',
                                index            => 'analyzed',
                                doc_values       => 'true',
                                fields => {
                                    raw => {
                                        type => 'keyword',
                                    },
                                },
                            },
                        }},
                        { string_template => {
                            match_mapping_type => 'string',
                            mapping => {
                                type         => 'keyword',
                                ignore_above => 256,
                            }
                        }},
                    ],
                    properties => {
                        timing => {
                            type => 'nested',
                            dynamic => 'false',
                            properties => {
                                phase => { type => 'keyword', ignore_above => 80 },
                                seconds => { type => 'float' },
                            }
                        },
                        'timestamp' => {
                            type       => 'date',
                            format     => 'date_time||date_time_no_millis||epoch_second',
                            index      => 'not_analyzed',
                        },
                        message => {
                            type => 'text',
                            analyzer => 'whitespace',
                        },
                        raw => {
                            type  => 'text',
                            index => 'false',
                            norms => 'false',
                        },
                    }
                }
            }
        },
    );

    # Build the Request
    my $req = HTTP::Request->new(PUT => sprintf("%s/_template/%s_mapping",$heap->{es_addr},$heap->{es_mapping_name}));
    $req->content(encode_json($mapping{$opt->es_version}));

    # Submmit it
    $kernel->post( ua => request => es_mapping_resp => $req );
}

sub es_mapping_resp {
    my ($kernel,$heap,$reqs,$resps) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Get the response object
    my $resp = $resps->[0];

    if( $resp->is_success ) {
        print STDERR "[mapping_set] Worker ready to index data\n";
        $heap->{es_ready} = 1;
    }
    else {
        printf STDERR "[es_mapping] ERROR: %d HTTP Response, %s\n", $resp->code, $resp->content ? $resp->content : "failed";
    }
}

sub es_bulk {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $bulk = delete $heap->{bulk_queue};

    # Only process and reschedule if we have data
    if( my $docs = scalar @{ $bulk } ) {
        if( $heap->{es_ready} ) {
            my $req = HTTP::Request->new(POST => sprintf "%s/_bulk", $heap->{es_addr});
            $req->header('Content-Type', 'application/x-ndjson');
            $req->content(join '', @{ $bulk });
            my $guid = guid_string();
            $heap->{batch_size}{$guid} = $docs;
            $kernel->post( ua => request => es_bulk_resp => $req, $guid );
        }
        else {
            $heap->{stats}{discarded} ||= 0;
            $heap->{stats}{discarded} += scalar( @{$bulk} ) / 2;
        }
    }
    $heap->{bulk_queue} = [];

    # Reschedule the flush
    $kernel->delay( es_bulk => $opt->flush_interval );
}

sub es_bulk_resp {
    my ($kernel,$heap,$reqs,$resps) = @_[KERNEL,HEAP,ARG0,ARG1];

    # HTTP::Request Object
    my $req  = $reqs->[0];
    my $guid = $reqs->[1];

    # Lookup and delete how many docs in the batch
    my $docs = exists $heap->{batch_size}{$guid} ? delete $heap->{batch_size}{$guid} : 1;

    # HTTP::Response Object
    my $resp = $resps->[0];

    # Record if this was successful or not
    my $stat = sprintf "bulk_%s", $resp->is_success ? 'success' : 'error';
    $heap->{stats}{$stat} ||= 0;
    $heap->{stats}{$stat} += $docs;

    # Spew errors to the parent on STDERR
    unless( $resp->is_success ) {
        print STDERR $resp->content;
        print STDERR $req->content;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-es-indexer.pl - Sample implementation using the eris toolkit to index data to elasticsearch

=head1 VERSION

version 0.004

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
