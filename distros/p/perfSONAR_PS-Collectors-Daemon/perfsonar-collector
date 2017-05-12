#!/usr/bin/perl -w -I lib

=head1 NAME

perfsonar.pl - An basic Measurement Collection framework

=head1 DESCRIPTION

This script shows how a script for a given service should look.

=head1 SYNOPSIS

./perfsonar-collector.pl [--verbose --help --config=config.file --piddir=/path/to/pid/dir --pidfile=filename.pid]\n";

The verbose flag allows lots of debug options to print to the screen.  If the option is
omitted the service will run in daemon mode.
=cut

use warnings;
use strict;
use Getopt::Long;
use Time::HiRes qw( gettimeofday );
use POSIX qw( setsid );
use File::Basename;
use Fcntl qw(:DEFAULT :flock);
use POSIX ":sys_wait_h";
use Cwd;
use Config::General;
use Module::Load;

our $VERSION = 0.09;

sub handleCollector($);
sub daemonize();
sub managePID($$);
sub killChildren();
sub signalHandler();
sub handleRequest($$$);

my $libdir;
my $confdir;
my $dirname;

# In the non-installed case, we need to figure out what the library is at
# compile time so that "use lib" doesn't fail. To do this, we enclose the
# calculation of it in a BEGIN block.
BEGIN {
    # this value is set by the installation scripts
    my $was_installed = 0;

    if ($was_installed) {
        # In this case, libdir needs to be set to the directory that the modules
        # were installed to, and confdir needs to be set to the directory that
        # logger.conf et al. were installed in. The installation script
        # replaces the LIBDIR and CONFDIR portions with the actual directories
        $libdir = "XXX_LIBDIR_XXX";
        $confdir = "XXX_CONFDIR_XXX";
        $dirname = "";
    } else {
        # we need a fully-qualified directory name in case we daemonize so that we
        # can still access scripts or other files specified in configuration files
        # in a relative manner. Also, we need to know the location in reference to
        # the binary so that users can launch the daemon from wherever but specify
        # scripts and whatnot relative to the binary.

        $dirname = dirname($0);

        if (!($dirname =~ /^\//)) {
            $dirname = getcwd . "/" . $dirname;
        }

        $confdir = $dirname;

        $libdir = dirname($0)."/lib";
    }
}

use lib "$libdir";

use perfSONAR_PS::Common;

my %child_pids = ();

$SIG{PIPE} = 'IGNORE';
$SIG{ALRM} = 'IGNORE';
$SIG{INT} = \&signalHandler;
$SIG{TERM} = \&signalHandler;

my $DEBUGFLAG = '';
my $READ_ONLY = '';
my $HELP = '';
my $CONFIG_FILE  = '';
my $LOGGER_CONF  = '';
my $PIDDIR = '';
my $PIDFILE = '';
my $LOGOUTPUT = '';
my $IGNORE_PID = '';

my $status = GetOptions (
        'config=s' => \$CONFIG_FILE,
        'logger=s' => \$LOGGER_CONF,
        'output=s' => \$LOGOUTPUT,
        'piddir=s' => \$PIDDIR,
        'pidfile=s' => \$PIDFILE,
        'ignorepid' => \$IGNORE_PID,
        'verbose' => \$DEBUGFLAG,
        'help' => \$HELP);

if(!$status or $HELP) {
    print "$0: starts the collector daemon.\n";
    print "\t$0 [--verbose --help --config=config.file --piddir=/path/to/pid/dir --pidfile=filename.pid --logger=logger/filename.conf --ignorepid]\n";
    exit(1);
}

my $logger;
if (!defined $LOGGER_CONF or $LOGGER_CONF eq "") {
    use Log::Log4perl qw(:easy);

    my $output_level = $INFO;
    if($DEBUGFLAG) {
        $output_level = $DEBUG;
    }

    my %logger_opts = (
        level => $output_level,
        layout => '%d (%P) %p> %F{1}:%L %M - %m%n',
    );

    if (defined $LOGOUTPUT and $LOGOUTPUT ne "") {
        $logger_opts{file} = $LOGOUTPUT;
    }

    Log::Log4perl->easy_init( \%logger_opts );
    $logger = get_logger("perfSONAR_PS");
} else {
    use Log::Log4perl qw(get_logger :levels);

    my $output_level = $INFO;
    if($DEBUGFLAG) {
        $output_level = $DEBUG;
    }
 
    Log::Log4perl->init($LOGGER_CONF);
    $logger = get_logger("perfSONAR_PS");
    $logger->level($output_level);
}

if (!defined $CONFIG_FILE or $CONFIG_FILE eq "") {
    $CONFIG_FILE = $confdir."/collector.conf";
}

# Read in configuration information
my $config =  new Config::General($CONFIG_FILE);
my %conf = $config->getall;

if (!defined $conf{"collection_interval"} or $conf{"collection_interval"} eq "") {
    $logger->warn("Setting default collection interval at 15 seconds");
    $conf{"collection_interval"} = 15;
}

my $pidfile;

if (!defined $IGNORE_PID or $IGNORE_PID eq "") {
    if (!defined $PIDDIR or $PIDDIR eq "") {
        if (defined $conf{"pid_dir"} and $conf{"pid_dir"} ne "") {
            $PIDDIR = $conf{"pid_dir"};
        } else {
            $PIDDIR = "/var/run";
        }
    }

    if (!defined $PIDFILE or $PIDFILE eq "") {
        if (defined $conf{"pid_file"} and $conf{"pid_file"} ne "") {
            $PIDFILE = $conf{"pid_file"};
        } else {
            $PIDFILE = "ps.pid";
        }
    }

    $pidfile = lockPIDFile($PIDDIR, $PIDFILE);
}

$logger->debug("Starting '".$$."'");

my %loaded_modules = ();

my %modules_loaded = ();
my @collectors = ();

if (!defined $conf{"collector"}) {
    $logger->error("No collectors defined");
    exit(-1);
}

if (ref $conf{"collector"} ne "ARRAY") {
    $logger->debug("Converting singular collector reference to array");
    my @conf_collectors = ();
    push @conf_collectors, $conf{"collector"};
    $conf{"collector"} = \@conf_collectors;
}

foreach my $collectors (@{ $conf{"collector"} }) {
    foreach my $id (keys %{ $collectors }) {
        my $collector = $collectors->{$id};

        my %collector_conf = %{ mergeConfig(\%conf, $collector) };

        if (!defined $collector_conf{"module"} or $collector_conf{"module"} eq "") {
            $logger->error("No module specified for collector");
            exit(-1);
        }

        if (!defined $modules_loaded{$collector_conf{"module"}}) {
            load $collector_conf{"module"};
            $modules_loaded{$collector_conf{"module"}} = 1;
        }

        my $collector_obj = $collector_conf{"module"}->new(\%collector_conf, $dirname);
        if ($collector_obj->init() != 0) {
            $logger->error("Failed to initialize module ".$collector_conf{"module"});
            exit(-1);
        }

        my %collector_info = ();
        $collector_info{"collector"} = $collector_obj;
        $collector_info{"config"} = \%collector_conf;
        push @collectors, \%collector_info;
    }
}

# Daemonize if not in debug mode. This must be done before forking off children
# so that the children are daemonized as well.
if(!$DEBUGFLAG) {
# flush the buffer
    $| = 1;
    &daemonize;
}

$0 = "perfsonar-collector.pl ($$)";

foreach my $collector_args (@collectors) {
    my $collector_pid = fork();
    if ($collector_pid == 0) {
        %child_pids = ();
        handleCollector($collector_args);
        exit(0);
    } elsif ($collector_pid < 0) {
        $logger->error("Couldn't spawn LS");
        killChildren();
        exit(-1);
    }

    $child_pids{$collector_pid} = "";
}

if (!defined $IGNORE_PID or $IGNORE_PID eq "") {
    unlockPIDFile($pidfile);
}

foreach my $pid (keys %child_pids) {
    waitpid($pid, 0);
}

=head2 handleCollector($args)
    The registerLS function is called in a separate process or thread and
    is responsible for calling the specified service's 'registerLS'
    function regularly.
=cut
sub handleCollector($) {
    my ($args) = @_;

    my $collector = $args->{"collector"};
    my $config = $args->{"config"};
    my $default_interval = $config->{"collection_interval"};
    my $collector_id = $config->{"id"};
    $0 .= " - Collector";

    if (defined $collector_id and $collector_id ne "") {
         $0 .= " - $collector_id";
    }

    while(1) {
        my $sleep_time;

        $collector->collectMeasurements(\$sleep_time);

        if (!defined $sleep_time or $sleep_time eq "") {
            $sleep_time = $default_interval;
        }

        $logger->debug("Sleeping for $sleep_time");

        sleep($sleep_time);
    }
}

=head2 daemonize
Sends the program to the background by eliminating ties to the calling terminal.
=cut
sub daemonize() {
    chdir '/' or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    setsid or die "Can't start a new session: $!";
    umask 0;
}

=head2 lockPIDFile($piddir, $pidfile);
The lockPIDFile function checks for the existence of the specified file in
the specified directory. If found, it checks to see if the process in the
file still exists. If there is no running process, it returns the filehandle for the open pidfile that has been flock(LOCK_EX).
=cut
sub lockPIDFile($$) {
    $logger->debug("Locking pid file");
    my($piddir, $pidfile) = @_;
    die "Can't write pidfile: $piddir/$pidfile\n" unless -w $piddir;
    $pidfile = $piddir ."/".$pidfile;
    sysopen(PIDFILE, $pidfile, O_RDWR | O_CREAT);
    flock(PIDFILE, LOCK_EX);
    my $p_id = <PIDFILE>;
    chomp($p_id) if (defined $p_id);
    if(defined $p_id and $p_id ne "") {
        open(PSVIEW, "ps -p ".$p_id." |");
        my @output = <PSVIEW>;
        close(PSVIEW);
        if(!$?) {
            die "$0 already running: $p_id\n";
        }
    }

    $logger->debug("Locked pid file");

    return *PIDFILE;
}

=head2 unlockPIDFile($)
This file writes the pid of the call process to the filehandle passed in,
unlocks the file and closes it.
=cut
sub unlockPIDFile($) {
    my($filehandle) = @_;

    truncate($filehandle, 0);
    seek($filehandle, 0, 0);
    print $filehandle "$$\n";
    flock($filehandle, LOCK_UN);
    close($filehandle);

    $logger->debug("Unlocked pid file");
}

=head2 killChildren
Kills all the children for this process off. It uses global variables
because this function is used by the signal handler to kill off all
child processes.
=cut
sub killChildren() {
    foreach my $pid (keys %child_pids) {
        kill("SIGINT", $pid);
    }
}

=head2 signalHandler
Kills all the children for the process and then exits
=cut
sub signalHandler() {
    killChildren();
    exit(0);
}

=head1 SEE ALSO

L<perfSONAR_PS::Services::Base>, L<perfSONAR_PS::Services::MA::General>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Transport>,
L<perfSONAR_PS::Client::Status::MA>, L<perfSONAR_PS::Client::Topology::MA>

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
