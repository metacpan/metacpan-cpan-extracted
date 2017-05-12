# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Config;


use strict;
use warnings;

use vars qw( $CONFIG_FILENAME );



#
# $CONFIG_FILENAME - The name of the default configuration file
#
$CONFIG_FILENAME = 'lsid-client.xml';





package LS::Config::File;

use strict;
use warnings;

use XML::XPath;


use LS;


use base 'LS::Base';



#
# new( %options ) -
#
sub new {

	my $self = shift;

	my %options = @_;

	unless(ref $self) {

		$self = bless { 

			_cacheConfig=> undef,
			_hostMappings=> {},
			_foreignAuthority=> {},
		}, $self;

		$self->fromXML( $options{'xml'} ) if($options{'xml'});
	}

	return $self;
}


#
# loadFile( [ $filename ] ) - Loads the configuration file from the current directory.
#			      An optional filename can be provided to override the default.
#
#	Parameters - $filename, Optional. The name of the file to read the configuration from.
#		     If left unspecified, the filename stored in $LS::Config::CONFIG_FILENAME
#		     will be used.
#
#	Returns - An LS::Config::File object with the file parsed and ready to be used.
#
sub loadFile {

	my $self = shift;

	my $filename = shift;

	# If unspecified, set to the default
	$filename = $LS::Config::CONFIG_FILENAME unless($filename);

	unless(open(FILE, "$filename")) {

		$self->recordError("Unable to open file: $filename");
		$self->addStackTrace();

		return undef;
	}

	local $/ = undef;
	my $data = <FILE>;

	close(FILE);

	if(UNIVERSAL::isa($self, 'LS::Config::File')) {

		$self->fromXML( $data );
	}
	else {

		$self = LS::Config::File->fromXML( $data );
	}

	return $self;
}


#
# isPresent( ) - Determines whether a configuration file is present in the current
#		 directory.
#
#		 This function is a package functio and can be called without i
#		 instantiating an LS::Config::File object.
#
#	Returns - True if the configuration file is present in the current directory,
#		  False if the configuration file is not present.
#
sub isPresent( ) {

	my $self = shift;

	return ( -e "$LS::Config::CONFIG_FILENAME" );
}


#
# cacheConfig( $cacheInfo ) - Updates or retrieves the cache related configuration items.
#
#	Parameter - $cacheInfo, Optional. The LS::Config::Cache object that will
#		    become the new cache configuration.
#
#	Returns - The current cache configuration if no parameter is specified.
#
sub cacheConfig {

	my $self = shift;

	@_ ? $self->{'_cacheConfig'} = shift : return $self->{'_cacheConfig'};
}


#
# useCache( ) - Queries the cache configuration in order to determine whether or not
#		the cache should be used.
#
#	Returns - True if the cache should be used,
#		  False if it should not.
#
sub useCache {

	my $self = shift;

	return undef unless($self->{'_cacheConfig'});

	my $value = $self->{'_cacheConfig'}->useConfig();

	return undef unless($value eq 'false');

	return 1;
}


#
# cacheDirectory( ) - Access to the directory where the cache should be
#		      stored.
#
#	Returns - The directory, from the LS::Config::Cache object, 
#		  where the cache files are stored.
#
sub cacheDirectory {

	my $self = shift;

	return undef unless($self->{'_cacheConfig'});

	return $self->{'_cacheConfig'}->cacheDirectory();
}

#
# getHostMapping( $authority ) -
#
sub getHostMapping {

	my $self = shift;

	my ($authority) = @_;

	return $self->{'_hostMappings'}->{ $authority };
}


#
# getHostMappingList( ) -
#
sub getHostMappingList {

	my $self = shift;

	my $hl = [];

	foreach my $name (keys(%{ $self->{'_hostMappings'} })) {

		push @{ $hl }, $self->{'_hostMappings'}->{ $name };
	}

	return $hl;
}


#
# addHostMapping( $hm ) -
#
sub addHostMapping {

	my $self = shift;

	my ($hm) = @_;

	unless(UNIVERSAL::isa($hm, 'LS::Config::HostMapping')) {

		$self->recordError('Invalid LS::Config::HostMapping parameter');
		$self->addStackTrace();

		return undef;
	}

	$self->{'_hostMappings'}->{ $hm->authority } = $hm;
}


