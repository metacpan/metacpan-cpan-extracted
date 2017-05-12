package Tk::Shell;
my $RCSRevKey = '$Revision: 0.44 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

=head1 NAME

  Tk::Shell.pm -- Handlers for Tk::Workspace.pm shell clients.

=head1 DESCRIPTION

This module is incomplete.

There's no API or calling synopsis at the moment.  It's 
primary purpose is to provide some abstraction, and hopefully
data hiding, from the parent Workspace process. 

Results may be unpredictable due to the I/O buffering behavior of
called programs.  Most programs that have line-oriented output
should work okay.  At this point Workspaces do not understand
terminal escape sequences.  

The buffers of the child process's STDOUT and STDERR pipes are set to
an abnormally high value: 65535 bytes each.  Hopefully that will help
prevent blocking from either channel.  If the programs that you run
within the browser create more output than that, then you'd probably
want to run them in an xterm, anyway.  If your Perl installation
doesn't have that much memory available, you can adjust the numbers
(the third argument in the setvbuf calls) downward, and be more
careful of what programs you run.

Broken pipe errors happen occasionally.  The program prints a message
to the browser's STDERR (that is, on the terminal, unless you've
redirected STDERR from the shell prompt), and goes on, instead of
killing the process that's running the browser.

This module is tested under several varieties of Linux, and Solaris.
It is untested, and probably unusable, under MS Windoze.


=cut

require Exporter;
require Carp;

@ISA=qw(Exporter);
@EXPORT_OK=qw( VERSION ishell shell_client shell_cmd );

use Env qw( PS1 HOME ); 
use FileHandle;
use IO::File;
use IPC::Open3;
use IO::Select;
use POSIX qw(:sys_wait_h :signal_h);

# Solaris seems to want the pid of the process, not -1, in waitpid.
# But, it doesn't seem to leave as many defunct processes lying 
# around, either.
my $os = `uname -a`;
if ( $os =~ /^Linux/ ) { $SIG{CHLD} = \&REAP };
sub REAP {
  my $childpid;
  while(($childpid = waitpid( -1, WNOHANG)) > 0 ) {
      if( WIFSTOPPED( $childpid ) ) {
	kill SIGKILL, $childpid;
      }
  }
  $SIG{CHLD} = \&REAP;
}

# Handle a broken pipe, which happens occasionally.
# Linux doesn't record the pid of the signalling process, or
# the signal is received after the child is gone.  
$SIG{PIPE} = \&PIPESIG;
sub PIPESIG {
  my $childpid = waitpid( -1, WHNOHANG );
  print STDERR "Broken Pipe: PID = $childpid, Status: $?.\n";
  $SIG{PIPE} = \&PIPESIG;
}

my $ppid;

# external programs that the shell executes
sub shell_client {
    my ($self) = @_;
    my $t = $self -> {text};
    my $cmdline; my $cmd;
    my $p = &prompt( $ENV{'PS1'} );
    my $o; my $output = '';

    my $startofprompt = 
	$t -> search( -backwards, -exact, $p, 
		      $t -> index( 'insert' ) );

    $cmdline = $t -> get( $startofprompt, 'insert' );
    $cmd = substr $cmdline, length $p ;
    chop $cmd;
    goto NEXT if( length $cmd <= 1 );

    # mimick some built-ins.
    if( $cmd =~ /exit/ ) {
      $self -> {window} -> bind( '<KeyPress-Return>', '' );
      return;
    } elsif ( $cmd =~ /^cd$/ ) {
      chdir $ENV{'HOME'};
      goto NEXT;
    } elsif ( ( $cmd =~ /cd/ ) || ( $cmd =~ /chdir/ ) ) {
	$cmd =~ s/(cd )|(chdir )//;
	chdir $cmd;
	goto NEXT;
    }

    $shpid = open3( *IN, *OUT, *ERR, ($cmd) );
    autoflush OUT, 1;
    autoflush ERR, 1;
    print IN $cmd;
    close( IN );

    my $selector = IO::Select -> new(); 
    $selector -> add( *OUT, *ERR );
    my @ch_read;
    my $handle;
    my $o; my $e;

    *OUT -> setvbuf( $o, _IOLBF, 65535 );
    *ERR -> setvbuf( $e, _IOLBF, 65535 );

    while ( @ch_read = $selector -> can_read( 5 ) ) {
      foreach $handle ( @ch_read ) {
	if( fileno( $handle ) == fileno( OUT ) ) {
	  $o = *OUT -> getline; 
	  $t -> insert( $t -> index( 'insert' ), $o );
	} elsif( fileno( $handle ) == fileno( ERR ) ) {
	  $e = *ERR -> getline; 
	  $t -> insert( $t -> index( 'insert' ), $e );
	}
	$t -> see( 'insert' );
	$t -> update;
	$selector -> remove( $handle ) if eof( $handle ); 
      }
    }
    close( OUT );
    close( ERR );
  NEXT:
    $p = &prompt( $ENV{'PS1'} );
    $t -> insert( $t -> index( 'insert' ), $p );
    $t -> see( 'insert' );
}

