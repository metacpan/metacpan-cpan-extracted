# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Cache::Manager;

use strict;
use warnings;

use vars qw( $WSDL_EXT $DATA_EXT $SERVICE_FILENAME $EXPIRATION_FILENAME $METADATA_EXT );


use IO::File;
use File::Copy;
use Fcntl ':flock';
use Time::HiRes qw( gettimeofday );

use Carp qw(:DEFAULT);

use LS::Cache::Config;
use LS::Cache::Logger;


#
# Cache constants
#
$WSDL_EXT = 'wsdl';
$DATA_EXT = 'tmp';
$METADATA_EXT = 'rdf';
$SERVICE_FILENAME = 'authority.wsdl';


#
#
#
$EXPIRATION_FILENAME = 'EXPIRES';




#
# new( %options ) -
#
sub new { 
	
	my ($self, %options) = @_;
	
	unless (ref $self) {
		
		$self = bless {

			_config=> LS::Cache::Config->new(),
			_logger=> undef,
		}, $self;
	}

	$self->{'_logger'} = LS::Cache::Logger->new('log-file' => $self->{'_config'}->get_config_entry('log-file'));
	
	$self->enable_log() if($self->{'_config'}->get_config_entry('logging-on') eq 'true');
	
	return $self;
}


#
# Accessor functions
#


#
# logger( ) -
#
sub logger {

	my $self = shift;
	return $self->{'_logger'};
}


#
# config( ) -
#
sub config {

	my $self = shift;
	return $self->{'_config'};
}


#
# enable_log( ) -
#
sub enable_log { 
	
	my $self = shift;
	$self->{_config}->{'logging-on'} = 'true';
}


#
# is_logging( ) -
#
sub is_logging { 
	
	my $self = shift;
	return $self->{_config}->get_config_entry('logging-on') eq 'true';
}


#
# get_time( ) -
#
sub get_time {
	
	my $self = shift;

	my ($seconds, $microsecs) = Time::HiRes::gettimeofday();
	return $seconds * 1_000 + $microsecs / 1000 ;
}



#
# Cache functions
#


