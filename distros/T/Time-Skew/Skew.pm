#!/usr/bin/perl -w
# $Revision: 1.2 $
# Computes local clock skew with respect to a remote clock.
# Copyright (c) 2005, Augusto Ciuffoletti, Universita' di Pisa

package Time::Skew;
use strict;
our $VERSION="0.1";
# skew jitter time constant;
my $K=16;


#sub printresult {
#    my $h=shift;
#    my %fm=(elems=>"%3d",select=>"%3d",skew=>"%0.6f",delay=>"%0.6f",jitter=>"%0.6f",count=>"%6d",lost=>"%6d",timestamp=>"%9.6f",delay=>"%8.6f",maxdelay=>"%8.6f",mindelay=>"%8.6f",skewjitter=>"%0.6f",itimestamp=>"%9.6f",delta=>"%0.6f",size=>"%6d",gap=>"%4.2f",avedelay=>"%8.6f");
#    foreach my $k ( keys %$h ) {
#	printf " %s=$fm{$k}",$k,$h->{$k}
#	}
#    print  "\n"
#}

sub convexhull {
# function convexhull takes as an input
# - a reference to the returned hash containing the drift
#   and other related issues
# - a reference to the input data, a time and a measured delay
# - a list containing the description of the hull, as a list of points
#   in the plane
    my ( $result, $datap, $sp) = @_;
    my ( $t,$d )=@$datap;
# index of last elem
    my $i=scalar(@$sp)-1;
# update convex hull points
    if ( $i >= 1 ) {
	while ( $i>=1 && 
		(($sp->[$i][1]-$sp->[$i-1][1])/($sp->[$i][0]-$sp->[$i-1][0])) >= 
		(($d-$sp->[$i][1])/($t-$sp->[$i][0])) ) {
	    pop @$sp;
	    $i--;
	}
    }
    push @$sp,$datap;

# proceed only if at least 2 items in stack
    $i=scalar(@$sp)-1;
    return 1 if $i<1;

# find optimal interpolation points
    my $maxdt;
    my $maxi=0;
    for ( $i=0; $i<scalar(@$sp)-1; $i++ ) {
        if ( ! defined $maxdt || 
	     $maxdt < $sp->[$i+1][0]-$sp->[$i][0] ) {
            $maxdt = $sp->[$i+1][0]-$sp->[$i][0];
            $maxi=$i;
        }
    }

# DEBUG only
#    for ( $i=0; $i<=scalar(@$sp)-1; $i++ ) {    
#	printf $logfh "---> %d | %2.2f %2.6f\n",$i,$sp->[$i][0],$sp->[$i][1];
#    }

# return stack elems
    $result->{elems}=scalar(@$sp);
    $result->{select}=$maxi;
# compute clock skew
    my $skew=($sp->[$maxi+1][1]-$sp->[$maxi][1])/
	($sp->[$maxi+1][0] - $sp->[$maxi][0]);
# compute amortized skew jitter
    if ( defined $result->{skew} ) {
	$result->{skewjitter} = 
	    ( defined $result->{skewjitter} ) ? 
	    (($result->{skewjitter}*($K-1))/$K)+($skew-$result->{skew}) :
	    ($skew-$result->{skew});
    }
    $result->{skew}=$skew;
# compute compensated delay
    $result->{delay}=$d-$sp->[$maxi][1]-($t-$sp->[$maxi][0])*$result->{skew};
    ( $result->{delay} < 0 ) && 
	warn "XXX HULL ALGORITHM ERROR (negative delay $result->{delay})\n";
# compute compensated delay jitter
    ( defined $result->{itimestamp} ) && 
	( $result->{jitter}=
	  ($result->{delta}-$d)-
	  (($result->{itimestamp}-$t)*$result->{skew}) );
    $result->{itimestamp}=$t;
    $result->{delta}=$d;
    return 0;
}

=head1 NAME

Time::Skew - Computes local clock skew with respect to a remote clock.

