# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>.
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package GPS::Garmin;

use GPS::Base ();
use GPS::Serial ();
use GPS::Garmin::Handler ();
use GPS::Garmin::Constant ':all';

use strict;
use vars qw($VERSION @ISA);

@ISA = qw(GPS::Base GPS::Serial);

$VERSION = sprintf("%d.%02d", q$Revision: 1.34 $ =~ /(\d+)\.(\d+)/);

#$|++; # XXX should not be here

sub new {
    my $class = shift;
    my %param = @_;
    $param{'Protocol'} ||= 'GRMN';

    my $self = $class->SUPER::common_new(%param);
    bless $self, $class;

    # Use the generic handler for protocol initialization
    $self->{handler} = GPS::Garmin::Handler::Generic->new($self);
    # Initialize protocol
    $self->get_product_id unless $param{do_not_init};

    $self;
}

sub DESTROY {
    my $self = shift;
    if ($self->serial) {
	$self->abort_transfer;
    }
}

sub records { shift->{records} }

sub protocol { shift->{protocol} }

sub product_id { shift->{product_id} }

sub software_version { shift->{software_version} }

sub product_description { shift->{product_description} }

sub handler { shift->{handler} }

*device_name = \&product_description;

sub cur_pid {
    my $self = shift;
    @_ ? ($self->{cur_pid} = shift) : $self->{cur_pid};
}

sub cur_request {
    my $self = shift;
    @_ ? ($self->{cur_request} = shift) : $self->{cur_request}
}

# - Packet ID Type - What's the packet all about?
sub Pid_Byte {
    my $self = shift;
    no strict 'refs';

    #Get the ID's from the constants
    #This is were we get
    #the subroutine names in GPS::Garmin::Handler

    unless (ref($self->{pidbytes}) eq 'ARRAY') {
	for(@{$GPS::Garmin::Constant::EXPORT_TAGS{pids}}) {
	    my ($tag) = /GRMN_(\w+)/;
	    $self->{pidbytes}[&$_] = ucfirst(lc($tag));
	}
    }

    my $b = shift;
    return $self->{pidbytes}[$b] || sprintf("0x%.2x",$b);
}

sub get_position {
    shift->send_command(GRMN_TRANSFER_POSN);
}

sub get_time {
    shift->send_command(GRMN_TRANSFER_TIME);
}

sub power_off {
    shift->send_command(GRMN_TURN_OFF_PWR);
}

sub abort_transfer {
    shift->send_command(GRMN_ABORT_TRANSFER,no_reply=>1);
}



sub upload_data {
    #This is still very experimental

    my $self = shift;
    my $aref = shift;
    my $cb   = shift;
    my $recn = @$aref;
    my $records  = pack("l", $recn+1);

    # Tell the Garmin how many are coming.
 RNUM: {
	$self->send_packet(GRMN_RECORDS,$records);
	redo RNUM if $self->get_reply(1) == GRMN_NAK;
    }

    my $i = 0;
    for (@$aref) {
	$self->send_packet(@$_);
	$self->get_reply(1);
	$cb->($i) if $cb;
	$i++;
    }
    $self->send_packet(GRMN_XFER_CMPLT);
}


sub prepare_transfer {
    my $self = shift;
    my $t = lc shift;

    my %cmd = ( wpt=>GRMN_TRANSFER_WPT,
		trk=>GRMN_TRANSFER_TRK,
		alm=>GRMN_TRANSFER_ALM,
		waypoint=>GRMN_TRANSFER_WPT,
		track=>GRMN_TRANSFER_TRK,
		almanac=>GRMN_TRANSFER_WPT,
		rte=>GRMN_TRANSFER_RTE,
		route=>GRMN_TRANSFER_RTE,
	      );

    if($cmd{$t}) {
	$self->send_command($cmd{$t});
	$self->cur_request($t);
    }
}

sub get_product_id {
    #returns (product_id,software_version,product_description)
    my $self = shift;
    $self->send_packet(GRMN_PRODUCT_RQST);
    my @result = $self->get_reply;

    if ($result[0] == GRMN_NAK) {
	$self->usleep(50);
	return $self->get_product_id;
    }

    $self->{product_id}	 = $result[0];
    $self->{software_version}	 = $result[1];
    $self->{product_description}     = $result[2];

    if (   $self->{product_id} == 694 # etrex vista hcx
       ) {
	$self->{handler} = GPS::Garmin::Handler::EtrexVistaHCx->new($self);
    } elsif (   $self->{product_id} == 154 # etrex venture
	     || $self->{product_id} == 169 # etrex vista
	     || $self->{product_id} == 315 # etrex vista c
	     || $self->{product_id} == 111 # emap
	     || $self->{product_id} == 248 # gecko 201
	     || $self->{product_id} == 292 # GPSmap 60CSx
	     || $self->{product_id} == 295 # etrex yellow
				      # XXX add more devices here ...
       ) {
	$self->{handler} = GPS::Garmin::Handler::EtrexVenture->new($self);
    } else {
	warn "Unknown product id $self->{product_id}, fallback to generic handler.\n";
	$self->{handler} = GPS::Garmin::Handler::Generic->new($self);
    }
    return @result;
}

