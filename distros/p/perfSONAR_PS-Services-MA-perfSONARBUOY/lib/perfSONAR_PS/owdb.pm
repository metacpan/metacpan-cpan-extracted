package perfSONAR_PS::owdb;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);
use constant JAN_1970 => 0x83aa7e80;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::owdb

=head1 DESCRIPTION

TBD 

=cut

use FindBin;
use POSIX;
use Fcntl qw(:flock);
use FileHandle;
use File::Basename;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

use perfSONAR_PS::OWP;
use perfSONAR_PS::OWP::Utils;

@ISA    = qw(Exporter);
@EXPORT = qw(owdb_prep owdb_fetch owdb_worst_case owdb_plot_script bwdb_plot_script bwdb_dist_plot_script ntpdb_peer_plot_script ntpdb_loop_plot_script ntpdb_color_per_peer_plot_script trdb_plot_script trcir_plot_script);

#$OWP::REVISION = '$Id: owdb.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION       = '1.0';

=head2 owdb_prep()

owdb_prep: this routine is used to initialize the database connection
for fetching owamp data.
Pass in a ref to a hash, and it will be filled with values for:
START
END
SENT
LOST
DUPS
MIN
MAX
ERR
ALPHA_%08.6f (with the %08.6f replaced ala sprintf for every alpha
  value passed in using the 'ALPHAS' arg.)
ALPHAS (A sub hash with the keys set from the original alphas passed
  in and the values set to the delay of that "alpha".)

=cut

sub owdb_prep {
    my (%args)     = @_;
    my (@must)     = qw(DBH RES TNAME FIRST LAST OWHASH BUCKETWIDTH);
    my (@optional) = qw(ONLY_VALIDATED ALPHAS);
    my (@argnames) = ( @must, @optional );
    %args = owpverify_args( \@argnames, \@must, %args );
    scalar %args || die "Invalid args passed to owdb_prep";

    my (%owdbh);

    # save ref to callers hash - values are returned in this hash.
    $owdbh{'OWHASH'}      = $args{'OWHASH'};
    $owdbh{'BUCKETWIDTH'} = $args{'BUCKETWIDTH'};

    my $sql;
    if ( $args{'ONLY_VALIDATED'} ) {
        $sql = "SELECT a.si,a.start,a.end,a.sent,a.lost,a.dups,
						a.min,a.max,a.err,b.i,b.n
			FROM OWP_$args{'TNAME'} AS a
			JOIN OWPDelays_$args{'TNAME'} AS b
			ON a.si = b.si and a.res = b.res
			WHERE
				a.res=? AND a.ei>? AND a.si<? AND a.valid!=0
			ORDER BY a.si,b.i";
    }
    else {
        $sql = "SELECT a.si,a.start,a.end,a.sent,a.lost,a.dups,
						a.min,a.max,a.err,b.i,b.n
			FROM OWP_$args{'TNAME'} AS a
			JOIN OWPDelays_$args{'TNAME'} AS b
			ON a.si = b.si and a.res = b.res
			WHERE
				a.res=? AND a.ei>? AND a.si<?
			ORDER BY a.si,b.i";
    }

    $owdbh{'STH'} = $args{'DBH'}->prepare($sql)
        || die "Prep:Select owdb data";
    $owdbh{'STH'}->execute( $args{'RES'}, $args{'FIRST'}, $args{'LAST'} )
        || die "Select owdb data $DBI::errstr";

    my @vrefs = \( $owdbh{'FIRST'}, $owdbh{'START'}, $owdbh{'END'}, $owdbh{'SENT'}, $owdbh{'LOST'}, $owdbh{'DUPS'}, $owdbh{'MIN'}, $owdbh{'MAX'}, $owdbh{'ERR'}, $owdbh{'Bi'}, $owdbh{'Bn'}, );
    $owdbh{'STH'}->bind_columns(@vrefs);
    my @alphas;
    for ( ref $args{'ALPHAS'} ) {
        /^$/ and push @alphas, $args{'ALPHAS'}, next;
        /ARRAY/ and @alphas = @{ $args{'ALPHAS'} }, next;
    }

    @{ $owdbh{'ALPHAVALS'} } = sort @alphas if (@alphas);

    $owdbh{'DOMORE'} = 1;
    $owdbh{'OSTART'} = 0;
    $owdbh{'OEND'}   = 0;

    return \%owdbh;
}

=head2 owdb_fetch()

TDB

=cut

sub owdb_fetch {
    my (%args)     = @_;
    my (@argnames) = qw(OWDBH);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || die "Invalid args passed to owdb_fetch";

    my $owdbh        = $args{'OWDBH'};
    my $owhash       = $owdbh->{'OWHASH'};
    my $nrecs        = 0;
    my $session_done = 0;

    if ( !$owdbh->{'DOMORE'} ) {
        return undef;
    }

    # increment nrecs to account for last record
    # from "previous" session.
    $nrecs++ if ( $owdbh->{'OSTART'} );

    while ( !$session_done ) {
        if ( !$owdbh->{'STH'}->fetch ) {
            $owdbh->{'START'}  = 0;
            $owdbh->{'DOMORE'} = 0;

            # If no records at all, return 0 here.
            return undef if ( !$owdbh->{'OSTART'} );
        }

        if ( $owdbh->{'START'} ne $owdbh->{'OSTART'} ) {

            # new owamp session - output current values
            if ( $owdbh->{'OSTART'} ) {
                $owhash->{'START'}     = $owdbh->{'OSTART'};
                $owhash->{'END'}       = $owdbh->{'OEND'};
                $owhash->{'SENT'}      = $owdbh->{'OSENT'};
                $owhash->{'LOST'}      = $owdbh->{'OLOST'};
                $owhash->{'DUPS'}      = $owdbh->{'ODUPS'};
                $owhash->{'ERR'}       = $owdbh->{'OERR'};
                $owhash->{'MIN'}       = $owdbh->{'OMIN'};
                $owhash->{'MAX'}       = $owdbh->{'OMAX'};
                $owhash->{'HISTOGRAM'} = $owdbh->{'HISTOGRAM'};
                my $avref      = $owdbh->{'ALPHAVALS'};
                my $adref      = $owdbh->{'ALPHADELAYS'};
                my $num_alphas = @{$avref};
                my $i;
                delete $owhash->{'ALPHAS'};

                for ( $i = 0; $i < $num_alphas; $i++ ) {
                    my $nstr = sprintf( "%08.6f", ${$avref}[$i] );
                    $owhash->{"ALPHA_$nstr"} = ${$adref}[$i];
                    ${ $owhash->{'ALPHAS'} }{ ${$avref}[$i] } = ${$adref}[$i];
                }
                $session_done = 1;

            }

            # Now initialize the values for the new current session.

            $owdbh->{'OSTART'} = new Math::BigInt( $owdbh->{'START'} );
            $owdbh->{'OEND'}   = new Math::BigInt( $owdbh->{'END'} );
            $owdbh->{'OSENT'}  = $owdbh->{'SENT'};
            $owdbh->{'OLOST'}  = $owdbh->{'LOST'};
            $owdbh->{'ODUPS'}  = $owdbh->{'DUPS'};
            $owdbh->{'OERR'}   = $owdbh->{'ERR'};
            $owdbh->{'OMIN'}   = $owdbh->{'MIN'};
            $owdbh->{'OMAX'}   = $owdbh->{'MAX'};

            # reset buckets
            $owdbh->{'ALPHADELAYS'} = [];
            $owdbh->{'ALPHAINDEX'}  = 0;
            $owdbh->{'ALPHASUM'}    = 0;
            delete $owdbh->{'HISTOGRAM'};

        }

        if ( $owdbh->{'START'} && !$session_done ) {
            $nrecs++;
        }

        if ( $owdbh->{'DOMORE'} ) {
            my $sum        = ( $owdbh->{'ALPHASUM'} += $owdbh->{'Bn'} );
            my $index      = $owdbh->{'ALPHAINDEX'};
            my $avref      = $owdbh->{'ALPHAVALS'};
            my $adref      = $owdbh->{'ALPHADELAYS'};
            my $sent       = $owdbh->{'OSENT'};
            my $num_alphas = @{$avref};
            my $href       = $owdbh->{'HISTOGRAM'};
            $owdbh->{'HISTOGRAM'}{ $owdbh->{'Bi'} } = $owdbh->{'Bn'};

            while (( $index < $num_alphas )
                && ( $sum >= ${$avref}[$index] * $sent ) )
            {
                ${$adref}[$index] = $owdbh->{'Bi'} * $owdbh->{'BUCKETWIDTH'};
                $index++;
            }
            $owdbh->{'ALPHAINDEX'} = $index;
        }
    }
    return $nrecs;
}

