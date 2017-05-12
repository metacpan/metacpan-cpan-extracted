# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Cache::Logger;

use strict;
use warnings;

use Fcntl ':flock';
use Carp qw(:DEFAULT);

sub new {

	my ($self, %params) = @_;
	
	unless (ref $self) {
		
		$self = bless {

			'log-file'=> $params{'log-file'},
		}, $self;
	}
	
	return $self;
}

sub log_message { 
	
	my ($self, $message) = @_;
	
	my $filename = ">>" . $self->{'log-file'};
	
	unless(open(LOG_FILE, $filename)) { 

		print STDERR Carp::longmess("Unable to open cache log file: $filename");
		
		return undef;
	}
	
	flock(LOG_FILE, LOCK_EX);

	my $now_string = localtime;

	print LOG_FILE "[ $now_string ]   $message\n";

	flock(LOG_FILE, LOCK_UN);
	
	close(LOG_FILE);

	return 1;
}

sub clear_log {
	
	my $self = shift;
	
	unless(unlink($self->{'log-file'})) { 
		
		print STDERR Carp::longmess("Unable to clear log file");
		return undef;
	}

	return 1;
}

1;

__END__

=head1 NAME

LS::Cache::Logger - Cache manager for LSID data, metadata, URIs and WSDL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over

=item new ( %options )

=back

=head1 METHODS

=over

=item log_message ( $message )

Enter $message in to the log in the form:

 [ TIMESTAMP ] Message

=item clear_log

Empty the log file.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>
