# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Cache::Config;

use strict;
use warnings;

use vars qw( $CACHE_FILENAME $LOG_FILENAME $DEFAULT_ROOT_CACHE_DIR );


use Carp qw(:DEFAULT);


use LS::Cache::Logger;



$CACHE_FILENAME = 'lsid-cache.properties';
$LOG_FILENAME = 'lsid-cache.log';
$DEFAULT_ROOT_CACHE_DIR = '/tmp/lsid-client/cache';


#
# new( %options ) - 
#
sub new {
	
	my ($self, %options) = @_;
	
	unless (ref $self) {
				
		$self = bless {

			# Setup the default cache settingss
			'cache-root-dir' => $DEFAULT_ROOT_CACHE_DIR,
			'max-cache-size' => -1,
			'max-cache-lifetime' => -1,
			'logging-on' => 'true',
			'log-file' => "$DEFAULT_ROOT_CACHE_DIR/$LOG_FILENAME",
			'max-cache-size-high' => 0,
			'max-cache-lifetime-high' => 0,
			
			'_logger' => undef,
		}, $self;
	}

	$self->{_logger} = LS::Cache::Logger->new('log-file' => $self->{'log-file'});
	
	
	# Override the root from the environment
	if($options{'cache-root-dir'}) {
		
		$self->{'cache-root-dir'} = $options{'cache-root-dir'};

		# Update the log file
		$self->{'log-file'} = $self->{'cache-root-dir'} . "/$LOG_FILENAME";
	}

	if($options{'logging-on'}) {

		$self->{'logging-on'} = 'true';
	}
	
	# Detect the path delimiter
	if($self->{'cache-root-dir'} =~ /^\\.*/) {
	
		$self->{'cache-root-dir'} =~ s/\\/\//g;
	}

	# Make sure it exists
	if(! -e $self->{'cache-root-dir'}) { 
		
		$self->create_dir($self->{'cache-root-dir'});
	}

	# Read the global cache settings	
	my $config_ref = $self->read_cache_settings($self->{'cache-root-dir'}, $self);
	
	$self->update_config($config_ref);
	
	return $self;
}

sub get_config_entry {
	
	my ($self, $entry_key) = @_;
	
	return $self->{$entry_key};
}

sub update_config {
	
	my ($self, $config_ref) = @_;
	
	foreach(keys(%$config_ref)) {
		
		$self->{$_} = $config_ref->{$_};
	}
}

sub import_cache_settings {
	
	my ($self, $directory) = @_;
	
	my @dirs = split /\//, $directory;

	# Elminate the blank space etc.
	while($dirs[0] =~ /^ *$/) {

		shift @dirs;
	}

	my $cwd = shift(@dirs);

	# Try to load the directory's cache using the template as a default
	my %cache_settings = %{$self->read_cache_settings($cwd, $self)};
	
	foreach my $d (@dirs) {
		
		if( -e "$cwd/$d/$CACHE_FILENAME") {
			
			%cache_settings = %{$self->read_cache_settings("$cwd/$d", \%cache_settings)};
		}
		$cwd .= "/$d";
	}
	
	return \%cache_settings;
}