sub ishell {
    my ($self) = @_;
    my $t = $self -> {text};
    my $w = $self -> {window};
    my $p = &prompt( $ENV{'PS1'} );
    $w -> bind( '<KeyPress-Return>', sub{shell_client( $self )});
    $t -> insert( $t -> index( 'insert' ), "\n$p" );
    $t -> see( 'insert' );
}

# subset of bash prompt syntax only for now.  
sub prompt {
    my ($s) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = 
	localtime;
    my $calyear = $year + 1900;
    my $mname = $months[$mon];
    my $day = $weekdays[$wday];

    if( $s =~ m/\\/ ) {
	if ( $s =~ m/\\[hH]/ ) {
	    my $hme = `hostname`;
	    chop $hme;
	    $s =~ s/\\h/$hme/;
	}
# eat a possible ANSI sequence.
	if ( $s =~ m/\\e/ || $s =~ m/\\033/ ) { 
	    $s =~ s/(\\e|\\033)]*[^;]*\;*//;
        }
        if ( $s =~ m/\\t/ ) {
	    $s =~ s/\\t/$hour:$min:$sec/;
	}
        if ( $s =~ m/\\T/ ) {
	    my $thour = (($hour == 12)?12:($hour - 12));
	    $s =~ s/\\T/$thour:$min:$sec/;
	}
        if ( $s =~ m/\\@/ ) {
	    my $thour = (($hour == 12)?12:($hour - 12));
	    my $merid = ((($hour<12||$hour==24))?'am':'pm');
		$s =~ s/\\@/$thour:$min$merid/;
	}
        if ( $s =~ m/\[wW]/ ) {
        }
             my $dir = `pwd`;
             chop $dir;
             $s =~ s/\\W/$dir/;
        }
        if ( $s =~ m/\\d/ ) {
             $s =~ s/\\d/$day $mname $mday/;
        }
    # eat an octal sequence,
    $s =~ s/\\[0-9][0-9][0-9]//; 
    # gobble newlines,
    $s =~ s/\n//s;
    # and other prompt variables not yet implemented
    $s =~ s/\\(u|v|V|a|!|\$|\\|\[)//g;
    # doesn't work with an empty prompt, so...
    if ( ! $s ) { $s = "# "; }
    return $s;
}

sub shell_cmd {
    my ($self) = @_;
    my $t = $self -> text;
    local $cmd; local $output;
    local $cmdentry;
    tie( *TEXT, 'Tk::TextUndo', $t );
    $cmddialog = ($self -> window) -> Dialog( -title => 'Shell Command',
				      -buttons => ["Ok", "Cancel"],
				      -default_button => "Ok" );
    $cmdentry = $cmddialog -> add( 'Entry', -width => 30 ) -> pack;
    $cmddialog -> Show;
    $cmd = $cmdentry -> get;
    $output = `$cmd`;
    print TEXT $output;
    untie *TEXT;
    $cmddialog -> destroy;
}

1;
