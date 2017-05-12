# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Locator;

use strict;
use warnings;

use vars qw( $METHODS );

use Net::DNS::Resolver;

use LS;
use LS::ID;
use LS::Authority;

use base 'LS::Base';


sub BEGIN {

	$METHODS = [
		'authorityCache',
		'localMappingFile',
		'cacheAuthorities',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %options ) - Creates a new LS::Locator that searches DNS for an LSID's authority.
#
#	This method accepts parameters in the form of a hash. The following hash keys are
#	used:
#
#		local - Specifies the local filename and path that LS::Locator will use to 
#			short ciruit DNS.
#
#		nocache - If set to true, then DNS queries for authorities will not be cached.
#
#
#	Returns: An LS::Locator object if successful,
#		 undef if there is a failure
#
sub new {
	
	my $self = shift;
	my (%params) = @_;
	
	unless (ref $self) {

		$self = bless {}, $self;

		$self->authorityCache( {} );
	}
	
	my $file = ( $params{'local'} || $params{'localMappingFile'} || 'authorities');
	$self->localMappingFile( $file );
	$self->loadLocalMappingFile();
	$self->cacheAuthorities(1);
	
	$self->cacheAuthorities($params{'nocache'})
		if(exists($params{'nocache'}));
	
	return $self;
}


#
# cacheAuthorities( $bool ) - Returns whether or not Authority queries will be cached.
#
#	 Returns: If Authority queries _WILL_ be cached, 1 is returned
#		  otherwise, a false value is returned 
#


#
# localMappingFile( [$filename] )
# 	Gets/Sets the local filename to use for the static 
#	authority -> endpoint mappings
#
#	Parameters:
#		If the filename parameter is specifed, the local filename is set to that
#		parameter.
#
#	Returns:
#		If the parameter is left unspecified the current local filename  
#		is used.
#


#
# clearCache( ) - Empties the Authority query cache
#
sub clearCache {

	my $self = shift;
	
	$self->authorityCache( {} );

	# Reload the authorities file
	$self->loadLocalMappingFile();
}


#
# clear_cache( ) - Synonym for clearCache
#
sub clear_cache {

	my $self = shift;
	return $self->clearCache();
}


sub loadLocalMappingFile {
	
	my $self = shift;

	# Can only initialize the cache if there is a filename set
	unless($self->localMappingFile()) {
	
		return undef;
	}

	# Load the local authorities file
	unless(open(FILE, $self->localMappingFile()) ) {
	
		return undef;
	}
		
	local ($/)= "\n";
	while (<FILE>) {
		
		# Trim whitespace
		s/^\s+|\s+$//g;

		# Ignore comments
		next if(/^#/);

		my ($name, $location) = split(/\s/, $_, 2);
		next unless($name);

		my ($host, $port, $path) = $location =~ m|^\s*(.*?):(.*?)(/(.*))?$|;
		next unless($host && $port);

		my $authority = LS::Authority->new_by_hostname($host, $port, $path);
		next unless($authority);

		$self->authorityCache()->{ lc($name) } = $authority;
	}

	close(FILE);
}


#
# resolveAuthority( $lsid ) - Resolves the authority for the specified LSID. This method will
#			      search DNS for the hostname and then retrieve the SRV resource 
#			      records for the authority.
#
#	Returns: An LS::Authority object if successful,
#		 undef if an error occurs, check errorString for more information
#
sub resolveAuthority {

	my $self = shift;
	my ($id) = @_;

	my $authority_id;

	unless(UNIVERSAL::isa($id, 'LS::ID')) {

		my $lsid = LS::ID->new($id);
		
		if ($lsid) {
			
			$authority_id = $lsid->authority();
		}
		elsif ($id =~ /^lsidauth:([A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\_\!\*\']*)$/i) { 
			$authority_id = $1;
		}
		else {
			
			$self->recordError( 'Cannot resolve invalid LSID: ' . $id );
			$self->addStackTrace() ;
			
			return undef;
		}
	}

	$authority_id = $id->authority();
	unless ($authority_id) {

		$self->recordError( 'Cannot resolve authority, invalid LSID' );
		$self->addStackTrace() ;

		return undef;
	}

	my $cached = $self->authorityCache()->{ $authority_id };

	return $cached 
		if($cached);

	# Use DNS to resolve the authority ID via an SRV record
	my $resolver = Net::DNS::Resolver->new();
	unless($resolver) {

		$self->recordError( 'Unable to create Net::DNS::Resolver object' );
		$self->addStackTrace();

		return undef;
	}

	# Do the DNS lookup
	my $query = $resolver->search('_lsid._tcp.' . $authority_id, 'SRV');  # $query is a Net::DNS::Packet object
	my $authority;
	if ($query) {

		$self->recordError( 'Unable to resolve authority to SRV record: ' .
				    ($resolver->errorstring() || 'No details available from $resolver') );

		$self->addStackTrace();
		my $rr = ($query->answer())[0];  # rr is a Net::DNS::RR::SRV object

		# Create an authority interface from the answer
		$authority = LS::Authority->new_by_hostname($rr->target(), $rr->port());

#		return undef;    # I want to temporarily over-ride this and allow http://domain/authority to be allowed!
	} else {  # okay, if all else fails, is there a presumptive authority at http://example.org:80/authority ?
		$query = $resolver->search($authority_id);  # $query is a Net::DNS::Packet object
		if ($query){
			use LWP::Simple;
			my ($content_type, $document_length, $modified_time, $expires, $server) = head("http://$authority_id/authority");
			return undef unless $document_length;  # if nothing responds then finally give up and return undef
		}
		# if we are here, then something must have responded at http://$authority_id:80/authority
		# so lets hope that its an LSID resolver!
		$authority = LS::Authority->new_by_hostname($authority_id, '80');
	}
	unless(UNIVERSAL::isa($authority, 'LS::Authority')) {
	
		$self->recordError('Unable to create new authority from host information');
		$self->addStackTrace();
		
		return undef;
	}

	$self->authorityCache()->{$authority_id} = $authority 
		if($self->cacheAuthorities());

	return $authority;
}
	

#
# resolve_authority - Synonym for resolveAuthority.
#
sub resolve_authority {

	my $self = shift;
	return $self->resolveAuthority(@_);
}




1;


__END__

=head1 NAME

LS::Locator - Resolve authorities for LSIDs

=head1 SYNOPSIS

 use LS::ID;
 use LS::Locator;

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 $locator = LS::Locator->new();
 $authority = $locator->resolveAuthority($lsid);

 $auth_host = $authority->host();
 $auth_port = $authority->port();
 $auth_path = $authority->path();

 $resource = $authority->getResource($lsid);
 $data = $resource->getData();

=head1 DESCRIPTION

Objects of the C<LS::Locator> class will resolve the authority of a
given LSID using DNS SRV records. Results are cached for speed.

If a file called F<authorities> is present in the working directory,
the locator's cache is preloaded with the contents of the file. The
authorities file contains a newline separated list of id/location pairs.
Each pair is delimited with whitespace. Lines starting with C<#> are
treated as comments. An example authorities file would look like this:

 # This file enables local resolution of LSID authorities.
 # id      server:port/servicepath

 authority.testing.org   myauthority.org:80/cgi-bin/authority.pl

More information on LSIDs and their resolution can be found at
L<http://www.omg.org/cgi-bin/apps/doc?dtc/04-05-01>

=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::Locator> object:

=over

=item new ( [%options] )

This class method creates a new C<LS::Locator> object and returns it.
Key/value pair arguments may be provided to initialize locator options.
The available options names are C<local> and C<nocache>. The options can
also be set or modified later by method calls described below.

Examples:

 $locator = LS::Locator->new(localMappingFile => 'c:\lsid\authorities.txt');

This creates a new locator object whose cache will be preloaded with the
contents of the file F<c:\lsid\authorities.txt>.

=back

=head1 METHODS

=over

=item loadLocalMappingFile ( )

Loads the entries specified by L<localMappingFile> in to the 
locator's cache. Calling this method will overwrite any 
existing entries in the cache that also appear in the file.

=item localMappingFile ( [$filename] )

Sets or retrieves the name of the local authorities file being used by
the locator. By default, the authorities file is the file called 
F<authorities> in the working directory. To turn off local authority 
resolution, call C<clearCache>, then call this method with an argument 
of C<undef>.

The file is NOT immediately read into the locator's cache, you must
call C<loadLocalMappingFile> which will overwrite any existing entries 
in the cache that also appear in the file.

Examples:

 $locator = LS::Locator->new();
 
 # Load the cache with the contents of f<c:\lsid\myauthorities.txt>
 
 $locator->localMappingFile('c:\lsid\myauthorities.txt');
 $locator->loadLocalMappingFile();
 
 $authority = $locator->resolveAuthority('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 
 # Now turn off local resolution

 $locator->clearCache();
 $locator->localMappingFile(undef);

=item clearCache ( )

Clears the locator's cache of authorities. After the cache is cleared,
it is re-initialized with the contents of the local authorities file, if
present.

=item cacheAuthorities ( $bool )

If this method is called with a true value, the results of future
Authority resolutions will be cached. This does not affect the current
contents of the cache, nor does it affect the reading of a local
authorities file into the cache. It only prevents future DNS respnses
from being added. If the method is called with a defined false value,
e.g. 0, caching of Authority responses will stop. If the method is called
with an undefined argument, the current setting is returned.

=item resolveAuthority ( $id )

Resolves the authority for the given ID. The ID may either be an LSID as
a string or an object of class C<LS::ID>, or an authority ID as a string
of the form lsidauth:authority_id. The return value is an object of
class C<LS::Authority>, or C<undef> if the LSID could not be resolved.
In this case, C<errorString> can be checked for a description of the
error.

Examples:

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 $authority = $locator->resolveAuthority($lsid);

 $authority = $locator->resolveAuthority('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 $authority = $locator->resolveAuthority('lsidauth:ncbi.nlm.nih.gov.lsid.biopathways.org');

=item errorString ( )

Returns a description of the last error that occurred in the locator.

Examples:

 $authority = $locator->resolveAuthority('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 if (!$authority) {
 	warn('Unable to resolve authority: ', $locator->errorString(),  '\n');
 }

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