#
# getForeignAuthority( %options ) -
#
sub getForeignAuthority {

	my $self = shift;

	my %options = @_;

	unless($options{'lsid'} ||
	       ($options{'authority'} && $options{'namespace'}) ) {

		$self->recordError('Missing parameters');
		$self->addStackTrace();

		return undef;
	}

	my $key = ($options{'lsid'} || "$options{'authority'}:$options{'namespace'}");

	return $self->{'_foreignAuthority'}->{ $key };
}


#
# getForeignAuthorityList( ) - 
#
sub getForeignAuthorityList {

	my $self = shift;

	my %options = @_;

	my $list = [];

	foreach my $fa (keys(%{ $self->{'_foreignAuthority'} }) ) {

		push @{ $list }, $self->{'_foreignAuthority'}->{ $fa };
	}

	return $list;
}


#
# addForeignAuthority( $fa ) -
#
sub addForeignAuthority {

	my $self = shift;

	my ($fa) = @_;

	unless(UNIVERSAL::isa($fa, 'LS::Config::ForeignAuthority')) {

		$self->recordError('Invalid LS::Config::ForeignAuthority parameter');
		$self->addStackTrace();

		return undef;
	}

	# Add each Foreign Authority based on its type (pattern or LSID)
	if($fa->authority() ) {

		$self->{'_foreignAuthority'}->{ $fa->authority . ':' . $fa->namespace } = $fa;
	}
	elsif($fa->lsid() ) {

		$self->{'_foreignAuthority'}->{ $fa->lsid } = $fa;
	}
	else {

		$self->recordError('Malformed LS::Config::ForeignAuthority object');
		$self->addStackTrace();

		return undef;
	}
}


#
# fromXML( $xml ) -
#
sub fromXML {

	my $self = shift->new;

	my ($xml) = @_;

	unless($xml) {

		$self->recordError('Missing XML parameter.');
		$self->addStackTrace();

		return undef;
	}

	my $xpath = XML::XPath->new(xml=> $xml);


	#
	# Caching
	#
	my $caching = $xpath->find('lsidClient/caching');

	foreach my $c ($caching->get_nodelist()) {

		$self->cacheConfig( LS::Config::Cache->from_xpath_node($c, $xpath) );
	}


	#
	# Host Mappings
	#
	my $hostMappings = $xpath->find('lsidClient/hostMappings/hostMapping');

	foreach my $hostMappingNode ($hostMappings->get_nodelist()) {

		my $hm = LS::Config::HostMapping->from_xpath_node($hostMappingNode, $xpath);
		next unless($hm);

		$self->addHostMapping($hm);
	}



	#
	# Foreign Authorities (Patterns)
	#
	my $foreignAuthoritiesPatterns= $xpath->find('lsidClient/foreignAuthorities/pattern');

	foreach my $patternNode ($foreignAuthoritiesPatterns->get_nodelist()) {

		my $fa = LS::Config::ForeignAuthority->from_xpath_pattern_node($patternNode, $xpath);
		next unless($fa);

		$self->addForeignAuthority($fa);
	}


	#
	# Foreign Authorities (LSID)
	#
	my $foreignAuthoritiesLSID = $xpath->find('lsidClient/foreignAuthorities/lsid');

	foreach my $lsidNode ($foreignAuthoritiesLSID->get_nodelist()) {

		my $fa = LS::Config::ForeignAuthority->from_xpath_lsid_node($lsidNode, $xpath);
		next unless($fa);

		$self->addForeignAuthority($fa);
	}

	return $self;
}


package LS::Config::Cache;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use base 'LS::Base';


#
# BEGIN( ) -
#
sub BEGIN {

        $METHODS = [
			'useCache',
			'cacheDirectory',
		   ];
}


# Create the accessors
for my $field (@{ $METHODS } ) {

        no strict "refs";

        my $slot = __PACKAGE__ . $field;

        *$field = sub {

                my $self = shift;

                @_ ? $self->{ $slot } = $_[0] : $self->{ $slot };
        }
}


