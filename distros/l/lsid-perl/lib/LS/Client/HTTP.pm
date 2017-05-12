# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Client::HTTP;

use strict;
use warnings;

use vars qw( $AGENT_IDENTIFIER $METHODS );

use URI;
use File::Temp;
use LWP::UserAgent;

use LS;
use LS::ID;
use LS::Client;
use LS::Service::Response;

use base 'LS::Client';



#
# $AGENT_IDENTIFIER -
#
$AGENT_IDENTIFIER = 'IBM LSID Resolver';


BEGIN {

	$METHODS = [
		'url',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %options ) -
#
sub new {

	my ($self, %options) = @_;

	unless(exists($options{'url'}) && defined($options{'url'})) {
		die('Missing URL parameter');	
	}
	
	unless(ref $self) {

		$self = bless {
			%options,
		}, $self;

	}

	$self->url( $options{'url'} );
	$self->{'userAgent'} = LWP::UserAgent->new(agent=> $AGENT_IDENTIFIER);

	return $self;
}

#
# getContent( %options ) - Makes a generic HTTP request to the specified URL and returns the content
#
# Hash Parameters:
#
#	$options{'url'} - The URL to retrieve data
#
# Returns:
#
#	undef if there is an error, otherwise 
#	data from the web request
#
#
sub getContent {

	my ($self, %options) = @_;

	unless($options{'url'}) {

		$self->recordError( 'Missing URL in sub getContent' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $url = $options{'url'};
	 
	# Method defaults to GET as per OMG spec
	my $method = $options{'method'} ? $options{'method'} : 'GET';

	my $ua = $self->{'userAgent'};

	# Stream the request in to a temporary file
	# so that we can store large files
	my $fh = File::Temp->new(UNLINK=> 1);

	my $request = HTTP::Request->new($method, $url);

	# Using the filename is bad.. but how to get around it on all platforms?
	my $response = $ua->request($request, $fh->filename());

	unless ($response->is_success()) {

		$self->recordError( 'HTTP ' . $method . ' unsuccessful: ' . $response->status_line() );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	return LS::Service::Response->new(response=> $fh);
}


#
# getServices -
#
sub getServices {

}


#
# getAvailableServices( %options ) -
#
sub getAvailableServices {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing parameters in sub getAvailableServices' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};

	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();
	my $request_url = $url . '?lsid=' . $lsid->as_string();

	return $self->getContent(url=> $request_url);
}


#
# getMetadata( %options ) -
#
sub getMetadata {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing parameters in sub getMetadata' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $acceptedFormats = $options{'acceptedFormats'} ? $options{'acceptedFormats'} : 'application/rdf+xml';

	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();

	my $request_url = $url . '?acceptedFormats=' . URI::Escape::uri_escape($acceptedFormats) . 
			  '&lsid=' . URI::Escape::uri_escape($lsid->as_string()); 

	return $self->getContent(url=> $request_url);
}


#
# getMetadataSubset( %options ) -
#
sub getMetadataSubset {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing parameters in sub getMetadataSubset' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $acceptedFormats = $options{'acceptedFormats'} ? $options{'acceptedFormats'} : 'application/rdf+xml';

	# FIXME: Add getMetadataSubset to URL parameters
	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();
	
	my $request_url = $url . '?acceptedFormats=' . URI::Escape::uri_escape($acceptedFormats) . 
			  '&lsid=' . URI::Escape::uri_escape($lsid->as_string); 

	return $self->getContent(url=> $request_url);
}


#
# getData( %options ) -
#
sub getData {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing parameters in sub getData' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();
	
	my $request_url = $url . '?lsid=' . URI::Escape::uri_escape($lsid->as_string()); 

	return $self->getContent(url=> $request_url);
}


#
# getDataByRange( %options ) -
#
sub getDataByRange {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'start'} &&
	       $options{'length'}) {

		$self->recordError( 'Missing parameters in sub getDataByRange' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $start = $options{'start'};
	my $length = $options{'length'};
	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();

	my $request_url = $url . '?lsid=' . URI::Escape::uri_escape($lsid->as_string());
	   $request_url .= '&start=' . $start;
	   $request_url .= '&length=' . $length;

	return $self->getContent(url=> $request_url);
}




#
# FAN Stubs
# NOTE: This may change
#


#
# _fan_call( %options ) -
#
sub _fan_call {

	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};
	my $authorityName = $options{'authorityName'};

	my $url = (exists($options{'url'}) && defined($options{'url'})) ? $options{'url'} : $self->url();

	my $request_url = $url . '?lsid=' . URI::Escape::uri_escape($lsid->as_string());
	   $request_url .= '&authorityName=' . URI::Escape::uri_escape($authorityName);

	return $self->getContent(url=> $request_url);
}


#
#
# notifyForeignAuthority(String lsid, String authorityName) 
#
sub notifyForeignAuthority {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'authorityName'}) {

		$self->recordError( 'Missing parameters in sub notifyForeignAuthority' );
		$self->addStackTrace();
		die($self->errorDetails());
	}
	
	return $self->_fan_call(%options);
}


#
#
# revokeNotifcationForeignAuthority(String lsid, String authorityName) 
#
sub revokeNotificationForeignAuthority {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'authorityName'}) {

		$self->recordError( 'Missing parameters in sub revokeNotificationForeignAuthority' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	return $self->_fan_call(%options);
}

1;

__END__

=head1 NAME

LS::Client::HTTP - Implements the HTTP protocol specific calls for invoking an LSID service

=head1 SYNOPSIS

 use LS::ID;
 use LS::Client::HTTP;

 $lsid = LS::ID->new('URN:LSID:pdb.org:PDB:112L:');

 $client = LS::Client::HTTP->new();

 $metadata = $client->getMetadata(url=> 'http://someauthority.org:8080/authority/metadata',
				  lsid=> $lsid);

=head1 DESCRIPTION

C<LS::Client::HTTP> provides wrapper methods to invoke an
LSID service in a protocol specific manner as defined by
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>.

=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::Client::HTTP> object:

=over

=item new 

This class method creates a new <LS::Client::HTTP> object. 

Examples:

 $http = LS::Client::HTTP->new()

 if (!$http) {
 	print STDERR "Unable to create protocol object!";
 }

=back

=head1 METHODS

C<LS::Client::HTTP> supports the following methods:

=over

=item getContent (url=> $url )

Generic method used to retrieve data from the specified URL.

=item getData (lsid=> $lsid, url=> $url )

Invokes the C<getData> service method (if available) and returns any data
from the authority.

=item getDataByRange ( lsid=> $lsid, url=> $url )

Invokes getDataByRange, see L<getData> for more information.

=item getMetadata ( lsid=> $lsid, url=> $url )

Invokes getMetadata, see L<getData> for more information.

=item getMetadataSubset ( lsid=> $lsid, url=> $url )

Invokes getMetadataSubset, see L<getData> for more information.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