=head1 SYNOPISI

  use Time::Skew

  # Init Convex Hull and timing data
  my $hull=[];
  my $result={};

  # Iterate data point introduction
  Time::Skew::convexhull($result,$datapoint,$hull);

=head1 DESCRIPTION

This module supports the computation of the skew between two clocks:
the (relative) skew is the speed with which two clocks diverge. For
instance, if yesterday two clocks, at the same time, showed
respectively 10:00 and 10:05, while today when the former shows 10:00
the latter shows 10:04, we say that their relative skew is 1 minute/24
hours, roughly 7E-4.

The module contains one single subroutine, which accepts as input a
pair of timestamps, associated to a message from host A to
host B: the timestamps correspond to the time when the message was
sent, and to the time when message is received. Each timestamp
reflects the value of the local clock where the operation takes place:
the clock of host A for the send, the clock of B for the receive.

Please note that the module does _not_ contain any message exchange
facility, but only the mathematics needed to perform the skew
approximation, once timestamps are known.

The subroutine takes as argument:

=over 4

=item *
a reference to a hash where values related to the timing of the
network path from A to B;

=item *
a 2-elems array (a data point in the sequel) containing the
timestamp of the receive event, and the differece between the send
timestamp and the receive timestamp for one message;

=item *
a stack containing some data points, those that form the convex hull.

=back

The usage is very simple, and is illustrated by the following example:

 #!/usr/bin/perl -w
 use strict;
 use Time::Skew;

 # Initialize data
 my $hull=[];
 my $result={};
 while ( 1 ) {
 # Exchange message and acquire a new data point
   my $datapoint = acquire();
 # Call the convexhull subroutine
   Time::Skew::convexhull($result,$datapoint,$hull);
 # After first message some results are still undefined
   ( defined $result->{skewjitter} ) || next;
 # here you can use the results

   };
 }
 
The data returned in the "result" hash is the following:

=over 4


=item *
result->{skew}       the clock skew;

=item *
result->{skewjitter} the variance of the skew estimate, used to estimate
                     convergence;

=item *
result->{jitter}     difference between the current delay and the
                     previous delay;

=item *
result->{delay}      the communication delay, decremented by a constant 
                     (yet unknown) value, used to compute communication
                     jitter;

=item *
result->{elems}      the number of data points in the convex hull;

=item *
result->{select}     the index of the data point in the convex hull used to 
                     compute the skew;

=item *
result->{itimestamp} the timestamp, first element in the data point
                     just passed to the subroutine;

=item *
result->{delta}      the timestamp difference, second element in the data
                     point just passed to the subroutine;

=back

The data returned in the "hull" stack is a series of data points,
selected from those passed to successive calls of the subroutine. The
number of data points in the "hull" stack usually does not exceed 20
units.

The algorithm is very fast: each call consists in scanning at most all
data points in the "hull" stack, performing simple arithmetic operations
for each element.

The algorithm must be fed with a sequence of data points before
returning significant results. The accuracy of the estimate keeps
growing while new data points are passed to the subroutine. A rough
rule of thumb to evaluate estimate accuracy is to observe the skew
jitter, and assume it corresponds to the skew estimate accuracy. Paths
with quite regular communication delay (small jitter) converge faster.

=head1 HISTORY

0.1 Original version

=head1 BUGS

A rounding problem may cause an inconsistent negative number of
magnitude E-15 as "delay", instead of 0. A warning is generated, and
the algorithm compensates the problem.

=head1 SEE ALSO

=over 4

=item *
Augusto Ciuffoletti, "Packet Delay Monitoring without a GPS", Technical Report 05-16, Universita' degli Studi di Pisa, Dipartimento di Informatica, June 2005. 

=item *
Sue B. Moon, Paul Skelly, and Don Towsley. "Estimation and removal of clock skew from network delay measurements". Technical Report 98-43, Department of Computer
Science - University of Massachusetts at Amherst - USA, 1998.

=back

=head1 AUTHOR

Augusto Ciuffoletti, E<lt>augusto@di.unipi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Augusto Ciuffoletti

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