#
# maintain_cache( timestampt, $currentDirectory, $cacheConfig ) -
#
sub maintain_cache {
	
	my ($self, $timestamp, $current_dir, $cache_config) = @_;
		
	# Useful for when we are called at the top level
	$current_dir = $self->{_config}->get_config_entry('cache-root-dir') if(!$current_dir);

	# Build a configuration reference if one was not specified 
	# (so that we don't modify the root configuration while traversing the cache)
	if(!$cache_config) { 
		
		my %hash;
		
		foreach(keys( %{$self->{_config}}) ) {
			
			$hash{$_} = $self->{_config}->get_config_entry($_);
		}
		
		$cache_config = \%hash;
	}
	
	$self->{_logger}->log_message("Begin cache maintenance on: $current_dir") if($self->is_logging);	
	
	if(!opendir(CACHE_DIR, $current_dir)) {
	
		$self->{_logger}->log_message("    Unable to open directory: $current_dir") if($self->is_logging);
		
		return undef;		
	}
	
	my @files = readdir(CACHE_DIR);
	
	closedir(CACHE_DIR);
	
	
	# Load the more specific configuration if it exists
	if ( -e "$current_dir/$LS::Cache::Config::CACHE_FILENAME" ) {
		
		$self->{_logger}->log_message("    Reading local cache settings from:") if($self->is_logging);
		$self->{_logger}->log_message("        $current_dir/$LS::Cache::Config::CACHE_FILENAME") if($self->is_logging);
		
		$cache_config = $self->{_config}->read_cache_settings($current_dir, $cache_config);
	}

	$self->{_logger}->log_message("    Found " . ( $#files + 1 ) . " files.") if($self->is_logging);

	# Remove cache entries that have expired based on their timestamp
	my @remaining_files = ();
	my $total_size = 0;
	
	foreach my $f (@files) { 
				
		next if($f eq '.' || $f eq '..');
		next if($f eq $LS::Cache::Config::CACHE_FILENAME || 
			    $f eq $EXPIRATION_FILENAME ||
			    $f eq $LS::Cache::Config::LOG_FILENAME);
			
		if( -d "$current_dir/$f") { 
			
			$self->{_logger}->log_message("    New directory found, recursing: $current_dir/$f") if($self->is_logging);
			
			push(@remaining_files, $self->maintain_cache($timestamp, "$current_dir/$f", $cache_config));
		}
		else {
			
			$self->{_logger}->log_message("    Checking timestamp for: $current_dir/$f") if($self->is_logging);
			
			if(!$self->is_expired(config => $cache_config, directory => $current_dir, 
								  filename => $f, timestamp => $timestamp)) {
				
				# Save some time and calculate the total size of the cache
				# in order to weed out the largets files to be compliant
				$total_size += -s "$current_dir/$f";
				
				push(@remaining_files, "$current_dir/$f");
				
				$self->{_logger}->log_message("    Keeping file based on date: $current_dir/$f") if($self->is_logging);
			}
			else {
				
				$self->expire_file($current_dir, $f);
				
				$self->{_logger}->log_message("    Removing file based on date: $current_dir/$f") if($self->is_logging);
			}
		}
	}
	
	
	$self->{_logger}->log_message("    Processing remaining files by size.") if($self->is_logging);
	
	# filter by size
	
	# Largest files are the first to go
	my @sorted_files = sort { (-s $b) <=> (-s $a) } @remaining_files;
	
	@remaining_files = ();

	# Remove files until the size of the directory is less than the max
	# If the max size is zero, make sure to remove zero byte files
	while($cache_config->{'max-cache-size'} != -1 && 
	      $total_size > $cache_config->{'max-cache-size'} ||
	      ($cache_config->{'max-cache-size'} == 0 && $#sorted_files > -1) ) { 
		
		my $f = pop(@sorted_files);

		$total_size -= ( -s $f );
			  
		$self->{_logger}->log_message("    Max size/current size: $cache_config->{'max-cache-size'} / $total_size") if($self->is_logging);
			  
		$self->expire_file($current_dir, $f);
			  
		$self->{_logger}->log_message("    Removing file based on size: $f") if($self->is_logging);
	}
	
	# Remove the directory if necessary
	if( $#sorted_files == -1) {
		
		# We really should check to see if the directory doesn't contain the log and Cache configuration
		#(!grep($LS::Cache::Config::CACHE_FILENAME|$LS::Cache::Config::LOG_FILENAME, @files))) {
		
		$self->{_logger}->log_message("    Removing directory: $current_dir") if($self->is_logging);
		rmdir($current_dir);
	}
	
	return @sorted_files;
}





#
# Retrieve cached entries
#



#
# lookupFile( %options ) - 
#
sub lookupFile {

	my ($self, %options) = @_;

	my $filename  = $options{'filename'};
	my $directory = $options{'directory'};

	unless( -e "$directory/$filename" ) {

		$self->{_logger}->log_message("File not cached: $directory/$filename") if($self->is_logging);

		return undef;
	}

	my $fh = new IO::File("$directory/$filename", "r");

	unless($fh) {

		$self->{_logger}->log_message("Unable to open cache file: $directory/$filename") if($self->is_logging);

		return undef;
	}

	my $expiration = $self->getExpiration(filename=> $filename,
					      directory=> $directory);

	return LS::Service::Response->new(response=> $fh,
				          expiration=> $expiration);
}


#
# lookupWSDL( %options ) -
#
sub lookupWSDL {

	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};

	
	my $authority = $lsid->authority;
	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/wsdl/' . $authority;

	my $filename = $self->canonicalized_disk_form($lsid) . ".$WSDL_EXT";


	
	$self->{_logger}->log_message("** Attempting to read WSDL for $authority from cache") if($self->is_logging);

	# Make sure the directory exists	
	$self->{_config}->create_dir($directory);
	
	# Load the expiration data and expire the file if necessary
	if($self->is_expired(directory=> $directory, 
			     filename=> $filename)) {
		
		$self->{_logger}->log_message("WSDL file has expired: $directory/$filename") if($self->is_logging);
		
		$self->expire_file($directory, $filename);
		
		return undef;
	}
	
	my $response;

	if( ($response = $self->lookupFile(filename=> $filename, directory=> $directory)) ) {

		$self->{_logger}->log_message("WSDL is cached: $directory/$filename") if($self->is_logging);
	}
	
	return $response;
}


#
# lookupData( %options ) -
#
sub lookupData {
	
	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};
	
	my $authority = $lsid->authority;
	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/data/' . $authority;
	
	
	$self->{_logger}->log_message("** Attempting to read DATA for $authority from cache") if($self->is_logging);

	# Make sure the directory exists	
	$self->{_config}->create_dir($directory);

	my $filename = 'data';

	# Find a file in the directory and return the filename

	my $response;

	if( ($response = $self->lookupFile(filename=> $filename, directory=> $directory)) ) {

		$self->{_logger}->log_message("DATA is cached: $directory/$filename") if($self->is_logging);
	}
	
	return $response;
}


#
# lookupMetadata( %options ) -
#
sub lookupMetadata {
	
	my ($self, %options) = @_;
	
	my $lsid = $options{'lsid'};

	my $portName = $options{'portName'};
	my $serviceName = $options{'serviceName'};

	my $authority = $lsid->authority;
	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/metadata';
	my $canonical = $self->canonicalized_disk_form($lsid);

	my $filename = "$serviceName;$portName.$METADATA_EXT";

	$directory .= "/$authority/$canonical";

	$self->{_logger}->log_message("** Attempting to read METADATA for $authority from cache") if($self->is_logging);

	# Make sure the directory exists	
	$self->{_config}->create_dir($directory);
	
	# Load the expiration data and expire the file if necessary
	if($self->is_expired(directory => $directory, filename => $filename)) {
		
		#$self->{_logger}->log_message("Expiring METADATA: $directory/$filename") if($self->is_logging);
		
		$self->expire_file($directory, $filename);
		
		return undef;
	}
	
	my $response;

	if( ($response = $self->lookupFile(filename=> $filename, directory=> $directory)) ) {

		$self->{_logger}->log_message("METADATA is cached: $directory/$filename") if($self->is_logging);
	}
	
	return $response;
}


#
# cacheFile( %options ) -
#
sub cacheFile {

	my ($self, %options) = @_;


	my $filename	= $options{'filename'};
	my $directory	= $options{'directory'};

	my $cacheData	= $options{'cacheData'};
	my $expiration	= $options{'expiration'};

	# 1. Can the file/data fit in the directory?
	my $size;

	if(UNIVERSAL::isa($cacheData, 'File::Temp') ||
	   UNIVERSAL::isa($cacheData, 'IO::File') ) {

		$size = -s $cacheData;
	}
	else {

		$size = length($cacheData);
	}

	return undef unless($self->cacheable(directory=> $directory,
					     size=> $size,
					     timestamp=> $expiration));

	# 2a. If our cachedData is a temporary file, move it in to a permanent location
	my $fh;

	if(UNIVERSAL::isa($cacheData, 'File::Temp')) {

		unless(File::Copy::move($cacheData->filename, "$directory/$filename")) {

			$self->{_logger}->log_message("Unable to cache file: $directory/$filename. " .
						      "Could not save temporary file $cacheData to a permanent location.") 
				if($self->is_logging);

			return undef;
		}

		# 3. Update the file's expiration
		$self->update_expiration($directory, $filename, $expiration) if($expiration);

		# 4. Return a response in the form of a file handle
		$fh = new IO::File("$directory/$filename", "r");

		return LS::Service::Response->new(response=> $fh,
						  expiration=> $expiration);
	}

	# 2b. If we were passed raw data, write that to the store
	$fh = new IO::File("$directory/$filename", "w");

	if($fh->opened) {
	
		$self->{_logger}->log_message("Caching file: $directory/$filename") if($self->is_logging);

		binmode $fh;

		flock($fh, LOCK_EX);
	
		if(UNIVERSAL::isa($cacheData, 'IO::File')) {

			while(<$cacheData>) {

				$fh->print($_);
			}
		}
		else {

			$fh->print($cacheData);
		}
		
		flock($fh, LOCK_UN);
		
		$fh->close;
	}
	else {
		
		$self->{_logger}->log_message("Unable to cache file: $directory/$filename. " .
					      "Could not open location for writing.")
			if($self->is_logging);
		
		return undef;
	}
	
	# 3. Update the file's expiration
	$self->update_expiration($directory, $filename, $expiration) if($expiration);

	# 4. Return a response in the form of a filehandle
	$fh = new IO::File("$directory/$filename", 'r');

	unless($fh->opened) {

		$self->{_logger}->log_message("Unable to open file: $directory/$filename. " .
					      "Could not obtain file handle.")
			if($self->is_logging);

		return undef;
	}

	return LS::Service::Response->new(response=> $fh,
					  expiration=> $expiration);
}


#
# cacheWSDL( %options ) - 
#
sub cacheWSDL {

	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};
	my $response = $options{'response'};

	my $authority = $lsid->authority;

	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/wsdl';

	if( -d "$directory/$authority" || mkdir("$directory/$authority")) {
		
		$directory .= "/$authority";
	}
	else {
		
		die("Unable to create cache direcory: $directory/$authority\n");
	}

	my $filename = $self->canonicalized_disk_form($lsid) . ".$WSDL_EXT";

	return $self->cacheFile(filename=> $filename,
				directory=> $directory,
				expiration=> $response->expiration,
				cacheData=> $response->response);
}