#Converts decimal coordinates to (N|E|W|S)Deg"Min
sub long_coords {
    my ($self,$lat,$lon) = @_;
    my $ltcord = "N";
    $ltcord = "S" if $lat < 0;
    my $lncord = "E";
    $lncord = "W" if $lon < 0;
    $lat = abs($lat);
    $lon = abs($lon);
    $lat = int($lat)+($lat - int($lat))*60/100;
    $lon = int($lon)+($lon - int($lon))*60/100;
    return($ltcord,$lat,$lncord,$lon);
}

# - Checksum calculation according to Garmin specs.
sub checksum {
    my $self = shift;
    my $csum;
    for (unpack "C*",shift) {
	$csum -= $_;
	$csum %= 256;	     #Is this trustable with negative numbers?
    }
    $csum;
}

# - Semicircle to degrees
sub semicirc_deg {
    my $self = shift;
    return shift() * (180/2**31);
}

sub deg_semicirc {
    my $self = shift;
    return shift() * (2**31/180);
}

sub read_packet {
    #gets a packet from the device, returns (data,command)
    #if any arg is given, it will consider a whole packet,
    #Otherwise, it'll assume that command is already read,
    #starting at length and returning undef in command.

    my $self = shift;
    my ($command,$data);

    if(@_) {
	while(my $buf = unpack "C", $self->_read) {
	    $self->usleep(1);
	    next if $buf != $self->cur_pid;
	    $self->usleep(10);
	}
	my $command = $self->_read;
    }

    my $len = $self->safe_read;
    my $lenc = unpack("C",$len);

    $self->usleep(1);
    for(1..$lenc) {
	$self->usleep(1) if (($_ % 6) == 0);
	$data .= $self->safe_read
    }

    my $csum = $self->safe_read;
    $self->_read(2);#Footer
    my $full_packet = pack("C",$self->cur_pid).$len.$data;
    if (pack("C",$self->checksum($full_packet)) ne $csum) {

	printf STDERR "NAK: %s != %s\n",$self->checksum($data),unpack"C",$csum
	    if $self->verbose;

	$self->_read(2);
	$self->send_packet(GRMN_NAK);
	$self->usleep(50);
	return $self->read_packet(shift,1);
    }

    return ($data,$command);
}


sub grab {
    my $self = shift;
    die "Must use prepare_transfer first!" unless $self->cur_request;

    my @result = $self->get_reply;

# XXX ignore it for now, because GRMN_NAK is the same as ID=021!
#      if ($result[0] == GRMN_NAK) {
#  	   printf STDERR "Received NAK in grab\n" if $self->verbose;
#          $self->usleep(50);
#          return $self->grab;
#      }

    return @result;
}


sub send_command ($) {
    #Sends Command to GPS
    #and starts get_reply so that a Garmin::Handler
    #takes care of the reply
    #returns Garmin::Handler reply

    my $self = shift;
    my $command = shift;
    my %p = @_;
    $self->send_packet(GRMN_COMMAND_DATA,pack("C2",$command,GRMN_NUL));

    my @result = $self->get_reply() unless $p{no_reply};

    if (@result && $result[0] == GRMN_NAK) {
	printf STDERR "Received NAK in send_command\n" if $self->verbose;
	$self->usleep(50);
	return $self->send_command($command,%p);
    }

    return @result;
}

sub send_packet {
    #Prepares the packet and sends it
    #first argument is command in decimal
    #following arguments are treated as already been packed

    my $self = shift;
    my $message = pack("C",shift);
    if(@_) {
	my $buf = join('',@_);
	$message .= pack("C",length($buf)).$buf;
    } else {
	$message .= pack("C2",GRMN_TRANSFER_ALM,GRMN_TRANSFER_ALM);
    }
    $message .= pack "C1",$self->checksum($message);
    $message = $self->escape_dle($message);
    $message = GRMN_HEADER . $message . GRMN_FOOTER;
    print STDERR "SENDING PACKET: (", join ' ',(map {$self->Pid_Byte($_)}unpack("C*",$message)),")","\n" if $self->verbose;
    $self->usleep(20);
    $self->_write($message);
}

sub escape_dle {
    #\x10 must become \x10\x10
    my $self = shift;
    my $buf = shift;

    my $i = index($buf,"\x10");
    if($i > -1) {
	for (my $i=0;$i<length($buf); ) {
	    $i=index($buf,"\x10",$i); last if $i == -1;
	    substr($buf,$i,1,"\x10\x10");
	    $i+=2;
	}
    }
    return $buf;
}