#
# new( %options ) - 
#
sub new {

	my $self = shift;

	my %options = @_;

	unless(ref $self) {

		$self = bless {

		}, $self;

		$self->useCache( $options{'useCache'} );
		$self->cacheDirectory( $options{'cacheDirectory'} );
	}

	return $self;
}


#
# from_xpath_node( $node, $xpath ) -
#
sub from_xpath_node {

	my $self = shift->new;

	my ($node, $xpath) = @_;

	my $useCacheNode = $xpath->find('useCache', $node);
	my $cacheDirectoryNode = $xpath->find('lsidCacheDir', $node);


	if($useCacheNode) {

		$self->useCache( $useCacheNode->string_value() );
	}
	else {

		$self->useCache( undef );
	}


	if($cacheDirectoryNode) {

		$self->cacheDirectory( $cacheDirectoryNode->string_value() );
	}
	else {

		$self->cacheDirectory( undef );
	}

	return $self;
}



package LS::Config::HostMapping;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;


use base 'LS::Base';



#
# BEGIN( ) -
#
sub BEGIN {

        $METHODS = [
			'authority',
			'endpoint',
		   ];
}


for my $field (@{ $METHODS } ) {

        no strict "refs";

        my $slot = __PACKAGE__ . $field;

        *$field = sub {

                my $self = shift;

                @_ ? $self->{ $slot } = $_[0] : $self->{ $slot };
        }
}



#
# new( %options ) -
#
sub new {

	my $self = shift;

	my %options = @_;

	unless(ref $self) {

		$self = bless { 

		}, $self;

		$self->authority($options{'authority'});
		$self->endpoint($options{'endpoint'});
	}

	return $self;
}


#
# from_xpath_node( $node, $xpath )
#
sub from_xpath_node {

	my $self = shift->new;

	my ($node, $xpath) = @_;

	my $authority = $xpath->find('authority', $node);
	my $endpoint  = $xpath->find('endpoint', $node);

	unless($authority && $endpoint) {

		return undef;
	}

	$self->authority($authority);
	$self->endpoint($endpoint);

	return $self;
}



package LS::Config::ForeignAuthority;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use base 'LS::Base';



#
# BEGIN( ) -
#
sub BEGIN {

        $METHODS = [
			'authority',
			'namespace',
			'lsid',
		   ];
}


for my $field (@{ $METHODS } ) {

        no strict "refs";

        my $slot = __PACKAGE__ . $field;

        *$field = sub {

                my $self = shift;

                @_ ? $self->{ $slot } = $_[0] : $self->{ $slot };
        }
}



#
# new( %options ) -
#
sub new {

	my $self = shift;

	unless(ref $self) {

		$self = bless {

			_authorities=> [],
		}, $self;
	}

	return $self
}


#
# from_xpath_pattern_node( $node, $xpath ) -
#
sub from_xpath_pattern_node {

	my $self = shift->new;

	my ($node, $xpath) = @_;

	my $authority = $node->getAttribute('auth');
	my $namespace = $node->getAttribute('ns');

	unless($authority && $namespace) {

		return undef;
	}

	$self->authority( $authority );
	$self->namespace( $namespace );

	my $authorities = $xpath->find('authority', $node);

	foreach my $auth ($authorities->get_nodelist()) {

		push @{ $self->{'_authorities'} }, $auth->string_value;
	}

	return $self;
}


#
# from_xpath_lsid_node( $node, $xpath ) -
#
sub from_xpath_lsid_node {

	my $self = shift->new;

	my ($node, $xpath) = @_;

	my $lsid = $node->getAttribute('lsid');

	unless($lsid) {

		return undef;
	}

	$self->lsid( $lsid );

	my $authorities = $xpath->find('authority', $node);

	foreach my $auth ($authorities->get_nodelist()) {

		push @{ $self->{'_authorities'} }, $auth->string_value;
	}

	return $self;
}

1;

__END__

=head1 NAME

LS::Config - Configuration management object

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::Config> object:

=over

=item new ( )

=back

=head1 METHODS

=over

=item authority ( )

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