=head2 owdb_plot_script()

TDB

=cut

sub owdb_plot_script {

    my ( $tname, $tstamp, $bucket_width, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $width = 500;
    my $ymin  = 0;
    my $ymax  = 0.16;

    my @reslist;

    # get resolutions
    $sql = "SELECT res from resolutions order by res";
    $sth = $dbh->prepare($sql) || die "Prep:Select resolutions";
    $sth->execute() || die "Select resolutions";
    while ( @row = $sth->fetchrow_array ) {
        push @reslist, @row;
    }

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;
    my $res    = 0;
    my $lowest = $reslist[-1];

    # search for highest resolution data that "fits" the width of the plot.
    while ( $_ = shift @reslist ) {
        $i = $_ + 0;
        next if ( $range / $i > $width );
        $res = $_;
        unshift @reslist, $_;
        last;
    }

    if ( !$res ) {

        # time range is too wide to show, select the lowest resolution
        # data we have, and adjust the start time so the data will fit
        # in the time window.
        $res     = $lowest;
        @reslist = ($res);
        $range   = $width * $res;
        $$fref   = new Math::BigInt owptimeadd( $$lref, -$range );
    }

    my $nrecs      = 0;
    my $datapoints = '';
    my %owpvals;
    my $oend;
    while ( !$nrecs ) {
        undef %owpvals;

        # TODO: Set alpha_vals dynamically from web - or at least a config
        my @alphas = [ .50, .95 ];
        my $owdb = owdb_prep(
            DBH         => $dbh,
            RES         => $res,
            TNAME       => $tname,
            FIRST       => owptstampi($$fref),
            LAST        => owptstampi($$lref),
            ALPHAS      => @alphas,
            OWHASH      => \%owpvals,
            BUCKETWIDTH => $bucket_width
        ) || die "Unable to init owp data request";

        $nrecs = 0;
        $oend  = 0;
        my $tdate;
        my $nbucks;

        while ( $nbucks = owdb_fetch( OWDBH => $owdb ) ) {
            $nrecs++;

            # clip start time if before "first"
            if ( $owpvals{'START'} < $$fref ) {
                $tdate = owptstamppldatetime($$fref);
            }
            else {
                $tdate = owptstamppldatetime( $owpvals{'START'} );
            }

            # add missing data record, if oend != start
            if ( $oend && ( $oend ne $owpvals{'START'} ) ) {
                my $odate = owptstamppldatetime($oend);
                $datapoints .= "\t$odate\n";
            }
            $oend = $owpvals{'END'};

            my ( $ffmt, $minfmt, $maxfmt, $a50fmt, $a95fmt );
            my ( $minval, $maxval, $a50val, $a95val );
            $minfmt = $maxfmt = $a50fmt = $a95fmt = "%8s";
            $minval = $maxval = $a50val = $a95val = "XXXXXXXX";

            $ffmt = "%08.6f";
            if ( $owpvals{'MIN'} ) {
                $minfmt = $ffmt;
                $minval = $owpvals{'MIN'};
                $minval = $ymin if ( $minval < $ymin );
                $minval = $ymax if ( $minval > $ymax );
            }
            if ( $owpvals{'MAX'} ) {
                $maxfmt = $ffmt;
                $maxval = $owpvals{'MAX'};
                $maxval = $ymin if ( $maxval < $ymin );
                $maxval = $ymax if ( $maxval > $ymax );
            }
            if ( $owpvals{'ALPHA_0.500000'} ) {
                $a50fmt = $ffmt;
                $a50val = $owpvals{'ALPHA_0.500000'};
                $a50val = $ymin if ( $a50val < $ymin );
                $a50val = $ymax if ( $a50val > $ymax );
            }
            if ( $owpvals{'ALPHA_0.950000'} ) {
                $a95fmt = $ffmt;
                $a95val = $owpvals{'ALPHA_0.950000'};
                $a95val = $ymin if ( $a95val < $ymin );
                $a95val = $ymax if ( $a95val > $ymax );
            }

            # output this datapoint
            $datapoints .= sprintf( "\t%s\t%d\t%d\t%d\t%08.6f\t$minfmt\t$a50fmt\t$a95fmt\t$maxfmt\n", owptstamppldatetime( $owpvals{'START'} ), $owpvals{'SENT'}, $owpvals{'LOST'}, $owpvals{'DUPS'}, $owpvals{'ERR'}, $minval, $a50val, $a95val, $maxval );
        }

        # add missing data record for right edge of plot
        if ( $oend > $$lref ) {
            my $odate = owptstamppldatetime($$lref);
            $datapoints .= "\t$odate\n";
        }

        last if ($nrecs);
        last if ( !( $res = shift @reslist ) );
    }

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    # TODO: Determine axis scaling based upon "resolution" above.

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print {$plfh} << "END_SCRIPT";
#proc page
        pagesize: 7 4
        scale: 0.75

// TODO: Add resolution information
#proc areadef
        title: min/median/95% delay
        frame: yes
        rectangle: 1 1 6 3
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        yrange: $ymin $ymax

#proc xaxis
        stubrange: $firststub $laststub
        stubs: inc 5 minute
        stubformat: hh:mm:ss

#proc xaxis
        stubrange: $firststub $laststub
        tics: yes
        ticincrement: 1 minute

#proc xaxis
        label: Sample time
        labeldetails: adjust=0,-0.15
        stubrange: $firststub $laststub
        stubs: inc 5 minute
        stubformat: mm/dd
        stubdetails: adjust=0,-0.15

#proc yaxis
        label: Delay(msec)
        stubrange: $ymin $ymax
        stubs: inc 20 0.001
        minorticinc: 0.005

#proc getdata
#intrailer

#proc lineplot
        xfield: 1
        yfield: 8
        stairstep: yes
	clip: yes
        gapmissing: small
        linedetails: color=red width=3 style=0
        legendlabel: 95th percentile

#proc lineplot
        xfield: 1
        yfield: 7
        stairstep: yes
	clip: yes
        gapmissing: small
        linedetails: color=rgb(0.0,1.0,1.0) width=3 style=1 dashscale=10
        legendlabel: 50th percentile

#proc lineplot
        xfield: 1
        yfield: 6
        stairstep: yes
	clip: yes
        gapmissing: small
        linedetails: color=rgb(.4,.4,.4) width=2 style=1 dashscale=4
        legendlabel: Minimum

#proc legend
        format: multiline

#proc trailer
data:
$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 bwdb_plot_script()

TDB

=cut

sub bwdb_plot_script {

    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT time, throughput
		FROM BW_${tname}
		WHERE
			ti>? AND
			ti<?
		ORDER BY ti DESC";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $time;
    my $throughput;
    my $min_throughput = 1000;
    my $max_throughput = 0;

    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] && $row[1] ) {
            $time           = $row[0];
            $throughput     = sprintf "%.1f", ( $row[1] / 1000000 );
            $min_throughput = $min_throughput < $throughput ? $min_throughput : $throughput;
            $max_throughput = $max_throughput > $throughput ? $max_throughput : $throughput;
            $nrecs++;
        }
        else {
            last;
        }

        # output this datapoint
        $datapoints .= sprintf( "\t%s\t%.1f\n", owptstamppldatetime($time), $throughput );
    }
    undef $sth;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page
        scale: 1
        pagesize: 4 4

