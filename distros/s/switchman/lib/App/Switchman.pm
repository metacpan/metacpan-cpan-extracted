package App::Switchman;

our $VERSION = '1.16';

=head1 NAME

App::Switchman

=head1 DESCRIPTION

switchman's internals

=cut

use strict;
use warnings;

use File::Basename qw(basename);
use Getopt::Long qw(GetOptionsFromArray);
use JSON;
use Linux::MemInfo;
use List::MoreUtils qw(part uniq);
use List::Util qw(max);
use Log::Dispatch;
use Moo;
use Net::Domain qw(hostfqdn);
use Net::ZooKeeper qw(:acls :errors :events :node_flags);
use Net::ZooKeeper::Semaphore;
use Pod::Usage;
use POSIX qw(strftime);
use Scalar::Util qw(blessed);
use Sys::CPU;
use Sys::SigAction qw(set_sig_handler);


our $DEFAULT_CONFIG_PATH ||= "/etc/switchman.conf";
our $LOCKS_PATH ||= 'locks';
our $QUEUES_PATH ||= 'queues';
our $SEMAPHORES_PATH ||= 'semaphores';


has command => (is => 'ro', required => 1);
has data_read_len => (
    is => 'ro',
    isa => sub {die "bad data_read_len: $_[0]" if defined $_[0] && $_[0] !~ m{^[0-9]+$}},
    default => sub {65535},
);
has do_get_lock => (is => 'ro', default => 1);
has group => (is => 'ro');
has leases => (is => 'ro');
has lock_path => (
    is => 'ro',
    lazy => 1,
    builder => sub {join '/', $_[0]->prefix, $LOCKS_PATH, $_[0]->lockname},
);
has lock_watch => (
    is => 'ro',
    lazy => 1,
    builder => sub {$_[0]->zkh->watch},
);
has lockname => (
    is => 'ro',
    isa => sub {
        die "lockname is too long: $_[0]" if length($_[0]) > 512;
        die "lockname must not contain '/'" if index($_[0], '/') != -1;
    },
    required => 1,
);
has log => (is => 'ro', lazy => 1, builder => 1);
has logfile => (is => 'ro');
has loglevel => (is => 'ro');
has prefix => (
    is => 'ro',
    isa => sub {die "bad prefix: $_[0]" unless $_[0] =~ m{^(?:/[^/]+)+$}},
    required => 1,
);
has prefix_data => (is => 'rw');
has prefix_data_watch => (
    is => 'ro',
    lazy => 1,
    builder => sub {$_[0]->zkh->watch},
);
has queue_positions => (
    is => 'ro',
    default => sub {+{}},
);
has resources_wait_timeout => (
    is => 'ro',
    isa => sub {die "bad resources_wait_timeout: $_[0]" if defined $_[0] && $_[0] !~ m{^[0-9]+$}},
    default => sub {0},
);
has termination_timeout => (
    is => 'ro',
    isa => sub {die "bad termination_timeout: $_[0]" if defined $_[0] && $_[0] !~ m{^\d+$}},
    default => sub {10},
);
has zkh => (
    is => 'rw',
    lazy => 1,
    builder => sub {Net::ZooKeeper->new($_[0]->zkhosts)},
);
has zkhosts => (is => 'ro', required => 1);


sub BUILDARGS
{
    my $class = shift;
    my $arguments = shift;

    return $arguments if ref $arguments eq 'HASH';
    die "Bad constructor arguments: hashref or arrayref expected" unless ref $arguments eq 'ARRAY';

    my %options = (do_get_lock => 1);
    my $config_path;
    my $leases = {};
    GetOptionsFromArray(
        $arguments,
        'c|config=s' => \$config_path,
        'g|group=s' => \$options{group},
        'h|help' => \&usage,
        'lease=s' => $leases,
        'lockname=s' => \$options{lockname},
        'v|version' => \&version,
        'lock!' => \$options{do_get_lock},
    ) or die "Couldn't parse options, see $0 -h for help\n";

    die "No command provided" unless @$arguments;
    $options{lockname} ||= basename($arguments->[0]);
    $options{command} = [@$arguments];

    $options{leases} = {};
    for my $resource (keys %$leases) {
        my ($count, $total) = split /:/, _process_resource_macro($leases->{$resource}), 2;
        $options{leases}->{_process_resource_macro($resource)} = {
            count => eval $count,
            total => eval $total,
        };
    }

    if (!$config_path && -f $DEFAULT_CONFIG_PATH) {
        $config_path = $DEFAULT_CONFIG_PATH;
    }
    die "$DEFAULT_CONFIG_PATH is absent and --config is missing, see $0 -h for help\n" unless $config_path;
    my $config = _get_and_check_config($config_path);
    for my $key (qw/data_read_len logfile loglevel prefix resources_wait_timeout termination_timeout zkhosts/) {
        next unless exists $config->{$key};
        $options{$key} = $config->{$key};
    }

    return \%options;
}


