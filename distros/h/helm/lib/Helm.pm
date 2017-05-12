package Helm;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints qw(enum);
use URI;
use namespace::autoclean;
use Try::Tiny;
use File::Spec::Functions qw(catdir catfile tmpdir devnull);
use File::HomeDir;
use Net::OpenSSH;
use Fcntl qw(:flock);
use File::Basename qw(basename);
use Helm::Log;
use Helm::Server;
use Scalar::Util qw(blessed);
use Parallel::ForkManager;
use DateTime;
use IO::File;

our $VERSION = 0.4;
our $DEBUG = 0;
our $DEBUG_LOG;
our $DEBUG_LOG_PID;

enum LOG_LEVEL => qw(debug info warn error);
enum LOCK_TYPE => qw(none local remote both);

has task                 => (is => 'ro', writer => '_task',           required => 1);
has user                 => (is => 'ro', writer => '_user',           isa      => 'Maybe[Str]');
has config_uri           => (is => 'ro', writer => '_config_uri',     isa      => 'Maybe[Str]');
has config               => (is => 'ro', writer => '_config',         isa      => 'Helm::Conf');
has lock_type            => (is => 'ro', writer => '_lock_type',      isa      => 'LOCK_TYPE');
has sleep                => (is => 'ro', writer => '_sleep',          isa      => 'Maybe[Num]');
has current_server       => (is => 'ro', writer => '_current_server', isa      => 'Helm::Server');
has current_ssh          => (is => 'ro', writer => '_current_ssh',    isa      => 'Net::OpenSSH');
has log                  => (is => 'ro', writer => '_log',            isa      => 'Helm::Log');
has default_port         => (is => 'ro', writer => '_port',           isa      => 'Maybe[Int]');
has timeout              => (is => 'ro', writer => '_timeout',        isa      => 'Maybe[Int]');
has sudo                 => (is => 'rw', isa    => 'Maybe[Str]',      default  => '');
has extra_options        => (is => 'ro', isa    => 'Maybe[HashRef]',  default  => sub { {} });
has extra_args           => (is => 'ro', isa    => 'Maybe[ArrayRef]', default  => sub { [] });
has parallel             => (is => 'ro', isa    => 'Maybe[Bool]',     default  => 0);
has parallel_max         => (is => 'ro', isa    => 'Maybe[Int]',      default  => 100);
has continue_with_errors => (is => 'ro', isa    => 'Maybe[Bool]',     default  => 0);
has all_configured_servers => (
    is      => 'ro',
    writer  => '_all_configured_servers',
    isa     => 'Maybe[Bool]',
    default => 0,
);
has local_lock_handle => (
    is     => 'ro',
    writer => '_local_lock_handle',
    isa    => 'Maybe[FileHandle]',
);
has servers => (
    is      => 'ro',
    writer  => '_servers',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);
has roles => (
    is      => 'ro',
    writer  => '_roles',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);
has exclude_servers => (
    is      => 'ro',
    writer  => '_exclude_servers',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);
has exclude_roles => (
    is      => 'ro',
    writer  => '_exclude_roles',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);
has log_level => (
    is      => 'ro',
    writer  => '_log_level',
    isa     => 'LOG_LEVEL',
    default => 'info',
);
has _dont_exit => (
    is      => 'rw',
    isa     => 'Maybe[Bool]',
    default => 0
);

