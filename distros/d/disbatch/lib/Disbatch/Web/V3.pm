package Disbatch::Web::V3;
$Disbatch::Web::V3::VERSION = '4.103';
use 5.12.0;
use warnings;

use Cpanel::JSON::XS;
use Disbatch::Web;	# exports: parse_params send_json_options template
use Limper::SendJSON;
use Limper;
use MongoDB::OID 1.0.4;
use Safe::Isa;
use Time::Moment;
use Try::Tiny;

my $disbatch;

sub init {
    ($disbatch, my $args) = @_;
}

################
#### OLD API ###
################

get '/scheduler-json' => sub {
    undef $disbatch->{mongo};
    send_json $disbatch->scheduler_report_old_api, send_json_options;
};

post '/set-queue-attr-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    my @valid_attributes = qw/threads/;
    unless (grep $_ eq $params->{attr}, @valid_attributes) {
        status 400;
        return send_json { success => 0, error => 'Invalid attr'}, send_json_options;
    }
    unless (defined $params->{value}) {
        status 400;
        return send_json {success => 0, error => 'You must supply a value'}, send_json_options;
    }
    unless (defined $params->{queueid}) {
        status 400;
        return send_json {success => 0, error => 'You must supply a queueid'}, send_json_options;
    }
    my $res = try {
        $disbatch->queues->update_one({_id => MongoDB::OID->new(value => $params->{queueid})}, {'$set' => { $params->{attr} => $params->{value} }});
    } catch {
        Limper::warning "Could not update queue $params->{queueid}: $_";
        $_;
    };
    my $reponse = {
        success => $res->{matched_count} == 1 ? 1 : 0,
        ref $res => {%$res},
    };
    unless ($reponse->{success}) {
        status 400;
        $reponse->{error} = "$res";
    }
    send_json $reponse, send_json_options;
};

sub get_plugins {
    my @plugins = try { $disbatch->queues->distinct('plugin')->all } catch { Limper::warning "Could not get current plugins: $_"; () };
    my $plugins = $disbatch->{config}{plugins} // [];
    my %plugins = map { $_ => $_ } @plugins, @$plugins;
    \%plugins;
}

post '/start-queue-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    unless (defined $params->{type} and defined $params->{name}) {
        status 400;
        return send_json [ 0, 'type and name required'], send_json_options;
    }

    unless (get_plugins->{$params->{type}}) {
        status 400;
        return send_json [ 0, 'unknown type'], send_json_options;
    }

    my $queue = { plugin => $params->{type}, name => $params->{name} };
    my $res = try { $disbatch->queues->insert_one($queue) } catch { Limper::warning "Could not create queue $params->{name}: $_"; $_ };
    my $reponse = {
        success => defined $res->{inserted_id} ? 1 : 0,
        ref $res => {%$res},
    };
    unless ($reponse->{success}) {
        status 400;
        $reponse->{error} = "$res";
    }
    send_json [ $reponse->{success}, $reponse->{ref $res}{inserted_id}, $reponse ], send_json_options;
};

post '/delete-queue-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    unless (defined $params->{id}) {
        status 400;
        return send_json [ 0, 'id required'], send_json_options;
    }

    my $res = try { $disbatch->queues->delete_one({_id => MongoDB::OID->new(value => $params->{id})}) } catch { Limper::warning "Could not delete queue $params->{id}: $_"; $_ };
    my $reponse = {
        success => $res->{deleted_count} ? 1 : 0,
        ref $res => {%$res},
    };
    unless ($reponse->{success}) {
        status 400;
        $reponse->{error} = "$res";
    }
    send_json [ $reponse->{success}, $reponse ], send_json_options;
};

# This is needed at least to create queues in the web interface (just the keys).
get '/queue-prototypes-json' => sub {
    undef $disbatch->{mongo};
    send_json get_plugins, send_json_options;
};

sub get_queue_oid_old {
    my ($queue) = @_;
    my $queue_id = try {
        MongoDB::OID->new(value => $queue);
    } catch {
        my $q = try { $disbatch->queues->find_one({name => $queue}) } catch { Limper::warning "Could not find queue $queue: $_"; undef };
        defined $q ? $q->{_id} : undef;
    };
}

