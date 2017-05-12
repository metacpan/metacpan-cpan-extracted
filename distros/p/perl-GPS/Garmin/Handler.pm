# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>.
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package GPS::Garmin::Handler;

use strict;
use vars qw($VERSION @ISA);

use GPS::Garmin::Constant ':all';

$VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

#$|++; # XXX should not be here...

# Don't pull in Math::Trig for just these two functions
sub pi ()   { 4 * atan2(1, 1) } # 3.141592653...
sub rad2deg { ($_[0]*180)/pi }

sub new {
    my($class, $p) = @_;
    my $self = bless { p => $p }, $class;
    if (eval { require Scalar::Util; Scalar::Util->import(qw(weaken)); 1 } ||
	eval { require WeakRef; WeakRef->import(qw(weaken)); 1 }) {
	weaken($self->{p}); # break self-reference
    }
    $self;
}

sub p   { $_[0]->{p} }

# The Garmin documentation says 1.0e+25, but take floating point inaccuracies
# into account.
use constant UNDEF_FLOAT => 9.9e+24;

#Fail
sub Nak_byte {
    shift->p->read_packet;
    GRMN_NAK
}

# - Ack byte - the GPS ACKnowledged, read the packet and move next.
sub Ack_byte {
    shift->p->read_packet;
    GRMN_ACK
}

# XXX use result_as_hash here too? But implementation of
# GPS::Garmin::get_product_id would be more complex...
sub Product_data {
    my ($data) = shift->p->read_packet;
    unpack("ssZ*",$data);
}

######################################################################
# Waypoints

sub Wpt_data_D103 {
    my $self = shift;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;

    my $ident	= substr($data,0,6,'');
    my $comment = substr($data,12,40,'');
    my($lat,$lon) = unpack("ll",$data);
    $lat = $p->semicirc_deg($lat);
    $lon = $p->semicirc_deg($lon);
    $p->send_packet(GRMN_ACK);

    if ($p->{records} == 0) { $p->get_reply }

    if ($p->{return_as_hash}) {
	(ident   => $ident,
	 lat     => $lat,
	 lon     => $lon,
	 comment => $comment,
	);
    } else {
	($ident, $lat, $lon, $comment);
    }
}

sub Wpt_data_D108 {
    my($self) = @_;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;

    my %res;
    @res{qw{wpt_class color dspl attr}} = unpack("C4", substr($data,0,4,''));
    $res{smbl} = unpack("s", substr($data,0,2,''));
    $res{subclass} = substr($data,0,18,''); # XXX chr(255)x18 == undef?
    my($lt,$ln) = unpack("ll", substr($data,0,4*2,''));
    $res{lat} = $p->semicirc_deg($lt);
    $res{lon} = $p->semicirc_deg($ln);
    @res{qw{alt dpth dist}} = unpack("f3", substr($data,0,4*3,''));
    for (qw(alt dpth dist)) {
	if ($res{$_} >= UNDEF_FLOAT) {
	    $res{$_} = undef;
	}
    }
    $res{state} = unpack("a2", substr($data,0,2,''));
    $res{cc} = unpack("a2", substr($data,0,2,''));
    @res{qw{ident comment facility city addr cross_road}} = split /\0/, $data;

    $p->send_packet(GRMN_ACK);

    if ($p->{records} == 0) { $p->get_reply }

    if ($p->{return_as_hash}) {
	%res;
    } else {
	@res{qw{ident lat lon comment}};
    }
}

