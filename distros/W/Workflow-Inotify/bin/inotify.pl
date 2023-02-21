#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Config::IniFiles;
use Data::Dumper;
use English qw(-no_match_vars);
use Getopt::Long;
use IO::Handle;
use Linux::Inotify2;
use List::Util qw(none any);
use Proc::Daemon;
use Proc::PID::File;

use Readonly;

Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

Readonly::Hash our %EVENTS => (
  IN_ACCESS        => IN_ACCESS,
  IN_ATTRIB        => IN_ATTRIB,
  IN_CLOSE_WRITE   => IN_CLOSE_WRITE,
  IN_CLOSE_NOWRITE => IN_CLOSE_NOWRITE,
  IN_CREATE        => IN_CREATE,
  IN_DELETE        => IN_DELETE,
  IN_DELETE_SELF   => IN_DELETE_SELF,
  IN_MODIFY        => IN_MODIFY,
  IN_MOVE_SELF     => IN_MOVE_SELF,
  IN_MOVED_FROM    => IN_MOVED_FROM,
  IN_MOVED_TO      => IN_MOVED_TO,
  IN_OPEN          => IN_OPEN,
);

our $VERSION = '1.0.3'; ## no critic (RequireInterpolationOfMetachars)

our %WATCH_HANDLERS;
our $KEEP_GOING = $TRUE;
our $CONFIG;
our $VERBOSE;
our %OPTIONS;
our $INOTIFY;

########################################################################
sub setup_signal_handlers {
########################################################################

  ## no critic (RequireLocalizedPunctuationVars)

  $SIG{HUP} = sub {

    print {*STDERR} "Caught SIGHUP:  \n";

    print {*STDERR} "...removing handlers\n";

    cleanup_handlers();

    print {*STDERR} "...re-reading config file\n";

    init_from_config();

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

  return if !$VERBOSE;

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

    eval { require $handler_path; };

    die $EVAL_ERROR
      if $EVAL_ERROR;

    my $handler = $handler_class->new($CONFIG);

    die $EVAL_ERROR
      if $EVAL_ERROR;

    die "your class must have a handler() method\n"
      if !$handler->can('handler');

    msg( sprintf '...setting up handler for [%s] =>  [%s]',
      $dir, ref $handler );

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
sub boolean {
########################################################################
  my ( $value, @default ) = @_;

  my $default_value;

  if (@default) {
    $default_value = $default[0];
  }

  $value =~ s/\s*([^ ]+)\s*/$1/xsm;

  return $default_value
    if !defined $value
    && defined $default_value;

  return $FALSE
    if !defined $value || any { $value eq $_ } qw( 0 false off no );

  return $TRUE
    if any { $value eq $_ } qw( 1 true on yes );

  die "invalid value ($value) for boolean variable";
}

########################################################################
sub init_from_config {
########################################################################
  $CONFIG = Config::IniFiles->new( -file => $OPTIONS{config} );

  $VERBOSE = boolean( $CONFIG->val( global => 'verbose' ), $TRUE );

  my $perl5lib = $CONFIG->val( global => 'perl5lib' );

  if ($perl5lib) {

    while ( $perl5lib =~ /\$(\w+)/xsm ) {
      my $env = $ENV{$1};
      $perl5lib =~ s/\$$1/$env/gxsm;
    }

    my @extra_inc;

    for my $inc ( split /:/xsm, $perl5lib ) {
      if ( none { $inc eq $_ } @INC ) {
        push @INC, $inc;
      }
    }
  }

  return;
}

########################################################################
sub help {
########################################################################
  return print <<"END_OF_HELP";
usage: $PROGRAM_NAME options

Options
-------
-h, --help     help
-c, --config   path to configuration file
-l, --logfile  path to logfile

Notes
-----
STDERR, STDOUT redirected to logfile if logfile is provide

See 'perldoc Workflow::Inotify' for details regarding usage and
configuration.

END_OF_HELP
}

########################################################################
sub main {
########################################################################
  GetOptions( \%OPTIONS, 'logfile=s', 'config=s', 'help' );

  return help()
    if $OPTIONS{help};

  die "no config file found!\n"
    if !-s $OPTIONS{config};

  init_from_config();

  my $daemonize = boolean( $CONFIG->val( global => 'daemonize', $FALSE ) );

  if ($daemonize) {
    Proc::Daemon::Init;
  }

  setup_signal_handlers();

  autoflush STDOUT $TRUE;
  autoflush STDERR $TRUE;

  $OPTIONS{logfile} //= $CONFIG->val( global => 'logfile' );

  # note that version 0.14 of Proc::Daemon will open STDOUT/STDERR and
  # redirect to a file for you, CentOS 5 has version 0.03 which opens
  # STDOUT/STDERR to /dev/null thus we need to re-open...

  if ( $OPTIONS{logfile} ) {
    open STDOUT, '+>>', $OPTIONS{logfile};
    open STDERR, '+>>&STDOUT'; ## no critic (ProhibitAmpersandSigils)
  }

  # If already running, then exit
  if ( $daemonize && Proc::PID::File->running() ) {
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

  return;
}

main();

1;

__END__
