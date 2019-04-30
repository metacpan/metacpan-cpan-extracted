package Disbatch::Web;
$Disbatch::Web::VERSION = '4.102';
use 5.12.0;
use strict;
use warnings;

use Clone qw/clone/;
use Cpanel::JSON::XS;
use Data::Dumper;
use Disbatch;
use Exporter qw/ import /;
use File::Slurp;
use Limper::SendFile;	# needed for public()
use Limper::SendJSON;
use Limper 0.014;
use MongoDB::OID 1.0.4;
use Safe::Isa;
use Scalar::Util qw/ looks_like_number /;
use Template;
use Time::Moment;
use Try::Tiny::Retry;
use URL::Encode qw/url_params_mixed/;

our @EXPORT = qw/ parse_params send_json_options template /;

my $oid_keys = [ qw/ queue / ];	# NOTE: in addition to _id

sub send_json_options { allow_blessed => 1, canonical => 1, convert_blessed => 1 }

my $tt;

# this should be compatible with Dancer's template(), except we do not support the optional settings (third value), and it was unused by RemoteControl
sub template {
    my ($template, $params) = @_;
    my $output = '';
    $params->{perl_version} = $];
    $params->{limper_version} = $Limper::VERSION;
    $params->{request} = request;
    $tt->process($template, $params, \$output) || die $tt->error();
    headers 'Content-Type' => 'text/html';
    $output;
}

my $disbatch;