sub read_cache_settings {

	my ($self, $directory, $cache_settings_ref) = @_;
	
	my %cache_settings;
			
	%cache_settings = %{$cache_settings_ref} if($cache_settings_ref);

	return $cache_settings_ref if(! -e "$directory/$CACHE_FILENAME");
	
	open(FILE, "$directory/$CACHE_FILENAME");
	
	while(<FILE>) {
		
		# TODO:
		# Change this so that it is a more strict regex
		# Add validation to the values as well
		
		if(/^max-cache-size:(.*)/) {
			
			if ($cache_settings{'max-cache-size'} > $1	|| 
				($cache_settings{'max-cache-size'} == -1 && $1 > 0)) {
									
				$cache_settings{'max-cache-size'} = $1;
			}
			else {
				
				$self->{_logger}->log_message("Invalid max-cache-size, parent: " . 
						$cache_settings{'max-cache-size'} . " current: $1") if($self->{'logging-on'} eq 'true');
			}
		}
		elsif(/^max-cache-lifetime:(.*)/) {
			
			if($cache_settings{'max-cache-lifetime'} > $1  || 
			   ($cache_settings{'max-cache-lifetime'} == -1 && $1 > 0)) {
					
				$cache_settings{'max-cache-lifetime'} = $1;
			}
			else {
				
				$self->{_logger}->log_message( 'Invalid max-cache-lifetime, parent ' . 
						$cache_settings{'max-cache-lifetime'} . " current: $1") if($self->{'logging-on'} eq 'true');
			}
		}
		elsif(/^logging-on:(true|false)/) {
			
			$cache_settings{'logging-on'} = 'false';
			$cache_settings{'logging-on'} = 'true' if ($1 eq 'true');
		}
		elsif(/^log-file:(.*)/) {
			
			$cache_settings{'log-file'} = $1;			
		}
		elsif(/^max-cache-size-high:(.*)/) {
			
			if($cache_settings{'max-cache-size-high'} > $1 ||
			   ($cache_settings{'max-cache-size-high'} == -1 && $1 > 0)) {
					
				$cache_settings{'max-cache-size-high'} = $1;
			}
			else {
				
				$self->{_logger}->log_message( 'Invalid max-cache-size-high, parent ' .
						$cache_settings{'max-cache-size-high'} . " current $1") if($self->{'logging-on'} eq 'true');
			}
		}
		elsif(/^max-cache-lifetime-high:(.*)/) {
			
			if($cache_settings{'max-cache-lifetime-high'} > $1 ||
			   ($cache_settings{'max-cache-lifetime-high'} == -1 &&	$1 > 0)) {
				
				$cache_settings{'max-cache-lifetime-high'} = $1;
			}
			else {
				
				$self->{_logger}->log_message( 'Invalid max-cache-lifetime-high, parent ' .
		  				$cache_settings{'max-cache-lifetime-high'} . " current $1") if($self->{'logging-on'} eq 'true');
			}
		}
		elsif(/^#/) {

			# Comment, ignored
			next;
		}
		else {
			print STDERR Carp::shortmess("Invalid configuration line: $_");
		}
	}

	close(FILE);

	return \%cache_settings;	
}

sub create_dir {
	
	my ($self, $directory) = @_;
	
	my @directories = split(/\//, $directory);
	my $work = '/' . $directories[1];
	
	# Elminate the blank space etc.
	shift @directories;
	shift @directories;
			
	foreach(@directories) {
	
		if(! -e $work) {
		
			print STDERR Carp::longmess("Unable to make directory $work") unless(mkdir($work));
		}
		
		$work .= "/$_";
	}
	
	if(! -e $work) {
	
		print STDERR Carp::longmess("Unable to make directory $work") unless(mkdir($work));
	}
}

1;

__END__

=head1 NAME

LS::Cache::Config - Configuration loader for LSID Cache manager

=head1 SYNOPSIS

 # Create a new configuration with the default settings, overridden
 # by those in /tmp/cache
 my $config = new LS::Cache::Config('cache-root-dir' => '/tmp/cache');

 print "Log filename: " . $config->get_config_entry('log-file');

=head1 DESCRIPTION

The Cache configuration object holds all configuration parameters for the LSID
cache manager. Additionally, it can read and validate cache settings from directories.

=head1 CONSTRUCTORS

=over

=item new ( %options )

Create a new cache configuration object with the specified options:

=over

 cache-root-dir: The root cache directory.
 log-file: The log file name.

=back

=back

=head1 METHODS

=over

=item get_config_entry ( $entry_name )

Returns the value that the configuration entry holds.

=item update_config ( $config_object_ref )

Update the configuration object's settings based on the reference passed. This
could just be a hash with the appropriate keys set, it does not need to be an object.

=item read_cache_settings( $directory, $config_object_ref )

Read the directory's cache settings in to the specified configuration object. 
Invalid cache settings will be ignored.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>