#proc getdata
#intrailer
#proc endproc

#proc areadef
        title: Throughput
        frame: yes
        rectangle: 1 1 4 3
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        xaxis.stubrange: $firststub $laststub
        xaxis.stubformat: hh:mm:ss
        xaxis.stubs: inc 6 hour
        xaxis.tics: yes
        xaxis.ticincrement: 60 minute
        xaxis.label: Sample Time (UTC)
        yrange: 0 1000
        yaxis.stubs: inc 100
        yaxis.stubrange: 0 1000
        yaxis.tics: yes
        yaxis.ticincrement: 100
        yaxis.label: Throughput (megabits/sec)
        yaxis.labeldetails: size=6
        yaxis.labeldistance: 0.1

#proc scatterplot
        xfield: 1
        yfield: 2
	linelen 0.005
        linedetails: color=red width=1.0
        legendlabel: Throughput

#proc legend
        location: min+1.0 min+0.2

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 bwdb_dist_plot_script()

TDB

=cut

sub bwdb_dist_plot_script {

    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT time, throughput
		FROM BW_${tname}
		WHERE
			ti>? AND
			ti<?
		ORDER BY throughput DESC";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $throughput;
    my @bucket;
    my $index;

    for ( $index = 0; $index <= 1000; $index++ ) {
        $bucket[$index] = 0;
    }

    my $sample_number = 0;
    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] && $row[1] ) {
            $throughput = sprintf "%d", ( $row[1] / 1000000 );
            $bucket[$throughput] += 1;
            $nrecs++;
        }
        else {
            last;
        }

    }
    undef $sth;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $min_bucket = 48 * 11 * 10 * 10;    # Max tests is 48 * 11 * 10, so this is 10x bigger
    my $max_bucket = 0;
    for ( $index = 1000; $index >= 0; $index-- ) {

        # output this datapoint
        $datapoints .= sprintf( "\t%d\t%d\n", $index, $bucket[$index] );
        $min_bucket = $min_bucket < $bucket[$index] ? $min_bucket : $bucket[$index];
        $max_bucket = $max_bucket > $bucket[$index] ? $max_bucket : $bucket[$index];
    }

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page
        scale: 1
        pagesize: 4 4

#proc getdata
#intrailer
#proc endproc

#proc areadef
        title: Throughput Histogram
        frame: yes
        rectangle: 1 1 4 3
        xscaletype: linear
        xrange: 0 1000
        xaxis.stubrange: 0 1000
        xaxis.stubs: inc 100
        xaxis.tics: yes
        xaxis.ticincrement: 100
        xaxis.label: Throughput (Megabits/Sec)
        yrange: 0 $max_bucket
        yaxis.stubs: inc 10
        yaxis.stubrange: 0 $max_bucket
        yaxis.tics: yes
        yaxis.ticincrement: 1
        yaxis.label: Test Count

#proc bars
        locfield: 1
        lenfield: 2
	thinbarline: color=red
        legendlabel: Throughput

#proc legend
        location: min+1.0 min+0.2

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 ntpdb_loop_plot_script()

TDB

=cut

sub ntpdb_loop_plot_script {

    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;
    warn "TABLE NAME: $tname\n";

    my $sql;
    my $sth;
    my @row;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT owp64time, offset, esterror 
                FROM ${tname}
                WHERE
                        owp32time >? AND
                        owp32time <?
                ORDER BY owp32time DESC";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $time;
    my $offset;
    my $esterror;

    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] && $row[1] && $row[2] ) {
            $time     = $row[0];
            $offset   = sprintf "%.1f", ( $row[1] * 1000000 );
            $esterror = sprintf "%.1f", ( $row[2] * 1000000 );
            $nrecs++;
        }
        else {
            last;
        }

        # output this datapoint
        $datapoints .= sprintf( "\t%s\t%.1f\t%.1f\n", owptstamppldatetime($time), $offset, $esterror );
    }
    undef $sth;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page
        scale: 1
        pagesize: 4 4

#proc getdata
#intrailer
#proc endproc

#proc areadef
        #title: NTP Loop Stats 
        frame: yes
        rectangle: 1 1 4 3
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        xaxis.stubrange: $firststub $laststub
        xaxis.stubformat: hh:mm:ss
        xaxis.stubs: inc 6 hour
        xaxis.tics: yes
        xaxis.ticincrement: 60 minute
        xaxis.label: Sample Time (UTC)
        yrange: -25 25
        yaxis.stubs: inc 3
        yaxis.stubrange: -25 25
        yaxis.tics: yes
        yaxis.ticincrement: 3
        yaxis.label: Scale Unit: micro secs
        yaxis.labeldetails: size=6
        yaxis.labeldistance: 0.4

#proc line  
        notation: scaled  
        linedetails: width=0.5 color=black
        points: $firstdate 0 $lastdate 0 

#proc bars       
        locfield: 1
        lenfield: 2
        errbarfield: 3
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes     

#proc scatterplot
        xfield: 1         
        yfield: 2    
        symbol: shape=circle style=filled radius=0.03 fillcolor=blue 

#proc legendentry
  sampletype: symbol
  details: shape=dot fillcolor=blue                  
  label: Loop Offset \n

#proc legendentry
  sampletype: symbol
  details: shape=dot fillcolor=orange                    
  label: Loop Estimated Error \n