#
# cacheData( %options ) -
#
sub cacheData {
	
	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};

	my $response = $options{'response'};
	
	my $authority = $lsid->authority;
	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/data';

	if(-d "$directory/$authority" || mkdir("$directory/$authority")) {
		
		$directory .= "/$authority";
	}
	else {
		
		die("Unable to create cache direcory: $directory/$authority\n");
	}

	my $filename = $self->canonicalized_disk_form($lsid) . ".$DATA_EXT";

	return $self->cacheFile(filename=> $filename,
				directory=> $directory,
				cacheData=> $response->response);	
}


#
# cacheMetadata( %options ) -
#
sub cacheMetadata {

	my ($self, %options) = @_;

	#my ($self, $lsid, $metadata, $expiration, $service_name, $port) = @_;
	
	my $lsid = $options{'lsid'};

	my $portName = $options{'portName'};
	my $serviceName = $options{'serviceName'};

	my $response = $options{'response'};
	
	my $authority = $lsid->authority;
	my $directory = $self->{_config}->get_config_entry('cache-root-dir') . '/metadata';
	my $canonical = $self->canonicalized_disk_form($lsid);

	if(-d "$directory/$authority" || mkdir("$directory/$authority")) {
		
		$directory .= "/$authority";
	}
	else {
		
		$self->{_logger}->log_message("Unable to create METADATA cache directory: $directory/$authority") if($self->is_logging);
	}

	if(-d "$directory/$canonical" || mkdir("$directory/$canonical")) {
	
		$directory .= "/$canonical";
	}
	else {
		
		$self->{_logger}->log_message("Unable to create METADATA cache directory: $directory/$canonical") if($self->is_logging);
	}
	
		
	my $filename = "$serviceName;$portName.$METADATA_EXT";
	
	return $self->cacheFile(filename=> $filename,
				directory=> $directory,
				expiration=> $response->expiration,
				cacheData=> $response->response);	
}


