#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Config::IniFiles;
use Cwd;
use Data::Dumper;
use English qw(-no_match_vars);
use Getopt::Long qw(:config no_ignore_case);
use IO::Handle;
use Linux::Inotify2;
use List::Util qw(none any);
use Proc::Daemon;
use Proc::PID::File;
use Pod::Usage;
use Workflow::Inotify::Handler qw(boolean %EVENTS %MASKS);

use Readonly;

Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

our $VERSION = '1.0.7';

our %WATCH_HANDLERS;
our $KEEP_GOING = $TRUE;
our $CONFIG;
our $VERBOSE;
our %OPTIONS;
our $INOTIFY;
our %HANDLERS;

########################################################################
sub setup_signal_handlers {
########################################################################

  ## no critic (RequireLocalizedPunctuationVars)

  $SIG{HUP} = sub {

    print {*STDERR} "Caught SIGHUP:  \n";

    print {*STDERR} "...removing handlers\n";

    cleanup_handlers();

    print {*STDERR} "...re-reading config file\n";

    $CONFIG = init_from_config( \%OPTIONS );

    print {*STDERR} "...setting up handlers\n";

    setup_watch_handlers();

    print {*STDERR} "...restarting\n";

    $KEEP_GOING = $TRUE;
  };

  $SIG{INT} = sub {
    print {*STDERR} ("Caught SIGINT:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  $SIG{QUIT} = sub {
    print {*STDERR} ("Caught SIGQUIT:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  $SIG{TERM} = sub {
    print {*STDERR} ("Caught SIGTERM:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  return;
}

########################################################################
sub msg {
########################################################################
  my (@msg) = @_;

  return
    if !$VERBOSE;

  return print {*STDERR} "@msg\n";
}

########################################################################
sub setup_watch_handlers {
########################################################################

  my @watch_dirs = $CONFIG->Sections();

  foreach my $wd (@watch_dirs) {
    next if $wd !~ /^watch_(.*)$/xsm;

    my $watch_name = $1;

    msg( sprintf '...configuring watch directory section => [%s]', $wd );

    my $dir = $CONFIG->val( $wd => 'dir' );

    die "no directory specified for section $wd\n"
      if !$dir;

    die "directory [$dir] does not exist\n"
      if !-d $dir;

    my $event_list = $CONFIG->val( $wd => 'mask' );

    my @events = split /\s*[|]\s*/xsm, $event_list;

    die "no events specified in $wd section\n"
      if !@events;

    for my $e (@events) {
      croak "not a valid event ($e)"
        if none { $e eq $e } keys %EVENTS;
    }

    my $event_mask;

    for (@events) {
      msg( sprintf '...configuring directory [%s] with [%s] mask', $dir, $_ );

      $event_mask |= $EVENTS{$_};
    }

    my $handler_class = $CONFIG->val( $wd => 'handler' );

    die "no handler defined\n"
      if !$handler_class;

    # get the handler for this directory and set up the callback

    my $handler_path = $handler_class;

    $handler_path =~ s/::/\//gxsm;

    if ( $handler_path !~ /[.]pm\z/xsm ) {
      $handler_path = "$handler_path.pm";
    }

    eval {
      if ( !$INC{$handler_path} ) {
        require $handler_path;
      }
    };

    die $EVAL_ERROR
      if $EVAL_ERROR;

    my $handler = $HANDLERS{$handler_path};

    if ( !$handler ) {
      $HANDLERS{$handler_path} = $handler = $handler_class->new($CONFIG);
    }

    die $EVAL_ERROR
      if $EVAL_ERROR;

    die "your class must have a handler() method\n"
      if !$handler->can('handler');

    msg( sprintf '...setting up handler for [%s] =>  [%s]', $dir, ref $handler );

    my $w = $INOTIFY->watch(
      $dir,
      $event_mask,
      sub {
        $handler->handler(shift);
      }
    );

    $WATCH_HANDLERS{$watch_name} = [ ref($handler), $w, $event_list ];
  }

  return \%WATCH_HANDLERS;
}

########################################################################
sub cleanup_handlers {
########################################################################
  for ( keys %WATCH_HANDLERS ) {
    $WATCH_HANDLERS{$_}->[1]->cancel();
  }

  return;
}

########################################################################
sub init_from_config {
########################################################################
  my ($options) = @_;

  my $config = Config::IniFiles->new( -file => $options->{config} );

  if ( !$config ) {
    my $errors = join "\n", @Config::IniFiles::errors;
    die sprintf "could not read config file %s\n", $options->{config}, $errors;
  }

  $VERBOSE = boolean( $config->val( global => 'verbose' ), $TRUE );

  my $perl5lib = $config->val( global => 'perl5lib' );

  if ($perl5lib) {
    if ( $ENV{HOME} ) {
      $perl5lib =~ s/[~]/\$HOME/xsmg;
    }

    while ( $perl5lib =~ /\$(\w+)/xsm ) {
      my $env = $ENV{$1};
      $perl5lib =~ s/\$$1/$env/gxsm;
    }

    my @extra_inc;

    for my $inc ( split /:/xsm, $perl5lib ) {
      if ( none { $inc eq $_ } @INC ) {
        unshift @INC, $inc;
      }
    }
  }

  return $config;
}

########################################################################
sub help {
########################################################################
  return pod2usage(1)
    if !$OPTIONS{version};

  return print {*STDOUT} sprintf "%s v%s\n", $PROGRAM_NAME, $VERSION;
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    logfile|l=s
    config|c=s
    daemonize|d
    help|h
    version|v
  );

  my $retval = GetOptions( \%OPTIONS, @option_specs );

  return help()
    if !$retval || $OPTIONS{help} || $OPTIONS{version};

  die "no config file found!\n"
    if !-s $OPTIONS{config};

  $CONFIG = init_from_config( \%OPTIONS );

  my $logfile = $OPTIONS{logfile} // $CONFIG->val( global => 'logfile' );

  my $daemonize = $OPTIONS{daemonize} // boolean( $CONFIG->val( global => 'daemonize' ), $TRUE );

  if ($daemonize) {

    my $daemon = Proc::Daemon->new(
      work_dir => cwd,
      $logfile ? () : ( dont_close_fh => ['STDERR'] )
    );

    $daemon->Init();
  }

  setup_signal_handlers();

  autoflush STDOUT $TRUE;
  autoflush STDERR $TRUE;

  # see perldoc Proc::Daemon for a description of how Proc::Daemon
  # closes all file handles

  if ($logfile) {
    no strict 'subs';
    open STDOUT, '+>>',  $logfile;
    open STDERR, '+>>&', STDOUT;
  }

  # If already running, then exit
  if ( $daemonize && Proc::PID::File->running( dir => cwd ) ) {
    msg('already running...');
    exit 0;
  }

  $INOTIFY = Linux::Inotify2->new;

  setup_watch_handlers();

  return run();
}

########################################################################
sub run {
########################################################################
  msg( sprintf "...configuration complete at [%s]\n", scalar localtime );

  my $block = boolean( $CONFIG->val( global => 'block' ), $TRUE );

  my $sleep = $CONFIG->val( global => 'sleep' );

  $INOTIFY->blocking($block);

  if ($VERBOSE) {
    msg('---------------------------');
    msg('Starting inotify polling...');
    msg('---------------------------');
    msg( '  blocking: ', $block ? 'true' : 'false' );
    msg( '     sleep: ', $sleep ? $sleep : 'no' );
    msg('  handlers: ');

    foreach ( keys %WATCH_HANDLERS ) {
      msg( '            name   : ', $_ );
      msg( '            handler: ', $WATCH_HANDLERS{$_}->[0] );
      msg( '            events : ', $WATCH_HANDLERS{$_}->[2] );
    }

    msg( "      \@INC:\n          :", join "\n          : ", @INC );

    msg("---------------------------\n");
  }

  if ( !$block && !$sleep ) {
    $sleep = 1;
  }

  # support for non-blocking, polling mode
  while ($KEEP_GOING) {
    $INOTIFY->poll;

    if ($sleep) {
      sleep $sleep;
    }
  }

  # clean up handlers...
  msg('...cleaning up handlers');

  cleanup_handlers();

  return 0;
}

exit main();

1;

## no critic

__END__

=pod

=head1 USAGE

inotify.pl options

Linux inotify handler.  See man inotify.pl for detailed documentation.

=head1 OPTIONS

 Options
 -------
 -h, --help      help
 -c, --config    path to configuration file
 -l, --logfile   path to logfile, overrides value in config file
 -d, --daemonize overrides value in config file (default: true)
 
 Notes
 -----
 STDERR and STDOUT will be redirected to a logfile if a logfile is provided
 
 See 'perldoc Workflow::Inotify' for details regarding usage and
 configuration.

=cut