#proc legend
	location: min min-0.5

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 ntpdb_peer_plot_script()

TDB

=cut

sub ntpdb_peer_plot_script {

    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT owp64time, offset, variance
                FROM ${tname}
                WHERE
                        owp32time >? AND
                        owp32time <?
                ORDER BY owp32time DESC";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $time;
    my $offset;
    my $variance;

    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] && $row[1] && $row[2] ) {
            $time     = $row[0];
            $offset   = sprintf "%.1f", ( $row[1] * 1000000 );
            $variance = sprintf "%.1f", ( $row[2] * 1000000 );
            $nrecs++;
        }
        else {
            last;
        }

        # output this datapoint
        $datapoints .= sprintf( "\t%s\t%.1f\t%.1f\n", owptstamppldatetime($time), $offset, $variance );
    }
    undef $sth;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page
        scale: 1
        pagesize: 4 4

#proc getdata
#intrailer
#proc endproc

#proc areadef
        #title: NTP Peer Stats
        frame: yes
        rectangle: 1 1 4 3
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        xaxis.stubrange: $firststub $laststub
        xaxis.stubformat: hh:mm:ss
        xaxis.stubs: inc 6 hour
        xaxis.tics: yes
        xaxis.ticincrement: 60 minute
        xaxis.label: Sample Time (UTC)
        yrange: -25 25 
        yaxis.stubs: inc 3
        yaxis.stubrange: -25 25
        yaxis.tics: yes
        yaxis.ticincrement: 3
        yaxis.label: Scale Unit: micro secs 
        yaxis.labeldetails: size=6
        yaxis.labeldistance: 0.4

#proc bars       
        locfield: 1
        lenfield: 2
        errbarfield: 3
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes     

#proc scatterplot
        xfield: 1         
        yfield: 2    
        symbol: shape=circle style=filled radius=0.02 fillcolor=red 

#proc legendentry
  sampletype: symbol
  details: shape=dot fillcolor=red                    
  label: Peer Offset \n

#proc legendentry
  sampletype: symbol
  details: shape=dot fillcolor=orange                  
  label: Peer Variance \n

#proc legend
        location: min+0.3 min+2.0 

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;
}

=head2 ntpdb_color_per_peer_plot_script()

TDB

=cut

sub ntpdb_color_per_peer_plot_script {
    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT owp64time, offset, variance, peeraddrid
                FROM ${tname}
                WHERE
                        owp32time >? AND
                        owp32time <?
                ORDER BY owp32time DESC";

    #AND peeraddrid = 10";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $time;
    my $offset;
    my $variance;
    my $peeraddrid;

    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] && $row[1] && $row[2] && $row[3] ) {
            $time       = $row[0];
            $offset     = sprintf "%.1f", ( $row[1] * 1000000 );
            $variance   = sprintf "%.1f", ( $row[2] * 1000000 );
            $peeraddrid = $row[3];
            $nrecs++;
        }
        else {
            last;
        }

        # logic to determine which column to print the peeraddrid field for the ploticus data file
        my $max_peeraddrid = 40;
        my $offset_id;
        my $sprintf_str = "";
        my $b4_index;
        my $after_index;

        $sprintf_str = sprintf( "%s%s", $sprintf_str, "\t\%s\t\%.1f" );    # owp64time and variance

        $offset_id = $peeraddrid - 7;                                      # -7 because the starting peeraddrid in the table is 8
        for ( $b4_index = 1; $b4_index < $offset_id; $b4_index++ ) {
            $sprintf_str = sprintf( "%s%s", $sprintf_str, "\tNA" );
        }

        $sprintf_str = sprintf( "%s%s", $sprintf_str, "\t\%.1f" );

        for ( $after_index = $offset_id + 1; $after_index <= $max_peeraddrid; $after_index++ ) {
            $sprintf_str = sprintf( "%s%s", $sprintf_str, "\tNA" );
        }
        $sprintf_str = sprintf( "%s%s", $sprintf_str, "\n" );

        # output this datapoint
        $datapoints .= sprintf( "$sprintf_str", owptstamppldatetime($time), $variance, $offset );
    }
    undef $sth;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page         
        scale: 1 
        pagesize: 8 14
        
#proc getdata
#intrailer                              
#proc endproc    
                    
#proc areadef
        frame: yes
        rectangle: 1.4 3 4.4 5
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        xaxis.stubrange: $firststub $laststub
        xaxis.stubformat: hh:mm:ss
        xaxis.stubs: inc 6 hour
        xaxis.tics: yes          
        xaxis.ticincrement: 60 minute
        xaxis.label: Sample Time (UTC)
        yrange: -250 250 
        yaxis.stubs: inc 30
        yaxis.stubrange: -250 250
        yaxis.tics: yes
        yaxis.ticincrement: 3
        yaxis.label: Scale Unit: micro secs
        yaxis.labeldetails: size=6
        yaxis.labeldistance: 0.4

#proc line
	notation: scaled
	linedetails: width=0.5 color=black
	points: $firstdate 0 $lastdate 0

// Variance error bar color legend
#proc legendentry
	sampletype: symbol
	details: shape=dot fillcolor=orange
	label: Peer Variance \n

#proc legend
        location: min min-0.5

// Title of Peer IDs
#proc annotate
	location: min min-0.9
	textdetails: size=10
	text: Peer ID Offsets:\n

// PeerID Field 8 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 3
	errbarfield: 2
	thinbarline: color=orange width=0.5
	tails: 0.02
	truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 3
	symbol: shape=square style=filled radius=0.03 fillcolor=purple

#proc legendentry
	sampletype: symbol
	details: shape=square fillcolor=purple
	label: local pps \n

#proc legend
        location: min min-0.9
//////////////////////////////////////////////
// PeerID Field 12 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 7
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 7
        symbol: shape=square style=filled radius=0.03 fillcolor=blue

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=blue
        label: local cdma \n

#proc legend
        location: min min-1.0
//////////////////////////////////////////////
// PeerID Field 10 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 5
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 5
        symbol: shape=square style=filled radius=0.03 fillcolor=green

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=green
        label: nms4-kscy.abilene.ucaid.edu \n

#proc legend
        location: min min-1.1
//////////////////////////////////////////////
// PeerID Field 11 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 6
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 6
        symbol: shape=square style=filled radius=0.03 fillcolor=brightgreen

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=brightgreen
        label: nms4-losa.abilene.ucaid.edu \n

#proc legend
        location: min min-1.2
//////////////////////////////////////////////
// PeerID Field 9 (yfield = n-7+2)            
#proc bars    
        locfield: 1
        lenfield: 4
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 4
        symbol: shape=square style=filled radius=0.03 fillcolor=red

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=red
        label: nms4-atla.abilene.ucaid.edu \n

#proc legend
        location: min min-1.3 
//////////////////////////////////////////////
// PeerID Field 13 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 8
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 8
        symbol: shape=square style=filled radius=0.03 fillcolor=darkblue

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=darkblue
        label: nms1-chin.abilene.ucaid.edu \n

#proc legend
        location: min min-1.4
