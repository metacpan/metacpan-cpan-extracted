#!/usr/bin/perl -w -I lib

=head1 NAME

perfsonar.pl - An basic MA (Measurement Archive) framework

=head1 DESCRIPTION

This script shows how a script for a given service should look.

=head1 SYNOPSIS

./perfsonar.pl [--verbose --help --config=config.file --piddir=/path/to/pid/dir --pidfile=filename.pid]\n";

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
use HTTP::Daemon;

our $VERSION = 0.09;

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

my %ns = (
  nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
  nmtm => "http://ggf.org/ns/nmwg/time/2.0/",
  ifevt => "http://ggf.org/ns/nmwg/event/status/base/2.0/",
  iperf => "http://ggf.org/ns/nmwg/tools/iperf/2.0/",
  bwctl => "http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
  owamp => "http://ggf.org/ns/nmwg/tools/owamp/2.0/",
  netutil => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
  neterr => "http://ggf.org/ns/nmwg/characteristic/errors/2.0/",
  netdisc => "http://ggf.org/ns/nmwg/characteristic/discards/2.0/" ,
  snmp => "http://ggf.org/ns/nmwg/tools/snmp/2.0/",
  select => "http://ggf.org/ns/nmwg/ops/select/2.0/",
  perfsonar => "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/",
  psservice => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/",
  nmwgr => "http://ggf.org/ns/nmwg/result/2.0/",
  xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/",
  xpath => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xpath/1.0/",
  nmwgt => "http://ggf.org/ns/nmwg/topology/2.0/",
  nmwgtopo3 => "http://ggf.org/ns/nmwg/topology/base/3.0/",
  ctrlplane => "http://ogf.org/schema/network/topology/ctrlPlane/20070707/",
  CtrlPlane => "http://ogf.org/schema/network/topology/ctrlPlane/20070626/",
  ctrlplane_oct => "http://ogf.org/schema/network/topology/ctrlPlane/20071023/",
  ethernet => "http://ogf.org/schema/network/topology/ethernet/20070828/",
  ipv4 => "http://ogf.org/schema/network/topology/ipv4/20070828/",
  ipv6 => "http://ogf.org/schema/network/topology/ipv6/20070828/",
  nmtb => "http://ogf.org/schema/network/topology/base/20070828/",
  nmtl2 => "http://ogf.org/schema/network/topology/l2/20070828/",
  nmtl3 => "http://ogf.org/schema/network/topology/l3/20070828/",
  nmtl4 => "http://ogf.org/schema/network/topology/l4/20070828/",
  nmtopo => "http://ogf.org/schema/network/topology/base/20070828/",
  sonet => "http://ogf.org/schema/network/topology/sonet/20070828/",
  transport => "http://ogf.org/schema/network/topology/transport/20070828/",
  pinger => "http://ggf.org/ns/nmwg/tools/pinger/2.0/",
  traceroute => "http://ggf.org/ns/nmwg/tools/traceroute/2.0/",
  tracepath => "http://ggf.org/ns/nmwg/tools/traceroute/2.0/",
  ping => "http://ggf.org/ns/nmwg/tools/ping/2.0/"
);

use lib "$libdir";

use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Request;
use perfSONAR_PS::RequestHandler;
use perfSONAR_PS::Error_compat qw/:try/;
use perfSONAR_PS::Error;

my %child_pids = ();

$SIG{CHLD} = \&REAPER;
$SIG{PIPE} = 'IGNORE';
$SIG{ALRM} = 'IGNORE';
$SIG{INT} = \&signalHandler;
$SIG{TERM} = \&signalHandler;

my $DEBUGFLAG = q{};
my $READ_ONLY = q{};
my $HELP = q{};
my $CONFIG_FILE  = q{};
my $LOGGER_CONF  = q{};
my $PIDDIR = q{};
my $PIDFILE = q{};
my $LOGOUTPUT = q{};