#
# Utility functions
#


#
# canonicalizedDiskForm( $lsid ) -
#
sub canonicalizedDiskForm {
	
	my ($self, $lsid) = @_;
	
	$lsid = $lsid->canonical;
	
	my $authority = $lsid->authority;
	my $namespace = $lsid->namespace;
	my $object = $lsid->object;
	my $revision = $lsid->revision;
	
	return "urn;lsid;$authority;$namespace;$object;$revision" if($revision);

	return "urn;lsid;$authority;$namespace;$object";
}


#
# canonicalized_disk_form( $lsid ) - Synonym for canonicalizedDiskForm.
#
sub canonicalized_disk_form {

	my $self = shift;
	return $self->canonicalizedDiskForm(@_);
}



#
# cacheable( %options ) - 
#
#
# 	Parameters: %options, Required. Keys used:
#		size:
#		directory:
#		timestamp:
#
#
# 	Returns: True if the file can be cached in the specifed directory
# 		 This loads the most specific configuration found and uses it to
# 		 determine cacheability.
#
sub cacheable {
	
	my ($self, %options) = @_;
	
	return undef if(!$options{'size'} || !$options{'directory'});
	
	my $config_ref = $self->{_config}->import_cache_settings($options{'directory'});
	
	my $dir_size = $self->dir_size($options{'directory'});
	
	if($config_ref->{'max-cache-size'} != -1 &&
	   $options{'size'} + $dir_size > $config_ref->{'max-cache-size'}) {

		$self->{_logger}->log_message("File can not be cached - Directory ($options{'directory'}) has reached its maximum capacity: $config_ref->{'max-cache-size'}");
		
		return undef;
	}
	
	if($config_ref->{'max-cache-lifetime'} != -1 && $options{'timestamp'}) {

		my $cur_time = $self->get_time;	
		my $time_lived = $cur_time - $options{'timestamp'};	

		
		if($time_lived > $config_ref->{'max-cache-lifetime'}) {
			
			$self->{_logger}->log_message("File can not be cached - Directory ($options{'directory'}) has low TTL: $time_lived > $config_ref->{'max-cache-lifetime'}");
		
			return undef;
		}
	}
	
	$self->{_logger}->log_message("File can be cached in: $options{'directory'}");
}

