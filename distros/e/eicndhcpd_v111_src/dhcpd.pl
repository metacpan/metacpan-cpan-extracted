#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# DHCPD.PL part
# -----------------------------------------------------------------------------
# EICNDHCPD is a static DHCP server for NT4.
# "static" because each computer is identified by his MAC address
# (ethernet addr.) and obtains the same configuration (IP addr., ...) all time.
# All the host configuration is centralized in a text file (netdata.dat).
#
# Made by Nils Reichen <eicndhcpd@worldcom.ch>
# EICN, NEUCHATEL SCHOOL OF ENGINEERING
# Le Locle, Switzerland
#
# under Perl 5.004_02 for WinNT4.0
# (c)1998,1999 Copyright EICN & Nils Reichen <eicndhcpd@worldcom.ch>
# 
# Use under GNU General Public License
# Details can be found at:http://www.gnu.org/copyleft/gpl.html
#
#$Header: dhcpd.pl,v 1.11 1999/06/27
# -----------------------------------------------------------------------------
# v0.9b Created: 19.May.1998 - Created by Nils Reichen <eicndhcpd@worldcom.ch>
# v0.901b Revised: 26.May.1998 - Renew bug solved, and optimized code
# v0.902b Revised: 04.Jun.1998 - EventLog and Service NT
# v1.0 Revised: 18.Jun.1998 - Fix some little bugs (inet_aton,...)
# v1.1 Revised: 07.Oct.1998 - Fix \x0a bug
# v1.11 Revised: 27.June.1999 - Fix a problem with particular MS DHCP client
$ver      = "v1.11";
$ver_date = "27.June.1999";
# -----------------------------------------------------------------------------

use Dhcpd;           # Dhcpd module: define some constant for EICN DHCPD
use Socket;          # Socket module: for the IP connection
use Win32;           # Win32 module: to check if the OS is Windows NT
use Win32::Service;  # Win32::Service module: to start/stop/status of services
use Win32::Process;  # Win32::Process module: to start pocesses
use Win32::EventLog; # Win32::EventLog module: for creating events messages

# Open dhcpd.log
unless(open(LOG,">>.\\log\\dhcpd.log")){
    warn "Cannot open .\\log\\dhcpd.log: $!";
    &SendEvent(5,EVENTLOG_ERROR_TYPE);
    goto END;
}
close(LOG);

# Check if netdata.dat file exist:
unless(-e "netdata.dat"){
    warn "Cannot open netdata.dat: $!";
    &SendEvent(4,EVENTLOG_ERROR_TYPE);
    goto END;
}

unless(Win32::IsWinNT()){ # if don't run under Win NT
    open(LOG,">>.\\log\\dhcpd.log") || die "Cannot open .\\log\\dhcpd.log: $!";
    print LOG "\n\nThis programm must be run under Windows NT(TM)\n\n";
    print LOG "EICNDHCPD stoped !\n";
    close(LOG);
    goto END;
}

###############################################################################
#
# Create a second process for analysed the frame and respond
#
pipe(READ, WRITE); # create interprocess pipe for data transfert
select(WRITE);     # select STDOUT for next apply $|=1
$|=1;              # unbufferise WRITE
select(STDOUT);    # select the default output handle
open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";     # save STDIN
open(STDIN, "< &READ")    ||  warn "Can not redirect STDIN\n"; # redirect STDIN
select(STDIN);     # select STDIN for next apply $|=1
$| = 1;            # unbufferise STDIN => unbufferise READ 
select(STDOUT);    # select the default output handle
  Win32::Process::Create($Process,
 			"c:\\perl\\bin\\perl.exe",
 			"c:\\perl\\bin\\perl.exe c:\\dhcpd\\dhcpd2.pl",
 			1,
 			NORMAL_PRIORITY_CLASS,
 			"c:\\dhcpd");
open(STDIN, "< &SAVEIN");    # restore STDIN
close(SAVEIN);
unless($Process){ # Error, no second process
    &SendEvent(6,EVENTLOG_ERROR_TYPE);
    goto END;
}