//////////////////////////////////////////////
// PeerID Field 14 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 9
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 9
        symbol: shape=square style=filled radius=0.03 fillcolor=black

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=black
        label: nms4-snva.abilene.ucaid.edu \n

#proc legend
        location: min min-1.5
//////////////////////////////////////////////
// PeerID Field 15 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 10
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 10
        symbol: shape=square style=filled radius=0.03 fillcolor=claret

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=claret
        label: nms4-hstn.abilene.ucaid.edu \n

#proc legend
        location: min min-1.6
//////////////////////////////////////////////
// PeerID Field 16 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 11
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 11
        symbol: shape=square style=filled radius=0.03 fillcolor=magenta

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=magenta
        label: nms4-wash.abilene.ucaid.edu \n

#proc legend
        location: min min-1.7
//////////////////////////////////////////////
// PeerID Field 17 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 12
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 12
        symbol: shape=square style=filled radius=0.03 fillcolor=lightpurple

#proc legendentry
        sampletype: symbol
        details: shape=square fillcolor=lightpurple
        label: nms4-sttl.abilene.ucaid.edu \n

#proc legend
        location: min min-1.8
//////////////////////////////////////////////
// PeerID Field 18 (yfield = n-7+2)           
#proc bars
        locfield: 1                           
        lenfield: 13
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 13
        symbol: style=spokes linecolor=purple radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=purple
        label: nms4-ipls.abilene.ucaid.edu \n

#proc legend
        location: min min-1.9
//////////////////////////////////////////////
// PeerID Field 19 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 14
	errbarfield: 2
	thinbarline: color=orange width=0.5
	tails: 0.02
	truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 14
	symbol: style=spokes linecolor=red radius=0.03

#proc legendentry
	sampletype: symbol
	details: style=spokes linecolor=red
	label: nms4-nycm.abilene.ucaid.edu \n

#proc legend
        location: min min-2.0
//////////////////////////////////////////////
// PeerID Field 20 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 15
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 15
        symbol: style=spokes linecolor=green radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=green
        label: Tick.UH.EDU \n

#proc legend
        location: min+2.0 min-0.9
//////////////////////////////////////////////
// PeerID Field 21 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 16
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 16
        symbol: style=spokes linecolor=brightgreen radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=brightgreen
        label: caspak.cerias.purdue.edu \n

#proc legend
        location: min+2.0 min-1.0
//////////////////////////////////////////////
// PeerID Field 22 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 17
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 17
        symbol: style=spokes linecolor=blue radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=blue
        label: nms4-chin.abilene.ucaid.edu \n

#proc legend
        location: min+2.0 min-1.1
//////////////////////////////////////////////
// PeerID Field 23 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 18
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 18
        symbol: style=spokes linecolor=darkblue radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=darkblue
        label: nms3-atla.abilene.ucaid.edu \n

#proc legend
        location: min+2.0 min-1.2
//////////////////////////////////////////////
// PeerID Field 24 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 19
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 19
        symbol: style=spokes linecolor=black radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=black
        label: tick.ucla.edu \n

#proc legend
        location: min+2.0 min-1.3
//////////////////////////////////////////////
// PeerID Field 25 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 20
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 20
        symbol: style=spokes linecolor=claret radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=claret
        label: timekeeper.isi.edu \n

#proc legend
        location: min+2.0 min-1.4
//////////////////////////////////////////////
// PeerID Field 26 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 21
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 21
        symbol: style=spokes linecolor=magenta radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=magenta
        label: gnomon.cc.columbia.edu \n

#proc legend
        location: min+2.0 min-1.5
//////////////////////////////////////////////
// PeerID Field 27 (yfield = n-7+2)
#proc bars
        locfield: 1
        lenfield: 22
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes

#proc scatterplot
        xfield: 1
        yfield: 22
        symbol: style=spokes linecolor=lightpurple radius=0.03

#proc legendentry
        sampletype: symbol
        details: style=spokes linecolor=lightpurple
        label: NAVOBS1.MIT.EDU \n

#proc legend
        location: min+2.0 min-1.6
//////////////////////////////////////////////
// PeerID Field 28 (yfield = n-7+2)          
#proc bars
        locfield: 1            
        lenfield: 23    
        errbarfield: 2               
        thinbarline: color=orange width=0.5
        tails: 0.02   
        truncate: yes     
        
#proc scatterplot      
        xfield: 1            
        yfield: 23
        symbol: shape=triangle style=filled radius=0.03 fillcolor=purple
        
#proc legendentry
        sampletype: symbol
        details: shape=triangle fillcolor=purple
        label: truetime.uoregon.edu \n    

#proc legend
        location: min+2.0 min-1.7
//////////////////////////////////////////////
// PeerID Field 29 (yfield = n-7+2)
#proc bars            
        locfield: 1   
        lenfield: 24
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes
                  
#proc scatterplot 
        xfield: 1
        yfield: 24        
        symbol: shape=triangle style=filled radius=0.03 fillcolor=red
                          
#proc legendentry
        sampletype: symbol                    
        details: shape=triangle fillcolor=red
        label: ntp0.mcs.anl.gov \n 
                    
#proc legend
        location: min+2.0 min-1.8
//////////////////////////////////////////////
// PeerID Field 30 (yfield = n-7+2)
#proc bars            
        locfield: 1   
        lenfield: 25
        errbarfield: 2
        thinbarline: color=orange width=0.5
        tails: 0.02
        truncate: yes
                  
#proc scatterplot 
        xfield: 1
        yfield: 25        
        symbol: shape=triangle style=filled radius=0.03 fillcolor=green
                          
#proc legendentry
        sampletype: symbol                    
        details: shape=triangle fillcolor=green
        label: ben.cs.wisc.edu \n
                    
#proc legend
        location: min+2.0 min-1.9
//////////////////////////////////////////////
// PeerID Field 31 (yfield = n-7+2)
//#proc bars            
        //locfield: 1   
        //lenfield: 26
        //errbarfield: 2
        //thinbarline: color=orange width=0.5
        //tails: 0.02
        //truncate: yes
                  
//#proc scatterplot 
        //xfield: 1
        //yfield: 26        
        //symbol: shape=triangle style=filled radius=0.03 fillcolor=brightgreen
                          
//#proc legendentry
        //sampletype: symbol                    
        //details: shape=triangle fillcolor=brightgreen
        //label: Unknown \n 
                    
//#proc legend
        //location: min+2.6 min-1.2

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 trdb_plot_script()

TDB

=cut

