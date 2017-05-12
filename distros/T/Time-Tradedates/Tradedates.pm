package Time::Tradedates;

use strict;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT = qw( getNumDays lastTradeDay firstTradeDay );
our $VERSION = '0.1.2';


# Preloaded methods go here.

use Time::Local;


sub getNumDays
{
    my $etime = shift;

    my @months = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );
    my @wkdays = ( "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" );
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $etime );

    my $py = $year+1900;

    my $days = 0;

    if ( $mon <= 5 ) {
        if ( ($mon % 2) == 0 ) {
	    $days = 31;
        } elsif ( $mon == 1 ) {
	    if ( (($year+1900)%4) == 0 ) {
	        $days = 29;
	    } else {
	        $days = 28;
	    }
        } else {
	    $days = 30;
        }
    } elsif ( ($mon % 2) == 1 ) {
        $days = 31;
    } else {
        $days = 30;
    }

    return( $days );
}

sub lastTradeDay
{
    my $mon = shift;
    my $py = shift;
    my $minus = shift;

    my $days = &getNumDays( timelocal( 0,0,0,1,$mon,$py ) );

    my $lday=timelocal( 0,0,0,$days,$mon,$py);
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $lday );

    my $done = 0;

    while ( $done == 0 ) {
        if ( ($wday > 0) && ($wday < 6) ) {
        	$done = 1;
        } else {
            $days = $days-1; 
            $lday=timelocal( 0,0,0,$days,$mon,$py);
            ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $lday );
    	}
    }
    if ( $minus != 0 ) {
	$minus = $minus * -1;
	if ( $minus > 1 ) {
	    return( 0 );
	}
	$mday=$mday - $minus;
	$lday = timelocal( 0,0,0,$mday,$mon,$py );
        ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $lday );

        my $done = 0;

        while ( $done == 0 ) {
            if ( ($wday > 0) && ($wday < 6) ) {
                $done = 1;
            } else {
                $days = $days-1;
                $lday=timelocal( 0,0,0,$days,$mon,$py);
                ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $lday );
            }
        }
    }

    return( $mday );
} # End sub lastBusDay

sub firstTradeDay
{
    my $mon = shift;
    my $py = shift;

    my $day = 1;
    my $fday=timelocal( 0,0,0,$day,$mon,$py);
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $fday );

    my $done = 0;

    while ( $done == 0 ) {
        if ( ($wday > 0) && ($wday < 6) ) {
                $done = 1;
        } else {
            $day = $day+1;
            $fday=timelocal( 0,0,0,$day,$mon,$py);
            ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $fday );
        }
    }

    return( $mday );
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Time::Tradedates - Perl extension for last and first trade dates in a month

=head1 SYNOPSIS

  use Time::Tradedates;
  $return = &getNumDays($edate);      # Pass in an epoch (UNIX) date.
                                      # See timelocal and localtime functions
                                      # Returns the number of days in the month
  $return = &lastTradeDay($mon,$year,$integer);
                                      # Pass in Perl Month (i.e. Jan=0), 4 digit year
                                      # and an integer.  0 = last trade day, -1 = LTD-1
				      # At this time only 0 and -1 are supported other
				      # Values will return 0
				      # Returns the last trade day or LTD-1
  $return = &firstTradeDay($mon,$year);
                                      # Pass in Perl Month (i.e. Jan=0) and 4 digit year
				      # Returns the first trade day

=head1 DESCRIPTION

This module is for companies that need to do processing only on the last trade date
of the month and/or N number of days before the last trade date.  It will also be
extended to provide the first trade date of the month.  It is Leap Year sensitive!

It should be used to check the current date and find out if that date is one of the
days you specified for processing.  If not, simply exit.


=head1 AUTHOR

David S. Spizzirro (dspizz@dspizz.com)

=head1 SEE ALSO

Time::Local, localtime(), timelocal()

=cut