sub get_reply {
    no strict "subs";
    my $self = shift;
    my $command = shift;
    my $handler = $self->handler;

    print STDERR "RECEBI:\n" if $self->{'verbose'};

    local $SIG{ALRM} = sub {die "GPS Device has timed out\n"};
    eval { alarm($self->{timeout}) };

    while (1) {
#	$self->usleep(10); # XXX try it with a smaller delay...
	$self->usleep(1);
	my $buf = unpack "C1",$self->_read;

	if (defined $buf && $buf == GRMN_DLE) { #Start processing Garmin data
	    $buf = $self->_read;
	    $buf = unpack("C1",$buf);
	    next if $buf == GRMN_NUL;#0 byte

	    if ($buf == GRMN_ETX) {
		print STDERR ";\n"  if $self->{'verbose'};
		eval { alarm($self->{timeout}) };
		next;
	    }
	    my $gcommand = $self->Pid_Byte($buf);
	    next unless defined $gcommand;

	    my $is_prot = 1 if($gcommand =~ /byte$/);

	    print STDERR "\nGot $gcommand\n" if $self->verbose;
	    $self->cur_pid($buf);

	    my @data = $handler->$gcommand($command) if $handler->can($gcommand);
##XXX ??? $data[0] is normal data?!
	    if ($gcommand !~ /^(?:Wpt|Trk|Rte)_(?:data|hdr)$/ && $data[0] == GRMN_ACK) {
		next unless $command;
	    }
	    eval {alarm 0; };
##XXX ??? $data[0] is normal data?!
#warn $gcommand;
	    if ($gcommand !~ /^(?:Wpt|Trk|Rte)_(?:data|hdr)$/ && $data[0] == GRMN_NAK) {
		print STDERR "First byte is NAK\n" if ($self->verbose);
		return GRMN_NAK;
	    }
	    return $data[0] if @data == 1;
	    return @data;
	}
    }
    eval {alarm 0; };
    print STDERR "No ACK seen, returning NAK\n\n" if ($self->verbose);
    return GRMN_NAK;
}




1;
__END__

=head1 NAME

GPS::Garmin - Perl interface to GPS equipment using the Garmin Protocol

=head1 SYNOPSIS

    use GPS::Garmin;
    $gps = new GPS::Garmin(  'Port'      => '/dev/ttyS0',
			     'Baud'      => 9600,
  		          );

To transfer current position, and direction symbols:

    ($latsign,$lat,$lonsign,$lon) = $gps->get_position;


To transfer current time:

    ($sec,$min,$hour,$mday,$mon,$year) = $gps->get_time;


To transfer trackpoints:

    $gps->prepare_transfer("trk");
    while($gps->records) {
	($lat,$lon,$time) = $gps->grab;
    }

To transfer Waypoints:

    $gps->prepare_transfer("wpt");
    while($gps->records) {
	($title,$lat,$lon,$desc) = $gps->grab;
    }

=head1 DESCRIPTION

GPS::Garmin allow the connection and use of of a GPS receiver in perl scripts.
Currently only the GRMN/GRMN protocol is implemented but NMEA is a work in
progress.

This module currently works with Garmin GPS II+ equipments,
but should work on most Garmin receivers that support the GRMN/GRMN
protocol.

=head1 GETTING STARTED

Make sure your GPS receiver is in host mode, GRMN/GRMN protocol.
To start a connection in your script, just:

    use GPS::Garmin;
    $gps = new GPS::Garmin (  'Port'      => '/dev/ttyS0',
	 		      'Baud'      => 9600,
			      'Return'    => 'hash',
			   ) or die "Unable to connect to receiver: $!";

Where Port is the port that your GPS is connected to, and Baud the
speed of connection ( default is 9600 bps).

If Return is set to 'hash', then waypoints and tracks are returned as
hashes, possibly containing more information. XXX This is not
implemented completely for all data and device types. An undefined
'Return' value would cause to return lists with basic information
(latitude and longitude) instead.

To know current coordinates:

    ($latsign,$lat,$lnsign,$lon) = $gps->get_position;

    $ltsign is "S" or "N" (South or North)
    $lat is current latitude in degrees.minutes.
    $lnsign is "W" or "E" (West or East)
    $lon is current longitude in degrees.minutes.

To transfer the track records:

    $gps->prepare_transfer("trk");
    while($gps->records) {
        ($lat,$lon,$time) = $gps->grab;
    }

C<$time> is in unix epoch seconds

With C<< 'Return' => 'hash' >> this would be

    $gps->prepare_transfer("trk");
    while($gps->records) {
        %trk_data = $gps->grab;
    }

instead.

=head1 KNOWN LIMITATIONS

- Trackpoint transfer won't work in the following Garmin devices,
since they don't support it:

GPS 50	    GPS 55
GPS 150	    GPS 150 XL
GPS 165	    GNC 250
GNC 250XL   GNC 300
GNC 300XL

You can check you GPS capabilities by looking at the table in page 50 of the
Garmin protocol specification at L<http://www.garmin.com/support/protocol.html>

- You need to have Win32::SerialPort to have GPS::Garmin working in Windows.

=head1 BUGS

Lacks documentation

=head1 AUTHOR

Joao Pedro B Gonçalves , joaop@iscsp.utl.pt

=head1 SEE ALSO

Peter Bennett's GPS www and ftp directory:

	ftp://sundae.triumf.ca/pub/peter/index.html.
	http://vancouver-webpages.com/peter/idx_garmin.html

Official Garmin Communication Protocol Reference

	http://www.garmin.com/support/protocol.html

=cut