###############################################################################
#
# Listen to the port 67 (DHCP server port)
#
# Var:
#     $paddr_c     : packed client IP address
#     $frame       : recieved frame in hex.
#     $recv_time   : time when recieving the frame
#     $port_c      : from witch port client frame has been sent
#     $iaddr_c     : client IP address
#     $op          : 'op' field of the frame
#     $htype       : 'htype' field of the frame
#     $hlen        : 'hlen' field of the frame
#     $cookie      : cookie part of 'options' field of the frame
#     $bootp       : for checking if frame is a BOOTP frame
#     $proto       : used protocol
#
my($paddr_c,$frame,$recv_time,$port_c,$iaddr_c);
my($op,$htype,$hlen,$cookie,$bootp);
my $proto=getprotobyname("udp"); # select the transfert protocol

# create socket:
socket(SOCK,PF_INET,SOCK_DGRAM,$proto) || warn "socket error: $!";
# set socket options 
# (SO_REUSEADDR : reuse IP addr. before last connection has been closed)
setsockopt(SOCK, SOL_SOCKET, SO_REUSEADDR,1) || warn "setsockopt error: $!";
# bind socket ( attach address to the socket
bind(SOCK,sockaddr_in($SERVER_PORT, INADDR_ANY)) || warn "bind error: $!";

while(1){
    $paddr_c=recv(SOCK,$frame,1500,0);    # recieve frame from socket
    $recv_time=time;                      # time in seconde from 1/1/1970
    ($port_c,$iaddr_c)=sockaddr_in($paddr_c);
    ($op)=($frame=~ /^(.)/s);             # get the 'op' field
    ($htype)=($frame=~ /^.(.)/s);         # get the 'htype' field
    ($hlen)=($frame=~ /^..(.)/s);         # get the 'hlen' field
    ($cookie)=($frame=~ /^.{236}(....)/s);# get the magic cookie
    ($bootp)=($frame=~ /^.{240}(.)/s);    # get the first option (after cookie)
    next if($op eq "\x02");               # ignore if it is a BOOTREPLY
    next if($cookie ne $MAGIC_COOKIE);    # ignore if it isn't a valid frame
    next if($bootp eq "\xff");            # ignore if it is a BOOTP frame
    # Ignore if network isn't a Ethernet network:
    if(($hlen ne "\x06")||($htype ne "\x01")){
	($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
	unless(open(LOG,">>.\\log\\dhcpd.log")){
	    &SendEvent(5,EVENTLOG_ERROR_TYPE);
	    warn "Cannot open .\\log\\dhcpd.log: $!";
	    goto END;
	}
	print LOG "$time DHCPREQUEST FOR A NETWORK OTHER THAN ETHERNET!\n";
	close(LOG);
	next;
    }
    # Send var to the second process (dhcpd2.pl) by the pipe:
    print WRITE $recv_time,"\n"; 
    print WRITE $port_c,"\n";
    # convert from char. to hex. form unless problem with "\n":
    # (for example "A" => "41")
    print WRITE unpack("H8",$iaddr_c),"\n"; 
    print WRITE unpack("H*",$frame),"\n";
}


###############################################################################
# 
# End of dhcpd.pl
#
END:
{
    close(SOCK) || warn "close error: $!";
    close(WRITE);
    close(READ);
    open(LOG,">>.\\log\\dhcpd.log") || die "Cannot open .\\log\\dhcpd.log: $!";
    ($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);    # local time
    print LOG "\n$time STOPING EICNDHCPD SERVICE....\n\n";
    print LOG "\n\n$time DHCPD STOPED !\n\n\n";
    close(LOG);
  Win32::Service::StopService('','EICNDHCPD');
}



###############################################################################
#
# Subroutines
#

sub SendEvent{
    my($msg_eventid,$msg_eventtype)=@_; # get arguments 
    my $EventLog;
    my %event=(
	       'EventID',$msg_eventid,
	       'EventType',$msg_eventtype,
	       'Category',NULL,
	       );
    $EventLog=new Win32::EventLog("EICNDHCPD") || warn $!;
    $EventLog->Report(\%event)||warn $!; # Add a event to the EventLog
}

