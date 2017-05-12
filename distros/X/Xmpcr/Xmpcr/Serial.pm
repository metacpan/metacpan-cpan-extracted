# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Audio::Xmpcr::Serial
# Copyright Paul Bournival 2003
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

package Audio::Xmpcr::Serial;

$VERSION="1.02";

use strict;
use Device::SerialPort;
use bytes;


sub new {
  my($class,$port)=@_;
  my $self={};
	$self->{port}=$port;	
	$self->{sdev} = new Device::SerialPort ("$self->{port}")
           || die "Can't open USB Port! ($self->{port} $!\n";
  $self->{sdev}->baudrate(9600);
  $self->{sdev}->parity('none');
  $self->{sdev}->databits(8);
  $self->{sdev}->stopbits(1);

	$self->{_state}={
		power => 0,	     
		channel => 0,
		radioId => "",
		channels => [],
	};

	bless $self,$class;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# a general send/receive method.
# if called in a scalar context, returns STATUS: undef=success || errmsg=failed
# if called in an array context, returns (STATUS (above),PORTREADSTR)
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub _doop {
	my($self,$op,$cmd,$wcnt,$rcnt)=@_;
	my($readstr,$retval,$cnt)=("",undef,0);
	return("$op: Power isn't on!")
					if $cmd ne "5AA500050010101001EDED" and ! $self->{_state}{power};
	$self->{sdev}->write(pack("H*",$cmd));
  $self->{sdev}->read_const_time($wcnt) if defined $wcnt;
	if ($rcnt) {
		while($cnt<$rcnt) {
			($cnt,$readstr)=$self->{sdev}->read($rcnt);
			$readstr=join("",unpack("H*",$readstr));
		}
		$retval=substr($readstr,0,6) eq "5aa500" ? undef : "$op failed";
		$self->{_state}{radioId}=pack("H*",substr($readstr, 46, 16))
																	if $cmd eq "5AA500050010101001EDED";
	}
	wantarray ? ($retval,$readstr) : $retval;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# turn on/off power
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub power {
  my($self,$status)=@_;
	defined($status) || die "power called improperly\n";
	my $res=$status eq "on" ?
		$self->_doop("power on","5AA500050010101001EDED",100,40) :
		$self->_doop("power off","5AA500020100EDED",0,0);

	$self->{_state}{power}=($status eq "on" ? 1 : 0) if ! $res;

	# if powering up, load the channels from the device.
	if ($status eq "on" and ! $res) {
		sleep(8);
		$self->_buildChannelList;
		$self->setchannel(1);
	}
	$res;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# turn on/off mute
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub mute {
  my($self,$status)=@_;
	defined($status) || die "mute called improperly\n";
	$self->_doop("mute $status",$status eq "on" ?
					"5AA500021301EDED" : "5AA500021300EDED", 0,10);
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# change channel
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub setchannel {
  my($self,$chan)=@_;
	defined($chan) || die "setchannel called improperly\n";
	$self->{_state}{channel}=$chan;
	$self->_doop("setchannel $chan",
			"5AA500061002@{[sprintf('%02X',$chan)]}000001EDED",3000,12);
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# list 1 or all channels
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub list {
  my($self,$chan)=@_;
  my(@ret,$err,$res);
	my @ch=$chan ? ($chan) : @{ $self->{_state}{channels} };
	for my $ch (@ch) {
		($err,$res)=$self->_doop("channel $ch info",
			"5AA500042508@{[sprintf('%02X',$ch)]}00EDED",100,83);
		last if $err;
		push(@ret,{
			NUM => $ch,
			NAME => $self->_prune(pack("H*", substr($res, 20, 32))),
			CAT => $self->_prune(pack("H*", substr($res, 52, 32))),
			ARTIST => $self->_prune(pack("H*", substr($res, 88, 32))),
			SONG => $self->_prune(pack("H*", substr($res, 122, 32))),
		});
	}
	$chan ? $ret[0] : @ret;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# remove extra spaces and control characters
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub _prune {
	my($self,$str)=@_;
	$str =~ s/[^[:graph:] ]//gs;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s#/#-#g;   # embedded forward slashes - yuk!
	$str;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# builds a list of channels on the radio
# this should probably write the list to a file somewhere...
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# to be used at power up only!!!
sub _buildChannelList {
  my($self)=@_;
  my($ch,$lasterr,$res)=("00",undef);
# NOTE: PAULB GET RID OF ME LATER! - for debugging only!!!!!!!!!!!!
#	$self->{_state}{channels}=[1,4,5,6,7,8,9,10,11,12,13,14,15,20,21,22,23,24,25,26,27,28,29,30,31,32,40,41,42,43,44,45,46,47,48,50,51,52,60,61,62,63,64,65,66,67,70,71,72,73,74,75,76,80,81,82,83,90,91,92,93,94,100,101,102,103,104,110,112,113,115,116,121,122,123,124,125,127,129,130,131,132,134,140,141,142,143,144,150,151,152,161,162,163,164,165,166,168,169,170,171];
#return;
	$self->{_state}{channels}=[];

  # build a cache file if none is present
  if (! -f "$ENV{HOME}/.xmpcrd-cache") {
    open(F,">$ENV{HOME}/.xmpcrd-cache") or die "Can't write cache file: $!";
	  while(1) {
	 		($lasterr,$res)=$self->_doop("channel $ch info",
																		"5AA500042509${ch}00EDED",100,83);
			$ch=substr($res,14,2);
			last if $ch eq "00" or $lasterr;
      print F hex($ch) . "\n";
	  }
    close(F);
  }

  my($line);
  open(F,"$ENV{HOME}/.xmpcrd-cache") or die "Can't read cache file: $!";
  while($line=<F>) {
    chop $line;
		push(@{ $self->{_state}{channels} },$line);
  }
  close(F);
  
	$lasterr;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# obtain general radio status
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub status {
  my($self)=@_;
	
	my %cur;
	if ($self->{_state}{power}) {
		%cur=%{ $self->list($self->{_state}{channel}) };
		$cur{RADIOID}= $self->{_state}{radioId};
 		my($err,$ti)=$self->_doop("tech info","5AA5000143EDED",100,32);
		$cur{ANTENNA}=int(1+(substr($ti, 16,2) || 0)*33.3);
	}
	$cur{POWER}=$self->{_state}{power} ? "on" : "off";
	%cur;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# event support (i.e., song changing)
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub events {
	die "Whoops! events aren't supported on the serial interface!\n";
}
sub processEvents {
	die "Whoops! events aren't supported on the serial interface!\n";
}
sub eventFd {
	die "Whoops! events aren't supported on the serial interface!\n";
}
sub forcelock {
	die "Whoops! locks aren't supported on the serial interface!\n";
}



1;
