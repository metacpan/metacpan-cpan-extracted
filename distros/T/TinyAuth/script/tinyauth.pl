#!/usr/bin/perl

package main;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.98';
}

sub error {
	print "Content-type: text/plain\n\nError: $_[0]\n";
	exit(0);
}

BEGIN {
	eval {
		require FindBin;
		require File::Spec;
		require Scalar::Util;
		require YAML::Tiny;
		require CGI;
		require Authen::Htpasswd;
		require Email::MIME;
		require Email::MIME::Creator;
		require Email::Send;
	};
	if ( $@ ) {
		error("Failed to load critical module dependency: $@");
	}
}

unless ( $ENV{TEST_TINYAUTH} ) {
	# Create the configuration
	my $config_file = File::Spec->catfile( $FindBin::Bin, 'tinyauth.conf' );
	unless ( -f $config_file ) {
		error("Config file $config_file does not exist");
	}
	unless ( -f $config_file ) {
		error("No read permissions for config file $config_file");
	}

	my $config = YAML::Tiny->read( $config_file );
	unless ( $config ) {
		error("Failed to load config file at $config_file");
	}

	# Create the web application
	my $application = eval {
		TinyAuth->new(
			config => $config,
		)
	};
	unless ( $application ) {
		error("Failed to create TinyAuth instance: $@");
	}

	# Run the instance
	my $rv = eval { $application->run };
	unless ( $rv ) {
		error("Application instance failed to run: $@");
	}

	exit(0);
}





$INC{'TinyAuth.pm'} = __FILE__;
#####################################################################
# Inline lib/TinyAuth.pm