sub _build_log
{
    my $self = shift;

    return Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                min_level => $ENV{DEBUG} ? 'debug' : 'warning',
                stderr => 1,
                newline => 1,
            ],
            $self->logfile ? [
                'File',
                min_level => $self->loglevel || 'info',
                filename => $self->logfile,
                mode => '>>',
                newline => 1,
                binmode => ':encoding(UTF-8)',
                format => '[%d] [%p] %m at %F line %L%n',
            ] : (),
        ],
        callbacks => sub {my %p = @_; return join "\t", strftime("%Y-%m-%d %H:%M:%S", localtime(time)), "[$$]", $p{message};},
    );
}


=head1 METHODS

=head2 acquire_semaphore

Acquires semaphore for a given resource

=cut

sub acquire_semaphore
{
    my $self = shift;
    my $resource = shift;

    $self->log->debug(sprintf "Trying to acquire semaphore %s", $resource);

    return Net::ZooKeeper::Semaphore->new(
        count => $self->leases->{$resource}->{count},
        data => _node_data(),
        path => $self->prefix."/$SEMAPHORES_PATH/$resource",
        total => $self->leases->{$resource}->{total},
        zkh => $self->zkh,
    );
}


=head2 get_group_hosts

Returns an arrayref of hosts included int the given group

=cut

sub get_group_hosts
{
    my $self = shift;
    my $groups = shift;
    my $group = shift;
    my $seen = shift || {$group => 1};

    my $items = $groups->{$group} or $self->_error(sprintf "Group <%s> is not described", $group);
    $items = [$items] unless ref $items eq 'ARRAY';
    my ($subgroups, $hosts) = part {exists $groups->{$_} ? 0 : 1} @$items;
    for my $subgroup (@$subgroups) {
        next if $seen->{$subgroup};
        $seen->{$subgroup} = 1;
        push @$hosts, @{$self->get_group_hosts($groups, $subgroup, $seen)};
    }
    return [uniq @$hosts];
}


=head2 get_lock

Creates a named lock in ZooKeeper
Returns undef is lock already exists, otherwise returns true and sets lock_watch

=cut

sub get_lock
{
    my $self = shift;

    my $lock_path = $self->zkh->create($self->lock_path, _node_data(),
        acl => ZOO_OPEN_ACL_UNSAFE,
        flags => ZOO_EPHEMERAL,
    );
    if (my $error = $self->zkh->get_error) {
        if ($error == ZNODEEXISTS) {
            return undef;
        } else {
            $self->_error(sprintf("Could not acquire lock %s: %s", $self->lockname, $self->zkh->str_error));
        }
    }
    $self->log->debug(sprintf "Lock <%s> taken", $self->lock_path);
    return $self->zkh->exists($lock_path, watch => $self->lock_watch);
}


=head2 get_queue_path

Returns queue path for a given resource

=cut

sub get_queue_path
{
    my $self = shift;
    my $resource = shift;

    return $self->prefix."/$QUEUES_PATH/$resource";
}


=head2 get_resources

Returns resource names listed in ZooKeeper
Macros are processed

=cut

sub get_resources
{
    my $self = shift;

    $self->load_prefix_data;
    return map {_process_resource_macro($_)} @{$self->prefix_data->{resources}};
}


=head2 is_group_serviced

Determines if execution is allowed on the current host

=cut

sub is_group_serviced
{
    my $self = shift;

    $self->load_prefix_data;
    my $hosts = $self->get_group_hosts($self->prefix_data->{groups}, $self->group);
    my $fqdn = hostfqdn();
    my $is_serviced = grep {$fqdn eq $_} @$hosts;
    return $is_serviced;
}


=head2 is_task_in_queue

Checks if task is already queue up for a given resource

=cut

