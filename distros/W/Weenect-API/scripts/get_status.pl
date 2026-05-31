#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Thu Apr 23 19:20:34 2026
# Last Modified By: Johan Vromans
# Last Modified On: Sat May 30 17:18:52 2026
# Update Count    : 260
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.36;
use Object::Pad;
use utf8;
use lib qw( lib );

# Package name.
my $my_package = 'Weenect';
# Program name and version.
my ($my_name, $my_version) = qw( get_status 1.00 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $ts = do {
    my @tm = localtime;
    sprintf( "%04d%02d%02d_%02d%02d%02d",
	     1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
};

################ The Process ################

main();

################ Subroutines ################

use Weenect;
use Weenect::Position;		# for W::Point

sub main() {
    my $home = Weenect::Point->new( latitude => 52.8849946,
				    longitude => 6.8592215 );
    print("== $ts\n");

    my $api = Weenect::API->new;
    $api->debug = $debug;
    $api->login;

    my $trackers = $api->get_trackers;

    foreach my $tracker ( @$trackers ) {

	printf("Tracker %s [%d%s]\n", $tracker->name, $tracker->id,
	      $tracker->active ? "" : ",inactive" );
	next unless $tracker->active;

	my $here = $tracker->position->[0];
	# date_tracker -> timestamp of position
	# date_server  -> timestamp when the server received it
	printf( "  Distance: %dm\n", $home->distance($here) );
	printf( "  %s\n", $here->$_ )
	  for qw( battery_text gsm_text accuracy_text );

	my $zones = $tracker->get_wifizones;
	my $zid = $here->wifi_zone_id;
	foreach my $zone ( @$zones ) {
	    printf( "  %sWiFi zone %s [%d, %dm]%s\n",
			$zid == $zone->id ? ">" : " ",
			$zone->name, $zone->id,
			$zone->radius,
			$zone->is_active ? "" : " INACTIVE",
		      );
	}

	$zid = $tracker->geofence_number;
	$zones = $tracker->get_zones;
	foreach my $zone ( @$zones ) {
	    my $mark = " ";
	    if ( $zone->id == $zid ) {
		$mark = ">";
		$zid = -1;
	    }
	    printf( "  %sZone %s [%d, mode %d, %dm]\n",
		    $mark,
		    $zone->name,
		    $zone->id,
		    $zone->mode, # No, Enter, Exit, Enter+Exit notification
		    $zone->distance,
		  );
	}
	if ( $zid >= 0 ) {
	    my $name = $here->geofence_name // "<unknown>";
	    printf( "  Geofence zone: %s [%d]\n", $name, $zid );
	}
    }
}

################ Classes ################


package main;

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'ident'	=> \$ident,
		     'verbose+'	=> \$verbose,
		     'quiet'	=> sub { $verbose = 0 },
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