# creates a task for given queue _id and params, returning task _id
sub create_tasks_old {
    my ($queue_id, $tasks) = @_;

    my @tasks = map {
        queue      => $queue_id,
        status     => -2,
        stdout     => undef,
        stderr     => undef,
        node       => undef,
        params     => $_,
        ctime      => Time::Moment->now_utc,
        mtime      => Time::Moment->now_utc,
    }, @$tasks;

    my $res = try { $disbatch->tasks->insert_many(\@tasks) } catch { Limper::warning "Could not create tasks: $_"; $_ };
    $res;
}

post '/queue-create-tasks-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    unless (defined $params->{queueid} and defined $params->{object}) {
        status 400;
        return send_json [ 0, 'queueid and object required'], send_json_options;
    }

    my $tasks = try { ref $params->{object} ? $params->{object} : Cpanel::JSON::XS->new->utf8->decode($params->{object}) } catch { $_ };
    return send_json [ 0, $tasks ], send_json_options unless ref $tasks;
    return send_json [ 0, 'object param must be a JSON array' ], send_json_options unless ref $tasks eq 'ARRAY';

    my $queue_id = get_queue_oid_old($params->{queueid});
    return send_json [ 0, 'Queue not found' ], send_json_options unless defined $queue_id;

    my $res = create_tasks_old($queue_id, $tasks);

    my $reponse = {
        success => @{$res->{inserted}} ? 1 : 0,
        ref $res => {%$res},
    };
    unless ($reponse->{success}) {
        status 400;
        $reponse->{error} = 'Unknown error';
    }
    send_json [ $reponse->{success}, scalar @{$res->{inserted}}, @{$res->{inserted}}, $reponse ], send_json_options;
};

post '/queue-create-tasks-from-query-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    unless (defined $params->{queueid} and defined $params->{collection} and defined $params->{jsonfilter} and defined $params->{params}) {
        status 400;
        return send_json [ 0, 'queueid, collection, jsonfilter, and params required'], send_json_options;
    }

    my $filter = try { ref $params->{jsonfilter} ? $params->{jsonfilter} : Cpanel::JSON::XS->new->utf8->decode($params->{jsonfilter}) } catch { $_ };	# {"migration":"foo"}
    return send_json [ 0, $filter ], send_json_options unless ref $filter;

    my $task_params = try { ref $params->{params} ? $params->{params} : Cpanel::JSON::XS->new->utf8->decode($params->{params}) } catch { $_ };	# {"migration":"document.migration","user1":"document.username"}
    return send_json [ 0, $task_params ], send_json_options unless ref $task_params;

    my $queue_id = get_queue_oid_old($params->{queueid});
    return send_json [ 0, 'Queue not found' ], send_json_options unless defined $queue_id;

    my @fields = grep /^document\./, values %$task_params;
    my %fields = map { s/^document\.//; $_ => 1 } @fields;

    my $cursor = $disbatch->mongo->coll($params->{collection})->find($filter)->fields(\%fields);
    my @tasks;
    my $error;
    try {
        while (my $object = $cursor->next) {
            my $task = { %$task_params };
            for my $key (keys %$task) {
                if ($task->{$key} =~ /^document\./) {
                    for my $field (@fields) {
                        my $f = quotemeta $field;
                        if ($task->{$key} =~ /^document\.$f$/) {
                            $task->{$key} = $object->{$field};
                        }
                    }
                }
            }
            push @tasks, $task;
        }
    } catch {
        Limper::warning "Could not iterate on collection $params->{collection}: $_";
        $error = "$_";
    };

    return send_json [ 0, $error ], send_json_options if defined $error;

    my $res = create_tasks_old($queue_id, \@tasks);	# doing 100k at once only take 12 seconds on my 13" rMBP

    my $reponse = {
        success => @{$res->{inserted}} ? 1 : 0,
        ref $res => {%$res},
    };
    unless ($reponse->{success}) {
        status 400;
        $reponse->{error} = 'Unknown error';
    }
    send_json [ $reponse->{success}, scalar @{$res->{inserted}} ], send_json_options;
#    send_json [ $reponse->{success}, scalar @{$res->{inserted}}, @{$res->{inserted}}, $reponse ], send_json_options;
};