sub _Wpt_data_D109_and_better {
    my($self) = @_;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;

    my %res;
    @res{qw{dtyp wpt_class dspl_color attr}} = unpack("C4", substr($data,0,4,''));
    $res{color} = $res{dspl_color} & 0x1f;
    $res{dspl} = ($res{dspl_color} >> 5) & 0x3;
    $res{smbl} = unpack("s", substr($data,0,2,''));
    $res{subclass} = substr($data,0,18,''); # XXX chr(255)x18 == undef?
    my($lt,$ln) = unpack("ll", substr($data,0,4*2,''));
    $res{lat} = $p->semicirc_deg($lt);
    $res{lon} = $p->semicirc_deg($ln);
    @res{qw{alt dpth dist}} = unpack("f3", substr($data,0,4*3,''));
    for (qw(alt dpth dist)) {
	if ($res{$_} >= UNDEF_FLOAT) {
	    $res{$_} = undef;
	}
    }
    $res{state} = unpack("a2", substr($data,0,2,''));
    $res{cc} = unpack("a2", substr($data,0,2,''));
    $res{ete} = unpack("l", substr($data,0,4,''));
    if ($res{attr} == 0x80) { # D110
	$res{temp} = unpack("f", substr($data,0,4,''));
	$res{time} = unpack("l", substr($data,0,4,''));
	$res{wpt_cat} = unpack("s", substr($data,0,2,''));
    }
    @res{qw{ident comment facility city addr cross_road}} = split /\0/, $data;

    $p->send_packet(GRMN_ACK);

    if ($p->{records} == 0) { $p->get_reply }

    if ($p->{return_as_hash}) {
	%res;
    } else {
	@res{qw{ident lat lon comment}};
    }
}

sub Wpt_data_D109 { shift->_Wpt_data_D109_and_better(@_) }
sub Wpt_data_D110 { shift->_Wpt_data_D109_and_better(@_) }

sub pack_Wpt_data_D108 {
    my $self = shift;
    my $d = shift;
    my %d = %$d;
    $d{wpt_class} = 0 unless defined $d{wpt_class};
    $d{color} = 255 unless defined $d{color};
    $d{dspl} = 0 unless defined $d{dspl};
    $d{attr} = 0x60 unless defined $d{attr};
    $d{smbl} = 8246 unless defined $d{smbl};
    foreach my $key (qw(alt dpth dist)) {
	$d{$key} = 1.0e25 unless defined $d{$key};
    }
    foreach my $key (qw(state cc)) {
	$d{$key} = "  " unless defined $d{$key};
    }
    foreach my $key (qw(ident comment facility city addr cross_road)) {
	$d{$key} = "" unless defined $d{$key};
    }
    if ($d{ident} eq '') {
	die "ident not defined";
    }
    die "lat or lon not defined" if !defined $d{lat} || !defined $d{lon};
    my $s = pack("C4s", @d{qw{wpt_class color dspl attr smbl}});
    $s .= chr(255)x18; # subclass
    $s .= pack("ll", $self->p->deg_semicirc($d{lat}), $self->p->deg_semicirc($d{lon}));
    $s .= pack("f3", @d{qw{alt dpth dist}});
    $s .= pack("A2A2", @d{qw{state cc}});
    $s .= join("\0", @d{qw{ident comment facility city addr cross_road}});
    $s;
}

sub _pack_Wpt_data_D109_and_better {
    my $self = shift;
    my $d = shift;
    my %d = %$d;
    die "dtyp not set" if !exists $d{dtyp};
    $d{wpt_class} = 0 unless defined $d{wpt_class};
    $d{color} = 255 unless defined $d{color};
    $d{dspl} = 0 unless defined $d{dspl};
    $d{dspl_color} = ($d{color} & 0x1f) | (($d{dspl} & 0x3) << 5);
    $d{smbl} = 8246 unless defined $d{smbl};
    foreach my $key (qw(alt dpth dist)) {
	$d{$key} = 1.0e25 unless defined $d{$key};
    }
    foreach my $key (qw(state cc)) {
	$d{$key} = "  " unless defined $d{$key};
    }
    $d{ete} = 0xffffffff if !defined $d{ete};
    if ($d{datatype} eq 'D110') {
	$d{temp} = 1.0e25 unless defined $d{temp};
	$d{time} = 0xFFFFFFFF unless defined $d{time};
	$d{wpt_cat} = 0 unless defined $d{wpt_cat};
    }
    foreach my $key (qw(ident comment facility city addr cross_road)) {
	$d{$key} = "" unless defined $d{$key};
    }
    if ($d{ident} eq '') {
	die "ident not defined";
    }
    die "lat or lon not defined" if !defined $d{lat} || !defined $d{lon};
    my $s = pack("C4s", @d{qw{dtyp wpt_class dspl_color attr smbl}});
    $s .= chr(255)x18; # subclass
    $s .= pack("ll", $self->p->deg_semicirc($d{lat}), $self->p->deg_semicirc($d{lon}));
    $s .= pack("f3", @d{qw{alt dpth dist}});
    $s .= pack("A2A2", @d{qw{state cc}});
    $s .= pack("l", $d{ete});
    if ($d{datatype} eq 'D110') {
	$s .= pack("f", $d{temp});
	$s .= pack("l", $d{time});
	$s .= pack("s", $d{wpt_cat});
    }
    $s .= join("\0", @d{qw{ident comment facility city addr cross_road}});
    $s;
}

