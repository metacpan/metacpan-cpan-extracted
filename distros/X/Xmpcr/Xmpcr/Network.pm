# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Audio::Xmpcr::Network
# Copyright Paul Bournival 2003
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  
package Audio::Xmpcr::Network;

$VERSION="1.02";

use strict;
use IO::Socket::INET;

sub new {
  my($class,$host,$port,$locker)=@_;
	$port ||= 32463;
  my $self={};

	$self->{s}=new IO::Socket::INET(PeerAddr => "$host:$port")
    or die "Can't contact xmdaemon: $!!\n";
  bless $self,$class;

	$self->_doop("appname $locker") if $locker;

	$self->{queuedEvents}=[];
	$self;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# turn on/off power
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub power {
	my($self,$status)=@_;
	die "Xmpcr::power: incorrect parameters" if ! $status;
  my @ret=$self->_doop($status);
	scalar(@ret)==0 ? undef : $ret[0];
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# turn on/off mute
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub mute {
	my($self,$status)=@_;
	die "Xmpcr::mute: incorrect parameters"  if ! $status;
  my @ret=$self->_doop("mute $status");
	scalar(@ret)==0 ? undef : $ret[0];
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# change channel
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub setchannel {
	my($self,$chan)=@_;
	die "Xmpcr::setchannel: incorrect parameters" if ! $chan;
  my @ret=$self->_doop("channel $chan");
	scalar(@ret)==0 ? undef : $ret[0];
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# force the lock
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub forcelock {
  my($self)=@_;
  my @ret=$self->_doop("forcelock");
	scalar(@ret)==0 ? undef : $ret[0];
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# list 1 or all channels
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub list {
	my($self,$chan)=@_;
	my @list=$self->_doop("list" . ($chan ? " $chan" : ""));
	my @ret;
	for my $line (@list) {
		push(@ret,$self->_hashifySongEntry($line));
	}
	$chan ? $ret[0] : @ret;	
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# splits a tab-delimited entry into a hash
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub _hashifySongEntry {
  my($self,$line)=@_;
	my(@e)=split("\t",$line);
	{
		NUM => $e[0] || 0,
		NAME => $e[1] || "",
		CAT => $e[2] || "",
		SONG => $e[3] || "",
		ARTIST => $e[4] || "",
	};
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# obtain general radio status
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub status {
	my($self)=@_;
	my %ret;
  map {
		my($k,$v)=split("\t",$_);
		$ret{$k}=$v;
	} $self->_doop("status");
	%ret;
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# event support (i.e., song changing)
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub events {
	my($self,$status)=@_;
	die "Xmpcr::mute: incorrect parameters"  if ! $status;
  my @ret=$self->_doop("events $status");
	scalar(@ret)==0 ? undef : $ret[0];
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# find out which channels have changed songs
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub processEvents {
	my($self)=@_;
	my($rin,$buf)="";
	my @events=@{ $self->{queuedEvents} };
	$self->{queuedEvents}=[];
	vec($rin,fileno($self->{s}),1)=1;
	if (select($rin,undef,undef,.05)) {
		sysread($self->{s},$buf,16000);
		if ($buf) {
			map {
				s/^\+\t//;
				push(@events,$_);
			} split("\n",$buf);
		}
	}
	map {
		$_=$self->_hashifySongEntry($_);
	} @events;
	@events;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# return the server socket FD for select() calls
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub eventFd {
	my($self)=@_;
	return fileno($self->{s});
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# a general send/receive method.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sub _doop {
  my($self,$cmd)=@_;
  my($ret,@ret)=("");
  syswrite($self->{s},$cmd . "\n") if $cmd;

	my($rin,$rout)="";
	vec($rin,fileno($self->{s}),1)=1;
 	while(1) {
 		my $buf;
 		sysread($self->{s},$buf,1024);
 		$ret .= $buf;
 		last if ! $buf or $ret =~ /Ready\n$/;
	}
	for my $line (split("\n",$ret)) {
		if ($line =~ /^\+/) {
			push(@{ $self->{queuedEvents} },$line) ;
		} elsif ($line eq "Ready") {
		} else {
			push(@ret,$line);
		}
	}
	@ret;
}

1;
