#!/usr/bin/perl

use 5.12.0;
use warnings;

use Data::Dumper;
use File::Slurp;
use Getopt::Long;
use IO::Wrap;
use JSON;
use LWP::UserAgent;
use Pod::Usage;
use Text::CSV_XS;
use Text::Table;
use Try::Tiny;

my $url = 'http://localhost:8080';
my $username;
my $password;
my $help = 0;
my $config_file = '/etc/disbatch/config.json';
my $ssl_ca_file;
my $disable_ssl_verification = 0;

GetOptions(
    'url|u=s'       => \$url,
    'username|n=s'  => \$username,
    'password=s'    => \$password,
    'help'          => \$help,
    'config=s'      => \$config_file,
    'ssl_ca_file=s' => \$ssl_ca_file,
    'disable_ssl_verification' => \$disable_ssl_verification,
);

pod2usage(-verbose => 2, -exitval => 0) if $help;
pod2usage(1) unless @ARGV;

my $json = JSON->new;

my $options = {};
if (defined $ssl_ca_file) {
    $options->{ssl_opts}{SSL_ca_file} = $ssl_ca_file;
} elsif ($disable_ssl_verification) {
    $options->{ssl_opts}{verify_hostname} = 0;
} else {
    # Note: the SSL settings are for MongoDB, but ideally if using SSL with MongoDB, it is also being used with the DCI
    # try loading the config file, but don't fail if it doesn't exist
    my $config = try { $json->relaxed->decode(scalar read_file $config_file) } catch { {} };
    if (defined $config->{attributes}{ssl}) {
        $options->{ssl_opts} = $config->{attributes}{ssl};
        $options->{ssl_opts}{verify_hostname} = $options->{ssl_opts}{SSL_verify_mode} if defined $options->{ssl_opts}{SSL_verify_mode};
    }
}

my $ua = LWP::UserAgent->new(%$options);