#
# Returns true if the file has expired
#
# %options keys - config, timestamp, filename, directory
#
sub is_expired {
	
	my ($self, %options) = @_;
	
	die("Invalid paramaters: is_expired\n") if(!$options{'filename'} || !$options{'directory'});

	my $config_ref = $self->{_config};
	my $curr_time = $self->get_time;
	
	$config_ref = $options{'config'} if($options{'config'});
	$curr_time = $options{'timestamp'} if($options{'timestamp'});
	
	my $max = $config_ref->{'max-cache-lifetime'};
	
	return undef if($max == -1);

	my $expiration = $self->getExpiration($options{'directory'}, $options{'filename'});
	
	if(!$expiration) {
		
		# Grab the last modified time and use that
		# (maybe use the creation time instead?)
		$expiration = ( stat ($options{filename}) )[9];
		$expiration *= 1000;
	}

	return undef if($expiration == -1);
	
	if($self->is_logging) {
		
		my $time_lived = $curr_time - $expiration;
		
		#$self->{_logger}->log_message("Is expired: $time_lived > $max");
	}
	
	return ($curr_time - $expiration) > $max;
}



#
# Expiration options for individual files
#

#
# getExpiration( $directory, $caononicalFilename ) -
#
#	Parameters:
#		$directory, Required. 
#		$canonicalFilename, Required. 
#
#
#	Returns:
#
sub getExpiration {

	my ($self, $directory, $canonical_filename) = @_;

	my $exp_hash_ref = $self->read_expiration_file($directory);
	
	if(!defined($exp_hash_ref->{$canonical_filename}) || 
	   $exp_hash_ref->{$canonical_filename} == -1) {
		
		return undef;
	}
	
	$self->{_logger}->log_message("Retrieving expiration for: $directory/$canonical_filename") if($self->is_logging);
	$self->{_logger}->log_message("Expiration Time: " . $exp_hash_ref->{$canonical_filename}) if($self->is_logging);
		
	return $exp_hash_ref->{$canonical_filename};
}	

sub expire_file { 
	
	my ($self, $directory, $canonical_filename) = @_;
	
	if ( -f "$directory/$canonical_filename" ) {
		
		$self->{_logger}->log_message("Removing file: $directory/$canonical_filename") if($self->is_logging);
		
		unlink("$directory/$canonical_filename");
	}
	
	my $exp_hash_ref = $self->read_expiration_file($directory);
	
	delete($exp_hash_ref->{$canonical_filename});
	
	$self->write_expiration_file($directory, $exp_hash_ref);
}

sub update_expiration {
	
	my ($self, $directory, $canonical_filename, $expiration_time) = @_;
	
	$self->{_logger}->log_message("Updating expiration for: $directory/$canonical_filename") if($self->is_logging);
	#$self->{_logger}->log_message("    Expiration time: $expiration_time") if($self->is_logging);
	
	my %exp;
	my $exp_hash_ref = $self->read_expiration_file($directory);
	
	if($exp_hash_ref) {
	
		# Update the expiration time for this entry. This has the side effect
		# of creating the entry if it doesn't exist
		$exp_hash_ref->{$canonical_filename} = $expiration_time;
	}
	else {
		
		$exp{$canonical_filename} = $expiration_time;
		$exp_hash_ref = \%exp;
	}
	
	$self->write_expiration_file($directory, $exp_hash_ref);
}

