#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Mon Apr 27 16:42:51 2026
# Last Modified By: Johan Vromans
# Last Modified On: Sat May 30 17:19:22 2026
# Update Count    : 127
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.36;
use Object::Pad;
use utf8;
use lib qw( lib );

# Package name.
my $my_package = 'Weenect';
# Program name and version.
my ($my_name, $my_version) = qw( get_history 1.00 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $start;			# "2026-05-04" or "2026-05-04T11:00:00.000Z"
my $end;			# "2026-05-04T11:00:00.000Z"
my $dir = ".";			# output dir
my $view;			# run gpxsee on data
my $fetch = 0;			# forced reload
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.

# Timestamp, "2026-05-04T11:00:00.000Z", GMT.
my $ts = do {
    my @tm = gmtime(time);
    sprintf( "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
	     1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
};

# Datestamp, "2026-05-04", GMT.
my $ds = substr( $ts, 0, 10 );

$start //= $ds;
if ( $start =~ /^\d{4}-\d\d-\d\d$/ ) {
    $start .= "T00:00:00.000Z";
}
unless ( $start =~ /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z$/ ) {
    die("Invalid start time: $start\n");
}
$end //= substr( $start, 0, 10 );
if ( $end =~ /^\d{4}-\d\d-\d\d$/ ) {
    $end .= "T23:59:59.000999Z"
}
unless ( $end =~ /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z$/ ) {
    die("Invalid end time: $start\n");
}

$dir //= ".";
$dir =~ s/\/*$/\//;

$trace |= ($debug || $test);

################ Presets ################

use JSON::XS;
my $json = JSON::XS->new->utf8;

################ The Process ################

my $hist = get_history();

my $gpx = make_gpx($hist);

system( "gpxsee", $gpx ) if $view;

################ Subroutines ################

sub make_gpx( $hist ) {
    my $ds = substr($start,0,10);
    my $gpx = "$dir/$ds.gpx";
    open( my $fd, '>', $gpx );
    select($fd);

    print <<EOD;
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" version="1.1" creator="$my_name $my_version">
  <metadata>
    <name>$ds</name>
  </metadata>
  <trk>
    <name>$ds</name>
    <trkseg>
EOD

    my $pts = "";
    my $pfx = 1;
    $hist->{positions} //= [];
    for ( reverse $hist->{positions}->@* ) {
	my $pos = Weenect::Position->create_sparse($_);
	my $ts = $pos->date_tracker;
	next if $ts eq $pts;
	# Check for long pause ( > 1h ).
	if ( $pts && substr($ts, 11, 2) - substr($pts, 11, 2) > 1 ) {
	    # New track.
	    $pfx++;
	    print <<EOD;
    </trkseg>
  </trk>
  <trk>
    <name>$ds $pfx</name>
    <trkseg>
EOD
	}
	$pts = $ts;
	$ts =~ s/\+00:00$/Z/;
	printf( qq{      <trkpt lat="%s" lon="%s">\n}.
		qq{        <time>%s</time>\n}.
		qq{      </trkpt>\n},
		$pos->latitude, $pos->longitude, $ts );
    }
    print <<EOD;
    </trkseg>
  </trk>
</gpx>
EOD
    close($fd) || die("$gpx: $!\n");

    return $gpx;
}

use IO::Compress::Gzip     qw( gzip   $GzipError   );
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );

use Weenect;

sub get_history {
    my $ds = substr($start,0,10);
    my $raw = "$dir/$ds.json.gz";
    if ( !$fetch && -s $raw ) {
	my $output;
	gunzip( $raw => \$output );
	return $json->decode($output);
    }

    my $api = Weenect::API->new;
    $api->debug = $debug;
    $api->login;

    my $trackers = $api->get_trackers;
    my $tracker = $trackers->[0];

    printf("Tracker %s [%d%s]\n", $tracker->name, $tracker->id,
	  $tracker->active ? "" : ",inactive" );
    next unless $tracker->active;

    my $hist = $tracker->get_history( $start, $end );
    return unless $hist;

    gzip( \$json->encode($hist) => $raw );
    die("$raw: $GzipError!\n") if $GzipError;

    return $hist;
}

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'start=s'  => \$start,
		     'end=s'    => \$end,
		     'dir=s'    => \$dir,
		     'fetch|reload'	=> \$fetch,
		     'view'	=> \$view,
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
   --start=XXX		start time
   --end=XXX		end time
   --view		show results
   --fetch		forced reload
   --dir=XXX		output folder (default: current dir)
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

start/end is YYY-MM-DDDTHH:MM:SS.mmmZ (iso 6801, UTC). The time part
is optional. Start defaults to today, 0:00 UTC. End defaults to start
at 23:59 UTC.

EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

