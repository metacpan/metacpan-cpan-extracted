use Statistics::Descriptive;
use Log::Log4perl qw(get_logger);


#######################################################################
package IEPM::PingER::Statistics::RTT;
#######################################################################

our $logger = Log::Log4perl::get_logger("IEPM::PingER::Statistics::RTT");

use strict;

sub calculate
{
  my $rtts = shift; # reference to list of rtts
  
  if ( ref($rtts) ne 'ARRAY' ) {
    $logger->fatal( "Input needs to be a reference to an array of rtt values.");
    return ( undef, undef, undef, undef );
  }

  my $size = scalar @$rtts;
  $logger->debug("input: @$rtts ($size)");
   
   if ( $size  > 0 ) {

     my $stat = Statistics::Descriptive::Full->new();

     for( my $i=0; $i<$size ; $i++ ) {
           $stat->add_data( $rtts->[$i] );
     }
     return ($stat->min(), $stat->max(),  $stat->mean(), $stat->median() );
	  
   } else {
  	  return ( undef, undef, undef, undef );
   }
}

#######################################################################
package IEPM::PingER::Statistics::IPD;
#######################################################################

our $logger = Log::Log4perl::get_logger("IEPM::PingER::Statistics::IPD");

use strict;

sub calculate
{
  my $rtts = shift; # reference to list of rtts
  
  if ( ref($rtts) ne 'ARRAY') {
    $logger->fatal( "Input needs to be a reference to an array of latency values.");
    return ( undef, undef, undef, undef, undef );
  }
 
  my $size = scalar @$rtts;
  $logger->debug("input: @$rtts ($size)");   
  
  # need special case as we can not determine the ipd for only one packet
  if ( $size > 1 ) {

    my $stat = Statistics::Descriptive::Full->new();
    my @ipds = ();
    for( my $i=1; $i<$size; $i++ ) {  	
      my $ipd = $rtts->[$i] - $rtts->[$i-1];
      $ipd = abs( $ipd );
      $logger->debug( " adding $ipd"); 
      $stat->add_data($ipd);
    }

    my $seventyfifth = $stat->percentile(75);
    my $twentyfifth = $stat->percentile(25);
    my $iqr = undef;
    if ( defined $seventyfifth && defined $twentyfifth ) {
	  $iqr = $seventyfifth - $twentyfifth;
    }

    return ( $stat->min(), $stat->mean(), $stat->max(), $stat->median(),  $iqr );

  } else {
    return ( undef, undef, undef, undef, undef );
  }
}



#######################################################################
package IEPM::PingER::Statistics::Other;
#######################################################################
use strict;
our $logger = Log::Log4perl::get_logger("IEPM::PingER::Statistics::Other");

###
# takes in a reference to a list of sequence numbers
###
sub calculate
{
  my $sent = shift;
  my $recv = shift;

  my $seqs = shift;
 
  # if no seqs are supplied, ie recv packets is zero, then we return undef undef as 
  # it is not know whether ooo nor dups are true or not
  if ( ! defined $seqs || ref($seqs) ne 'ARRAY') {
    $logger->fatal( "Input needs to be a reference to an array of packet sequence values.");
    return ( undef, undef );
  }

  my $size = scalar @$seqs;
  $logger->debug( "input: sent $sent, recv $recv, seqs $seqs ($size)");

  return ( undef, undef ) if $size < 2;
  
  # dups and ooo
  my $dups = 0;
  my $ooo = 0;
  
  # seen initiate with first element as loop doesn't
  
  # ooo
  my %seen = ();
  $seen{$seqs->[0]}++;
  $logger->debug("Searching for Out of Order packets");

  #doubel check the input
  return (undef,undef) if ( $seqs->[0] > $sent );

  for( my $i=1; $i< $size; $i++) {
    
    return (undef, undef) if ( $seqs->[$i] > $sent );

    $logger->debug( " Looking at " . $seqs->[$i] );
    if ( $seqs->[$i] >= $seqs->[$i-1] ) { # note => means that dups are not counted as out of order
      # okay
    } else {
      $logger->debug( " Found duplicate at $i / $seqs->[$i]");
      $ooo++;
    }
    # dups
    $seen{$seqs->[$i]}++;
  }


  $logger->debug("Searching for Duplicate packets");
  # analyse dups
  foreach my $k ( keys %seen ) {
  	$logger->debug( " Saw packet #$k " . $seen{$k} . " times");
    if( $seen{$k} > 1 ) {
      $dups++;
    }
  }
  
  return ( $dups == 0 ? 'false' : 'true', $ooo == 0 ? 'false' : 'true' );
}



#######################################################################
package IEPM::PingER::Statistics::Loss;
#######################################################################
use strict;
our $logger = Log::Log4perl::get_logger("IEPM::PingER::Statistics::Loss");

###
# takes in a reference to a list of sequence numbers
###
sub calculate
{
  my $sent = shift;
  my $recv = shift;
    
  $recv = 0 if ! defined $recv;
  $logger->debug("input: $sent / $recv");
  if (  !$sent ||   $sent < $recv ) {
    $logger->fatal( "Error in parsing loss with sent ($sent), recieved ($recv)");
    return -1;
  }
  
  return 100. - 100. * ( $recv / $sent );
}


#######################################################################
package IEPM::PingER::Statistics::Loss::CLP;
#######################################################################
use strict;
###
# Conditional Loss Probability (CLP) defined in Characterizing End-to-end
# Packet Delay and Loss in the Internet by J. Bolot in the Journal of
# High-Speed Networks, vol 2, no. 3 pp 305-323 December 1993.
# See: http://citeseer.ist.psu.edu/bolot93characterizing.html
###

our $logger = Log::Log4perl::get_logger("IEPM::PingER::Statistics::Loss::CLP");

###
# takes in a reference to a list of sequence numbers
###
sub calculate
{
  my $pktSent = shift;
  my $pktRcvd = shift;
  my $seqs = shift;
 
  ### check if $seqs a reference to array
  if ( ref($seqs) ne  'ARRAY') {
      $logger->fatal( "Input should be list of sequence numbers.");
      return undef;
  }
  
  my $stringified_arr =   join ",", @$seqs;
  my $size = scalar @$seqs;

  $logger->debug( "Size: $size"); 
    
  if ( $pktRcvd !=  $size ) {
    $logger->warn( "pkts recvd ($pktRcvd) is not equal to size $size of array $stringified_arr ");
    return undef;
  }
  ### lookup hash with sequence numbers as keys and sequence numbers + 1 as values 
  ###  ( to get defined value for the first packet
  ###  duplicated packets will be considered as lost, reordered packets will be ignored
  ###  for example: 0 2 3 4 5 5 6 7 sequence with 8 packets sent and 
  my %lookup_seq = map {($_+1) =>  ($_+1)} @$seqs;
  my $consecutive_packet_loss=0;
  my $lost_packets = $pktSent - $pktRcvd;
  $logger->debug( "input: sent $pktSent / recv $pktRcvd");
 
  $logger->debug( "Determining lost packets from sequence $stringified_arr");
  for my $i (2 ..    $pktSent) {
     $logger->debug( " Looking at packet #$i ");
     unless($lookup_seq{$i-1}) {
        $consecutive_packet_loss++ unless  $lookup_seq{$i};
        $logger->debug( "  Found lost packet #$i ");
     }    
  }

  $logger->debug( "Determining Conditional Loss Probability where lost_packets=$lost_packets");
 
  my $clp = undef;
   
  if ( $lost_packets > 1) {
    $clp =  $consecutive_packet_loss*100/($lost_packets - 1);
  }
  return $clp;
  
}



1;
