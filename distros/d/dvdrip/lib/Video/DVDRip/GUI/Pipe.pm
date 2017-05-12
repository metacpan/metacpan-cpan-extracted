# $Id: Pipe.pm 2067 2006-05-15 20:27:34Z joern $

package Video::DVDRip::GUI::Pipe;

use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;

use strict;

use Carp;
use Cwd;
use FileHandle;
use Data::Dumper;

use Gtk2::Helper;
use POSIX qw(:errno_h);

sub fh				{ shift->{fh}				}
sub command			{ shift->{command}			}
sub args			{ shift->{args}				}
sub need_output			{ shift->{need_output}			}
sub output			{ shift->{output}			}
sub cb_line_read		{ shift->{cb_line_read}			}
sub cb_finished			{ shift->{cb_finished}			}
sub pid				{ shift->{pid}				}
sub watcher_tag			{ shift->{watcher_tag}			}

sub set_fh			{ shift->{fh}			= $_[1] }
sub set_command			{ shift->{command}		= $_[1]	}
sub set_args			{ shift->{args}			= $_[1]	}
sub set_need_output		{ shift->{need_output}		= $_[1]	}
sub set_output 			{ shift->{output}		= $_[1]	}
sub set_cb_line_read		{ shift->{cb_line_read}		= $_[1]	}
sub set_cb_finished		{ shift->{cb_finished}		= $_[1]	}
sub set_pid			{ shift->{pid}			= $_[1]	}
sub set_watcher_tag		{ shift->{watcher_tag}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($command, $need_output, $cb_line_read, $cb_finished) =
	@par{'command','need_output','cb_line_read','cb_finished'};
	my  ($args) =
	@par{'args'};

	my $self = {
		command			=> $command,
		args			=> ($args || []),
		need_output		=> $need_output,
		cb_line_read		=> $cb_line_read,
		cb_finished		=> $cb_finished,
 	};
	
	return bless $self, $class;
}

sub open {
	my $self = shift;

	my $fh  = FileHandle->new;
	
	# we use fork & exec, because we want to have
	# STDERR on STDOUT in the child.
	my $pid = open($fh, "-|");
	croak "can't fork child process" if not defined $pid;

	if ( not $pid ) {
		# we are the child. Copy STDERR to STDOUT
		close STDERR;
		open (STDERR, ">&STDOUT")
			or croak "can't dup STDOUT to STDERR";
		my $command = $self->command;
		my $dvdrip_exec = $command =~ /dvdrip-exec/ ? "" : "dvdrip-exec ";
		exec ($dvdrip_exec.$command, @{$self->args})
			or croak "can't exec program: $!";
	}

	$self->log ("Executing command: ".$self->command);

	$self->set_fh ( $fh );
	$self->set_pid ( $pid );
	$self->set_output ( "" );

	$self->set_watcher_tag (
		Gtk2::Helper->add_watch (
			$fh->fileno,
			'in', sub { $self->progress; 1; }
		),
	);

	1;
}

sub close {
	my $self = shift;

	Gtk2::Helper->remove_watch ( $self->watcher_tag )
		if $self->watcher_tag;

	close ($self->fh)
		if $self->fh;

	$self->set_watcher_tag(undef);
	$self->set_fh (undef);

	1;
}

sub cancel {
	my $self = shift;

	my $pid = $self->pid;

	if ( $pid ) {
		$self->log ("Aborting command. Sending signal 9 to PID $pid...");
		kill 9, $pid;
	}

	$self->close;

	1;
}

sub progress {
	my $self = shift;

	my $fh = $self->fh;

	# read a chunk from the filehandle
	# (no Perl I/O here, instead low level sysread, since
	#  Gtk watches the low level filehandle, not the
	#  buffered Perl handle, otherwise evil deadlocking
	#  is promised)
	my $buffer;
	if ( !sysread($fh, $buffer, 4096) ) {
		my $cb_finished  = $self->cb_finished;
		&$cb_finished() if $cb_finished;
		return 1;
	}

	# store output
	if ( $self->need_output ) {
		$self->{output} .= $buffer;
	} else {
		$self->{output} = substr($self->{output}.$buffer,-16384);
	}

	# get job's PID
	my ($pid) = ( $buffer =~ /DVDRIP_JOB_PID=(\d+)/ );
	if ( defined $pid ) {
		$self->set_pid ( $pid );
		$self->log ("Job has PID $pid");
		$buffer =~ s/DVDRIP_JOB_PID=(\d+)\n//;
	}

	# prepend rest data from previous run
	my $buffer = $self->{buffer}.$buffer;

	# line callback
	my $cb_line_read = $self->cb_line_read;

	# process by line
	my $has_line_breaks;
	while ( $buffer =~ s/(.*)\n// ) {
		$has_line_breaks = 1;
		&$cb_line_read ( $1 ) if $cb_line_read;
	}
	
	# process buffer as-is if there is no line break
	# in command's output
	if ( !$has_line_breaks ) {
		&$cb_line_read ( $buffer ) if $cb_line_read;
		$buffer = "";
	}

	# save rest of buffer
	$self->{buffer} = $buffer;

	1;
}

1;