sub is_task_in_queue
{
    my $self = shift;
    my $resource = shift;

    my $re = quotemeta($self->lockname).'-\d+';
    my $is_in_queue = scalar grep {$_ =~ /^$re$/} $self->zkh->get_children($self->get_queue_path($resource));
    if ($self->zkh->get_error && $self->zkh->get_error != ZNONODE) {
        $self->_error("Could not check queue for <$resource>: ".$self->zkh->str_error);
    }
    $self->log->debug(sprintf "Check if task <%s> already queued up for resource <%s>: %s", $self->lockname, $resource, ($is_in_queue ? 'true' : 'false'));
    return $is_in_queue;
}


=head2 leave_queues

Leaves all resource queues

=cut

sub leave_queues
{
    my $self = shift;

    for my $resource (keys %{$self->queue_positions}) {
        my $position = $self->queue_positions->{$resource};
        $self->log->debug(sprintf "Delete from queue %s", $position);
        $self->zkh->delete($position);
        if ($self->zkh->get_error) {
            $self->_error("Could not delete <$position>: ".$self->zkh->str_error);
        }
        delete $self->queue_positions->{$resource};
    }
}


=head2 load_prefix_data

Loads data from prefix znode
Sets prefix_data_watch

=cut

sub load_prefix_data
{
    my $self = shift;

    my $json_data = $self->zkh->get($self->prefix, watch => $self->prefix_data_watch);
    if ($self->zkh->get_error) {
        $self->_error("Could not get data: ".$self->zkh->str_error);
    }

    my (%data, $prefix_data);
    if ($json_data) {
        $prefix_data = eval {from_json($json_data)};
        if (!$prefix_data || $@) {
            $self->_error("Could not decode data: $@");
        } elsif (ref $prefix_data ne 'HASH') {
            $self->_error("Bad prefix data: hashref expected");
        }
        if ($prefix_data->{resources} && ref $prefix_data->{resources} ne 'ARRAY') {
            $self->_error("Bad prefix data: resources should be an array");
        }
        if ($prefix_data->{groups} && ref $prefix_data->{groups} ne 'HASH') {
            $self->_error("Bad prefix data: groups should be a hash");
        }
    }

    $data{resources} = $prefix_data->{resources} || [];
    $data{groups} = $prefix_data->{groups} || {};

    $self->prefix_data(\%data);
}


=head2 prepare_zknodes

Ensures existence of subnodes we use

=cut

sub prepare_zknodes
{
    my $self = shift;
    my $nodes = shift;

    for my $path (@$nodes) {
        unless ($self->zkh->exists($path)) {
            my $error = $self->zkh->get_error;
            if ($error && $error != ZNONODE) {
                $self->_error("Failed to check $path existence: ".$self->zkh->str_error);
            }
            $self->log->debug("Create $path");
            $self->zkh->create($path, _node_data(),
                acl => ZOO_OPEN_ACL_UNSAFE,
            ) or $self->_error("Failed to prepare $path: ".$self->zkh->str_error);
        }
    }
}


=head2 queue_up

Puts task in queue for resource
Returns queue item path

=cut

sub queue_up
{
    my $self = shift;
    my $resource = shift;

    my $queue_path = $self->get_queue_path($resource);
    $self->prepare_zknodes([$queue_path]);
    my $item_path = $self->zkh->create(sprintf("%s/%s-", $queue_path, $self->lockname), _node_data(),
        acl => ZOO_OPEN_ACL_UNSAFE,
        flags => (ZOO_EPHEMERAL | ZOO_SEQUENCE),
    );
    if ($self->zkh->get_error) {
        $self->_error(sprintf("Could not push task <%s> in queue for <%s>: %s", $self->lockname, $resource, $self->zkh->str_error));
    } else {
        $self->log->debug(sprintf "Added task in queue for <%s>: <%s>", $resource, $item_path);
    }
    $self->queue_positions->{$resource} = $item_path;
    return $item_path;
}


=head2 zk_connect

Connect to zookeeper cluster

=cut

sub zk_connect
{
    my $self = shift;

    # check connection and try and reconnect in case of a failure
    for (1 .. 10) {
        if (!$self->zkh) {
            $self->log->debug("NetZooKeeper initialization failed");
        } else {
            $self->zkh->exists($self->prefix);
            if (!$self->zkh->get_error || $self->zkh->get_error == ZNONODE) {
                last;
            }
        }
        $self->log->debug("Trying to reconnect");
        $self->zkh(Net::ZooKeeper->new($self->zkhosts));
    }

    if (!$self->zkh) {
        $self->_error("Failed to connect to ZooKeeper");
    }

    $self->zkh->{data_read_len} = $self->data_read_len;
}