my $status = GetOptions (
        'config=s' => \$CONFIG_FILE,
        'logger=s' => \$LOGGER_CONF,
        'output=s' => \$LOGOUTPUT,
        'piddir=s' => \$PIDDIR,
        'pidfile=s' => \$PIDFILE,
        'verbose' => \$DEBUGFLAG,
        'help' => \$HELP);

if(not $status or $HELP) {
    print "$0: starts the MA daemon.\n";
    print "\t$0 [--verbose --help --config=config.file --piddir=/path/to/pid/dir --pidfile=filename.pid --logger=logger/filename.conf]\n";
    exit(1);
}

my $logger;
if (not defined $LOGGER_CONF or $LOGGER_CONF eq q{}) {
    use Log::Log4perl qw(:easy);

    my $output_level = $INFO;
    if($DEBUGFLAG) {
        $output_level = $DEBUG;
    }

    my %logger_opts = (
        level => $output_level,
        layout => '%d (%P) %p> %F{1}:%L %M - %m%n',
    );

    if (defined $LOGOUTPUT and $LOGOUTPUT ne q{}) {
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

if (not defined $CONFIG_FILE or $CONFIG_FILE eq q{}) {
    $CONFIG_FILE = $confdir."/daemon.conf";
}

# Read in configuration information
my $config =  new Config::General($CONFIG_FILE);
my %conf = $config->getall;

if (not defined $conf{"max_worker_lifetime"} or $conf{"max_worker_lifetime"} eq q{}) {
    $logger->warn("Setting maximum worker lifetime at 60 seconds");
    $conf{"max_worker_lifetime"} = 60;
}

if (not defined $conf{"max_worker_processes"} or $conf{"max_worker_processes"} eq q{}) {
    $logger->warn("Setting maximum worker processes at 32");
    $conf{"max_worker_processes"} = 32;
}

if (not defined $conf{"ls_registration_interval"} or $conf{"ls_registration_interval"} eq q{}) {
    $logger->warn("Setting LS registration interval at 60 minutes");
    $conf{"ls_registration_interval"} = 60;
}

# turn the interval from minutes to seconds
$conf{"ls_registration_interval"} *= 60;

if (not defined $conf{"disable_echo"} or $conf{"disable_echo"} eq q{}) {
    $logger->warn("Enabling echo service for each endpoint unless specified otherwise");
    $conf{"disable_echo"} = 0;
}

if (not defined $conf{"reaper_interval"} or $conf{"reaper_interval"} eq q{}) {
    $logger->warn("Setting reaper interval to 20 seconds");
    $conf{"reaper_interval"} = 20;
}

if (not defined $PIDDIR or $PIDDIR eq q{}) {
    if (defined $conf{"pid_dir"} and $conf{"pid_dir"} ne q{}) {
        $PIDDIR = $conf{"pid_dir"};
    } else {
        $PIDDIR = "/var/run";
    }
}

if (not defined $PIDFILE or $PIDFILE eq q{}) {
    if (defined $conf{"pid_file"} and $conf{"pid_file"} ne q{}) {
        $PIDFILE = $conf{"pid_file"};
    } else {
        $PIDFILE = "ps.pid";
    }
}

my $pidfile = lockPIDFile($PIDDIR, $PIDFILE);

$logger->debug("Starting '".$$."'");

my @ls_services;
my @ls_reaper;

my %loaded_modules = ();
my $echo_module = "perfSONAR_PS::Services::Echo";

my %handlers = ();
my %listeners = ();
my %modules_loaded = ();
my %port_configs = ();
my %service_configs = ();

if (not defined $conf{"port"}) {
    $logger->error("No ports defined");
    exit(-1);
}

foreach my $port (keys %{ $conf{"port"} }) {
    my %port_conf = %{ mergeConfig(\%conf, $conf{"port"}->{$port}) };

    next if (defined $port_conf{"disabled"} and $port_conf{"disabled"} == 1);

    $service_configs{$port} = \%port_conf;

    if (not defined $conf{"port"}->{$port}->{"endpoint"}) {
        $logger->warn("No endpoints specified for port $port");
        next;
    }

    my $listener = HTTP::Daemon->new(
                        LocalPort => $port,
                        ReuseAddr => 1,
                        Timeout => $port_conf{"reaper_interval"},
                    ); 
    if (not defined $listener != 0) {
        $logger->error("Couldn't start daemon on port $port");
        exit(-1);
    }

    $listeners{$port} = $listener;

    $handlers{$port} = ();

    $service_configs{$port}->{"endpoint"} = ();

    my $num_endpoints = 0;

    foreach my $key (keys %{ $conf{"port"}->{$port}->{"endpoint"} }) {
        my $fixed_endpoint = $key;
        $fixed_endpoint = "/".$key if ($key =~ /^[^\/]/);

        my %endpoint_conf = %{ mergeConfig(\%port_conf, $conf{"port"}->{$port}->{"endpoint"}->{$key}) };

        $service_configs{$port}->{"endpoint"}->{$fixed_endpoint} = \%endpoint_conf;

        next if (defined $endpoint_conf{"disabled"} and $endpoint_conf{"disabled"} == 1);

        $logger->debug("Adding endpoint $fixed_endpoint to $port");

        $handlers{$port}->{$fixed_endpoint} = perfSONAR_PS::RequestHandler->new();

        if (not defined $endpoint_conf{"module"} or $endpoint_conf{"module"} eq q{}) {
            $logger->error("No module specified for $port:$fixed_endpoint");
            exit(-1);
        }

        my @endpoint_modules = ();

        if (ref $endpoint_conf{"module"} eq "ARRAY") {
            @endpoint_modules = @{ $endpoint_conf{"module"} };
        } else {
            $logger->debug("Modules is not an array: ".ref($endpoint_conf{"module"}));
            push @endpoint_modules, $endpoint_conf{"module"};
        }

        # the echo module is loaded by default unless otherwise specified
        if (not $endpoint_conf{"disable_echo"} and not $conf{"disable_echo"}) {
            my $do_load = 1;
            foreach my $curr_module (@endpoint_modules) {
                if ($curr_module eq $echo_module) {
                    $do_load = 0;
                }
            }

            if ($do_load) {
                push @endpoint_modules, $echo_module;
            }
        }

        foreach my $module (@endpoint_modules) {
            if (not defined $modules_loaded{$module}) {
                load $module;
                $modules_loaded{$module} = 1;
            }

            my $service = $module->new(\%endpoint_conf, $port, $fixed_endpoint, $dirname);
            if ($service->init($handlers{$port}->{$fixed_endpoint}) != 0) {
                $logger->error("Failed to initialize module ".$module." on $port:$fixed_endpoint");
                exit(-1);
            }

            if ($service->needLS()) {
                my %ls_child_args = ();
                $ls_child_args{"service"} = $service;
                $ls_child_args{"conf"} = \%endpoint_conf;
                $ls_child_args{"port"} = $port;
                $ls_child_args{"endpoint"} = $fixed_endpoint;
                push @ls_services, \%ls_child_args;
            }

            if ($service->can("cleanLS")) {
                my %ls_reaper_args = ();
                $ls_reaper_args{"service"} = $service;
                $ls_reaper_args{"conf"} = \%endpoint_conf;
                push @ls_reaper, \%ls_reaper_args;
            }
        }

        $num_endpoints++;
    }

    if ($num_endpoints == 0) {
        $logger->warn("No endpoints enabled for port $port");

        delete($listeners{$port});
        delete($handlers{$port});
        delete($service_configs{$port});
    }
}

if (scalar(keys %listeners) == 0) {
    $logger->error("No ports enabled");
    exit(-1);
}

# Daemonize if not in debug mode. This must be done before forking off children
# so that the children are daemonized as well.
if(not $DEBUGFLAG) {
# flush the buffer
    $| = 1;
	&daemonize;
}

$SIG{CHLD} = \&REAPER;

$0 = "perfsonar.pl ($$)";

foreach my $port (keys %listeners) {
    my $pid = fork();
    if ($pid == 0) {
        %child_pids = ();
        $0 .= " - Listener ($port)";
        psService($listeners{$port}, $handlers{$port}, $service_configs{$port});
         exit(0);
    } elsif ($pid < 0) {
        $logger->error("Couldn't spawn listener child");
        killChildren();
        exit(-1);
    } else {
        $child_pids{$pid} = q{};
    }
}

foreach my $ls_args (@ls_services) {
    my $ls_pid = fork();
    if ($ls_pid == 0) {
        %child_pids = ();
        $0 .= " - LS Registration (".$ls_args->{"port"}.":".$ls_args->{"endpoint"}.")";
        registerLS($ls_args);
        exit(0);
    } elsif ($ls_pid < 0) {
        $logger->error("Couldn't spawn LS");
        killChildren();
        exit(-1);
    }

    $child_pids{$ls_pid} = q{};
}

foreach my $ls_reaper_args (@ls_reaper) {
    my $ls_reaper_pid = fork();
    if ($ls_reaper_pid == 0) {
        %child_pids = ();
        $0 .= " - LS Reaper";
        cleanLS( $ls_reaper_args );
        exit(0);
    } elsif ($ls_reaper_pid < 0) {
        $logger->error("Couldn't spawn LS Reaper");
        killChildren();
        exit(-1);
    }
    $child_pids{$ls_reaper_pid} = q{};
}

unlockPIDFile($pidfile);

foreach my $pid (keys %child_pids) {
    waitpid($pid, 0);
}

=head2 psService
This function will wait for requests using the specified listener. It
will then select the appropriate endpoint request handler, spawn a new
process to handle the request and pass the request to the request handler.
The function also tracks the processes spawned and kills them if they
go on for too long, responding to the request with an error.
=cut
sub psService {
    my ($listener, $handlers, $service_config) = @_;
    my $max_worker_processes;

    $logger->debug("Starting '".$$."' as the MA.");

    $max_worker_processes = $service_config->{"max_worker_processes"};

    while(1) {
        if ($max_worker_processes > 0) {
            while (%child_pids and scalar(keys %child_pids) >= $max_worker_processes) {
                $logger->debug("Waiting for a slot to open");
                my $kid = waitpid(-1, 0);
                if ($kid > 0) {
                    delete $child_pids{$kid};
                }
            }
        }

        if (%child_pids) {
            my $time = time;

            $logger->debug("Reaping children (total: " .scalar  (keys %child_pids) . ") at time " . $time );

            # reap any children that have finished or outlived their allotted time
            foreach my $pid (keys %child_pids) {
                if (waitpid($pid, WNOHANG))  {
                    $logger->debug("Child $pid exited.");
                    delete $child_pids{$pid};
                } elsif ($child_pids{$pid}->{"timeout_time"} <= $time and $child_pids{$pid}->{"child_timeout_length"} > 0) {
                    $logger->error("Pid $pid timed out.");
                    kill 9, $pid;

                    my $msg = "Timeout occurred, current limit is ".$child_pids{$pid}->{"child_timeout_length"}." seconds. Try decreasing the breadth of your search if possible.";
                    my $resMsg = getErrorResponseMessage(eventType => "error.common.timeout", description => $msg);
                    my $response = HTTP::Response->new();
                    $response->message("success");
                    $response->header('Content-Type' => 'text/xml');
                    $response->header('user-agent' => 'perfSONAR-PS/1.0b');
                    $response->content(makeEnvelope($resMsg));
                    $child_pids{$pid}->{"listener"}->send_response($response);
                    $child_pids{$pid}->{"listener"}->close();
                }
            }
        }

        my $handle = $listener->accept;
        if (not defined $handle) {
            my $msg = "Accept returned nothing, likely a timeout occurred or a child exited";
            $logger->debug($msg);
        } else {
            $logger->info("Received incoming connection from:\t".$handle->peerhost());
            my $pid = fork();
            if ($pid == 0) {
                %child_pids = ();

                $0 .= " - ".$handle->peerhost();

                my $http_request = $handle->get_request;
                if (not defined $http_request) {
                    my $msg = "No HTTP Request received from host:\t".$handle->peerhost();
                    $logger->error($msg);
                    $handle->close;
                    exit(-1);
                }

                my $request = perfSONAR_PS::Request->new($handle, $http_request);
                if (not defined $handlers->{$request->getEndpoint()}) {
                    my $msg = "Received message with has invalid endpoint: ".$request->getEndpoint();
                    $request->setResponse(getErrorResponseMessage(eventType => "error.common.transport", description => $msg));
                    $request->finish();
                } else {
                    $0 .= " - ".$request->getEndpoint();
                    handleRequest($handlers->{$request->getEndpoint()}, $request, $service_config->{"endpoint"}->{$request->getEndpoint()});
                }
                exit(0);
            } elsif ($pid < 0) {
                $logger->error("Error spawning child");
            } else {
                my $max_worker_lifetime =  $service_config->{"max_worker_lifetime"};
                my %child_info = ();
                $child_info{"listener"} = $handle;
                $child_info{"timeout_time"} = time + $max_worker_lifetime;
                $child_info{"child_timeout_length"} = $max_worker_lifetime;
                $child_pids{$pid} = \%child_info;
            }
        }
    }

    return;
}

=head2 registerLS($args)
    The registerLS function is called in a separate process or thread and
    is responsible for calling the specified service's 'registerLS'
    function regularly.
=cut
sub registerLS {
    my ($args) = @_;

    my $service = $args->{"service"};
    my $default_interval = $args->{"conf"}->{"ls_registration_interval"};

    $logger->debug("Starting '".$$."' for LS registration");

    while(1) {
        my $sleep_time;

        eval {
            $service->registerLS(\$sleep_time);
        };
        if ($@) {
            $logger->error("Problem running register LS: $@");
            $sleep_time = undef;
        }

        if (not defined $sleep_time or $sleep_time eq q{}) {
            $sleep_time = $default_interval;
        }

        $logger->debug("Sleeping for $sleep_time");

        sleep($sleep_time);
    }

    return;
}

=head2 cleanLS($args)
    The cleanLS function is (only by the LS) to periodically clean out the 
    LS database.
=cut

sub cleanLS {
    my ($args) = @_;

    my $service = $args->{"service"};
    my $sleep_time = $args->{"conf"}->{"ls"}->{"reaper_interval"} * 60;
    my $error = q{};

    unless ( $sleep_time ) {
      return -1;
    }

    while(1) {
        my $status = q{};
        eval {
            $status = $service->cleanLS( { error => \$error } );
        };
        if ($@) {
            $logger->error("Problem cleaning LS: $@");
        }
        elsif ( $status == -1 ) {
            $logger->error("Error returned: $error");        
        }
        
        $logger->debug("Sleeping for $sleep_time");

        sleep($sleep_time);
    }
    return 0;
}

=head2 handleRequest($handler, $request, $endpoint_conf);
This function is a wrapper around the handler's handleRequest function.
It's purpose is to ensure that if a crash occurs or a perfSONAR_PS::Error_compat
message is thrown, the client receives a proper response.
=cut
sub handleRequest {
    my ($handler, $request, $endpoint_conf) = @_;

    my $messageId = q{};

    try {
        my $error;

        if($request->getRawRequest->method ne "POST") {
            my $msg = "Received message with an invalid HTTP request, are you using a web browser?";
            $logger->error($msg);     
            throw perfSONAR_PS::Error_compat("error.common.transport", $msg);
        }

        my $action = $request->getRawRequest->headers->{"soapaction"};
        if (!$action =~ m/^.*message\/$/) {
            my $msg = "Received message with an invalid soap action type.";
            $logger->error($msg);     
            throw perfSONAR_PS::Error_compat("error.common.transport", $msg);
        }

        $request->parse(\%ns, \$error);
        if (defined $error and $error ne q{}) {
            throw perfSONAR_PS::Error_compat("error.transport.parse_error", "Error parsing request: $error");
        }

        my $message = $request->getRequestDOM()->getDocumentElement();;
        $messageId = $message->getAttribute("id");
        $handler->handleMessage($message, $request, $endpoint_conf);
    }
    catch perfSONAR_PS::Error with {
        my $ex = shift;

        my $msg = "Error handling request: ".$ex->eventType." => \"".$ex->errorMessage."\"";
        $logger->error($msg);

        $request->setResponse(getErrorResponseMessage(messageIdRef => $messageId, eventType => $ex->eventType, description => $ex->errorMessage));
    }
    catch perfSONAR_PS::Error_compat with {
        my $ex = shift;

        my $msg = "Error handling request: ".$ex->eventType." => \"".$ex->errorMessage."\"";
        $logger->error($msg);

        $request->setResponse(getErrorResponseMessage(messageIdRef => $messageId, eventType => $ex->eventType, description => $ex->errorMessage));
    }
    otherwise { 
        my $ex = shift;
        my $msg = "Unhandled exception or crash: $ex";
        $logger->error($msg);

        $request->setResponse(getErrorResponseMessage(messageIdRef => $messageId, eventType => "error.common.internal_error", description => "An internal error occurred"));
    };

    $request->finish();

    return;
}

=head2 daemonize
Sends the program to the background by eliminating ties to the calling terminal.
=cut
sub daemonize {
    chdir '/' or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    setsid or die "Can't start a new session: $!";
    umask 0;
    return;
}

=head2 lockPIDFile($piddir, $pidfile);
The lockPIDFile function checks for the existence of the specified file in
the specified directory. If found, it checks to see if the process in the
file still exists. If there is no running process, it returns the filehandle for the open pidfile that has been flock(LOCK_EX).
=cut
sub lockPIDFile {
    $logger->debug("Locking pid file");
    my($piddir, $pidfile) = @_;
    die "Can't write pidfile: $piddir/$pidfile\n" unless -w $piddir;
    $pidfile = $piddir ."/".$pidfile;
    sysopen(PIDFILE, $pidfile, O_RDWR | O_CREAT);
    flock(PIDFILE, LOCK_EX);
    my $p_id = <PIDFILE>;
    chomp($p_id) if (defined $p_id);
    if(defined $p_id and $p_id ne q{}) {
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

=head2 unlockPIDFile
This file writes the pid of the call process to the filehandle passed in,
unlocks the file and closes it.
=cut
sub unlockPIDFile {
    my($filehandle) = @_;

    truncate($filehandle, 0);
    seek($filehandle, 0, 0);
    print $filehandle "$$\n";
    flock($filehandle, LOCK_UN);
    close($filehandle);

    $logger->debug("Unlocked pid file");

    return;
}

=head2 killChildren
Kills all the children for this process off. It uses global variables
because this function is used by the signal handler to kill off all
child processes.
=cut
sub killChildren {
    foreach my $pid (keys %child_pids) {
        kill("SIGINT", $pid);
    }

    return;
}

=head2 signalHandler
Kills all the children for the process and then exits
=cut
sub signalHandler {
    killChildren;
    exit(0);
}

sub REAPER {
    # We have to get the signal when children exit so that we can close our
    # reference to that child's socket. Otherwise, the TCP connection will
    # remain open until the accept call times out and the reaper kicks in.
    # We could have the reaper clean up the processes, but by handling the
    # SIGCHLD, it will cause the accept call to return, triggering a process
    # cleanup. Since this process cleanup must exist (to handle timeouts), we
    # may as well reuse it to clean up the exiting children as well.

    $SIG{CHLD} = \&REAPER;
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