sub trdb_plot_script {

    my ( $tname, $tstamp, $fref, $lref, $dbh, $plfh ) = @_;

    my $sql;
    my $sth;
    my @row;
    my $sql2;
    my $sth2;
    my @row2;
    my $width = 500;

    my $range = owptime2time($$lref) - owptime2time($$fref);
    my $i;

    $sql = "SELECT distinct routeid 
                FROM $tname
                WHERE
                        timestamp>? AND
                        timestamp<?
                ";

    $sth = $dbh->prepare($sql)
        || die "Prep:Select status $tname";
    $sth->execute( owptstampi($$fref), owptstampi($$lref) )
        || die "Select status $tname";

    my $nrecs      = 0;
    my $datapoints = '';

    my $routeid;
    my $ftime;
    my $ltime;

    while (1) {
        if ( ( @row = $sth->fetchrow_array ) && $row[0] ) {
            $routeid = $row[0];
            $nrecs++;
        }
        else {
            last;
        }

        $sql2 = "SELECT min(timestamp), max(timestamp)
                	FROM $tname
                	WHERE
				routeid = $routeid AND
                        	timestamp>? AND
                        	timestamp<?
                	";

        $sth2 = $dbh->prepare($sql2)
            || die "Prep:Select status $tname";
        $sth2->execute( owptstampi($$fref), owptstampi($$lref) )
            || die "Select status $tname";

        #if((@row2 = $sth2->fetchrow_array) && $row2[0] && $row2[1]){
        if ( @row2 = $sth2->fetchrow_array ) {
            $ftime = ts_owptstamppldatetime( $row2[0] );
            $ltime = ts_owptstamppldatetime( $row2[1] );
        }

        # output this datapoint
        $datapoints .= sprintf( "\t%d\t%s\t%s\n", $routeid, $ftime, $ltime );
    }
    undef $sth;
    undef $sth2;

    if ( !$nrecs ) {

        # Nothing to plot.
        return $nrecs;
    }

    my $firstdate = owptstamppldatetime($$fref);
    my $lastdate  = owptstamppldatetime($$lref);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$fref);
    if ( $sec > 30 ) {
        $min += 1;
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $firststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = owpgmtime($$lref);
    if ( $sec < 30 ) {
        $sec = 0;
    }
    else {
        $sec = 30;
    }
    my $laststub = pldatetime( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday );

    #
    #
    # Here is the ploticus script - data gets appended on the end.
    print $plfh <<"END_SCRIPT";
#proc page
        scale: 1
        pagesize: 4 4

#proc getdata
#intrailer
#proc endproc

#proc areadef
        title: Traceroute RouteIDs Timeline Graph
        frame: yes
        rectangle: 1 1 4 3
        xscaletype: datetime yyyy-mm-dd.hh:mm:ss
        xrange: $firstdate $lastdate
        xaxis.stubrange: $firststub $laststub
        xaxis.stubformat: hh:mm:ss
        xaxis.stubs: inc 10 minute
        xaxis.tics: yes
        xaxis.ticincrement: 10 minute
        xaxis.label: Sample Time (UTC)

	yscaletype: categories
	ycategories: datafield 1
        yaxis.stubs: categories
        yaxis.label: RouteIDs
        yaxis.labeldetails: size=6
	yaxis.grid: color=green

#proc bars
	color: green
	barwidth: 0.05
	horizontalbars: yes
	segmentfields: 2 3
	locfield: 1
	tails: 0.1

#proc trailer
data:$datapoints
END_SCRIPT

    return $nrecs;

}

=head2 ts_owptstamppldatetime()

TDB

=cut

sub ts_owptstamppldatetime {
    my $tmpTs    = shift @_;
    my @dTime    = gmtime( $tmpTs - JAN_1970 );
    my $dHour    = $dTime[2];
    my $dMinute  = $dTime[1];
    my $dSecond  = $dTime[0];
    my $dMonth   = $dTime[4] + 1;
    my $dDay     = $dTime[3];
    my $dYear    = $dTime[5] + 1900;
    my $tmpTsStr = sprintf( '%04d-%02d-%02d.%02d:%02d:%02d', $dYear, $dMonth, $dDay, $dHour, $dMinute, $dSecond );
    return $tmpTsStr;
}

=pod
#######################################################################
#Traceroute Circle Dig code
sub trcir_plot_script{
        my ($tname,$tstamp,$fref,$lref,$dbh,$plfhpng) = @_;

	my $nrecs;
        my $sql;
        my $sth;
        my @row;
	my $sql2;
	my $sth2;
	my @row2;

	######################################################################
	# Definition of parameters

	my $basex = 0; #base for all plots of the traceroute route tree
	my $basey = 0;
	my $stepx = 500;
	my $stepy = 700;
	my $radius= 200;
	my $offsetTextx = 7000;
	my $offsetTexty = 500;

	my $outfile = "route_changes.fig"; 
	my $psfile = "route_changes.ps"; 
	my $pngfile = "route_changes.png"; 
	######################################################################
	#global vars
	my (@arrayOfDates,       @arrayOfRoutes,         %hashOfRoutes,  %hashOfRoutesList,      %arrayOfDefectsByDate);
	my (@listOfRouters, @stringOfRouters);
	my ($maxRoutes, $sumRoutes,     $errorInTrace);
	my (%edge,      %x,     %y,     %error, %name,  %domain); #data about each router [node] and link [edge] in the graph
	my (%miniEdge, @miniRouter); #same but for the timed graphs
	my ($source, $destination); #source and destination nodes
	my $family="hola"; #destination
	my $dir; #source
	my $indir;
	my $maxy;
	my ($widthWeigth);
	my (%nodeIndex, @routeName);
	my @nodeNumbers;
	my ($xfigSummaryTreeWithDomains, $xfigSummaryTree, $xfigTimedTree,
                $printTableWithAllAnomalies, $nodebug);

	$nodebug = 1;
	chomp($dir = `/`);
	$outfile = $dir  "/tmp/traceplots/". $outfile;
	$psfile = $dir  "/tmp/traceplots/". $psfile;
	$pngfile = $dir "/tmp/traceplots/". $pngfile;

	print `rm -rf $outfile $psfile $pngfile`;

	$indir = $dir . "/tmp/tracedata";
	
	#code to generate the input files by quering the database

	#output file
	open (OUT,">$outfile");
	#go over all families
	&goOverAllFamilies();
	close OUT;

	#Convert fig to ps
	#print `fig2dev -L ps -m 0.750 -x -200 -y -1500 -M -e -z Letter $outfile $psfile`;
	print `fig2dev -L ps -m 0.75 $outfile $psfile`;
	#Convert ps to png
	#print `convert $psfile $pngfile`;
	print `gs -dNOPAUSE -q -sDEVICE=png256 -sOutputFile=$pngfile $psfile -dBATCH`;
	$plfh = $pngfile;

	if(!$plfh){
		$nrecs++;
	} else {
		$nrecs =  0;
	}
	return $nrecs;
}

######################################################################
sub printDebug {
        if (!$nodebug) {
                print STDERR "@_";
        }
}