sub init {
    my $args = { @_ };
    $disbatch = Disbatch->new(class => 'Disbatch::Web', config_file => ($args->{config_file} // '/etc/disbatch/config.json'));
    $disbatch->load_config;
    public ($disbatch->{config}{web_root} // '/etc/disbatch/htdocs/');
    for my $plugin (keys %{$disbatch->{config}{web_extensions} // {}}) {
        if ($plugin !~ /^[\w:]+$/) {
            Limper::warning "Illegal plugin value: $plugin, ignored";
        } elsif (eval "require $plugin") {
            Limper::info "$plugin found and loaded";
            no strict 'refs';
            ${"${plugin}::"}{init}->($disbatch, $disbatch->{config}{web_extensions}{$plugin}) if $plugin->can('init');
        } else {
            Limper::warning "Could not load $plugin, ignored";
        }
    }
    require Disbatch::Web::Files;	# this has a catch-all to send any matching file in the public root directory, so must be loaded last.
    # the following options should be compatible with previous Dancer usage:
    $tt = Template->new(ANYCASE => 1, ABSOLUTE => 1, ENCODING => 'utf8', INCLUDE_PATH => $disbatch->{config}{views_dir} // '/etc/disbatch/views/', START_TAG => '\[%', END_TAG => '%\]', WRAPPER => 'layouts/main.tt');
}

sub parse_params {
    my $params = {};
    if ((request->{headers}{'content-type'} // '') eq 'application/x-www-form-urlencoded') {
        $params = url_params_mixed(request->{body}, 1);
    } elsif ((request->{headers}{'content-type'} // '') eq 'application/json') {
        $params = try { Cpanel::JSON::XS->new->utf8->decode(request->{body}) } catch { $_ };
    } elsif (request->{query}) {
        $params = url_params_mixed(request->{query}, 1);
    }
    my $options = { map { $_ => delete $params->{$_} } grep { /^\./ } keys %$params } if ref $params eq 'HASH';	# put fields starting with '.' into their own HASH
    # NOTE: $options may contain: .limit .skip .count .pretty .terse .epoch
    wantarray ? ($params, $options) : $params;
}

sub parse_accept {
    +{ map { @_ = split(/;q=/, $_); $_[0] => $_[1] // 1 } split /,\s*/, request->{headers}{accept} // '' };
}

sub want_json {
    my $accept = parse_accept;
    # prefer 'text/html' over 'application/json' if equal, but default to 'application/json'
    ($accept->{'text/html'} // 0) >= ($accept->{'application/json'} // 1) ? 0 : 1;
}

################
#### NEW API ###
################

get '/' => sub {
    # NOTE: not doing just "template 'index.tt', $params;" because not using WRAPPER here
    my $tt = Template->new(ANYCASE => 1, ABSOLUTE => 1, ENCODING => 'utf8', INCLUDE_PATH => $disbatch->{config}{views_dir} // '/etc/disbatch/views/', START_TAG => '\[%', END_TAG => '%\]');
    my $output = '';
    my $params = { database => $disbatch->{config}{database}, web_extensions => [sort keys %{$disbatch->{config}{web_extensions} // {}}], get_routes => [ grep { m{^/} } sort keys +{@{Limper::routes('GET')}} ] };
    $tt->process('index.tt', $params, \$output) || die $tt->error();
    headers 'Content-Type' => 'text/html';
    $output;
};

get '/info' => sub {
    my $routes = Limper::routes;	# WARNING: do not modify $routes, it is a footgun!
    my %routes;
    for my $verb (keys %$routes) {
        # this takes just the even elements of @{$routes->{$verb}} and ensures they are strings, keeping their order
        $routes{$verb} = [ map { $routes->{$verb}[$_*2] . "" } (0..@{$routes->{$verb}}/2-1) ];
    }
    my $info = { database => $disbatch->{config}{database}, web_extensions => [sort keys %{$disbatch->{config}{web_extensions} // {}}], routes => \%routes };
    send_json $info, send_json_options;
};

sub datetime_to_millisecond_epoch {
    int($_[0]->hires_epoch * 1000);
}

# will throw errors
sub get_nodes {
    my ($filter) = @_;
    $filter //= {};
    my @nodes = $disbatch->nodes->find($filter)->sort({node => 1})->all;
    for my $node (@nodes) {
        $node->{id} = "$node->{_id}";
        $node->{timestamp} = datetime_to_millisecond_epoch($node->{timestamp}) if ref $node->{timestamp} eq 'DateTime';
    }
    \@nodes;
}

get '/nodes' => sub {
    undef $disbatch->{mongo};
    my $nodes = try { get_nodes } catch { status 400; "Could not get current nodes: $_" };
    if ((status() // 200) == 400) {
        Limper::warning $nodes;
        return send_json { error => $nodes }, send_json_options;
    }
    send_json $nodes, send_json_options;
};

get qr'^/nodes/(?<node>.+)' => sub {
    undef $disbatch->{mongo};
    my $filter = try { {_id => MongoDB::OID->new(value => $+{node})} } catch { {node => $+{node}} };
    my $node = try { get_nodes($filter) } catch { status 400; "Could not get node $+{node}: $_" };
    if ((status() // 200) == 400) {
        Limper::warning $node;
        return send_json { error => $node }, send_json_options;
    }
    send_json $node->[0], send_json_options;
};

#  postJSON('/nodes/' + row.rowId , { maxthreads: newValue}, loadQueues);
post qr'^/nodes/(?<node>.+)' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;

    unless (keys %$params) {
        status 400;
        return send_json {error => 'No params'}, send_json_options;
    }
    my @valid_params = qw/maxthreads/;
    for my $param (keys %$params) {
        unless (grep $_ eq $param, @valid_params) {
            status 400;
            return send_json { error => 'Invalid param', param => $param}, send_json_options;
        }
    }
    my $node = $+{node};	# regex on next line clears $+
    if (exists $params->{maxthreads} and defined $params->{maxthreads} and $params->{maxthreads} !~ /^\d+$/) {
        status 400;
        return send_json {error => 'maxthreads must be a non-negative integer or null'}, send_json_options;
    }
    my $filter = try { {_id => MongoDB::OID->new(value => $node)} } catch { {node => $node} };
    my $res = try {
        $disbatch->nodes->update_one($filter, {'$set' => $params});
    } catch {
        Limper::warning "Could not update node $node: $_";
        $_;
    };
    my $reponse = {
        ref $res => {%$res},
    };
    unless ($res->{matched_count} == 1) {
        status 400;
        if ($res->$_isa('MongoDB::UpdateResult')) {
            $reponse->{error} = $reponse->{'MongoDB::UpdateResult'};
        } else {
            $reponse->{error} = "$res";
        }
    }
    send_json $reponse, send_json_options;
};

# This is needed at least to create queues in the web interface.
get '/plugins' => sub {
    send_json $disbatch->{config}{plugins}, send_json_options;
};

get '/queues' => sub {
    undef $disbatch->{mongo};
    my $queues = try { $disbatch->scheduler_report } catch { status 400; "Could not get current queues: $_" };
    if ((status() // 200) == 400) {
        Limper::warning $queues;
        return send_json { error => $queues }, send_json_options;
    }
    send_json $queues, send_json_options;
};

get qr'^/queues/(?<queue>.+)$' => sub {
    undef $disbatch->{mongo};

    my $key = try { MongoDB::OID->new(value => $+{queue}); 'id' } catch { 'name' };
    my $queues = try { $disbatch->scheduler_report } catch { status 400; "Could not get current queues: $_" };
    if ((status() // 200) == 400) {
        Limper::warning $queues;
        return send_json { error => $queues }, send_json_options;
    }
    my ($queue) = grep { $_->{$key} eq $+{queue} } @$queues;
    send_json $queue, send_json_options;
};

sub map_plugins {
    my %plugins = map { $_ => 1 } @{$disbatch->{config}{plugins}};
    \%plugins;
}

post '/queues' => sub {
    undef $disbatch->{mongo};
    my $params = parse_params;
    unless (($params->{name} // '') and ($params->{plugin} // '')) {
        status 400;
        return send_json { error => 'name and plugin required' }, send_json_options;
    }
    my @valid_params = qw/name plugin/;
    for my $param (keys %$params) {
        unless (grep $_ eq $param, @valid_params) {
            status 400;
            return send_json { error => 'Invalid param', param => $param}, send_json_options;
        }
    }
    unless (map_plugins->{$params->{plugin}}) {
        status 400;
        return send_json { error => 'Unknown plugin', plugin => $params->{plugin} }, send_json_options;
    }

    my $res = try { $disbatch->queues->insert_one($params) } catch { Limper::warning "Could not create queue $params->{name}: $_"; $_ };
    my $reponse = {
        ref $res => {%$res},
        id => $res->{inserted_id},
    };
    unless (defined $res->{inserted_id}) {
        status 400;
        $reponse->{error} = "$res";
        $reponse->{ref $res}{result} = { ref $reponse->{ref $res}{result} => {%{$reponse->{ref $res}{result}}} } if ref $reponse->{ref $res}{result};
    }
    send_json $reponse, send_json_options;
};

post qr'^/queues/(?<queue>.+)$' => sub {
    my $queue = $+{queue};
    undef $disbatch->{mongo};
    my $params = parse_params;
    my @valid_params = qw/threads name plugin/;

    unless (keys %$params) {
        status 400;
        return send_json {error => 'no params'}, send_json_options;
    }
    for my $param (keys %$params) {
        unless (grep $_ eq $param, @valid_params) {
            status 400;
            return send_json { error => 'unknown param', param => $param}, send_json_options;
        }
    }
    if (exists $params->{plugin} and !map_plugins()->{$params->{plugin}}) {
        status 400;
        return send_json { error => 'unknown plugin', plugin => $params->{plugin} }, send_json_options;
    }
    if (exists $params->{threads} and $params->{threads} !~ /^\d+$/) {
        status 400;
        return send_json {error => 'threads must be a non-negative integer'}, send_json_options;
    }
    if (exists $params->{name} and (ref $params->{name} or !($params->{name} // ''))){
        status 400;
        return send_json {error => 'name must be a string'}, send_json_options;
    }

    my $filter = try { {_id => MongoDB::OID->new(value => $queue)} } catch { {name => $queue} };
    my $res = try {
        $disbatch->queues->update_one($filter, {'$set' => $params});
    } catch {
        Limper::warning "Could not update queue $queue: $_";
        $_;
    };
    my $reponse = {
        ref $res => {%$res},
    };
    unless ($res->{matched_count} == 1) {
        status 400;
        $reponse->{error} = "$res";
    }
    send_json $reponse, send_json_options;
};

del qr'^/queues/(?<queue>.+)$' => sub {
    undef $disbatch->{mongo};

    my $filter = try { {_id => MongoDB::OID->new(value => $+{queue})} } catch { {name => $+{queue}} };
    my $res = try { $disbatch->queues->delete_one($filter) } catch { Limper::warning "Could not delete queue '$+{queue}': $_"; $_ };
    my $reponse = {
        ref $res => {%$res},
    };
    unless ($res->{deleted_count}) {
        status 400;
        $reponse->{error} = "$res";
    }
    send_json $reponse, send_json_options;
};

# returns an MongoDB::OID object of either a simple string representation of the OID or a queue name, or undef if queue not found/valid
sub get_queue_oid {
    my ($queue) = @_;
    my $queue_id = try {
        $disbatch->queues->find_one({_id => MongoDB::OID->new(value => $queue)});
    } catch {
        try { $disbatch->queues->find_one({name => $queue}) } catch { Limper::warning "Could not find queue $queue: $_"; undef };
    };
    defined $queue_id ? $queue_id->{_id} : undef;
}

# creates a task for given queue _id and params, returning task _id
sub create_tasks {
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

sub post_tasks {
    my ($legacy_params) = @_;
    undef $disbatch->{mongo};
    my $params = parse_params;
    # NEW:
    # { "queue": queue, "params": single_task_params }
    # { "queue": queue, "params": [single_task_params, another_task_params, ...] }
    # { "queue": queue, "params": generic_task_params, "collection": collection, "filter": collection_filter }

    $params = { params => $params } if ref $params eq 'ARRAY';
    $params = { %$params, %$legacy_params } if defined $legacy_params;

    my $queue_id = get_queue_oid($params->{queue});
    unless (defined $queue_id) {
        status 400;
        return send_json { error => 'queue not found' }, send_json_options;
    }

    my $task_params = $params->{params};
    my $keys = join(',', sort keys %$params);
    # { "queue": queue, "params": single_task_params }
    # NOTE: wait does anything use this??
    if ($keys eq 'params,queue' and ref $task_params eq 'HASH') {
        $task_params = [$task_params];
    }
    # { "queue": queue, "params": [single_task_params, another_task_params, ...] }
    if ($keys eq 'params,queue' and ref $task_params eq 'ARRAY') {
        # validate array of hash params
        if (!@$task_params or grep { ref $_ ne 'HASH' } @$task_params) {
            status 400;
            return send_json { error => "'params' must be a JSON array of task params objects" }, send_json_options;
        } elsif (grep { keys %$_ == 0 } @$task_params) {
            status 400;
            return send_json { error => "'params' must be a JSON array of task params objects with key/value pairs" }, send_json_options;
        }
        # $task_params is ready
    # { "queue": queue, "params": generic_task_params, "collection": collection, "filter": collection_filter }
    } elsif ($keys eq 'collection,filter,params,queue' and ref $task_params eq 'HASH') {
        # validate and parse
        # {"migration":"foo"}
        # {"migration":"document.migration","user1":"document.username"}
        if (ref $params->{filter} ne 'HASH') {
            status 400;
            return send_json { error => "'filter' must be a JSON object" }, send_json_options;
        } elsif (!ref $params->{collection} eq '' or !$params->{collection}) {
            status 400;
            return send_json { error => "'collection' required and must be a scalar (string)'" }, send_json_options;
        }

        my @fields = grep /^document\./, values %$task_params;
        my %fields = map { s/^document\.//; $_ => 1 } @fields;

        my $cursor = $disbatch->mongo->coll($params->{collection})->find($params->{filter})->fields(\%fields);
        # FIXME: maybe fail unless $cursor->has_next
        my @tasks;
        my $error;
        try {
            # NOTE: yes, this loads all of them into @tasks
            while (my $doc = $cursor->next) {
                my $task = clone $task_params;
                for my $key (keys %$task) {
                    if ($task->{$key} =~ /^document\./) {
                        for my $field (@fields) {
                            my $f = quotemeta $field;
                            if ($task->{$key} =~ /^document\.$f$/) {
                                $task->{$key} = $doc->{$field};
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
        if (defined $error) {
            status 400;
            return send_json { error => $error }, send_json_options;
        }
        $task_params = \@tasks;
        # $task_params is ready
    } else {
        # fail
        status 400;
        return send_json { error => 'invalid parameters passed' }, send_json_options;
    }

    my $res = create_tasks($queue_id, $task_params);	# doing 100k at once only take 12 seconds on my 13" rMBP

    my $reponse = {
        ref $res => {%$res},
    };
    unless (@{$res->{inserted}}) {
        status 400;
        $reponse->{error} = 'Unknown error';
    }
    send_json $reponse, send_json_options;
};

post '/tasks' => sub {
    post_tasks();
};

# NOTE: i hate this, but it should maybe be here for backcompat
sub _munge_tasks {
    my ($tasks, $options) = @_;
    $tasks = [$tasks] if ref $tasks eq 'HASH';	# NOTE: if $options->{'.limit'} is 1
    for my $task (@$tasks) {
        for my $type (qw/stdout stderr/) {
            if ($options->{'.terse'}) {
                $task->{$type} = '[terse mode]' if defined $task->{$type} and !$task->{$type}->$_isa('MongoDB::OID') and $task->{$type};
            } elsif ($options->{'.full'} // 0 and $task->{$type}->$_isa('MongoDB::OID')) {
                $task->{$type} = try { $disbatch->get_gfs($task->{$type}) } catch { Limper::warning "Could not get task $task->{_id} $type: $_"; $task->{$type} };
            }
        }
        if ($options->{'.epoch'}) {
            for my $type (qw/ctime mtime/) {
                $task->{$type} = $task->{$type}->hires_epoch if ref $task->{$type} eq 'DateTime';
            }
        }
    }
}

# FIXME: in query.tt at least toggleGroup() should run at $(document).ready() when returning a form because of invalid params, instead of only showing the limit (bug is there, not at all here)
get '/tasks' => sub {
    undef $disbatch->{mongo};	# FIXME: why is this added?
    my ($params, $options) = parse_params;	# NOTE: $options may contain: .limit .skip .count .pretty .terse .epoch .full
    $params = undef if defined $params and $params eq '';	# FIXME: maybe move to parse_params() above
    my $want_json = want_json;

    my $indexes = get_indexes($disbatch->tasks);
    my $schema = {
            verb => 'GET',
            limit => 100,
            title => 'Disbatch Tasks Query',
            subtitle => 'Warning: this can return a LOT of data!',
            params => +{ map { map { $_ => { repeatable => 'yes', type => ['string' ]} } @$_ } @$indexes },
    };
    if (!$want_json and !%$params and !%$options) {
        my $result = { schema => $schema, indexes => $indexes };
        return template 'query.tt', $result;
    }

    my $result = query($params, $options, $schema->{title}, $oid_keys, $disbatch->tasks, request->{path}, $want_json, $indexes);
    if ($want_json) {
        status 400 if ref $result ne 'ARRAY' and exists $result->{error};
        _munge_tasks($result, $options);
        send_json $result, send_json_options, pretty => $options->{'.pretty'} // 0;
    } else {
        if (exists $result->{error}) {
            $result->{schema} = $schema;
            $result->{schema}{error} = $result->{error};
            status 400;
        }
        _munge_tasks($result, $options);	# FIXME: do we want _munge_tasks() here too? well let's TIAS
        template 'query.tt', $result;
    }
};

get qr'^/tasks/(?<id>[0-9a-f]{24})$' => sub {
    my $title = "Disbatch Single Task Query";
    my $want_json = want_json;
    my $result = query({id => $+{id}}, {'.limit' => 1}, $title, $oid_keys, $disbatch->tasks, request->{path}, $want_json, [['id']]);
    if ($want_json) {
        if (!keys %$result) {
            status 404;
            $result = { error => "no task with id $+{id}" };
        } elsif (exists $result->{error}) {
            status 400;
        }
        send_json $result, send_json_options, pretty => 1;
    } else {
        if (!defined $result->{result}) {
            status 404;
        } elsif (exists $result->{error}) {
            status 400;
        }
        template 'query.tt', $result;
    }
};

sub get_balance {
    my $balance = $disbatch->balance->find_one() // { notice => 'balance document not found' };
    delete $balance->{_id};
    $balance->{known_queues} = [ $disbatch->queues->distinct("name")->all ];
    $balance->{settings} = $disbatch->{config}{balance};	# { log => 1, verbose => 0, pretend => 0, enabled => 0 }
    $balance;
}

sub post_balance {
    my $params = parse_params;

    # TODO: make this not all hardcoded:
    my $error = try {
        die join(',', sort keys %$params) unless join(',', sort keys %$params) =~ /^(?:disabled,)?max_tasks,queues$/;

        if (defined $params->{disabled}) {
            die unless $params->{disabled} =~ /^\d+$/;
            die if $params->{disabled} and $params->{disabled} < time;
        }

        die unless ref $params->{queues} eq 'ARRAY';
        ref $_ eq 'ARRAY' or die for @{$params->{queues}};
        my @q;
        my @known_queues = $disbatch->queues->distinct("name")->all;
        for my $q (@{$params->{queues}}) {
            ref $_ and die ref $_ for @$q;
            /^[\w-]+$/ or die for @$q;
            for my $e (@$q) {
                grep { /^$e$/ } @known_queues or die;
            }
            push @q, @$q;
        }
        my %q = map { $_ => undef } @q;
        die unless @q == keys %q;
        die unless join(',', sort @q) eq join(',', sort keys %q);

        die unless ref $params->{max_tasks} eq 'HASH';
        /^\d+$/ or die for values %{$params->{max_tasks}};
        /^[*0-6] (?:[01]\d|2[0-3]):[0-5]\d$/ or die for keys %{$params->{max_tasks}};
        return undef;
    } catch {
        status 400;
        return { status => 'failed: invalid json passed ' . $_ };
    };
    return $error if defined $error;

    $_ += 0 for values %{$params->{max_tasks}};

    $disbatch->balance->update_one({}, {'$set' => $params }, {upsert => 1});
    { status => 'success: queuebalance modified' };
};

get '/balance' => sub {
    my $want_json = want_json;
    if ($want_json) {
        send_json get_balance(), send_json_options, pretty => 1;
    } else {
        template 'balance.tt', get_balance();
    }
};

post '/balance' => sub {
    send_json post_balance(), send_json_options;
};

# For Disbatch basic status.
# Returns hash with keys status and message.
# NOTE: this *is* disbatch (web). but we now check if any nodes are running, instead of if the web server is running on a list of hosts (as old disbatch was monolithic)
sub check_disbatch {
    try {
        # $nodes is an ARRAY of nodes, each HASH has a 'timestamp' field (in ms) so you can tell if it's running, as well as 'node' and 'id'
        my $nodes = get_nodes;
        if (!@$nodes) {
            return { status => 'WARNING', message => 'No Disbatch nodes found' };
        }
        my $status = {};
        my $now = time;
        for my $node (@$nodes) {
            my $timestamp = int($node->{timestamp} / 1000);
            if ($timestamp + 60 < $now) {
                # old
                $status->{stale}{$node->{node}} = $now - $timestamp;
            } else {
                $status->{fresh}{$node->{node}} = $now - $timestamp;
            }
        }
        if (keys %{$status->{fresh}}) {
            return { status => 'OK', message => 'Disbatch is running on one or more nodes', nodes => $status };
        } else {
            return { status => 'CRITICAL', message => 'No active Disbatch nodes found', nodes => $status };
        }
    } catch {
        return { status => 'CRITICAL', message => "Could not get current Disbatch nodes: $_" };
    };
}

sub check_queuebalance {
    return { status => 'OK', message => 'queuebalance disabled' } unless $disbatch->{config}{balance}{enabled};
    # FIXME: return some sort of OK status if 'balance' collection doesn't exist (no QueueBalance) or $qb below is undef
    my $qb = $disbatch->balance->find_one({}, {status => 1, message => 1, timestamp => 1, _id => 0});
    return $qb if $qb->{status} eq 'CRITICAL' and !exists $qb->{timestamp}; # error via _mongo()	# FIXME: this will never happen because rewrite (wait why??), but maybe should check for timestamp anyway
    my $timestamp = delete $qb->{timestamp};
    return { status => 'CRITICAL' , message => 'queuebalanced not running for ' . (time - $timestamp) . 's' } if $timestamp < time - 60;
    return $qb if $qb->{status} =~ /^(?:OK|WARNING|CRITICAL)$/;
    return { status => 'CRITICAL', message => 'queuebalanced unknown status', result => $qb };
}

sub checks {
    my $checks = {};
    if ($disbatch->{config}{monitoring}) {
        $checks->{disbatch} = check_disbatch();
        $checks->{queuebalance} = check_queuebalance();
    } else {
        $checks->{disbatch} = { status => 'OK', message => 'monitoring disabled' };
        $checks->{queuebalance} = { status => 'OK', message => 'monitoring disabled' };
    }
    $checks;
}

get '/monitoring' => sub {
    send_json checks(), send_json_options;
};

sub get_indexes {
    my ($coll) = @_;
    my @indexes = $coll->indexes->list->all;
    my %names = map { $_->{name} =~ s/_-1(_|$)/_1$1/; $_->{name} => $_ } @indexes;
    my @parsed;
    for my $name (sort keys %names) {
        next if grep { my $qm = quotemeta $name; $_ =~ /^$qm.+/ } keys %names;	# $name is a subset of another index, so ignore it
        my $count = keys %{$names{$name}{key}};
        $names{$name}{name} =~ s/_1$//;
        my @array = split /_1_/, $names{$name}{name}, $count;
        die "Couldn't parse index: ", Cpanel::JSON::XS->new->convert_blessed->allow_blessed->pretty->encode($names{$name}) unless $count == @array;
        $array[0] = '_id' if $array[0] eq '_id_';	# damn mongo for it ending in '_'
        map { $array[$_] = 'id' if $array[$_] eq '_id' } 0..@array-1;	# damn T::T
        push @parsed, \@array;
    }
    \@parsed;
}

sub invalid_params {
    my ($params, $indexes) = @_;
    my @invalid;
    param: for my $param (keys %$params) {
        # 2. if param is part of an index, and every part of the index to its left is a param, it's good
        for my $compound (@$indexes) {
            if (grep { $param eq $_ } @$compound) {
                # we know at least this param is part of this index
                my $good = 1;
                for my $i (@$compound) {
                    $good = 0 unless grep {$i eq $_ } keys %$params;	# part of the prefix is not indexed
                    last if !$good or $i eq $param;
                }
                next param if $good;
            }
        }
        # 3. otherwise, it's bad
        push @invalid, $param;
    }
    @invalid;
}

sub params_to_query {
    my ($params, $oid_keys) = @_;
    # build a query:
    my @and = ();
    while (my ($k, $v) = each %$params) {
        next if $v eq '';
        if ($k eq 'id' or grep { $k eq $_ } @$oid_keys) {
            # TT doesn't like keys starting with an underscore:
            $k = '_id' if $k eq 'id';
            # change $v into an ObjectId / ARRAY of ObectIds:
            push @and, ref($v) eq 'ARRAY'
                ? { '$or' => [ map { MongoDB::OID->new(value => $_) } @$v ] }
                : { $k => MongoDB::OID->new(value => $v) };
        } elsif (looks_like_number(ref $v eq 'ARRAY' ? $v->[0] : $v)) {	# NOTE: this only checks the first element in @$v
            push @and, ref($v) eq 'ARRAY'
                ? { '$or' => [ map { { $k => 0 + $_ } } @$v ] }
                : { $k => 0 + $v };
        } else {
            push @and, ref($v) eq 'ARRAY'
                ? { '$or' => [ map { { $k => $_ } } @$v ] }
                : { $k => $v };
        }
    }
    @and ? { '$and' => \@and } : {};
}

# get_indexes() invalid_params() params_to_query()
# FIXME: i hate this code
sub query {
    my ($params, $options, $title, $oid_keys, $collection, $path, $raw, $indexes) = @_;
    $options //= {};	# .count .limit .skip .fields
    $title //= '';
    $indexes //= get_indexes($collection);

    my $fields = $options->{'.fields'} || {};
    my $limit = $options->{'.limit'} || 0;
    my $skip = $options->{'.skip'} || 0;

    # FIXME: maybe move this $fields modification to parse_params()
    $fields = Cpanel::JSON::XS->new->utf8->decode($fields) unless ref $fields;	# NOTE: i don't like embedding json in url params	# FIXME: catch and return error
    $fields = { map { $_ => 1 } @$fields } if ref $fields eq 'ARRAY';

    # can only query indexed fields
    my @invalid_params = invalid_params($params, $indexes);
    return { title => $title, path => $path, error => 'non-indexed params given', invalid_params => \@invalid_params, indexes => $indexes } if @invalid_params;

    my $query = params_to_query($params, $oid_keys);

    return { count => $collection->count($query) } if $options->{'.count'};

    # we don't want to return the entire collection
    return { title => $title, path => $path, error => 'refusing to return everything - include one or more indexed search restrictions', indexes => $indexes } unless keys %$query or $limit > 0;

    my @documents = $collection->find($query)->fields($fields)->limit($limit)->skip($skip)->all;

    if ($raw // 0) {
        # FIXME: return [] if no @documents unless $limit == 1, then maybe return undef
        return {} unless @documents;
        return ($limit == 1 ? $documents[0] : \@documents);
    }

    # need allow_blessed for some reason because analysed value is a boolean. convert_blessed messes this up, but is needed for OIDs.
    my $documents = Cpanel::JSON::XS->new->convert_blessed->allow_blessed->pretty->encode($limit == 1 ? $documents[0] : \@documents) if @documents;
    my $result = {
        result  => $documents,
        title   => "$title Results",
        count   => scalar @documents,
        limit   => $limit,
        skip    => $skip,
        params_str  => join('&', map { "$_=$params->{$_}" } keys %$params),	# FIXME: maybe we need $options in here too
        mypath => $path,
    };

    $result->{json} = $documents[0] if $limit == 1;

    return $result;
}

1;

__END__

=encoding utf8

=head1 NAME

Disbatch::Web - Disbatch Command Interface (JSON REST API and web browser interface to Disbatch).

=head1 VERSION

version 4.102

=head1 EXPORTED

parse_params, send_json_options, template

=head1 SUBROUTINES

=over 2

=item init(config_file => $config_file)

Parameters: path to the Disbatch config file. Default is C</etc/disbatch/config.json>.

Initializes the settings for the web server, including loading any custom routes via C<config.web_extensions> (see L<CUSTOM ROUTES> below).

Returns nothing.

=item template($template, $params)

Parameters: template (C<.tt>) file name in the C<config.views_dir> directory, C<HASH> of parameters for the template.

Creates a web page based on the passed data.

Sets C<Content-Type> to C<text/html>.

Returns the generated html document.

NOTE: this sub is automatically exported, so any package using L<Disbatch::Web> can call it.

=item parse_params

Parameters: none

Parses request parameters in the following order:

* from the request body if the Content-Type is C<application/x-www-form-urlencoded>

* from the request body if the Content-Type is C<application/json>

* from the request query otherwise

It then puts any fields starting with C<.> into their own C<HASH> C<$options>.

Returns the C<HASH> of the parsed request parameters, and if C<wantarray> also returns the C<HASH> of options.

NOTE: this sub is automatically exported, so any package using L<Disbatch::Web> can call it.

=item send_json_options

Parameters: none

Used to enable the following options when returning JSON: C<allow_blessed>, C<canonical>, and C<convert_blessed>.

Returns a C<list> of key/value pairs of options to pass to C<send_json>.

NOTE: this sub is automatically exported, so any package using L<Disbatch::Web> can call it.

=item parse_accept

Parameters: none

Parses C<Accept> header.

Returns a C<HASH> where keys are types and values are q-factor weights.

=item want_json

Parameters: none

Returns true if C<Accept> header has C<application/json> with a higher q-factor weight than C<text/html>.

Note: if not specified, C<text/html> has an assumed q-factor weight of C<0> and C<application/json> has an assumed q-factor weight of C<1>.

=item get_nodes

Parameters: none

Returns an array of node objects defined, with C<timestamp> stringified and C<id> the stringified C<_id>.

=item get_plugins

Parameters: none

Returns a C<HASH> of defined queues plugins and any defined C<config.plugins>, where values match the keys.

=item get_queue_oid($queue)

Parameters: Queue ID as a string, or queue name.

Returns a C<MongoDB::OID> object representing this queue's _id.

=item create_tasks($queue_id, $tasks)

Parameters: C<MongoDB::OID> object of the queue _id, C<ARRAY> of task params.

Creates one queued task document for the given queue _id per C<$tasks> entry. Each C<$task> entry becomes the value of the C<params> field of the document.

Returns: the repsonse object from a C<MongoDB::Collection#insert_many> request.

=item post_tasks($legacy_params)

Parameters: legacy params (optional, used by routes in Disbatch::Web::Tasks), also parses request parameters

Handles creating tasks to insert, and then creates them via C<create_tasks()>. See C<POST /tasks> below for usage.

Returns the resonse of C<create_tasks()> as JSON with the key the ref type of the response and the value the response turned into a C<HASH>,
or on error sets HTTP status to C<400> and returns JSON of C<{"error":message}>.

=item _munge_tasks($tasks, $options)

Parameters: C<ARRAY> of task documents, C<HASH> of param options

Options handled are C<.terse>, C<.full>, and C<.epoch>, all booleans.

If C<.terse>, C<stdout> and C<stderr> values of each document will be C<[terse mode]> if defined and not a L<MongoDB::OID> object.
Else if C<.full>, C<stdout> and C<stderr> values of each document will be actual content instead of L<MongoDB::OID> objects.
If C<.epoch>, C<ctime> and C<mtime> will be turned into C<hires_epoch> (ex: C<1548272576.574>) insteaad of stringified (ex: C<2019-01-23T19:42:56>) if they are C<DateTime> objects.

Returns nothing, modifies passed tasks.

=item get_balance

Parameters: none

Returns a C<HASH> of the balance doc without the C<_id> field, with the following added:
field C<known_queues> with value an C<ARRAY> of all existing queue names, field C<settings> with value the C<HASH> of C<config.balance>.
If the balance doc does not exist, the field C<notice> with value C<balance document not found> is added.

=item post_balance

Parameters: none (but parses request parameters, see C<POST /balance> below)

Sets the C<balance> document fields given in the request parameters to the given values.

Returns C<< { status => 'success: queuebalance modified' } >> on success, or C<< { status => 'failed: invalid json passed ' . $_ } >> with HTTP status of C<400> on error.

=item check_disbatch

Parameters: none

Checks if Disbatch nodes exist and determines if any have been running within the last 60 seconds.

Returns C<< { status => 'WARNING', message => 'No Disbatch nodes found' } >> if no nodes,
C<< { status => 'OK', message => 'Disbatch is running on one or more nodes', nodes => $status } >> if at least one node recently running,
or C<< { status => 'CRITICAL', message => 'No active Disbatch nodes found', nodes => $status } >> if not.
On error, returns C<< { status => 'CRITICAL', message => "Could not get current Disbatch nodes: $_" } >>.

=item check_queuebalance

Parameters: none

Checks if QueueBalance has been running within the last 60 seconds.

Returns C<< { status => 'OK', message => 'queuebalance disabled' } >> if C<config.balance.enabled> is false.
If the balance doc has C<status> of C<CRITICAL> and no C<timestamp>, returns C<< { status => 'CRITICAL', message => $message } >>.
If the C<timestamp> value is older than 60 seconds, returns C<< { status => 'CRITICAL' , message => "queuebalanced not running for ${seconds}s" } >>.
If the  C<status> value is not C<OK>, C<WARNING>, or  C<CRITICAL>, returns C<< { status => 'CRITICAL', message => 'queuebalanced unknown status', result => $doc } >>.
Otherwise returns the doc: C<< { status => $status, message => $message, timestamp => $timestamp } >>.

=item checks

Parameters: none

Checks the status of Disbatch and QueueBalance.

If C<config.monitoring>, calls C<check_disbatch()> and C<check_queuebalance()>.

Returns C<< { disbatch => check_disbatch() , queuebalance => check_queuebalance() } >> if C<config.monitoring> is true, otherwise
C<< { disbatch => { status => 'OK', message => 'monitoring disabled' }, queuebalance => $checks->{queuebalance} = { status => 'OK', message => 'monitoring disabled' } } >>.

=item get_indexes($coll)

Parameters: C<MongoDB::Collection>.

Returns an C<ARRAY> of C<ARRAY>s of current indexes for the given collection.

Note: C<_id> is turned into C<id> because of L<Template>.

=item invalid_params($params, $indexes)

Parameters: MongoDB query params C<HASH>, current existsing collection indexes C<HASH>

Returns a list of all params passed which do not match the given indexes. If the list is empty, the params are good.

Note: only looks at keys in C<$params>, not their values.

=item params_to_query($params, $oid_keys)

Parameters: C<HASH> form parameters for a MongoDB query, C<ARRAY> of index keys whose values are always ObjectIds, excluding C<_id>.

Turns fields from an HTTP request into a query suitable for L<MongoDB::Collection>.

=over 2

Skips key/value pairs where the value is the empty string.

If a key is C<id> or is in C<$oid_keys>, turns the value(s) which should be hex strings into L<MongoDB::OID> objects.

Otherwise if a value (or first element of an C<ARRAY> value) looks like a number, ensures the value (or elements) is a Perl number.

Any values which are C<ARRAY>s are turned into queries joined by C<$or>.

If more than one key/value pair, they are joined into an C<$and> query.

=back

Returns a query to pass a L<MongoDB::Collection> object.

=item query($params, $options, $title, $oid_keys, $collection, $path, $raw, $indexes)

Performs a MongoDB query (C<count> or C<find>).

Parameters: HTTP params (C<HASH>), options (C<HASH>), title (string), OID keys (C<ARRAY>), L<MongoDB::Collection> object,
form action path (string), return raw result (boolean), indexes (C<ARRAY> of arrays).

Form action path should be from C<< request->{path} >>.

Options can be C<.count>, C<.fields> to return, C<.limit>, and C<.skip>.

Raw and indexes key are optional -- raw defaults to 0, and indexes are queried if C<undef>.

Returns the result of the query as a C<HASH> or C<ARRAY>, or an error C<HASH>.

NOTE: I hate this code. Read it to determine the formats it might return.

=back

=head1 JSON ROUTES

NOTE: all JSON routes use C<send_json_options>, documented above.

=over 2

=item GET /info

Parameters: none.

Returns an object with the following fields: C<database> (the name of the MongoDB database used), C<web_extensions> (an array of configured web extensions for custom routes),
and C<routes> (an object where fields are HTTP verbs and values are routes in the ordered configured).

Note: new in Disbatch 4.2

=item GET /nodes

Parameters: none.

Returns an Array of node Objects defined (with C<id> the stringified C<_id>) on success, C<< { "error": "Could not get current nodes: $_" } >> on error.

Sets HTTP status to C<400> on error.

Note: new in Disbatch 4

=item GET /nodes/:node

URL: C<:node> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<node> name if it does not.

Parameters: none.

Returns node Object (with C<id> the stringified C<_id>) on success, C<< { "error": "Could not get node $node: $_" } >> on error.

Sets HTTP status to C<400> on error.

Note: new in Disbatch 4

=item POST /nodes/:node

URL: C<:node> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<node> name if it does not.

Parameters: C<< { "maxthreads": maxthreads } >>

"maxthreads" is a non-negative integer or null

Returns C<< { ref $res: Object } >> or C<< { ref $res: Object, "error": error_string_or_reponse_object } >>

Sets HTTP status to C<400> on error.

Note: new in Disbatch 4

=item GET /plugins

Parameters: none.

Returns an Array of allowed plugin names.

Should never fail.

Note: replaces /queue-prototypes-json

=item GET /queues

Parameters: none.

Returns an Array of queue Objects on success, C<< { "error": "Could not get current queues: $_" } >> on error.

Each item has the following keys: id, plugin, name, threads, queued, running, completed

Sets HTTP status to C<400> on error.

Note: replaces /scheduler-json

=item GET /queues/:queue

URL: C<:queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not.

Parameters: none.

Returns a queue Object on success, C<< { "error": "Could not get current queues: $_" } >> on error.

Each item has the following keys: id, plugin, name, threads, queued, running, completed

Sets HTTP status to C<400> on error.

=item POST /queues

Create a new queue.

Parameters: C<< { "name": name, "plugin": plugin } >>

C<name> is the desired name for the queue (must be unique), C<plugin> is the plugin name for the queue.

Returns: C<< { ref $res: Object, "id": $inserted_id } >> on success; C<< { "error": "name and plugin required" } >>,
C<< { "error": "Invalid param", "param": $param } >>, or C<< { "error": "Unknown plugin", "plugin": $plugin } >> on input error; or
C<< { ref $res: Object, "id": null, "error": "$res" } >> on MongoDB error.

Sets HTTP status to C<400> on error.

Note: replaces /start-queue-json

=item POST /queues/:queue

URL: C<:queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not.

Parameters: C<< { "name": name, "plugin": plugin, "threads": threads } >>

C<name> is the new name for the queue (must be unique), C<plugin> is the new plugin name for the queue (must be defined in the config file), 
C<threads> must be a non-negative integer. Only one of C<name>, C<plugin>, and  C<threads> is required, but any combination is allowed.

Returns C<< { ref $res: Object } >> or C<< { "error": error } >>

Sets HTTP status to C<400> on error.

Note: replaces /set-queue-attr-json

=item DELETE /queues/:queue

Deletes the specified queue.

URL: C<:queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not.

Parameters: none

Returns: C<< { ref $res: Object } >> on success, or C<< { ref $res: Object, "error": "$res" } >> on error.

Sets HTTP status to C<400> on error.

Note: replaces /delete-queue-json

=item GET /tasks

Parameters: anything indexed on the C<tasks> collection, as well as any dot options.

Options can be C<.count>, C<.fields> to return, query C<.limit> and C<.skip>, C<.terse> or C<.full> output, dates as C<.epoch>, and C<.pretty> print JSON result.

Performs a search of tasks, returning either JSON or a web page.

If C<want_json()> (based on the C<Accept> header), returns a JSON array (which may be pretty-printed if specified in the parameters) of task documents,
or on error an object with an C<error> field (and possibly other fields).

Otherwise, if no parameters returns a web form to perform a search of indexed fields. If parameters, returns a web page of results or error.

Sets HTTP status to C<400> on error.

Note: new in 4.2, replaces C<POST /tasks/search>

=item GET /tasks/:id

Parameters: Task OID in URL

Returns the task matching OID as JSON, or C<{ "error": "no task with id :id" }> and status C<404> if OID not found.
Or, via a web browser (based on C<Accept> header value), returns the task matching OID with some formatting, or C<No tasks found matching query> if OID not found.

=cut

=item POST /tasks

Parameters: C<{ "queue": queue, "params": [single_task_params, another_task_params, ...] }> or C< { "queue": queue, "params": generic_task_params, "collection": collection, "filter": filter }>.

C<queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not.

C<collection> is a MongoDB collection name.

C<filter> is a filter expression (query) object for the C<:collection> collection.

C<params> depends on if passing a collection and filter or not.

=over 2

If not, C<params> is an array of objects, each of which will be inserted as-is as the C<params> value in created tasks.

Otherwise, C<params> is an object of generic task params. To insert a document value from a query into the params, prefix the desired key name with C<document.> as a value.

=back

Returns: C<< { ref $res: Object } >> on success; C<< { "error": "params must be a JSON array of task params" } >>, C<< { "error": "filter and params required and must be name/value objects" } >>
or C<< { "error": "queue not found" } >> on input error; C<< { "error": "Could not iterate on collection $collection: $error" } >> on query error, or C<< { ref $res: Object, "error": "Unknown error" } >> on MongoDB error.

Sets HTTP status to C<400> on error.

Note: new in 4.2, replaces C<POST /tasks/:queue> and C<POST /tasks/:queue/:collection>

=item GET /balance

Parameters: none

Returns a web page to view and update Queue Balance settings if the C<Accept> header wants C<text/html>, otherwise returns a pretty JSON result of C<get_balance>

=item POST /balance

Parameters: C<{ "max_tasks": max_tasks, "queues": queues, "disabled": disabled }>

C<max_tasks> is a C<HASH> where keys match C</^[*0-6] (?:[01]\d|2[0-3]):[0-5]\d$/> (that is, C<0..6> or C<*> for DOW, followed by a space and a 24-hour time) and values are non-negative integers.

C<queues> is an C<ARRAY> of C<ARRAY>s of queue names which must exist

C<disabled> is a timestamp which must be in the future (optional)

Sets the C<balance> document fields given in the above parameters to the given values.

Returns JSON C<{"status":"success: queuebalance modified"}> on success, or C<{"status":"failed: invalid json passed " . $_}> with HTTP status of C<400> on error.

=item GET /monitoring

Parameters: none

Checks the status of Disbatch and QueueBalance.

Monitoring is controlled by setting C<config.monitoring> and C<config.balance.enabled>.

Returns as JSON the result of C<checks()>, documented above.

=back

=head1 CUSTOM ROUTES

You can set an object of package names and arguments (can be C<null>) to C<web_extensions> in the config file to load any custom routes and call
C<< init($disbatch, $arguments) >> if available.
Note that if a request which matches your custom route is also matched by an above route, your custom route will never be called.
If a custom route package needs to interface with Disbatch or have any arguments passed to it, it should have the following:

    my $disbatch;

    sub init {
        ($disbatch, my $args) = @_;
        # do whatever you may need to do with $args
    }

For examples see L<Disbatch::Web::Files> (which is automatically loaded at the end of C<init(), after any custom routes) and L<Disbatch::Web::Tasks> (not loaded by default).

=head1 BROWSER ROUTES

=over 2

=item GET /

Returns the contents of "/index.html" – the queue browser page.

=item GET qr{^/}

Returns the contents of the request path.

Note: this is loaded from L<Disbatch::Web::Files>.

=back

=head1 SEE ALSO

L<Disbatch>

L<Disbatch::Roles>

L<Disbatch::Plugin::Demo>

L<disbatchd>

L<disbatch.pl>

L<task_runner>

L<disbatch-create-users>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

Matt Busigin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015, 2016, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