sub pack_Wpt_data_D109 {
    my($self, $d) = @_;
    my %d = %$d;
    $d{datatype} = "D109";
    $d{dtyp} = 1; # 0x1 for D109
    $d{attr} = 0x70;
    $self->_pack_Wpt_data_D109_and_better(\%d);
}

sub pack_Wpt_data_D110 {
    my($self, $d) = @_;
    my %d = %$d;
    $d{datatype} = "D110";
    $d{dtyp} = 1; # 0x1 for D110
    $d{attr} = 0x80;
    $self->_pack_Wpt_data_D109_and_better(\%d);
}

######################################################################
# Routes

sub Rte_hdr {
    my $self = shift;
    $self->p->{records}--;
    my ($data) = $self->p->read_packet;

    my %res;
    $res{nmbr} = unpack("C", substr($data,0,1,''));
    $res{cmnt} = unpack("Z*", $data);

    $self->p->send_packet(GRMN_ACK);

    if($self->p->{records} == 0) { $self->p->get_reply; }
    return %res;
}

sub pack_Rte_hdr {
    my $self = shift;
    my %d = %{$_[0]};
    die "Please specify route number" if !defined $d{nmbr};
    $d{cmnt} = "" if !defined $d{cmnt};
    # D201
    my $s = pack("C", $d{nmbr});
    $s .= pack("a20", $d{cmnt});
    $s;
}

sub Rte_wpt_data {
    my $self = shift;
    $self->Wpt_data;
}

sub pack_Rte_wpt_data {
    my $self = shift;
    $self->pack_Wpt_data(@_);
}

sub Rte_link_data {
    my $self = shift;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;

    my %res;
    $res{class} = unpack("s", substr($data,0,2,''));
    $res{subclass} = unpack("a18", substr($data,0,18,''));
    $res{ident} = $data;

    $p->send_packet(GRMN_ACK);

    if($p->{records} == 0) { $p->get_reply; }
    return %res;
}

sub pack_Rte_link_data {
    my $self = shift;
    my $d = shift || {};
    my %d = %$d;
    $d{class} = 0 unless defined $d{class};
    $d{subclass} = ("\0"x6).("\xff"x12) unless defined $d{subclass};
    $d{ident} = "" unless defined $d{ident};
    # D210
    my $s = pack("s", $d{class});
    $s .= pack("a18", $d{subclass});
    $s .= substr($d{ident},0,50)."\0" if $d{ident} ne "";
    $s;
}

######################################################################
# Almanac

# XXX use return_as_hash
sub Almanac_data {
    my $self = shift;
    $self->p->{records}--;
    my ($data) = $self->p->read_packet;
    my (@ident,@comm,$lt,$ln);

    #D501 Almanac Datatype
    my($wn,$toa,$af0,$af1,$e,$sqrta,$m0,$w,$omg0,$odot,$i,$htlh) =
	unpack('sf10c',$data);

    $self->p->send_packet(GRMN_ACK);
    if($self->p->{records} == 0) { $self->p->get_reply; }
    return($wn,$toa,$af0,$af1,$e,$sqrta,$m0,$w,$omg0,$odot,$i,$htlh);
}