######################################################################
#go over all families
sub goOverAllFamilies() {

        &printXFigHeader();
        my $key;
        my $value;

        my @file_list;

        my @listOfFiles = `ls $indir`;
#       print "\nFile list: @listOfFiles\n";

        undef @arrayOfDates;
        undef @arrayOfRoutes;
        undef %hashOfRoutes;
        undef %hashOfRoutesList;
        undef %arrayOfDefectsByDate;
        $maxRoutes = 0;
        $sumRoutes = 0;
        $errorInTrace = 0;

        my $file;
        my $routerNum;
        my $router;
        my $date;
        my @field;
        my $fileNumber;

        #go over all files
        $fileNumber = 0;
        foreach $file (@listOfFiles) {
                chop($file);
                $file = $indir . "/" . $file ;
                #print "\nInput file: $file \n";
                open(IN, "<$file");
                $routerNum = 1;
                #if($fileNumber!=0){&SetArrayOfRoutes("$date");}
                &ClearListOfRouters();

                #$date = $1;
                if ($errorInTrace) {printDebug "clearing up the error ($date)\n\n";print "Inside 3.2\n";}
                $errorInTrace = 0;

                my $lineNum=0;
                my $line;
                while ($line=<IN>) {
                        #print "Reading Line $line\n";
                        if($lineNum==0){
                        @routeName[$fileNumber]= $line;
                        $lineNum++;
                        next;
                        }
                        $lineNum++;
                        if($lineNum > 10000) {last;}
                        @field = split ' ', $line ;
                        #&InsertRouter(@field[1], $fileNumber);
                        &InsertRouter(@field[0], -1);

                        $nodeIndex{@field[0]}= "@field[1] @field[2]";


                }
                #This is a new trace

                #if (!$errorInTrace && ($stringOfRouters[0] ne "")) {

                &SetArrayOfRoutes("$fileNumber");
                #print "Inside 3.1\n";
                #}
                #print "String of Routers: @stringOfRouters \n";
                #print "List of Routers: @listOfRouters \n";
                $fileNumber++;
        }


        #&SetArrayOfRoutes("UNDEF");

        &calculateEdges($date);
        &xfigTimedTree();
}

######################################################################
sub printXFigHeader() {
                print OUT "#FIG 3.1\n".
#                       "Landscape\n".
                        "Portrait\n".
                                "Center\n".
                                        "Inches\n".
                                                "1200 2\n";
}
######################################################################

######################################################################
sub SetArrayOfRoutes() {
        my ($date) =@_;
        my ($i, $myStringOfRouters, $myStringOfRouters0);

        for ($i=0; $i < 3; $i++) {
          $myStringOfRouters = $stringOfRouters[$i];
          $myStringOfRouters0 = $stringOfRouters[0];
                if (($i == 0) || ($myStringOfRouters ne $myStringOfRouters0)) {
                        $arrayOfDates[$sumRoutes] = "$date";
                #       print "I am doing something\n";
                        $arrayOfRoutes[$sumRoutes] = $myStringOfRouters;
                        $hashOfRoutes{$myStringOfRouters}=5-$date;
                        #$hashOfRoutes{$date}=$myStringOfRouters;
                        $sumRoutes++;
                        $hashOfRoutesList{$myStringOfRouters}= \@{$listOfRouters[$i]};
                        #if ($maxRoutes < $hashOfRoutes{$myStringOfRouters}) {
                        #       $maxRoutes = $hashOfRoutes{$myStringOfRouters};
                        #}
#                               printDebug "router: $myStringOfRouters=> $hashOfRoutes{$myStringOfRouters}\n";
                }
        }
}
######################################################################
sub GetRouterName() {
        my ($router) = @_;

        return ($router, $router);
}
######################################################################
sub ClearListOfRouters() {
        my $i;
        for ($i=0; $i <= 3; $i++) {
                @{$listOfRouters[$i]}= ();
                $stringOfRouters[$i]="";
  }
}
######################################################################
sub InsertRouter() {
        my ($router, $listNum) = @_;
        my $i;

#                               printDebug "router: $router\n";
        if ($listNum >= 0 ) {
                push(@{$listOfRouters[$listNum]}, "$router");
                if ($stringOfRouters[$listNum] ne "") {
                   $stringOfRouters[$listNum] .= "-";
                }
                $stringOfRouters[$listNum] .= "$router";
        } else {
                for ($i=0; $i <= $#listOfRouters; $i++) {
                         push(@{$listOfRouters[$i]}, "$router");
                        if ($stringOfRouters[$i] ne "") {
                                $stringOfRouters[$i] .= "-";
                        }
                $stringOfRouters[$i] .= "$router";
                }
        }
}