my %REGISTERED_MODULES = (
    task => {
        get       => 'Helm::Task::get',
        patch     => 'Helm::Task::patch',
        put       => 'Helm::Task::put',
        rsync_put => 'Helm::Task::rsync_put',
        run       => 'Helm::Task::run',
        unlock    => 'Helm::Task::unlock',
    },
    log => {
        console => 'Helm::Log::Channel::console',
        file    => 'Helm::Log::Channel::file',
        mailto  => 'Helm::Log::Channel::email',
        irc     => 'Helm::Log::Channel::irc',
    },
    configuration => {helm => 'Helm::Conf::Loader::helm'},
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    # allow "log" list of URIs to be passed into new() and then convert them into
    # a Helm::Log object with various Helm::Log::Channel objects
    if (my $log_uris = delete $args{log}) {
        my $log =
          Helm::Log->new($args{log_level} ? (log_level => $args{log_level}) : ());
        foreach my $uri (@$log_uris) {
            # console is a special case
            $uri = 'console://blah' if $uri eq 'console';
            $uri = try {
                URI->new($uri);
            } catch {
                CORE::die("Invalid log URI $uri");
            };
            my $scheme = $uri->scheme;
            CORE::die("Unknown log type for $uri") unless $scheme;
            my $log_class  = $REGISTERED_MODULES{log}->{$scheme};
            CORE::die("Unknown log type for $uri") unless $log_class;
            eval "require $log_class";

            if( $@ ) {
                my $log_class_file = $log_class;
                $log_class_file =~ s/::/\//g;
                if( $@ =~ /Can't locate \Q$log_class_file\E\.pm/ ) {
                    CORE::die("Can not find module $log_class for log type $scheme");
                } else {
                    CORE::die("Could not load module $log_class for log type $scheme: $@");
                }
            }
            Helm->debug("Adding new logging channel for URI $uri using class $log_class");
            $log->add_channel($log_class->new(uri => $uri, task => $args{task}));
        }
        $args{log} = $log;
    }

    return $class->$orig(%args);
};

sub BUILD {
    my $self = shift;

    $self->log->initialize($self);

    # create a config object from the config URI string (if it's not already a config object)
    if ($self->config_uri && !$self->config ) {
        Helm->debug("Loading configuration for URI " . $self->config_uri);
        $self->_config($self->load_configuration($self->config_uri));
    }

    # do we have any servers we're excluding?
    my %excludes;
    if( my @excludes = @{$self->exclude_servers} ) {
        foreach my $server_name (Helm::Server->expand_server_names(@excludes)) {
            if( my $config = $self->config ) {
                if( my $server = $config->get_server_by_abbrev($server_name, $self) ) {
                    $server_name = $server->name;
                }
            }
            $excludes{$server_name} = 1;
        }
    }

    # if we have servers let's turn them into Helm::Server objects, let's fully expand their names in case we're using abbreviations
    my @server_names = @{$self->servers};
    if(@server_names) {
        my @server_objs;
        foreach my $server_name (Helm::Server->expand_server_names(@server_names)) {
            if( $excludes{$server_name} ) {
                Helm->debug("Excluding server $server_name");
                next;
            }
            # if it's already a Helm::Server just keep it
            if( ref $server_name && blessed($server_name) && $server_name->isa('Helm::Server') ) {
                push(@server_objs, $server_name);
            } elsif( my $config = $self->config ) {
                # with a config file we can find out more about these servers
                my $server = $config->get_server_by_abbrev($server_name, $self)
                  || Helm::Server->new(name => $server_name);
                push(@server_objs, $server);
            } else {
                push(@server_objs, Helm::Server->new(name => $server_name));
            }
        }
        $self->_servers(\@server_objs);
    }

    # if we have any roles, then get the servers with (or without) those roles
    my @roles = @{$self->roles};
    my @exclude_roles = @{$self->exclude_roles};
    if( @roles ) {
        $self->die("Can't specify roles without a config") if !$self->config;
        my @servers = @{$self->servers};
        push(@servers,  grep { !$excludes{$_->name} } $self->config->get_servers_by_roles(\@roles, \@exclude_roles));
        if(!@servers) {
            if( @exclude_roles ) {
                $self->die("No servers with roles ("
                      . join(', ', @roles)
                      . ") when roles ("
                      . join(', ', @exclude_roles)
                      . ") are excluded");
            } else {
                $self->die("No servers with roles: " . join(', ', @roles));
            }
        }
        $self->_servers(\@servers);
    }
    
    # if we still don't have any servers, then use 'em all
    my @servers = @{$self->servers};
    if(!@servers) {
        $self->die("You must specify servers if you don't have a config") if !$self->config;
        
        # exclude any servers we don't want
        @servers =
          grep { !@exclude_roles || !$_->has_role(@exclude_roles) }
          grep { !$excludes{$_->name} } @{$self->config->servers};

        # are we operating on all the servers?
        if(!@exclude_roles && !%excludes ) {
            $self->_all_configured_servers(1);
        }
        
        $self->_servers(\@servers);
    }
}