######################################################################
# Tracks

sub Trk_hdr_D310 {
    my $self = shift;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;

    my %res;
    $res{dspl}      = unpack("c", substr($data,0,1));
    $res{color}     = unpack("C", substr($data,1,1));
    $res{trk_ident} = unpack("Z*", substr($data,2));

    $p->send_packet(GRMN_ACK);
    if ($p->{records} == 0) { $p->get_reply }
    return %res;
}

sub Trk_data_D300 {
    my $self = shift;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;
    my (@ident,@comm,$lt,$ln);

    #D300 Track Point Datatype
    my ($lat,$lon,$time,$is_first) = unpack('llLb',$data);
    $lat = $p->semicirc_deg($lat);
    $lon = $p->semicirc_deg($lon);
    $time += GRMN_UTC_DIFF;

    $p->send_packet(GRMN_ACK);
    if($p->{records} == 0) { $p->get_reply; }
    if ($p->{return_as_hash}) {
	(lat  => $lat,
	 lon  => $lon,
	 time => $time,
	);
    } else {
	($lat, $lon, $time);
    }
}

sub Trk_data_D301 {
    my $self = shift;
    my $p = $self->p;
    $p->{records}--;
    my ($data) = $p->read_packet;
    my (@ident,@comm,$lt,$ln);

    # D301 Track Point Datatype
    my ($lat,$lon,$time,$alt,$dpth,$new_trk) = unpack('llLffb',$data);
    $lat = $p->semicirc_deg($lat);
    $lon = $p->semicirc_deg($lon);
    if ($time == 0xffffffff) { # XXX check
	undef $time;
    } else {
	$time += GRMN_UTC_DIFF;
    }
    if ($dpth >= UNDEF_FLOAT) { $dpth = undef }
    if ($alt  >= UNDEF_FLOAT) { $alt = undef }

    $p->send_packet(GRMN_ACK);
    if ($p->{records} == 0) { $p->get_reply }

    if ($p->{return_as_hash}) {
	(lat     => $lat,
	 lon     => $lon,
	 time    => $time,
	 alt     => $alt,
	 dpth    => $dpth,
	 new_trk => $new_trk,
	);
    } else {
	($lat, $lon, $time, $alt, $dpth, $new_trk);
    }
}

sub pack_Trk_data_D301 {
    my $self = shift;
    my $d = shift;
    my %d = %$d;
    foreach my $key (qw(alt dpth)) {
	$d{$key} = 1.0e25 unless defined $d{$key};
    }
    $d{first} = 0 unless defined $d{first};
    $d{time} = time + GRMN_UTC_DIFF unless defined $d{time};
    die "lat or lon not defined" if !defined $d{lat} || !defined $d{lon};
    my $s = pack("ll", $self->p->deg_semicirc($d{lat}), $self->p->deg_semicirc($d{lon}));
    $s .= pack('Lffb', $d{time}, $d{alt}, $d{dpth}, $d{first});
    $s;
}

sub pack_Trk_hdr_D310 {
    my $self = shift;
    my $d = shift || {};
    my %d = %$d;
    $d{dspl} = 0 unless defined $d{dspl};
    $d{color} = 255 unless defined $d{color};
    if (!defined $d{ident}) {
	die "ident is required";
    }
    # D310
    my $s = pack("cC", $d{dspl}, $d{color});
    $s .= $d{ident}."\0";
    $s;
}

######################################################################

sub Xfer_cmplt {
    my $self = shift;
    delete $self->p->{records};
    delete $self->p->{cur_pid};
    delete $self->p->{cur_request};
    return(1);
}