######################################################################
sub calculateEdges() {
        my ($date) = @_;

        my ($router, $end, $i);
        my ($key);

        undef %edge;
        undef %x;
        undef %y;
        undef %error;
        undef %name;
        undef %domain;
#       %edge = %x = %y = ();
        my $y=0;
        my ($x, $first, $previous);

        if ($maxRoutes > 20) {$widthWeigth = 20/$maxRoutes;}
        else {$widthWeigth=1;}
        $maxy=0;
        $destination = "";
        my (@routes);
        #print "Inside Edge 1.0\n";
        #now print the results of all the files
        if (%hashOfRoutes !=()) {
                #print "Inside Edge 1.1\n";
                my $mostCommmonRoute =1;
                foreach $key (sort  { $hashOfRoutes{$b} <=> $hashOfRoutes{$a} } keys %hashOfRoutes) {
                #foreach $key (sort  { $hashOfRoutes{$a} <=> $hashOfRoutes{$b} } keys %hashOfRoutes) {
                #my(@routelist);
                #@routelist = keys %hashOfRoutes;
                #print "Route list: @routelist\n";
                #foreach $key (@routelist) {
                        #print "Inside Edge 1.2\n";
                        printDebug "router: $key=> $hashOfRoutes{$key}\n";
                        @routes = split(/-/, $key);
                        if ($mostCommmonRoute) {
                                $mostCommmonRoute=0;
                                $source = $routes[0];
                                $destination = $routes[$#routes];
                        }

                        $first =1;
                        $maxy = ++$y;
                        $x=0;
                        foreach $router (@routes) {
                                $x++;
                                #printDebug "router: $router ($x, $y)\n";
                                if ($first) {
                                        $first=0;
                                        $previous = "$router";
                                        if (! defined  $x{"$router"}) {
                                                ($domain{"$router"}, $name{"$router"})= &GetRouterName($router);
                                                $x{"$router"}=$x;
                                                $y{"$router"}=$y;
                                        printDebug "$router ($x, $y, $name{$router}, $domain{$router})\n";
                                        }
                                        next;
                                }

                                ${$edge{"$router"}}{"$previous"}+=$hashOfRoutes{"$key"};
                                if (! defined  $x{"$router"}) {
                                        ($domain{"$router"}, $name{"$router"})= &GetRouterName($router);
                                        $x{"$router"}=$x;
                                        $y{"$router"}=$y;
                                        printDebug "$router ($x, $y, $name{$router}, $domain{$router})\n";
                                }
                                $previous = "$router";
                        }
                if ("$router" ne "$destination") {
                                $error{"$router"}++;
                                printDebug "$router error: ".$error{"$router"}."\n";
                                ${$arrayOfDefectsByDate{$date}}{"NotEndingInDestination"}++;
                        }
#                               printDebug "$router $destination\n";
          }
        $maxy = $y;
}
}
######################################################################

######################################################################
sub calculateMiniEdges() {
        my ($path, $numPaths) = @_;
#       printDebug "$path=> $numPaths\n";

        undef %miniEdge;
        undef @miniRouter;
        &recalculateMiniEdges($path, $numPaths);
}
######################################################################
sub recalculateMiniEdges() {
        my ($path, $numPaths) = @_;

        my ($router);
        my ($first, $previous);

#       printDebug "$path=> $numPaths\n";

        #now print the results of all the files
        if (%hashOfRoutes !=()) {
                $first =1;
                foreach $router (split(/-/, $path)) {
#                       printDebug "router: $router ($x, $y)\n";
                        push (@miniRouter, "$router");
                        if ($first) {
                                $first=0;
                                $previous = "$router";
                                next;
                        }
                        ${$miniEdge{"$router"}}{"$previous"}+=$numPaths;
                #                                       printDebug "$router ($x, $y)\n";
                $previous = "$router";
        }

        #print "LIst of miniRouter: @miniRouter\n";
}

}
######################################################################
sub xfigTimedTree() {

        my ($centerx,                   $centery,                       $borderx,                       $bordery,                       $width);
        my ($startx,                                    $starty,                                        $endx,                                  $endy);
        my ($labelx,                    $labely,                                $label, $textx, $texty);
        my ($router, $end, $i);
        my ($sumEdges, $firstDate);

        if (%hashOfRoutes !=()) {
                #print "fig 1.0 \n";
                my $numPaths=1;
                for ($i=0; $i<=$#arrayOfRoutes; $i++) {
                        #print "fig 1.1 \n";
#printDebug "path=> $arrayOfRoutes[$i] \n****** $arrayOfRoutes[$i+1]\n";
                        if ($numPaths==1) {
                                $firstDate=$arrayOfDates[$i];
                        }

                        if (((($i+1)<=$#arrayOfRoutes) &&
                                        ("$arrayOfRoutes[$i]" eq "$arrayOfRoutes[$i+1]")) &&
                                        ((($i+2)<=$#arrayOfRoutes) && ("$arrayOfDates[$i+1]" ne "$arrayOfDates[$i+2]"))) {
                                #print "fig 1.2 \n";
                                $numPaths++;
                                next;
                        }

                        if ((($i+1)<=$#arrayOfRoutes) &&
                                        ("$arrayOfDates[$i]" eq "$arrayOfDates[$i+1]")) {
                                #print "fig 1.3 \n";
                                &calculateMiniEdges($arrayOfRoutes[$i], 1);
                                &recalculateMiniEdges($arrayOfRoutes[$i+1], 1);
#printDebug "path=> $arrayOfRoutes[$i] \n****** $arrayOfRoutes[$i+1]\n";
                                $i++;
                        } elsif ((($i+2)<=$#arrayOfRoutes) &&
                                        ("$arrayOfDates[$i]" eq "$arrayOfDates[$i+2]")) {
                                #print "fig 1.4 \n";
                                &calculateMiniEdges($arrayOfRoutes[$i], 1);
                                &recalculateMiniEdges($arrayOfRoutes[$i+1], 1);
                                &recalculateMiniEdges($arrayOfRoutes[$i+2], 1);
                                $i++;
                                $i++;
                        } else {
                                #print "fig 1.5 \n";
                                &calculateMiniEdges($arrayOfRoutes[$i], $numPaths);
                        }

                        $maxy=0;

                        #Print the route Name first
                        print OUT "4 0 0 2 0 0 18 0.0000 4 135 360 $basex $basey @routeName[$i]\\001\n\n";
                        $basey+=300;

                        foreach $router (@miniRouter) {
                                #print "Router: $router ($x{\"$router\"},$y{\"$router\"})\n";
                                $centerx=$basex+$x{"$router"}*$stepx;
                                $centery=$basey+$y{"$router"}*$stepy;
                                if ($maxy < $y{"$router"}) {$maxy = $y{"$router"};};

                                #printDebug "router: $router ($centerx, $centery)\n";

                                $borderx=$centerx-$radius;
                                $bordery=$centery-$radius;
                                $width=1;
                                print OUT "1 3 0 $width -1 7 0 0 -1 0.000 1 0.0000 $centerx $centery ".
                                        "$radius $radius $borderx $bordery $borderx $bordery\n";
                                $labelx=$centerx-$radius;
                                $labely=$centery-$radius;
                                #if ($router =~ /(\w+)\.(\w+)\.(\w+)\.(\w+)/) {
                                #label="$4";
                                #}
                                $label = $router;
                                print OUT "4 0 0 2 0 0 16 0.0000 4 135 360 $labelx $labely $label\\001\n\n";
                                #print OUT "4 0 0 2 0 0 12 0.0000 4 135 360 $labelx $labely test\\001\n\n";

                                $sumEdges=0;
                                foreach $end ( keys %{$miniEdge{"$router"}}) {
                                        $startx=$centerx;
                                        $starty=$centery;
                                        $endx=$basex+$x{"$end"}*$stepx;
                                        $endy=$basey+$y{"$end"}*$stepy;
                                        $width=int(${$miniEdge{"$router"}}{"$end"}*$widthWeigth);
                                        $width=($width?$width:1);
                                        $sumEdges+=${$miniEdge{"$router"}}{"$end"};
                                        if (($startx == $endx) && ($starty == $endy)) {
                                                #this is looping into itself
                                                $endx=$startx-$radius;
                                                $endy=$starty+$radius*1.5;
                                        }
                                        print OUT "2 1 0 $width -1 7 0 0 -1 0.000 0 0 -1 0 0 2\n".
                                        "         $startx $starty $endx $endy\n";
                                        #                                       printDebug "$router $end 2 1 0 $width -1 7 0 0 -1 0.000 0 0 -1 0 0 2\n".
                                        #                                               "         $startx $starty $endx                                                                 (=$basex+".$x{"$end"}."*$stepx) $endy \n";
                                }
                                #$labelx=$centerx+$radius*0;
                                #$labely=$centery+$radius+200;
                                #$label=(int($sumEdges/$sumRoutes*100))."%";
                                #if ($label eq "0%") {
                                #$label=(int($sumEdges/$sumRoutes*1000))."%%";
                                #}
                                #if ($label eq "0%%") {
                                #         $label=".".(int($sumEdges/$sumRoutes*10000))."%%";
                                #}
                                #print OUT "4 0 1 2 0 0 12 0.0000 4 135 360 $labelx $labely $label \\001\n\n";

                        }
                        $basey += ($maxy+1)*$stepy;
                        $numPaths=1;
                }

        $texty = $offsetTexty+$basey;
        $textx = $offsetTextx+$basex;

        my $key;
        foreach $key (sort (keys %nodeIndex)){
        print OUT "4 0 -1 0 0 0 16 0.0000 4 135 360 $stepx $texty $key => $nodeIndex{$key} \\001\n\n";
        #$textx += $basex;
        $texty += 250;
        }

}

#print "Done leaving Timed Tree\n";
}
=cut

1;

__END__

=head1 SEE ALSO

L<FindBin>, L<POSIX>, L<Fcntl>, L<FileHandle>, L<perfSONAR_PS::OWP>,
L<perfSONAR_PS::OWP::Utils>, L<perfSONAR_PS::CGI::Carp>, L<File::Basename>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: owdb.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Jeff Boote, boote@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2002-2008, Internet2

All rights reserved.

=cut

