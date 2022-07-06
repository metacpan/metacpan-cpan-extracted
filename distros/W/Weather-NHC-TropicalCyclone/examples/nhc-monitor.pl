#!/usr/bin/env perl

use strict;
use warnings;

use Weather::NHC::TropicalCyclone ();

use Getopt::Long ();
$|++;    # autoflush

my $nhc = Weather::NHC::TropicalCyclone->new;

my $opts_ref = {};
Getopt::Long::GetOptions( $opts_ref, "nhcName=s", "once", "statefile=s", "storm=i", "year=s" );

my $stormsAdvCache = {};

my $DONE = 0;

WATCH:
while ( not $DONE ) {
    local $@;
    my $ok = eval { $nhc->fetch; };

    if ( not $ok or $@ ) {
        print qq{Error fetching NHC JSON detected. Retrying in 5 seconds...\n};
        sleep 5;
        next WATCH;
    }

    my $storms_ref = $nhc->active_storms;

    # grab all xml files
    my $index_at_xml = $nhc->fetch_rss_atlantic(q{index-at.xml});
    my $index_ep_xml = $nhc->fetch_rss_east_pacific(q{index-ep.xml});
    my $index_cp_xml = $nhc->fetch_rss_central_pacific(q{index-cp.xml});

  STORMS:
    foreach my $storm (@$storms_ref) {
        my $advNum   = $storm->publicAdvisory->{advNum};
	print qq{$advNum\n};
        my $imgs_ref = $storm->fetch_forecastGraphics_urls;
	next;
        if ( not $stormsAdvCache->{ $storm->id }->{$advNum} ) {
            my $advisory_file = sprintf( "%s.fst", $storm->id );
            my ( $text, $advNum, $local_file ) = $storm->fetch_forecastAdvisory($advisory_file);

            my $new_advisory_file = sprintf( "%s.%s.fst.html", $advNum, $storm->id );
            rename $local_file, $new_advisory_file;

            # convert forecast advisorys to ATCF format
            my $new_advisory_atcf_file = sprintf( "%s.%s.fst", $advNum, $storm->id );
            my ( $atcf_ref, $advNum_atcf, $saved ) = $storm->fetch_forecastAdvisory_as_atcf($new_advisory_atcf_file);

            print qq{Extracted ATCF format from $new_advisory_file ... \n};

            # create symlink to latest $new_advisory_file withouth advNum
            my $_advisory_file = sprintf( "%s.fst", $storm->id );

            $stormsAdvCache->{ $storm->id }->{$advNum} = $text;
            print qq{New advisory ($advNum) found for } . $storm->id . qq{!\n};
            my $best_track = $storm->fetch_best_track( sprintf( qq{b%s.dat}, $storm->id ) );
            if ( -e $best_track ) {
                print qq{Downloaded "$best_track" successfully\n};
            }
            else {
                print qq{Download of "$best_track" failed!\n};
            }

        }
    }

    if ( $opts_ref->{once} ) {
        ++$DONE;
        next WATCH;
    }

    print qq{. };
    sleep 30;
}