#
# Read and write to expiration files
#
# It's important to know that these deal with complete files,
# in otherwords write_expiration_file overwrites the entire file,
# read_expiration_file read the entire file in to a hash.
# 
sub read_expiration_file {
	
	my ($self, $directory) = @_;
	
	my %exp_hash;
	
	return undef if(! -e "$directory/$EXPIRATION_FILENAME");		
	#$self->{_logger}->log_message("Expiration file does not exist: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
		
	if(!open(EXPIRE_FILE, "$directory/$EXPIRATION_FILENAME")) {
		
		$self->{_logger}->log_message("Unable to open expiration file: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
		
		return undef;
	}
	
	flock(EXPIRE_FILE, LOCK_EX);
	
	#$self->{_logger}->log_message("Reading expiration file: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
	
	# The file is of the form - canonical_filename::expiration
	# All other lines are ignored
	while(<EXPIRE_FILE>) {
		
		if(/(.*)::(.*)/) {

			$exp_hash{$1} = $2;
		}			
	}
	
	flock(EXPIRE_FILE, LOCK_UN);
	
	close(EXPIRE_FILE);

	return \%exp_hash;
}

sub write_expiration_file {
	
	my ($self, $directory, $exp_hash_ref) = @_;
	
	return undef if(!$exp_hash_ref);
	
	if(!open(EXPIRE_FILE, ">$directory/$EXPIRATION_FILENAME")) {
		
		$self->{_logger}->log_message("Unable to open expiration file: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
		
		return undef;
	}
	
	flock(EXPIRE_FILE, LOCK_EX);
	
	#$self->{_logger}->log_message("Writing expiration file: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
	
	foreach my $cf (keys(%{$exp_hash_ref})) {

		# The file is of the form - canonical_filename::expiration	
		print EXPIRE_FILE "$cf\:\:" . $exp_hash_ref->{$cf} . "\n";
	}		
	
	flock(EXPIRE_FILE, LOCK_UN);
	
	close(EXPIRE_FILE);
	
	# Remove the empty file
	if( -s "$directory/$EXPIRATION_FILENAME" == 0) {
		
		#$self->{_logger}->log_message("Empty expiration file, removing: $directory/$EXPIRATION_FILENAME") if($self->is_logging);
		
		unlink("$directory/$EXPIRATION_FILENAME");
	}
}

#
# Calculates the size of the directory
# excluding system files
#
sub dir_size {
	
	my ($self, $dir) = @_;
	
	opendir(DIR, $dir);
	my @files = readdir(DIR);
	closedir(DIR);
	
	my $sz = 0;
	foreach(@files) {
		
		next if($_ eq '.' || $_ eq '..');
		next if($_ eq $LS::Cache::Config::CACHE_FILENAME || 
			$_ eq $EXPIRATION_FILENAME ||
			$_ eq $LS::Cache::Config::LOG_FILENAME);
		
		$sz += (-s "$dir/$_");
	}
	
	return $sz;
}

1;

__END__

=head1 NAME

LS::Cache::Manager - Cache manager for LSID data, metadata, URIs and WSDL

=head1 SYNOPSIS

=head1 DESCRIPTION

A cache manager for all LSID client and server transactions. The cache manager can be
control through two environment variables: LSID_CACHE_ROOT for the root of the cache and
LSID_LOGGING_ON which can be either string 'true' or 'false'.

=head1 CONSTRUCTORS

=over

=item new ( %options )

=back

=head1 METHODS

=over

=item maintain_cache( $timestamp, $current_dir, $cache_config_ref )

Cleans the cache based on the specified timestamp in the directory $current_dir. 
Optionally, the cache configuration paramaters can be specified. If left unspecified,
the system wide defaults will be loaded and then any local configurations from $current_dir
down will be loaded.

=item get_time

Returns the current time in milliseconds.

=item enable_log ( )

Enables cache transaction logging to the specified file.

=item is_logging ( )

Returns true of the file log is on, false otherwise.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>
