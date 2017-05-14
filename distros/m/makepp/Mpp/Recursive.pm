# $Id: Recursive.pm,v 1.18 2012/03/04 13:56:35 pfeiffer Exp $

=head1 NAME

Mpp::Recursive - Support for making dumb recursive make smart

=head1 DESCRIPTION

This file groups all the functions needed only if an old style recursive build
is detected.  The actual functionality is also dispersed in makepp and other
modules.

=cut

package Mpp::Recursive;

use Mpp::File;
use Mpp::Text;
use Mpp::Event qw(wait_for read_wait);

our $traditional;		# 1 if we invoke makepp recursively, undef if
				# we call the recursive_makepp stub and do
				# the build in the parent process.
our $hybrid;			# 1 if we try non-traditional, but fall back for
				# directories with multiple makefiles.
our $depth;			# Brake
if( defined $traditional || defined $hybrid ) {
  $depth = 50 unless defined $depth;
  die "`--traditional-recursive-make' has reached max depth.
  Probably your invocations of \$(MAKE) have a cycle (which gmake ignores).
  For e.g. 70 levels of recursion, add to command line: recursive_makepp=70\n"
    if --$depth < 0;
}

my $_MAKEPPFLAGS;

END {
  local $?;
  defined $traditional || defined $hybrid and $Mpp::Rule::last_build_cwd and $Mpp::print_directory and
    print "$Mpp::progname: Leaving directory `" . absolute_filename( $Mpp::Rule::last_build_cwd ). "'\n";
}

#
# Set up our socket for listening to recursive make requests.  We don't do
# this unless we actually detect the use of the $(MAKE) variable.
#
our $socket;
our $socket_name = $Mpp::global_ENV{MAKEPP_SOCKET} if exists $Mpp::global_ENV{MAKEPP_SOCKET};
				# In case of --hybrid, speak to the original process, don't have our own socket.
sub setup_socket {
  return if $socket_name; # Don't do anything if we've already
				# made the socket.
#
# Get a temp name that goes away at the end, so we don't clutter up /tmp.
#
  $socket_name = Mpp::Subs::f_mktemp '/tmp/makepp.';
				# Name of socket for listening to recursive
				# make requests.  This is exported to the
				# environment by Rule::execute.
  require IO::Socket;
  $socket =
    IO::Socket::UNIX->new(Local => $socket_name,
			  Type => eval 'use IO::Socket; SOCK_STREAM',
			  Listen => 2) or
				# Make the socket.
    die "can't create socket $socket_name--$!\n";
  chmod 0600, $socket_name;	# Don't let other people access it.
  read_wait $socket, \&connection;
}

our $command;			# Once this is set, we know we can potentially have recursion.
my $traditional_command;
#
# This subroutine is called whenever a connection is made to the recursive
# make socket.
#
sub connection {
  my $connected_socket = $_[0]->accept(); # Make the connection.
  return unless $connected_socket; # Skip failed accepts.  I guess this might
				# happen if the other process has already
				# exited.
#
# Set up a few data items about this stream.  These will be passed through
# the closure to the actual read routine.
#
  my $whole_command = '';	# Where we accumulate the whole command
				# from the recursive make process.
  my $read_sub;
  $read_sub = sub {
#
# This subroutine is called whenever we get a line of text through our
# recursive make socket.
    my $fh = $_[0];		# Access the file handle.
    my $line;
    if (sysread($fh, $line, 8192) == 0) {	# Try to read.
      $fh->close;		# If we got 0 bytes, it means the other end
				# closed the socket.
      return;
    }
    $whole_command .= $line;	# Append the line.
    if ($whole_command =~ s/^(.*)\01END\01//s) {
				# Do we have the whole command
				# now?
      my @lines = split(/\n/, $1); # Access each of the pieces.
      my @words = unquote_split_on_whitespace shift @lines;
				# First one is the set of arguments to
				# parse_command_line.
      my %this_ENV;		# Remaining lines are environment variables.
      foreach (@lines) {
	if( s/^([^=]+)=// ) {	# Correct format?
	  $this_ENV{$1} = unquote $_; # Store it.
	} else {
	  die "illegal command received from recursive make process:\n$_\n";
	}
      }
#
# We've now got all of the environment and command words.  Start executing
# them.
#
      chdir shift @words;	# Move to the appropriate directory.
      Mpp::Event::Process::adjust_max_processes(1); # Allow one more process to
				# run simultaneously.
      my $status = eval {
	local @ARGV = @words;
        wait_for Mpp::parse_command_line %this_ENV; # Build all the targets.
      };
      if( $@ ) {		# Have an error code?
	if( defined $hybrid && $@ =~ /\Aattempt to load two makefiles/ ) {
	  local $traditional = 1;
	  local $command = $traditional_command;
	  local $depth = defined $depth ? $depth-1 : 50;
	  $status = 'exec ' . Mpp::Subs::f_MAKE( undef, {}, 'recursion' ) . "\n$_MAKEPPFLAGS\n";
	  $traditional_command ||= $command;
	  $@ = '';
	} else {
	  $status = 1;
	}
      } elsif( 'Mpp::File' eq ref $status ) {
	$status = '2 Dependency of `' . absolute_filename($status) . "' failed";
      }
      Mpp::Event::Process::adjust_max_processes(-1); # Undo our increment above.
      print $fh "$status $@";	# Send the result to the recursive make process.
      close $fh;                # Force a close immediately.
    } else {
      read_wait $fh, $read_sub;	# Prepare to read another line.
    }
  };

  read_wait $connected_socket, $read_sub; # Start the initial read.
  read_wait $_[0], \&connection; # Requeue listening.
}