sub steer {
    my $self = shift;
    my $task = $self->task;

    # make sure it's a task we know about and can load
    my $task_class = $REGISTERED_MODULES{task}->{$task};
    $self->die("Unknown task $task") unless $task_class;
    eval "require $task_class";

    if( $@ ) {
        my $task_class_file = $task_class;
        $task_class_file =~ s/::/\//g;
        if( $@ =~ /Can't locate \Q$task_class_file\E\.pm/ ) {
            $self->die("Can not find module $task_class for task $task");
        } else {
            $self->die("Could not load module $task_class for task $task");
        }
    }

    my $task_obj = $task_class->new(helm => $self);
    $task_obj->validate();

    # make sure have a local lock if we need it
    if ($self->lock_type eq 'local' || $self->lock_type eq 'both') {
        Helm->debug("Trying to optain local helm lock");
        $self->die("Cannot obtain a local helm lock. Is another helm process running?",
            no_release_locks => 1)
          unless $self->_get_local_lock;
    }

    my @servers = @{$self->servers};
    $self->log->info("Helm execution started by " . getlogin);
    if( @servers > 20 ) {
        $self->log->info(qq("Running task "$task" on ) . scalar(@servers) . " servers");
    } else {
        $self->log->info(qq(Running task "$task" on servers: ) . join(', ', @servers));
    }

    $self->log->debug("Running task setup");
    $task_obj->setup();

    my $forker;
    if( $self->parallel ) {
        Helm->debug("Setting up fork manager");
        $forker = Parallel::ForkManager->new($self->parallel_max);
        Helm->debug("Letting loggers know we're going to parallelize things");
        $self->log->parallelize($self);
    }

    # execute the task for each server
    $self->_dont_exit(1) if $self->continue_with_errors;
    foreach my $server (@servers) {
        $self->log->start_server($server);
        $self->_current_server($server);

        my $port = $server->port || $self->default_port;
        my %ssh_args = (
            ctl_dir     => catdir(File::HomeDir->my_home, '.helm'),
            strict_mode => 0,
        );
        $ssh_args{port}    = $port if $port;
        $ssh_args{timeout} = $self->timeout      if $self->timeout;
        $self->log->debug("Setting up SSH connection to $server" . ($port ? ":$port" : ''));

        # in parallel mode, send all stdout/stderr from each connection to a file
        if( $self->parallel ) {
            my $log_file = catfile(tmpdir(), "helm-$server.log");
            open(my $log_fh, '>', $log_file) or die "Could not open file $log_file for logging: $!";
            open(my $devnull, '<', devnull) or die "Could not open /dev/null: $!";
            $ssh_args{default_stdout_fh} = $log_fh;
            $ssh_args{default_stderr_fh} = $log_fh;
            $ssh_args{default_stdin_fh} = $devnull;
            $self->log->info("Logging output for $server to $log_file");

            my $pid = $forker->start;
            Helm->debug("Letting the loggers know we've actually forked off a child task worker");
            if( $pid ) {
                # let the loggers know we're now forked;
                $self->log->forked('parent');
                next;
            } else {
                $self->log->forked('child');
            }
        }

        my $connection_name = $server->name;
        my $user = $self->user;
        $connection_name = $user . '@' . $connection_name if $user;

        my $ssh = Net::OpenSSH->new($connection_name, %ssh_args);
        $ssh->error
          && $self->die("Can't ssh to $server" . ($user ? " as user $user" : '') . ": " . $ssh->error);
        $self->_current_ssh($ssh);

        # get a lock on the server if we need to
        if ($self->lock_type eq 'remote' || $self->lock_type eq 'both') {
            Helm->debug("Trying to obtain remote lock on $server");
            $self->die("Cannot obtain remote lock on $server. Is another helm process working there?",
                no_release_locks => 1) unless $self->_get_remote_lock($ssh);
        }

        Helm->debug(qq(Excuting task "$task" on server "$server"));
        $task_obj->execute(
            ssh    => $ssh,
            server => $server,
        );

        $self->log->end_server($server);
        $self->_release_remote_lock($ssh);
        if( my $secs = $self->sleep ) {
            Helm->debug("Sleeping for $secs seconds between servers");
            sleep($secs);
        }
        if($self->parallel) {
            Helm->debug("Finished work in child task process");
            $forker->finish;
        }
    }

    if( $self->parallel ) {
        Helm->debug("Waiting on all child task processes to finish");
        $forker->wait_all_children;
    }

    $self->log->debug("Running task teardown");
    $task_obj->teardown();

    # release the local lock
    $self->_release_local_lock();
    Helm->debug("Finalizing loggers");
    $self->log->finalize($self);
    Helm->debug("Finished with all tasks on all servers");
}

sub load_configuration {
    my ($self, $uri) = @_;
    $uri = try { 
        URI->new($uri) 
    } catch {
        $self->die("Invalid configuration URI $uri");
    };

    # try to load the right config module
    my $scheme = $uri->scheme;
    $self->die("Unknown config type for $uri") unless $scheme;
    my $loader_class  = $REGISTERED_MODULES{configuration}->{$scheme};
    $self->die("Unknown config type for $uri") unless $loader_class;
    eval "require $loader_class";

    if( $@ ) {
        my $loader_class_file = $loader_class;
        $loader_class_file =~ s/::/\//g;
        if( $@ =~ /Can't locate \Q$loader_class_file\E\.pm/ ) {
            $self->die("Can not find module $loader_class for configuration type $scheme");
        } else {
            $self->die("Could not load module $loader_class for configuration type $scheme: $@");
        }
    }

    $self->log->debug("Loading configuration for $uri from $loader_class");
    return $loader_class->load(uri => $uri, helm => $self);
}

sub task_help {
    my ($class, $task) = @_;
    # make sure it's a task we know about and can load
    my $task_class = $REGISTERED_MODULES{task}->{$task};
    CORE::die(qq(Unknown task "$task")) unless $task_class;
    eval "require $task_class";
    die $@ if $@;

    return $task_class->help($task);
}

sub known_tasks {
    my $class = shift;
    return sort keys %{$REGISTERED_MODULES{task}};
}

sub _get_local_lock {
    my $self = shift;
    $self->log->debug("Trying to acquire global local helm lock");
    # lock the file so nothing else can run at the same time
    my $lock_handle;
    my $lock_file = $self->_local_lock_file();
    open($lock_handle, '>', $lock_file) or $self->die("Can't open $lock_file for locking: $!");
    if (flock($lock_handle, LOCK_EX | LOCK_NB)) {
        $self->_local_lock_handle($lock_handle);
        $self->log->debug("Local helm lock obtained");
        return 1;
    } else {
        return 0;
    }
}

sub _release_local_lock {
    my $self = shift;
    if($self->local_lock_handle) {
        $self->log->debug("Releasing global local helm lock");
        close($self->local_lock_handle) 
    }
}

sub _local_lock_file {
    my $self = shift;
    return catfile(tmpdir(), 'helm.lock');
}

sub _get_remote_lock {
    my ($self, $ssh) = @_;
    my $server = $self->current_server;
    $self->log->debug("Trying to obtain remote server lock for $server");

    # make sure the lock file on the server doesn't exist
    my $lock_file = $self->_remote_lock_file();
    my $output = $self->run_remote_command(
        ssh        => $ssh,
        command    => qq(if [ -e "/tmp/helm.remote.lock" ]; then echo "lock found"; else echo "no lock found"; fi),
        ssh_method => 'capture',
    );
    chomp($output);
    if( $output eq 'lock found') {
        return 0;
    } else {
        # XXX - there's a race condition here, not sure what the right fix is though
        $self->run_remote_command(ssh => $ssh, command => "touch $lock_file");
        $self->log->debug("Remote server lock for $server obtained");
        return 1;
    }
}

sub _release_remote_lock {
    my ($self, $ssh) = @_;
    if( $self->lock_type eq 'remote' || $self->lock_type eq 'both' ) {
        $self->log->debug("Releasing remote server lock for " . $self->current_server);
        my $lock_file = $self->_remote_lock_file();
        $self->run_remote_command(ssh => $ssh, command => "rm -f $lock_file");
    }
}

sub _remote_lock_file {
    my $self = shift;
    return catfile(tmpdir(), 'helm.remote.lock');
}

sub run_remote_command {
    my ($self, %args) = @_;
    my $ssh         = $args{ssh};
    my $ssh_options = $args{ssh_options} || {};
    my $cmd         = $args{command};
    my $ssh_method  = $args{ssh_method} || 'system';
    my $server      = $args{server} || $self->current_server;
    my $sudo        = $self->sudo;

    if( $sudo && !$args{no_sudo}) {
        $cmd = "sudo -u $sudo $cmd";
        $ssh_options->{tty} = 1;
    }

    $self->log->debug("Running remote command ($cmd) on server $server");
    $ssh->$ssh_method($ssh_options, $cmd)
      or $self->die("Can't execute command ($cmd) on server $server: " . $ssh->error);
}

sub run_local_command {
    my $self = shift;
    my %args = @_ > 1 ? @_ : (command => $_[0]);
    my @cmd  = ref $args{command} ? @{$args{command}} : ($args{command});

    my $return = system(@cmd);
    if( system(@cmd) != 0 ) {
        $self->die("Can't execute local command (" . join(' ', @cmd) . ": " . $!);
    }
}

sub ssh_connection {
    my ($self, %args) = @_;
    my $server = $args{server};
    my %ssh_args = (
        ctl_dir     => catdir(File::HomeDir->my_home, '.helm'),
        strict_mode => 0,
    );
    my $port = $server->port || $self->default_port;
    $ssh_args{port}    = $port if $port;
    $ssh_args{timeout} = $self->timeout      if $self->timeout;
    $self->log->debug("Setting up SSH connection to $server" . ($port ? ":$port" : ''));
    return Net::OpenSSH->new($server->name, %ssh_args);
}

sub die {
    my ($self, $msg, %options) = @_;
    $self->log->error($msg);
    unless($options{no_release_locks}) {
        $self->_release_remote_lock($self->current_ssh);
        $self->_release_local_lock();
    }

    exit(1) unless $self->_dont_exit;
}

sub register_module {
    my ($class, $type, $key, $module) = @_;
    CORE::die("Unknown Helm module type '$type'!") unless exists $REGISTERED_MODULES{$type};
    Helm->debug("Loading module $module for $type plugins with key $key");
    $REGISTERED_MODULES{$type}->{$key} = $module;
}

# this is a class method so that it can be called even before any objects
# have been fully initialized.
sub debug {
    return unless $DEBUG;
    my ($self, @msgs) = @_;

    # open the debug log handle if we haven't opened it yet
    # or re-open if we're already opened it in another process
    if(!$DEBUG_LOG || $DEBUG_LOG_PID != $$) {
        $DEBUG_LOG = IO::File->new('>> debug.log')
          or $self->die("Could not open helm.debug for appending: $!");
        $DEBUG_LOG->autoflush(1);
        $DEBUG_LOG_PID = $$;
    }

    my $ts = DateTime->now->strftime('%a %b %d %H:%M:%S %Y'); 
    my ($calling_class) = caller();
    foreach my $msg (@msgs) {
        $msg =~ s/\s+$//;
        $DEBUG_LOG->print("[$ts] [$$] [$calling_class] $msg\n");
    } 
}

__PACKAGE__->meta->make_immutable;

1;
