package Working::Daemon;

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use Carp;

our $VERSION = 0.31;
our $SVN = 5236;
our %config;

#these are all default configs

# perl really need the protocols file to function
sub chroot_files { return ("/etc/protocols") }

sub chroot_dirs { return ("/etc/") }

sub default_action { return "start" }

sub exit_success { exit(0) }

sub exit_error { exit(1) }

sub default_options {
    return (
        "help"       => undef() => "This help",
        "version"    => undef() => "Version number",
        "loglevel=i" => undef() => "The higher the loglevel, the more detailed messages. Default to 0",
        "daemon!"    => undef() => "Set to --no-daemon if you don't want it to daemonize. Default is true",
        "chroot!"    => undef() => "Set to --no-chroot if you don't want it to chroot. Default is true",
        "foreground" => undef() => "Inverse of daemonize, default is off",
        "user=s"     => undef() => "User to run this app as. Default is 'nobody'",
        "group=s"    => undef() => "Group to run this app as. Default is 'nobody'",
        "pidfile=s"  => undef() => "Where to store the pidfile. Default is /var/run/\$name.pid",
        "name=s"     => undef() => "Name of this app")
}


sub tmpdir {
    my $self = shift;
    return "/tmp/" . $self->name . ".$$";
}


# end of config methods

sub standard {
    my $self = shift;
    $self->parse_options(@_);
    $self->do_action();
    $self->change_root();
    $self->drop_privs();
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}


sub do_action {
    my $self = shift;
    my $action = shift @ARGV || $self->default_action;
    my $action_method = "action_$action";
    $self->print_version if($self->options->{version});
    if ($self->options->{help}) {
        $self->show_help;
        exit;
    }

    if($self->can($action_method)) {
        my $exit_value = $self->$action_method;
        exit $exit_value unless ($action eq 'start' || $action eq 'restart');
    } else {
        print STDERR "Unknown command '$action'\n";
        $self->show_help;
        exit;
    }
}