post '/search-tasks-json' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    #unless (defined $params->{queue} and defined $params->{filter}) {
    #    status 400;
    #    return send_json [ 0, 'queue and filter required'], send_json_options;
    #}

    $params->{filter} //= {};
    my $filter = try { ref $params->{filter} ? $params->{filter} : Cpanel::JSON::XS->new->utf8->decode($params->{filter}) } catch { $_ };
    return send_json [ 0, $params->{json} ? $filter : 'JSON object required for filter' ], send_json_options unless ref $filter eq 'HASH';

    my $attrs = {};
    $attrs->{limit} = $params->{limit} if $params->{limit};
    $attrs->{skip}  = $params->{skip}  if $params->{skip};

    my $error;
    try {
        $filter->{queue} = MongoDB::OID->new(value => $params->{queue}) if $params->{queue};
        $filter->{_id} = MongoDB::OID->new(value => delete $filter->{id}) if $filter->{id};
    } catch {
        $error = "$_";
        Limper::warning "Bad OID passed: $error";
    };
    return send_json [ 0, $error ], send_json_options if defined $error;
    $filter->{status} = int $filter->{status} if defined $filter->{status};

    if ($params->{count}) {
        my $count = try { $disbatch->tasks->count($filter) } catch { Limper::warning $_; $_; };
        return send_json [ 0, "$count" ], send_json_options if ref $count;
        return send_json [ 1, $count ], send_json_options;
    }
    my @tasks = try { $disbatch->tasks->find($filter, $attrs)->all } catch { Limper::warning "Could not find tasks: $_"; () };

    for my $task (@tasks) {
        if ($params->{terse}) {
            $task->{stdout} = '[terse mode]' unless $task->{stdout}->$_isa('MongoDB::OID');
            $task->{stderr} = '[terse mode]' unless $task->{stderr}->$_isa('MongoDB::OID');
        } else {
            $task->{stdout} = try { $disbatch->get_gfs($task->{stdout}) } catch { Limper::warning "Could not get task $task->{_id} stdout: $_"; $task->{stdout} } if $task->{stdout}->$_isa('MongoDB::OID');
            $task->{stderr} = try { $disbatch->get_gfs($task->{stderr}) } catch { Limper::warning "Could not get task $task->{_id} stderr: $_"; $task->{stderr} } if $task->{stderr}->$_isa('MongoDB::OID');
        }

        for my $type (qw/ctime mtime/) {
            if ($task->{$type}) {
                if (ref $task->{$type}) {
                    if (ref $task->{$type} eq 'Time::Moment' or ref $task->{$type} eq 'DateTime') {
                        $task->{"${type}_str"} = "$task->{$type}";
                        $task->{$type} = $task->{$type}->epoch;
                    } else {
                        # Unknown ref, force to string
                        $task->{"${type}_str"} = "$task->{$type}";
                        $task->{$type} = undef;
                    }
                } else {
                    try {
                        my $dt = DateTime->from_epoch(epoch => $task->{$type});
                        $task->{"${type}_str"} = "$dt";
                    } catch {
                        $task->{"${type}_str"} = "$task->{$type}";
                        $task->{$type} = undef;
                    };
                }
            }
        }
    }

    send_json \@tasks, send_json_options;
};

1;

=encoding utf8

=head1 NAME

Disbatch::Web::V3 - Disbatch::Web routes for deprecated v3 API

=head1 VERSION

version 4.103

=head1 DEPRECATION NOTICE

This is deprecated as of Disbatch 4.0 and may be removed in Disbatch 4.2.

=head1 NOTE

These routes were formerly in L<Disbatch::Web>, but moved here. They are not loaded by default. They will not be documented.

=head1 SEE ALSO

L<Disbatch::Web>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

Matt Busigin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