=head2 run

Application loop
Never returns

=cut

sub run
{
    my $self = shift;
    $self->zk_connect();

    $self->prepare_zknodes([$self->prefix, map {$self->prefix."/$_"} ($LOCKS_PATH, $QUEUES_PATH, $SEMAPHORES_PATH)]);

    if ($self->group && !$self->is_group_serviced) {
        $self->log->debug(sprintf "Group <%s> is not serviced at the moment", $self->group);
        exit;
    }

    if ($self->do_get_lock && $self->zkh->exists($self->lock_path, watch => $self->lock_watch)) {
        $self->log->info(sprintf "Lock %s already exists", $self->lock_path);
        exit;
    }

    my %known_resources = map {$_ => 1} $self->get_resources;
    if (my @unknown_resources = grep {!exists $known_resources{$_}} keys %{$self->leases}) {
        $self->_error("Unknown resources: ".join(', ', @unknown_resources));
    }

    my $alarm_handler_guard;
    if ($self->resources_wait_timeout) {
        $alarm_handler_guard = set_sig_handler('ALRM', sub {
            local *__ANON__ = 'timed_out_resources_waiting_handler';
            $self->_error("Reached timeout while waiting for resources");
        }, {safe => 0});
        alarm($self->resources_wait_timeout);
    }

    my @resources = grep {exists $self->leases->{$_}} $self->get_resources;
    for my $resource (@resources) {
        if ($self->is_task_in_queue($resource)) {
            exit;
        } else {
            $self->queue_up($resource);
        }
    }

    my @semaphores = ();

    for my $resource (@resources) {
        $self->wait_in_queue($resource);
        # try to acquire a semaphore until success
        while (1) {
            if ($self->lock_watch->{state}) {
                $self->log->info(sprintf "Lock watch received %s while waiting for $resource semaphore, we exit", $self->lock_watch->{event});
                exit;
            }
            my $semaphore = $self->acquire_semaphore($resource);
            if ($semaphore) {
                $self->log->debug(sprintf "Semaphore <%s> acquired", $resource);
                push @semaphores, $semaphore;
                last;
            }
            sleep 1;
        }
    }

    $self->log->debug("All resources acquired");

    $self->leave_queues;
    alarm(0);

    if ($self->do_get_lock && !$self->get_lock) {
        $self->log->info(sprintf "Lock %s already exists", $self->lockname);
        exit;
    }

    # We want to exit right after our child dies
    $SIG{CHLD} = sub {
        my $pid = wait;
        my $exit_code = $? >> 8;
        $self->log->warn("Child $pid exited with $exit_code") if $exit_code;
        # THE exit
        exit $exit_code;
    };

    my $CHILD;

    # If we suddenly die, we won't leave our child alone
    # Otherwise the process will be active and not holding the lock
    $SIG{__DIE__} = sub {
        my $msg = shift;
        chomp $msg;
        if ($CHILD && kill 0 => $CHILD) {
            $self->log->warn("Parent is terminating abnormally ($msg), killing child $CHILD");
            kill 9 => $CHILD or $self->log->warn("Failed to KILL $CHILD");
        }
    };
    $SIG{TERM} = $SIG{INT} = sub {
        my $signame = shift;
        warn "Parent received SIG$signame, terminating child $CHILD\n";
        if (kill $signame => $CHILD) {
            warn "Sent SIG$signame to $CHILD\n";
            sleep 1; # wait for process cleanup
        }
        if (kill 0 => $CHILD) {
            warn "Failed to $signame $CHILD\n";
        } else {
            exit;
        }
    };

    $CHILD = $self->run_command_in_background;

    while (1) {
        if ($self->lock_watch->{state}) {
            $self->log->warn("It's not secure to proceed, lock watch received ".$self->lock_watch->{event});
            $self->_stop_child($CHILD);
            last;
        }
        if ($self->group && $self->prefix_data_watch->{state}) {
            unless ($self->is_group_serviced) {
                $self->log->info(sprintf "Group <%s> is not serviced by the current host anymore", $self->group);
                $self->_stop_child($CHILD);
                last;
            }
        }
        sleep 1;
    }
}


=head2 run_command_in_background

Execs command

=cut