#
# This is the actual function which overloads the stub.
#
no warnings 'redefine';

#
# $(MAKE) needs to expand to the name of the program we use to replace a
# recursive make invocation.  We pretend it's a function with no arguments.
#
my $n = -1;
sub Mpp::Subs::f_MAKE {
  if( defined $traditional ) { # Do it the bozo way?
    $_[1]{EXPORTS}{_MAKEPPFLAGS} = $_MAKEPPFLAGS ||= join_with_protection
      defined $hybrid ? '--hybrid' : '--traditional',
      $Mpp::BuildCheck::default == $Mpp::BuildCheck::exact_match::exact_match ? () :
	"--buildcheck=".((ref $Mpp::BuildCheck::default)=~/BuildCheck::(.+)/)[0],
      $Mpp::Subs::defer_include ? '--deferinclude' : (),
      $Mpp::final_rule_only ? '--finalruleonly' : (),
      $Mpp::gullible ? '--gullible' : (),
      $Mpp::last_chance_rules ? '--lastchancerules' : (),
      $Mpp::log_level == 1 ? '-v' : $Mpp::log_level == 0 ? '--nolog' : (),
      $Mpp::no_path_executable_dependencies ? '--nopathexedep' : (),
      $Mpp::remake_makefiles ? () : '--noremakemakefiles',
      $Mpp::rm_stale_files ? '--rmstalefiles' : (),
      $Mpp::Signature::default_name ? "-m$Mpp::Signature::default_name" : (),

      map { /^makepp_/ ? "$_=$Mpp::Makefile::global_command_line_vars->{$_}" : () }
	keys %$Mpp::Makefile::global_command_line_vars;

    unless( defined $command ) { # Haven't figured it out yet?
      $command = $0;		# Get the name of the program.
      unless( $command =~ m@^/@ ) { # Not absolute?
#
# We have to search the path to figure out where we came from.
#
	foreach( Mpp::Text::split_path(), '.' ) {
	  my $finfo = file_info "$_/$0", $Mpp::original_cwd;
	  if( file_exists $finfo ) { # Is this our file?
	    $command = absolute_filename $finfo;
	    last;
	  }
	}
      }
    }
    my $log = '';
    if( $Mpp::log_level == 2 ) {
      $log = ".makepp/log-$$-" . ++$n;
      Mpp::log LOG => $_[2], $log
	if $Mpp::log_level;
      substr $log, 0, 0, ' --log=';
    }
#@@explicit_perl
    Mpp::PERL . ' ' .
#@@
    "$command recursive_makepp=$depth$log";
				# All the rest of the info is passed in the
				# _MAKEPPFLAGS environment variable.
				# The --recursive option is just a flag that
				# helps the build subroutine identify this as
				# a recursive make command.  It doesn't
				# actually do anything.
  } else {
    die "makepp: recursive make without --traditional-recursive-make only supported on Cygwin Perl\n"
      if Mpp::is_windows < -1 || Mpp::is_windows > 0;

    my $makefile = $_[1];	# Get the makefile we're run from.

    $command ||=
#@@explicit_perl
      Mpp::PERL . ' ' .
#@@
      absolute_filename( file_info $Mpp::datadir, $Mpp::original_cwd ) .
	'/recursive_makepp';
				# Sometimes we can be run as ../makepp, and
				# if we didn't hard code the paths into
				# makepp, the directories may be relative.
				# However, since recursive make is usually
				# invoked in a separate directory, the
				# path must be absolute.
    $makefile->cleanup_vars;
    join ' ', $command,
      map { "$_=" . requote $makefile->{COMMAND_LINE_VARS}{$_} } keys %{$makefile->{COMMAND_LINE_VARS}};
  }
}

1;