#Position from the GPS
sub Position_data {
    my $self = shift;
    my ($lat,$lon,$ltcord,$lncord);

    my ($data) = $self->p->read_packet;


    $lat = substr($data,0,8);
    $lon = substr($data,8,8);


    $lat = rad2deg(unpack("d*",$lat));

    $lon = rad2deg(unpack("d*",$lon));

    $ltcord = "N";$ltcord = "S" if $lat < 0;
    $lncord = "E";$lncord = "W" if $lon < 0;
    $lat = abs($lat);$lon = abs($lon);
    $lat = int($lat)+($lat - int($lat))*60/100;
    $lon = int($lon)+($lon - int($lon))*60/100;

    $self->p->send_packet(GRMN_ACK);
    return($ltcord,$lat,$lncord,$lon);

}


sub Date_time_data {
    my $self = shift;
    my(@date);

    my $data = $self->p->safe_read;

    for(my $i=0;$i < 8;$i++) {
	$data = $self->p->safe_read;

	if ($i == 2 || $i == 3) {
	    $date[2] .= $data;next;
	}

	$date[$i] = ord $data;
	$date[$i] =~ s/(\d)/0$1/ if length($date[$i]) == 1;
    }

    $date[2] = unpack("s*",$date[2]);
    return ($date[7],$date[6],$date[4],$date[1],$date[0],$date[2],1);
}

sub Records {

    my ($self,$command) = @_;
    my ($numrec,$buf,$len);

    $buf = $self->p->safe_read;

    for (my $i=0;$i<2;$i++) {
	$self->p->usleep(5);
	$numrec .= $self->p->safe_read;
    }

    $buf = $self->p->_read(3);
    $numrec = unpack("S*",$numrec);

    $self->p->send_packet(GRMN_ACK);
    $self->p->{records} = $numrec;
    return $numrec;
}

######################################################################

package GPS::Garmin::Handler::Generic;
use vars qw(@ISA);
@ISA = qw(GPS::Garmin::Handler);

sub Wpt_data { shift->Wpt_data_D103(@_) }
sub Trk_data { shift->Trk_data_D300(@_) }
sub pack_Wpt_data { shift->pack_Wpt_data_D103(@_) }
sub pack_Trk_data { shift->pack_Trk_data_D300(@_) }

######################################################################

package GPS::Garmin::Handler::EtrexVenture;
use vars qw(@ISA);
@ISA = qw(GPS::Garmin::Handler);

sub Wpt_data { shift->Wpt_data_D108(@_) }
sub Trk_data { shift->Trk_data_D301(@_) }
sub Trk_hdr  { shift->Trk_hdr_D310(@_) }
sub pack_Wpt_data { shift->pack_Wpt_data_D108(@_) }
sub pack_Trk_data { shift->pack_Trk_data_D301(@_) }
sub pack_Trk_hdr { shift->pack_Trk_hdr_D310(@_) }

######################################################################

package GPS::Garmin::Handler::EtrexVistaHCx;
use vars qw(@ISA);
@ISA = qw(GPS::Garmin::Handler);

sub Wpt_data { shift->Wpt_data_D110(@_) }
sub Trk_data { shift->Trk_data_D301(@_) }
sub Trk_hdr  { shift->Trk_hdr_D310(@_) }
sub pack_Wpt_data { shift->pack_Wpt_data_D110(@_) }
sub pack_Trk_data { shift->pack_Trk_data_D301(@_) }
sub pack_Trk_hdr { shift->pack_Trk_hdr_D310(@_) }

1;


__END__

=head1 NAME

GPS::Garmin::Handler - Handlers to Garmin data

=head1 SYNOPSIS

  use GPS::Garmin::Handler;


=head1 DESCRIPTION

    Used internally

=over

=head1 AUTHOR

Joao Pedro B Gonçalves , joaop@sl.pt

=head1 SEE ALSO

Peter Bennett's GPS www and ftp directory:

	ftp://sundae.triumf.ca/pub/peter/index.html.
	http://vancouver-webpages.com/peter/idx_garmin.html

Official Garmin Communication Protocol Reference

	http://www.garmin.com/support/protocol.html

=cut