sub run_command_in_background
{
    my $self = shift;

    my $command = join(' ', @{$self->command});
    $self->log->info("Executing <$command>");

    my $child = fork();
    if (!defined $child) {
        $self->_error("Could not fork");
    } elsif (!$child) {
        exec(@{$self->command}) or $self->_error("Failed to exec <$command>: $!");
    } else {
        return $child
    }
}


=head2 usage

Shows help and exits

=cut

sub usage
{
    pod2usage(-exitval => 1, -verbose => 99, -sections => [qw(USAGE DESCRIPTION EXAMPLES), 'SEE ALSO', 'COPYRIGHT AND LICENSE']);
}


=head2 version

Shows version info and exits

=cut

sub version
{
    print "switchman $VERSION\n";
    pod2usage(-exitval => 1, -verbose => 99, -sections => ['COPYRIGHT AND LICENSE']);
}


=head2 wait_in_queue

Waits in queue for a given resource

=cut

sub wait_in_queue
{
    my $self = shift;
    my $resource = shift;

    my $queue_path = $self->prefix."/$QUEUES_PATH/$resource";
    my $queue_position = $self->queue_positions->{$resource} or $self->_error("queue position for <$resource> is not initialized");
    my ($position) = $queue_position =~ /-(\d+)$/;

    while (1) {
        $self->log->debug(sprintf "Wait in queue cycle for %s", $queue_position);
        my @items = $self->zkh->get_children($queue_path);
        if ($self->zkh->get_error) {
            $self->_error("Could not get items in queue $queue_path: ".$self->zkh->str_error);
        }
        my %positions;
        for my $item (@items) {
            if ($item =~ /-(\d+)$/) {
                $positions{$1} = $item;
            } else {
                $self->_error("Unexpected item <$item> in queue $queue_path");
            }
        }

        if (!exists $positions{$position}) {
            $self->log->debug(sprintf "Our position <%s> does not exists in queue. Queue items: %s.", $position, join(', ', @items));
            $self->_error("Lost position <$position> in queue $queue_path");
        }

        my @prior_pos = grep {$_ < $position} keys %positions;
        last if !@prior_pos;

        my $neighbour = max @prior_pos;
        my $neighbour_watch = $self->zkh->watch();
        my $neighbour_exists = $self->zkh->exists("$queue_path/$positions{$neighbour}", watch => $neighbour_watch);
        if (($self->zkh->get_error) && $self->zkh->get_error != ZNONODE) {
            $self->_error("Could not check $positions{$neighbour} existence: ".$self->zkh->str_error);
        }
        if ($neighbour_exists) {
            $self->log->debug(sprintf 'Wait for changing %s state (%d items before us)', $positions{$neighbour}, scalar(@prior_pos));
            $neighbour_watch->wait;
        }
    }
    $self->log->debug(sprintf "Waited %s", $queue_position);
}


sub _error
{
    my $self = shift;
    my $message = shift;

    @_ = ($self->log, level => 'critical', message => $message);
    my $class = blessed $self->log;
    no strict 'refs';
    goto &{"${class}::log_and_croak"};
}


sub _get_and_check_config
{
    my $config_path = shift;

    open my $config_file, '<:encoding(UTF-8)', $config_path or die "Failed to open <$config_path>";
    my $config_json = do {local $/; <$config_file>};
    close $config_file;
    $config_json =~ s/(?:^\s*|\s*$)//gm;
    my $config = from_json($config_json);
    die "zkhosts is not defined in $config_path\n" unless $config->{zkhosts};
    die "zk chroot is not supported in older versions, use prefix in $config_path\n" if $config->{zkhosts} =~ m!/\w+!;
    die "prefix is not defined in $config_path\n" unless $config->{prefix};

    return $config;
}


sub _node_data
{
    return hostfqdn()." $$";
}


sub _process_resource_macro
{
    my $string = shift;

    my %mem_info = Linux::MemInfo::get_mem_info();
    my %expand = (
        CPU => Sys::CPU::cpu_count(),
        FQDN => hostfqdn(),
        MEMMB => int($mem_info{MemTotal} / 1024),
    );
    my $re = join '|', keys %expand;
    $string =~ s/($re)/$expand{$1}/eg;
    return $string;
}


sub _stop_child
{
    my $self = shift;
    my $pid = shift;

    kill TERM => $pid or die "Failed to TERM $pid";
    # give some time to terminate gracefully
    for (1 .. $self->termination_timeout) {
        return unless kill 0 => $pid;
        sleep 1;
    }
    # ran out of patience
    kill KILL => $pid or die "Failed to KILL $pid";
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
