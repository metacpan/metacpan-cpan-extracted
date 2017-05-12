# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Client::FTP;

use strict;
use warnings;

use vars qw( @ISA );

use File::Temp;
use Net::FTP;

use LS;
use LS::ID;
use LS::Client;
use LS::Service;


@ISA = ( 'LS::Client' );

sub new {

	my ($self, %options) = @_;

	unless(ref $self) {

		$self = bless {

			%options,

		}, $self;
	}

	return $self;
}

sub getContent {

	my ($self, %options) = @_;
	
	unless($options{'url'}) {

		$self->recordError( 'Invalid FTP URL in sub getContent' );
		$self->addStackTrace() ;

		return undef;
	}

	my $url = $options{'url'};

	my $host = $url->host;
	my $port = $url->port;
	my $path = $url->path;
	$path =~ s|^/+||;

	my $user = $url->user;
	my $password = $url->password;

	my $ftp = Net::FTP->new($host, Port=> $port);

	unless ($ftp) {

		$self->recordError('Error initializing FTP client');
		$self->addStackTrace();

		return undef;
	}

	unless ($ftp->login($user, $password)) {

		$ftp->quit;

		$self->recordError('Login failed in sub getContent');
		$self->addStackTrace();

		return undef;
	}

	#
	# Store the data in a temporary file
	# The file handle should be passed up the stack to the user
	# in the form of a LS::Service::Response object
	#
	my ($fh, $local) = File::Temp::tempfile();

	unless ($fh) {

		$ftp->quit;

		$self->recordError('Unable to open temp file in sub getContent');
		$self->addStackTrace();

		return undef;
	}

	my $success = $ftp->get($path, $local);
	$ftp->quit;

	unless ($success) {

		File::Temp::unlink0($fh, $local);

		$self->recordError('Download failed in sub getContent');
		$self->addStackTrace();

		return undef;
	}

	local($/) = undef;

	seek($fh, 0, 0);
	binmode $fh;

	my $data = <$fh>;

	if (File::Temp::unlink0($fh, $local)) {

		$self->recordError( undef );
	}
	else {

		$self->recordError("Failed to delete temp file $local in sub getContent");
		$self->addStackTrace();
	}

	return \$data;
}

sub getMetadata {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'url'}) {

		return undef;
	}

	my $url = URI->new($options{'url'});

	unless ($url && $url->isa('URI::ftp')) {

		$self->recordError('Invalid FTP URL in sub getMetadata');
		$self->addStackTrace();

		return undef;
	}

	my $data_ref = $self->getContent(url=> $url);

	return undef unless($data_ref);

	return LS::Service::Response->new(response=> ${ $data_ref } );
}

sub getMetadataSubset {

	my $self = shift;

	return $self->getMetadata(@_);
}

sub getData {

	my $self = shift;

	return $self->getMetadata(@_);
}

sub getDataByRange {

	my $self = shift;

	return $self->getMetadata(@_);
}


1;

__END__