if (defined $username and defined $password) {
    my ($host) = $url =~ qr{^https?://(.+?)(?:/|$)};
    $ua->credentials($host, 'disbatch', $username, $password);
    say "$host\t$username\t$password";
} elsif (defined $username or defined $password) {
    die "--username and --password must be used together\n";
}

my %commands = (
    status       => \&parse_status,
    queue        => \&parse_queue,
);

sub parse_status {
    my ($params) = @_;
    $params->{execute} = \&status;
    return 1, 'Status';
}

sub parse_queue {
    my ($params, @ARGS) = @_;

    my %queue_commands = (
        set    => \&parse_queue_set,
        start  => \&parse_queue_start,
        task   => \&parse_queue_task,
        tasks  => \&parse_queue_tasks,
        search => \&parse_queue_search,
        types  => \&parse_queue_types,
    );

    return 0, "Command '$params->{command}' needs a sub-command.  Options: " . join(' ', keys %queue_commands) if @ARGS < 1 or !defined $ARGS[0];

    my $command = shift @ARGS;
    return 0, "Queue sub-command '$command' does not exist." unless exists $queue_commands{$command};

    my $func = $queue_commands{$command};
    return &$func($params, @ARGS);
}

sub parse_queue_types {
    my ($params, @ARGS) = @_;
    $params->{execute} = \&queue_types;
    return 1, undef;
}

sub parse_queue_start {
    my ($params, @ARGS) = @_;
    return 0, "Start takes 2 arguments:  type & name." if @ARGS != 2;
    $params->{execute} = \&queue_start;
    ($params->{type}, $params->{name}) = @ARGS;
    return 1, undef;
}

sub parse_queue_search {
    my ($params, @ARGS) = @_;
    return 0, "Search takes 2 arguments:  queue & filter." if @ARGS != 2;
    $params->{execute} = \&queue_search;
    ($params->{queue}, $params->{filter}) = @ARGS;
    return 1, undef;
}

sub parse_queue_set {
    my ($params, @ARGS) = @_;
    return 0, "Set takes 3 arguments:  queueid, key & value." if @ARGS != 3;
    $params->{execute} = \&queue_set;
    ($params->{queueid}, $params->{key}, $params->{value}) = @ARGS;
    return 1, undef;
}

sub parse_queue_task {
    my ($params, @ARGS) = @_;
    return 0, "Item takes at least one argument:  queueid.\n" if @ARGS < 1;
    $params->{execute} = \&queue_task;
    $params->{queueid} = shift @ARGS;

    my $state = 0;
    my %parameters;
    my $key;
    while (my $parameter_term = shift @ARGS) {
        if ($state == 0) {
            $key   = $parameter_term;
            $state = 1;
        } elsif ($state == 1) {
            $parameters{$key} = $parameter_term;
            $state = 0;
        }
    }

    return 0, 'Parameters must be an even number of elements to comprise a key/value pair set' if $state == 1;

    $params->{object} = [ \%parameters ];
    return 1, undef;
}

sub parse_queue_tasks {
    my ($params, @ARGS) = @_;
    return 0, "Item takes at least 3 arguments: queueid, collection, filter" if @ARGS < 3;
    $params->{execute}    = \&queue_tasks;
    $params->{queueid}    = shift @ARGS;
    $params->{collection} = shift @ARGS;

    my %filter;
    my $key;
    my $state = 0;
    while ((my $filter_term = shift @ARGS) ne '--') {
        return 0, "Filter clause terminator '--' is required" unless $filter_term;
        if ($state == 0) {
            $key   = $filter_term;
            $state = 1;
        } elsif ($state == 1) {
            $filter{$key} = $filter_term;
            $state = 0;
        }
    }

    return 0, 'The filter must be an even number of elements to comprise a key/value pair set' if $state == 1;
    $params->{filter} = \%filter;

    $state = 0;
    my %parameters;
    while (my $parameter_term = shift @ARGS) {
        if ($state == 0) {
            $key   = $parameter_term;
            $state = 1;
        } elsif ($state == 1) {
            $parameters{$key} = $parameter_term;
            $state = 0;
        }
    }

    return 0, 'Parameters must be an even number of elements to comprise a key/value pair set' if $state == 1;
    $params->{params} = $json->encode(\%parameters);

    return 1, undef;
}

sub parse_arguments {
    ## No arguments?  Let caller know by returning -1.
    return -1, {} unless @_;

    my ($command, @ARGS) = @_;

    my $parameters = {command => $command};
    unless (exists $commands{$parameters->{command}}) {
        say "No such command '$parameters->{command}'.";
        return 0, $parameters;
    }

    if (my $func = $commands{$parameters->{command}}) {
        my ($ret, $msg) = &$func($parameters, @ARGS);
        if ($ret == 0) {
            say $msg;
            return 0, $parameters;
        }
    }

    return 1, $parameters;
}

sub status {

    #my ($params) = @_;
    my $this_url = "$url/scheduler-json";

    my $r = $ua->get($this_url);
    if ($r->is_success) {
        my $obj   = $json->decode($r->decoded_content);
        my $count = 0;

        my $sep = \' | ';
        my $tl  = Text::Table->new(
            {title => 'ID',         align => 'right'}, $sep,
            {title => 'Plugin',     align => 'right'}, $sep,
            {title => 'Name',       align => 'right'}, $sep,
            {title => 'Threads',    align => 'right'}, $sep,
            {title => 'Queued',     align => 'right'}, $sep,
            {title => 'Running',    align => 'right'}, $sep,
            {title => 'Completed',  align => 'right'},
        );

        for my $queue (@$obj) {
            $tl->add(
                $queue->{id},
                $queue->{plugin},
                $queue->{name},
                $queue->{threads},
                $queue->{queued},
                $queue->{running},
                $queue->{completed},
            );
            $count++;
        }

        print $tl->title;
        print $tl->rule('-', '+');
        say $tl->body;
        say "$count total queues.";
    } else {
        say "Unable to connect to $this_url: ", $r->status_line;
    }
}

sub queue_set {
    my ($params) = @_;
    my $this_url = "$url/set-queue-attr-json";
    my $r        = $ua->post(
        $this_url,
        [
            queueid => $params->{queueid},
            attr    => $params->{key},
            value   => $params->{value},
        ]
    );

    if ($r->is_success) {
        my $obj = $json->decode($r->decoded_content);
        return if $obj->{success};
        say "Couldn't set queue attribute: $obj->{error}";
    } else {
        say "Unable to connect to: $this_url";
    }
}

sub queue_start {
    my ($params) = @_;
    my $this_url = "$url/start-queue-json";
    my $r        = $ua->post(
        $this_url,
        [
            type => $params->{type},
            name => $params->{name},
        ]
    );

    if ($r->is_success) {
        my $obj = $json->decode($r->decoded_content);
        if ($obj->[0] == 1) {
            say "New Queue #$obj->[1]{'$oid'}";
            return;
        } else {
            say "Couldn't create queue:  $obj->[1]";
        }
    } else {
        say "Unable to connect to:  $this_url";
    }
}

sub queue_task {
    my ($params) = @_;
    my $this_url = "$url/queue-create-tasks-json";
    my $r        = $ua->post(
        $this_url,
        [
            queueid => $params->{queueid},
            object  => $json->encode($params->{object}),
        ]
    );

    if ($r->is_success) {
        my @ret = @{$json->decode($r->decoded_content)};
        say $r->decoded_content;

        #say "New task #$ret[2]";
    } else {
        say "Unable to connect to:  $this_url";
    }
}

sub queue_tasks {
    my ($params) = @_;
    my $this_url = "$url/queue-create-tasks-from-query-json";
    my $r        = $ua->post(
        $this_url,
        [
            queueid    => $params->{queueid},
            collection => $params->{collection},
            jsonfilter => $json->encode($params->{filter}),
            params     => $params->{params},
        ]
    );

    if ($r->is_success) {
        print $r->decoded_content;

        #my @ret = @{$json->decode($r->decoded_content)};
        #say "New task #$ret[2]";
    } else {
        say "Unable to connect to:  $this_url";
    }
}

sub queue_types {
    my ($params) = @_;
    my $this_url = "$url/queue-prototypes-json";
    my $r        = $ua->post($this_url);

    if ($r->is_success) {

        #print $r->decoded_content;
        my $obj = $json->decode($r->decoded_content);
        my $text = join("\n", keys %$obj);
        say $text;
    } else {
        say "Unable to connect to:  $this_url";
    }
}

sub queue_search {
    my ($params) = @_;
    my $this_url = "$url/search-tasks-json";
    my $r        = $ua->post(
        $this_url,
        [
            queue  => $params->{queue},
            filter => $params->{filter},
        ]
    );

    if ($r->is_success) {
        print $r->decoded_content;

        #my $obj = $json->decode($r->decoded_content);
    } else {
        say "Unable to connect to:  $this_url";
    }
}

my ($ret, $params) = parse_arguments(@ARGV);
exit 1 unless $ret;

pod2usage(-verbose => 2, -exitval => 0) if $ret == -1;

$params->{execute}->($params);

warn "DEPRECATION NOTICE: This is deprecated as of Disbatch 4.0 and will be removed in Disbatch 4.2. Use 'disbatch'.\n";

__END__

=encoding utf8

=head1 NAME

disbatch.pl - CLI to the Disbatch Command Interface (DCI).

=head1 VERSION

version 4.102

=head1 DEPRECATION NOTICE

This is deprecated as of Disbatch 4.0 and will be removed in Disbatch 4.2. Use L<disbatch>.

=head1 SYNOPSIS

    disbatch.pl [<arguments>] <command> [<command arguments>]

=head2 ARGUMENTS

=over 2

=item --url <URL>

URL for the DCI you wish to connect to. Default is C<http://localhost:8080>.

=item --username <username>

DCI username

=item --password <password>

DCI password

=item --help

Display this message

=item --ssl_ca_file <ssl_ca_file>

Path to the SSL CA file. Needed if using SSL with a private CA.

=item --disable_ssl_verification

Disables hostname verification if SSL is used.

Only used if C<--ssl_ca_file> is not used.

=item --config <config_file>

Path to Disbatch config file. Default is C</etc/disbatch/config.json>.

Only used if neither C<--ssl_ca_file> nor C<--disable_ssl_verification> is used.

Note: the SSL settings in the Disbatch config file are for MongoDB, but ideally if using SSL with MongoDB, then it is also being used with the DCI.

=back

=head2 COMMANDS

=over 2

=item status

List all queues this disbatch server processes.

  $ disbatch.pl status
  ID                       | Type                   | Name | Threads | Done | To-Do | Processing
  -------------------------+------------------------+------+---------+------+-------+-----------
  56eade3aeb6af81e0123ed21 | Disbatch::Plugin::Demo | demo | 0       | 0    | 0     | 0

  1 total queues.

=item queue set <queue> <key> <value>

Change a field's value in a queue.
The only valid field is C<threads>.

  $ disbatch.pl queue set 56eade3aeb6af81e0123ed21 threads 10

=item queue start <type> <name>

Create a new queue.

  $ disbatch.pl queue start Disbatch::Plugin::Demo foo
  New Queue #5717f5edeb6af80362796221

=item queue task <queue> [<key> <value> ...]

Creates a task in the specified queue with the given params.

  $ disbatch.pl queue task 5717f5edeb6af80362796221 user1 ashley user2 ashley
  [1,1,{"index":0,"_id":{"$oid":"5717f70ceb6af803671f7c71"}},{"MongoDB::InsertManyResult":{"acknowledged":1,"inserted":[{"index":0,"_id":{"$oid":"5717f70ceb6af803671f7c71"}}],"write_concern_errors":[],"write_errors":[]},"success":1}]

=item queue tasks <queue> <collection> [<filter key> <value> ...] -- -- [<param key> <value> ...]

Creates multiple tasks in the specified queue with the given params, based off a filter from another collection.

In the below example, the C<users> collection is queried for all documents matching C<{migration: "foo"}>.
These documents are then used to set task params, and the values from the query collection are accessed by prepending C<document.>.

  $ disbatch.pl queue tasks 5717f5edeb6af80362796221 users migration foo -- -- user1 document.username user2 document.username migration document.migration
  [1,2]

=item queue search <queue> <json_query>

Returns a JSON array of task documents matching the JSON query given. Note that blessed values may be munged to be proper JSON.

$ disbatch.pl queue search 5717f5edeb6af80362796221 '{"params.migration": "foo"}'
[{"ctime":1461189920,"stderr":null,"status":-2,"mtime":0,"_id":{"$oid":"5717fd20eb6af803671f7c72"},"node":null,"params":{"migration":"foo","user1":"ashley","user2":"ashley"},"queue":{"$oid":"5717f5edeb6af80362796221"},"stdout":null,"ctime_str":"2016-04-20T22:05:20"},{"ctime":1461189920,"stderr":null,"status":-2,"mtime":0,"_id":{"$oid":"5717fd20eb6af803671f7c73"},"node":null,"params":{"migration":"foo","user1":"matt","user2":"matt"},"queue":{"$oid":"5717f5edeb6af80362796221"},"stdout":null,"ctime_str":"2016-04-20T22:05:20"}]

=item queue types

  $ disbatch.pl queue types
  Disbatch::Plugin::Demo

=back

=head1 SEE ALSO

L<disbatch>

L<Disbatch>

L<Disbatch::Web>

L<Disbatch::Roles>

L<Disbatch::Plugin::Demo>

L<task_runner>

L<disbatchd>

L<disbatch-create-users>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

Matt Busigin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Matt Busigin.

This software is Copyright (c) 2014, 2015, 2016 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