sub show_help {
    my $self = shift;
    my %options_desc = %{$self->options_desc};
    %options_desc = $self->default_options if (!%options_desc);
    my $max_length = 0;
    my @commands;
    my @desc;
    my @values;
    foreach my $option (keys %options_desc) {
        my $command = $option;
        if($command =~s/\=(.)%?//g) {
            $command .= "=str" if($1 eq 's');
            $command .= "=int" if($1 eq 'i');
        }
        $command = "no-$command" if($command =~s/\!$//);
        $max_length = length($command) if(length($command) > $max_length);
        push @commands, $command;
        push @desc, $options_desc{$option};
        $option =~s/(\w+)/$1/;
        my $raw_option = $1;
        if ($self->can($raw_option)) {
            push @values, $self->$raw_option;
        } else {
            push @values, ($self->options->{$raw_option}||"");
        }
    }
    $max_length += 4;
    print STDERR "[start | stop | restart | status]\n";
    foreach my $command (@commands) {
        my $cmd = sprintf("  --%-${max_length}s", $command);
        my $desc = shift @desc;
        my $value = shift @values;
        print STDERR "$cmd$desc: $value\n";
    }
    exit;
}

sub parse_options {
    my $self = shift;

    my %options;
    my %option_keys;
    my @options = ($self->default_options, @_);
    while(@options) {
        my $option = shift @options;
        my $default_value = shift @options;
        my $help = shift @options;
        $option_keys{$option} = $help;
        my ($key) = $option =~/(\w+)/;
        $options{$key} = $default_value if(defined $default_value);
    }
    GetOptions(\%options, keys %option_keys);
    $self->options(\%options);
    $self->options_desc(\%option_keys);
    $self->assign_options(qw(user group name chroot foreground daemon pidfile));
    $self->init();
    return \%options;

}

sub init {}

sub print_version {
    my $self = shift;
    my $name = $self->name;
    my $version = $self->version;
    print STDERR "$name $version (Working::Daemon: $VERSION)\n";
}


sub assign_options {
    my ($self, @options) = @_;
    foreach my $option (@options) {
        $self->$option($self->options->{$option})
            if (exists $self->options->{$option});
    }
}


sub change_root {
    my $self = shift;
    return unless $self->chroot;

    my $tmpdir = $self->tmpdir;
    mkdir ($tmpdir)
        || croak "Cannot create directory '$tmpdir': $!";

    chown($self->uid,$self->gid, $tmpdir)
        || croak("Cannot chown $tmpdir to (". $self->uid . ":". $self->gid . "): $!");

    my $dirs  = $self->{__PACKAGE__}->{chroot_clean_dirs} = [];
    my $files = $self->{__PACKAGE__}->{chroot_clean_files} = [];

    foreach my $dir ($self->chroot_dirs) {
        push @$dirs, "$tmpdir/$dir";
        mkdir("$tmpdir/$dir")
            || croak "Cannot create $tmpdir/$dir: $!";
    }

    foreach my $file_to_copy ($self->chroot_files) {
        push @$files, "$tmpdir/$file_to_copy";
        copy("$file_to_copy", "$tmpdir/$file_to_copy")
            || croak "Cannot copy $file_to_copy -> $tmpdir/$file_to_copy: $!";
    }

    chroot("$tmpdir/")
        || croak ("Can't chroot to $tmpdir: $!");
    chdir("/")
        || croak ("Can't chdir to '/': $!");
}

sub version {
    my $self = shift;
    my $caller = caller(2);
    no strict 'refs';
    my $varname = "${caller}::VERSION";
    my $version = $$varname;
    return $version || "";
}

sub write_pidfile {
    my $self = shift;
    my $pidfile = $self->pidfile;
    open(my $pidfh, "+>$pidfile") || croak "Cannot open '$pidfile': $!";
    print $pidfh "$$";
    close $pidfh;
}


sub delete_pidfile {
    my $self = shift;
    unlink($self->pidfile) || croak "Cannot remove pidfile '".$self->pidfile."': $!";
}


sub cleanup_chroot {
#    unlink("/tmp/glbdns.$pid/etc/protocols") || die "$!";
#    rmdir("/tmp/glbdns.$pid/etc/") || die;
#    rmdir("/tmp/glbdns.$pid/") || die;
#    unlink($config{pidfile}) || die $!;
}

sub action_start {
    my $self = shift;
    my $name = $self->name;
    if(my $pid = $self->get_pid) {
        $self->log(0, "fatal", "Cannot start '$name' because it is already running at $pid");
        $self->exit_error;
    }
    $self->log(0, 'info', "Starting '$name'");
    $self->daemonize;
    $self->spawn_worker_child;
}

sub spawn_worker_child {
    my $self = shift;
    if(my $pid = fork()) {
        my $name = $self->name;
        # this is the master session
        # it makes sure to cleanup from the slave
        # it stays as superuser


        $self->write_pidfile;

        $self->openlog;
        $self->log(1, 'info', "started master session $name - child is $pid");
        $SIG{INT} = sub { kill(2,$pid) };
        $0 = "$name - waiting for child $pid";
        $self->wait_for_worker_child($pid);
        $self->log(1, 'info', "exiting master session $name - child is $pid");

        $self->cleanup_chroot;

        $self->delete_pidfile;
        exit;
    }

    return 1;
}

sub wait_for_worker_child {
    my ($self, $pid) = @_;
    waitpid($pid, 0);
}

sub action_restart {
    my $self = shift;
    if ($self->is_running) {
        $self->action_stop
    }
    $self->action_start;
}

sub action_status {
    my $self = shift;
    if (my $pid = $self->is_running) {
        print STDERR $self->name . " is running on $pid\n";
        return 0;
    } else {
        print STDERR $self->name . " is not running\n";
        return 1;
    }
}

sub action_stop {
    my $self = shift;
    my $pid = $self->is_running;
    if ($pid) {
        while($self->is_running) {
            kill(2, $pid);
            $self->log(0, 'info', "sent SIGINT to $pid - waiting on stopped pid $pid");
            sleep 1;
        }
        $self->log(0, 'info',"Stopped " . $self->name . " on $pid");
    } else {
        $self->log(0, 'info', $self->name . " is not running");
    }
    return 0;
}

sub is_running {
    my $self = shift;
    my $pid = $self->get_pid;
    return $pid
        if($self->check_pid($pid));
    return 0;
}

sub openlog {
#        openlog("$config{name}", 'ndelay,pid', LOG_DAEMON) if($config{syslog});}
}


sub get_pid {
    # pid code needs serious overhaul to use flock
    my $self = shift;
    my $pidfile = $self->pidfile;
    if(-r $pidfile) {
        open(my $pidfh, "<$pidfile") || croak "Cannot open pidfile ($pidfile): $!";
        my $line = <$pidfh>;
        close($pidfh);
        $line =~/(\d+)/;
        if(my $pid_to_check = $1) {
            $ENV{PATH} = '';
            return $pid_to_check if($self->check_pid($pid_to_check));
        }
    }
   return 0;
}


sub check_pid {
    my $self = shift;
    my $pid  = shift;
    return 0 unless $pid;
    my $grep = "/bin/grep";
    $grep = "/usr/bin/grep" if ($^O eq 'darwin');
    my $name = $self->name;
    my $rv = qx{/bin/ps ax | $grep $pid | $grep -v grep | $grep $name};
    $rv =~s/\s+$//;
    print STDERR "$rv\n";
    return !$?;
}


sub daemonize {
    my $self = shift;
    return 0 unless $self->daemon;
    use POSIX qw(setsid);
    my $name = $self->name;
    defined(my $pid = fork) || croak "Can't fork: $!";
    if ($pid) {
        print "$name started on $pid\n";
        exit 0;
    }
    setsid() || croak "Can't start a new session: $!";
    open (STDIN , '/dev/null') || croak "Can't read /dev/null: $!";
    open (STDOUT, '>/dev/null') || croak "Can't write to /dev/null: $!";
    open (STDERR, '>/dev/null') || croak "Can't write to /dev/null: $!";
    return 1;
}


sub log {
    my ($self, $level, $prio, $msg) = @_;
    return if ($level > $self->log_level);
    $self->do_log($prio, $msg);
}


sub do_log {
    my ($self, $prio, $msg) = @_;
    print STDERR "$prio - $msg\n";
}


sub drop_privs {
    my $self = shift;
  # drop user
    $< = $self->uid;
    $> = $self->uid;
  # drop group
    $( = $self->gid;
    $) = $self->gid;
}


sub uid {
    my $self = shift;
    return scalar getpwnam($self->user);
}


sub gid {
    my $self = shift;
    return scalar getpwnam($self->group);
}



# accessors
# yes they are nearly identical

sub user {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{user} = shift;
    } elsif (exists($self->{__PACKAGE__}->{user})) {
        return $self->{__PACKAGE__}->{user};
    } else {
        return "nobody";
    }
}


