# $Id: TranscodeRC.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::TranscodeRC;
use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

# use base Video::DVDRip::Base;

use Socket;
use FileHandle;

my $DEBUG = 0;

my %preview_commands = (
	display	=> 1,	     
	draw	=> 1,	     
	fastbw  => 1,
	faster	=> 1,	     
	fastfw	=> 1,	     
	pause	=> 1,	     
	rotate	=> 1,	     
	slowbw	=> 1,	     
	slower	=> 1,	     
	slowfw	=> 1,	     
	toggle	=> 1,	     
	undo	=> 1,	     
);

sub socket_file			{ shift->{socket_file}			}

sub loaded_filters		{ shift->{loaded_filters}		}
sub command_queue		{ shift->{command_queue}		}

sub error_cb			{ shift->{error_cb}			}
sub selection_cb		{ shift->{selection_cb}			}
sub socket			{ shift->{socket}			}
sub sent			{ shift->{sent}				}
sub paused			{ shift->{paused}			}
sub window_closed		{ shift->{window_closed}		}

sub set_error_cb		{ shift->{error_cb}		= $_[1]	}
sub set_selection_cb		{ shift->{selection_cb}		= $_[1]	}
sub set_socket			{ shift->{socket}		= $_[1]	}
sub set_sent			{ shift->{sent}			= $_[1]	}
sub set_paused			{ shift->{paused}		= $_[1]	}
sub set_window_closed		{ shift->{window_closed}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($socket_file, $error_cb, $closed_cb, $selection_cb) =
	@par{'socket_file','error_cb','closed_cb','selection_cb'};

	my $self = {
		socket_file	=> $socket_file,
		error_cb	=> $error_cb,
		closed_cb	=> $closed_cb,
		selection_cb	=> $selection_cb,
		loaded_filters	=> {},
		command_queue	=> [],
	};

	return bless $self, $class;
}

sub connect {
	my $self = shift;

	my $socket_file = $self->socket_file;

	my $socket = FileHandle->new;

	socket ($socket, PF_UNIX, SOCK_STREAM, 0)   or die "socket: $!";
	connect($socket, sockaddr_un($socket_file)) or die "connect: $!";

	unlink $socket_file;

	select $socket;
	$| = 1;
	select STDOUT;

	$self->set_socket ($socket);
	
	1;
}

sub disconnect {
	my $self = shift;
	
	close $self->socket;

	1;
}

sub send {
	my $self = shift;
	my %par = @_;
	my ($line) = @par{'line'};

	if ( $self->sent ) {
		push @{$self->command_queue}, $line;
		$DEBUG && print "[socket] send - queued: $line\n";
		return 1;
	}

	my $socket = $self->socket;
	
	$self->set_sent ( $line );

	print $socket $line, "\n"
		or croak __"can't send command to transcode";

	$DEBUG && print "[socket] send - $line\n";
	
	1;
}

sub receive {
	my $self = shift;
	
	my $socket = $self->socket;
	
	$DEBUG && print "[socket] receive - ";
	
	if ( eof ($socket) ) {
		$self->disconnect;
		$DEBUG && print "EOF\n";
		return;
	}
	
	my $line = <$socket>;
	chomp $line;

	$DEBUG && print "$line\n";

	if ( $self->sent ) {
		if ( $line eq 'OK' ) {
			$self->set_sent (undef);
			$line = "";
		} elsif ( $line eq 'FAILED' ) {
			my $error_cb = $self->error_cb;
			&$error_cb ( $self->sent )
				if $error_cb;
			$self->set_sent (undef);
			$line = "";
		}
	}

	if ( not $self->sent and @{$self->command_queue} != 0 ) {
		Glib::Timeout->add (200, sub {
			$self->send ( line => shift @{$self->command_queue} );
			return 0;
		});
	}

	if ( $line =~ /preview window close/ ) {
		$self->set_window_closed ( 1 );
	}

	if ( $line =~ /pos1=(\d+)x(\d+)\s+pos2=(\d+)x(\d+)/ ) {
		my $selection_cb = $self->selection_cb;
		&$selection_cb (
			x1 => $1,
			y1 => $2,
			x2 => $3,
			y2 => $4,
		) if $selection_cb;
		$line = "";
	}

	return $line;
}

sub load_filter {
	my $self = shift;
	my %par = @_;
	my ($filter, $options) = @par{'filter','options'};
	
	$self->send ( line => "load $filter $options" );
	
	$self->loaded_filters->{$filter} = 1;
	
	1;
}

sub config_filter {
	my $self = shift;
	my %par = @_;
	my ($filter, $options) = @par{'filter','options'};

	if ( not exists $self->loaded_filters->{$filter} ) {
		$self->load_filter (
			filter  => $filter,
			options => $options,
		);
		return 1;
	}

	$self->send ( line => "config $filter $options" );
	
	1;
}

sub enable_filter {
	my $self = shift;
	my %par = @_;
	my ($filter) = @par{'filter'};

	$self->send ( line => "enable $filter" );
	
	1;
}

sub disable_filter {
	my $self = shift;
	my %par = @_;
	my ($filter) = @par{'filter'};

	return 1 if not exists $self->loaded_filters->{$filter};

	$self->send ( line => "disable $filter" );
	
	1;
}

sub preview {
	my $self = shift;
	my %par = @_;
	my ($command, $options) = @par{'command','options'};

	croak __x("Unknown preview command '{command}'", command => $command)
		if not exists $preview_commands{$command};

	$options = " $options" if $options ne '';

	$self->send ( line => "preview $command$options" );

	if ( $command eq 'pause' ) {
		$self->set_paused ( $self->paused xor 1 );
	}

	1;
}

sub quit {
	my $self = shift;

	$self->send ( line => "quit" );

	1;
}