sub pidfile {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{pidfile} = shift;
    } elsif (exists($self->{__PACKAGE__}->{pidfile})) {
        return $self->{__PACKAGE__}->{pidfile};
    } else {
        return "/var/run/". $self->name . ".pid";
    }
}


sub daemon {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{daemon} = shift;
    } elsif (exists($self->{__PACKAGE__}->{daemon})) {
        return $self->{__PACKAGE__}->{daemon};
    } else {
        return 1;
    }
}


sub foreground {
    my $self = shift;
    if (@_) {
        return $self->daemon(!$_[0]);
    } else {
        return !$self->daemon;
    }
}


sub chroot {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{chroot} = shift;
    } elsif (exists($self->{__PACKAGE__}->{chroot})) {
        return $self->{__PACKAGE__}->{chroot};
    } else {
        return 1;
    }
}


sub log_level {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{log_level} = shift;
    } elsif (exists($self->{__PACKAGE__}->{log_level})) {
        return $self->{__PACKAGE__}->{log_level};
    } else {
        return 1;
    }
}


sub group {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{group} = shift;
    } elsif (exists($self->{__PACKAGE__}->{group})) {
        return $self->{__PACKAGE__}->{group};
    } else {
        return "nobody";
    }
}


sub name {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{name} = shift;
    } elsif (exists($self->{__PACKAGE__}->{name})) {
        return $self->{__PACKAGE__}->{name};
    } else {
        return "unnamed app";
    }
}


sub options {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{options} = shift;
    } elsif (exists($self->{__PACKAGE__}->{options})) {
        return $self->{__PACKAGE__}->{options};
    } else {
        return {};
    }
}

sub options_desc {
    my $self = shift;
    if (@_) {
        return $self->{__PACKAGE__}->{options_desc} = shift;
    } elsif (exists($self->{__PACKAGE__}->{options_desc})) {
        return $self->{__PACKAGE__}->{options_desc};
    } else {
        return {};
    }
}






# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Working::Daemon - Perl extension for turning your script inta daemon.

=head1 SYNOPSIS

  use Working::Daemon;
  our $VERSION = 0.45;
  my $daemon = Working::Daemon->new();
  $daemon->name("testdaemon");
  $daemon->standard("bool"      => 1 => "Test if you can set bools",
                    "integer=i" => 2323 => "Integer settings",
                    "string=s"  => string => "String setting",
                    "multi=s%"  => undef() => "Multiset variable");

Or

  use Working::Daemon;
  our $VERSION = 0.45;
  my $daemon = Working::Daemon->new();
  $daemon->name("testdaemon");
  $daemon->user("foo");
  $daemon->parse_options("myoption" => "sets myoption!");
  $daemon->do_action;

  # only the worker continues to from here
  $self->change_root;
  $self->drop_privs;

  # your app codefrom here

=head1 DESCRIPTION

This is a modular Daemon wrapper. It handles forking, master session, chroot
pidfiles, and command line parsing.

While it isn't perfect yet, it works better than any existing
on CPAN. Notably it doesn't force itself on you unconditionally.

The commandline parsing uses Getopt::Long

It also supports start,stop,status and restart. So you can symlink your
daemon directly into init.d

=head1 SEE ALSO

=head1 AUTHOR

Artur Bergman, E<lt>sky+cpan@crucially.net@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Artur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
