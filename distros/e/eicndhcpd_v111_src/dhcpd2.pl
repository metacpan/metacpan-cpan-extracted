#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.htm
# DHCPD2.PL part
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
#$Header: dhcpd2.pl,v 1.11 1999/06/27
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
use File::Copy;      # File::Copy module: for files copy
use Win32::Service;  # Win32::Service module: to start/stop/status of services
use Win32::Process;  # Win32::Process module: to start pocesses
use Win32::EventLog; # Win32::EventLog module: for creating events messages

my $max_size_debug=200000;  # max size of debug.log in bytes

# Open dhcpd.log (second check for security):
unless(open(LOG,">>.\\log\\dhcpd.log")){
    warn "Cannot open .\\log\\dhcpd.log: $!";
    &SendEvent(5,EVENTLOG_ERROR_TYPE);
    goto END;
}

# Check if netdata.dat file exist (second check for security):
unless(-e "netdata.dat"){
    warn "Cannot open netdata.dat: $!";
    &SendEvent(4,EVENTLOG_ERROR_TYPE);
    goto END;
}


###############################################################################
#
# Download the configuration from the dhcpd.conf file
#
# Var:
#     $debug        : level 0/1  of debuging informations in debug.log
#     $hard_debug   : level 2 of debugging informations in debug.log
#     $mail_mac     : Enable/Disable E-Mail when there is a problem with 
#                     IP allocution
#     $mail_log     : E/D E-Mail (if $log2bak==0) when dhcpd.log is over
#                     maximum size ($log_size)
#     $log2bak      : ==0 rename dhcpd.log to dhcpd_log.bak 
#                         (overwrite if already exit)
#                     ==1 rename dhcpd.log to dhcpd_log.bak001,
#                         dhcpd_log.bak002, ...
#     $log_size     : maximum size of dhcpd.log (in byte)
#     $smtp_server  : name of the STMP (mail) server
#     $admin_mail   : E-Mails addresses of administators
#     $server_ip    : IP address of DHCP server
#     $b_ipaddr     : DHCP broadcast IP address
#     $time         : local time
#     $frame_ttl    : frame time to live in buffer (pipe) between dhcpd1.pl
#                     and dhcpd2.pl
#     $force_netm   : force the server to send subnet mask option (nr. 1)
#     $focre_router : force the server to send router option (nr. 3)
#
my ($debug,$hard_debug,$mail_mac,$mail_log,$log2bak,$log_size,$smtp_server,
    $admin_mail,$server_ip,$b_ipaddr,$time,$frame_ttl,$force_netm,
    $force_router);

# Open dhcpd.conf:
unless(open(CONF,"<dhcpd.conf")){
    warn "Cannot open dhcpd.conf: $!";
    &SendEvent(3,EVENTLOG_ERROR_TYPE);
    goto END;
}

# Get configuration from dhcpd.conf:
while(<CONF>){
    next if($_=~/^\#\s/);
    if($_=~/^DEBUG\s/){
	($debug)=($_=~/^.{6}(\d)/);
	$hard_debug=1 if($debug==2);
    }
    elsif($_=~ /^SMTP\sMAIL\sMAC\s/){
	($mail_mac)=($_=~/^.{14}(\d)/);
    }
    elsif($_=~/^SMTP\sMAIL\sLOG\s/){
	($mail_log)=($_=~/^.{14}(\d)/);
    }
    elsif($_=~/^SMTP\sSERVER\s/){
	($smtp_server)=($_=~/^.{12}(\S+)/);
    }
    elsif($_=~/^ADMIN\sMAIL\s/){
	($admin_mail)=($_=~/^.{11}(\S+)/);
    }
    elsif($_=~/^DHCPD\.LOG\sMAX\sSIZE\s/){
	($log_size)=($_=~/^.{19}(\d+)/);
    }
    elsif($_=~/^DHCPD\.LOG\sTO\sBAK\s/){
	($log2bak)=($_=~/^.{17}(\d+)/);
    }
    elsif($_=~/^SERVER\sIP\sADDRESS\s/){
	($server_ip)=($_=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
	$server_ip=pack('C4',($server_ip=~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)) if($server_ip);
    }
    elsif($_=~/^BROADCAST\sIP\sADDRESS\s/){
	($b_ipaddr)=($_=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
	$b_ipaddr=inet_aton($b_ipaddr) if($b_ipaddr);
    }
    elsif($_=~/^FRAME\sTTL\s/){
	($frame_ttl)=($_=~/^.{10}(\d)/);
    }
    elsif($_=~/^FORCE\sNETMASK\s/){
	($force_netm)=($_=~/^.{14}(\d)/);
    }
    elsif($_=~/^FORCE\sROUTER\s/){
	($force_router)=($_=~/^.{13}(\d)/);
    }
}
close(CONF);
# set minimum size for dhcpd.log to 10000 bytes:
$log_size=10000 if(($log_size<10000)or($log_size eq ""));
$frame_ttl=2 if(($frame_ttl==0)or($frame_ttl==""));    # def. frame ttl: 2 sec.
unless($b_ipaddr){ # set default DHCP broadcast IP address 
    $b_ipaddr=255.255.255.255;
    $b_ipaddr=inet_aton($b_ipaddr); # convert to 4 bytes format
}
# disable E-Mail if E-Mail address or smtp server name is invalid:
if(($mail_log or $mail_mac)and(($smtp_server eq "")or($admin_mail eq "")or(!($admin_mail=~ /\S+\@\S+/))))
{
    $mail_log=0;$mail_mac=0;
    unless(open(LOG,">>.\\log\\dhcpd.log")){
	warn "Cannot open .\\log\\dhcpd.log: $!";
	&SendEvent(5,EVENTLOG_ERROR_TYPE);
	goto END;
    }
    print LOG "\n\nINVALID DHCPD.CONF: SMTP SERVER or ADMIN MAIL error !";
    print LOG "\n\nE-MAIL DESACTIVED !\n\n\n";
    close(LOG);
}

# stop dhcpd if the server IP address is invalid:
if(($server_ip eq "")||(inet_ntoa($server_ip)=~/255/)||
   (inet_ntoa($server_ip)=~/\.0$/))
{
    ($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
    unless(open(LOG,">>.\\log\\dhcpd.log")){
	warn "Cannot open .\\log\\dhcpd.log: $!";
	&SendEvent(5,EVENTLOG_ERROR_TYPE);
	goto END;
    }
    print LOG "\n\nERROR IN DHCPD.CONF: invalid SERVER IP ADDRESS !";
    print LOG "\n\n$time DHCPD WILL BE STOPED !\n\n\n";
    close(LOG);
    &SendEvent(2,EVENTLOG_ERROR_TYPE);
    goto END;         # END OF DHCPD !
}

    
###############################################################################
#
# Check size of dhcpd.log & debug.log
#
my $size=-s ".\\log\\dhcpd.log";  # get the size of dhcpd.log in byte
&Log_backup if($size>=$log_size); # backup dhcpd.log to .bak
    
if($debug){
    open(DEBUG,">>.\\log\\debug.log")||
	warn "Cannot open .\\log\\debug.log: $!";
    my $size=-s ".\\log\\debug.log";       # size of .\\log\\debug.log in byte
    if($size>=$max_size_debug){
	close(DEBUG);
	unlink(".\\log\\debug_log.bak");   # Remove debug_log.bak
	# backup debug.log file to debug_log.bak:
	copy(".\\log\\debug.log",".\\log\\debug_log.bak")||
	    warn "rename: $!";  
	open(DEBUG,">.\\log\\debug.log")||
	    warn "Cannot open .\\log\\debug.log: $!";
	print DEBUG "\nDEBUG.LOG > ",$max_size_debug,
	      " bytes => backup in debug_log.bak !\n\n";
    }
}

###############################################################################
#
# Creating dhcpd3.pl process
#	
pipe(READ2, WRITE2);  # create interprocess pipe for data transfert
select(WRITE2);       # select STDOUT for next apply $|=1
$|=1;                 # unbufferise WRITE2
select(STDOUT);       # select the default output handle
open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";     # save STDIN
open(STDIN, "< &READ2")   ||  warn "Can not redirect STDIN\n"; # redirect STDIN
select(STDIN);        # select STDIN for next apply $|=1
$| = 1;               # unbufferise STDIN => unbufferise READ 
select(STDOUT);       # select the default output handle
 Win32::Process::Create($Mailprocess,
			"c:\\perl\\bin\\perl.exe",
			"c:\\perl\\bin\\perl.exe c:\\dhcpd\\dhcpd3.pl",
			1,
			NORMAL_PRIORITY_CLASS,
			"c:\\dhcpd");
open(STDIN, "< &SAVEIN");    # restore STDIN
close(SAVEIN);
print WRITE2 "$$\n";         # send to dhcpd3.pl the PID ($$) of this script
close(WRITE2);
close(READ2);

###############################################################################
#
# Read the frames from the pipe and answer
#
# Var:
#    $paddr_c         : packed client IP address
#    $frame           : recieved frame in hex.
#    $recv_time       : time when dhcpd1.pl recieved the frame
#    $now             : time when this script read the frame from the pipe
#    $port_c          : from witch port client frame has been sent
#    $iaddr_c         : client IP address
#    $proto           : used protocol
#    $nr_frame        : counter for the size check of log files
#
# for recieved frame
#    $option          : 'code' field of DHCP option (option number in hex.)
#    $o_len           : 'len' field of DHCP option (length of DHCP option)
#    $o_contens       : contens of DHCP option
#    $i               : postion in frame
#                       (analyse from first bytes ('op') to last (End option)
#    $hlen            : 'hlen' field
#    $xid             : 'xid' field
#    $flags           : 'flags' field
#    $ciaddr          : 'ciaddr' field
#    $giaddr          : 'giaddr' field
#    $p_chaddr        : 'chaddr' field (16 bytes)
#    $hlen_d          : $hlen in dec. (hardware address length)
#    $chaddr          : only $hlen_d length of 'p_chaddr'
#    $chaddr_c        : $chaddr in ASCII (0000f8308010 form)
#    $chaddr_txt      : ASCII form of $chaddr with "-" (00-00-f8-30-80-10 form)
#    $msg_type        : DHCP message type
#    $p_requested_ip  : requested IP address in 4 bytes form
#    $requested_ip    : requested IP address (172.16.1.1 form)
#    $server_id       : server ID (DHCP server IP address in 4 bytes form)
#    $client_hostname : host name of the client (ASCII)
#    $requested_param : parameter request list
#    $vendor_spec     : vendor specific information
#    $dhcp_message    : message (in NAK and DECLINE frames)
#    $f_netm          : force server to send netmask option
#                       reinit with $force_netm for each frame
#    $f_router        : force server to send router option
#                       reinit with $force_router for each frame
#
my($paddr_c,$frame,$recv_time,$now,$port_c,$iaddr_c);
my $proto=getprotobyname("udp"); # select the transfert protocol
my $nr_frame=0;    
my($option,$o_len,$o_contens,$i);

($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);   # get the local time
print LOG "\n$time Start of DHCP server\n\n";
print DEBUG "\n$time Start of DHCP server\n" if($debug);
&SendEvent(1,EVENTLOG_INFORMATION_TYPE);              # Send start up event

if($debug){
    select(DEBUG); # select def. output handle
    $|=1;          # unbufferise DEBUG
}
select(LOG);       # select def. output handle
$|=1;              # unbufferise LOG
select(STDOUT);    # select def. output handle 

# Infinite loop for getting frame from the pipe and answer:
FRAME_IN:
while(1){
    $nr_frame++;
    $f_netm=$force_netm;     # reinit force netmask option for this frame
    $f_router=$force_router; # renint force router option for this frame

    $recv_time=<STDIN>; # get time when dhcpd1.pl recieved the frame
    chop($recv_time);   # remove last character ("\n")
    $now=time();        # time in seconde from 1/1/1970
    # if the frame is too old(older than ttl):
    if(($recv_time+$frame_ttl)<$now){
	<STDIN>; <STDIN>; <STDIN>;  # remove this old frame in the pipe
	($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
	print LOG "$time Recieved a too old frame (",$now-$recv_time,
	      " sec. old)\n";
	next;
    }
    $port_c=<STDIN>;    # get the (UDP) source port (client port)
    $iaddr_c=<STDIN>;   # get the (IP) source address 
    $frame=<STDIN>;     # get the frame
    
    # remove "\n" and convert from hex. to character (f.e. "41"=>"A"):
    chop($port_c); chop($iaddr_c); $iaddr_c=pack("H8",$iaddr_c);
    chop($frame); $frame=pack("H*",$frame);

    # Check size of log files after 20 frames:
    if($nr_frame>=20){                    
	$nr_frame=0;                      # reset the counter
	$size=-s ".\\log\\dhcpd.log";     # get the size of dhcpd.log in byte
	&Log_backup if($size>=$log_size); # backup dhcpd.log to .bak
	if($debug){
	    $size=-s ".\\log\\debug.log"; # size of .\\log\\debug.log in byte
	    if($size>=$max_size_debug){
		close(DEBUG);
		unlink(".\\log\\debug_log.bak"); # Remove debug_log.bak
		copy(".\\log\\debug.log",".\\log\\debug_log.bak") || 
		    warn "backup .\\log\\debug.log: $!";  # backup file
		open(DEBUG,">.\\log\\debug.log")||
		    warn "Cannot open .\\log\\debug.log: $!";
		print DEBUG "\nDEBUG.LOG > ",$max_size_debug,
		      " bytes => backup in debug_log.bak !\n\n";
	    }
	}
    }

    # Analysis the frame:
    # clear this variables:
    ($msg_type,$p_requested_ip,$requested_ip,$server_id,$client_hostname,
     $requested_param,$vendor_spec,$dhcp_message,$option)="" x 9;

    # 'op','htype','hlen' and magic cookie: allready tested in dhcpd.pl
    # 'hops','secs','yiaddr' and 'siaddr' ignored: don't needed
    my ($hlen)=($frame=~ /^..(.)/s);         # 'hlen' field, need for $chaddr
    ($xid)=($frame=~ /^....(....)/s);        # 'xid' field
    ($flags)=($frame=~ /^.{10}(..)/s);       # 'flags' field
    ($ciaddr)=($frame=~ /^.{12}(....)/s);    # 'ciaddr' field
    ($giaddr)=($frame=~ /^.{24}(....)/s);    # 'giaddr' field
    ($p_chaddr)=($frame=~ /^.{28}(.{16})/s); # 'chaddr' field (16 bytes)
    $hlend=hex(unpack("H2",$hlen));         # hardware address length in dec.
    ($chaddr)=($p_chaddr=~ /^(.{$hlend})/s); # only 'hlen' length of MAC addr.
    my $chaddr_c=unpack("H12",$chaddr);  # $chaddr in ASCII (0000f8308010 form)
    # $chaddr_txt: ASCII form of $chaddr with "-" (00-00-f8-30-80-10 form):
    $chaddr_txt=pack "a2aa2aa2aa2aa2aa2", $chaddr_c=~ /^(..)/s,"-",
                $chaddr_c=~ /^..(..)/s,"-",$chaddr_c=~ /^.{4}(..)/s,"-",
                $chaddr_c=~ /^.{6}(..)/s,"-",$chaddr_c=~ /^.{8}(..)/s,"-",
                $chaddr_c=~ /^.{10}(..)/s;       
    
    $i=240;    # set postion at the begining of 'option' field

    while($option ne "\xff")
    { 
	if($i>1496){
            # if there is a problem with DHCP frame structure,
	    # ignore this frame and wait next frame. (1496 -> MTU)
	    ($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
	    print LOG "\n$time ERROR IN A RECIEVED DHCP FRAME:\n";
	    print LOG "       INVALID STRUCTURE, frame ignored !\n";
	    print LOG "       Frame from $chaddr_txt !!!\n";
	    print LOG "       You should check this client !\n\n";
	    goto FRAME_IN;
	}

	($option)=($frame=~ /^.{$i}(.)/s);    # option number
	$i++;
	next if($option eq "\x00");           # next if it's a 'pad' option
	$o_len=&hex2dec($i,$frame);           # lenth of data (in decimal)
	$i++;
	($o_contens)=($frame=~ /^.{$i}(.{$o_len})/s); # option data
	$i=$i+$o_len;
	
	if($option eq $O_DHCP_MSG_TYPE){
	    $msg_type=hex(unpack("H2",$o_contens)); # convert from hex. to dec.
	}
	elsif($option eq $O_ADDRESS_REQUEST){
	    $p_requested_ip=$o_contens;
	    $requested_ip=inet_ntoa($p_requested_ip);
	}
	elsif($option eq $O_DHCP_SERVER_ID){
	    $server_id=$o_contens;
	}
	elsif($option eq $O_HOST_NAME){
	    $client_hostname=$o_contens;
	    if($client_hostname=~ /\x00$/s){ # if containing a trailing NULL
		chop($client_hostname);      # remove this NULL character
	    }
	}
	elsif($option eq $O_PARAMETER_LIST){
	    $requested_param=$o_contens;
	}
	elsif($option eq $O_VENDOR_SPECIFIC){
	    $vendor_spec=$o_contens;
	    $vendor_spec_len=pack("h2",$o_len);
	}
	elsif($option eq $O_DHCP_MESSAGE){
	    $dhcp_message=$o_contens;
	}
	elsif($option eq $O_OVERLOAD){  # client use overload option !
	    my $field="\'file\' or \'sname\'";
	    if($o_contens=="\x01"){     # 'file' field used
		$field="\'file\'";
	    }elsif($o_contens=="\x02"){ # 'sname' field used
		$field="\'sname\'";
	    }elsif($o_contens=="\x03"){ # 'file' and 'sname' used
		$field="\'file\' and \'sname\'";
	    }
	    print LOG "WARNING: a client ($chaddr_txt) use ",$field,
	          " field(s) (OPTION OVERLOAD)\n";
	    print LOG "         This server don\'t support this !\n";
	}
    } # End of While
    
    sub hex2dec
    {   # hex2dec($pos,$frame) Extract /^.{$pos}(.)/s from $frame 
	# and convert to decimal
	my($i,$frame)=@_;
	my($o_lenh,$o_lend); # option length in hex. and dec.
	($o_lenh)=($frame=~ /^.{$i}(.)/s);
	$o_lend=hex(unpack("H2",$o_lenh));
	return($o_lend);
    }
# End of the frame analysis

    # If BOOTREQUEST isn't for this server (other server ID):
    next if(($server_id ne $server_ip)&&($server_id ne ""));

    # if debug level is 2, print hex. dump of frame in debug.log
    print DEBUG "Recieved from ",inet_ntoa($iaddr_c),
          " from port $port_c:\n",unpack("H*",$frame),"\n" if($hard_debug);

    # if debug level is 2, print if client is a Windows95 station
    print DEBUG "$chaddr_txt is a Windows95(TM) station\n"
          if($hard_debug &&($vendor_spec eq "\x37\x02\x00\x00"));
    
# Send answer:
    if($msg_type==3){   # it's a DHCPREQUEST
	if($debug){     # print debug level 1 informations
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPREQUEST for ";
	    if($ciaddr eq "\x00\x00\x00\x00"){
		print DEBUG $requested_ip;
	    }
	    else{
		print DEBUG inet_ntoa($ciaddr);
	    }
	    print DEBUG " from $chaddr_txt\n";
	}
	&R_request;
    }
    elsif($msg_type==1){ # it's a DHCPDISCOVER
	if($debug){      # print debug level 1 informations
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPDISCOVER from $chaddr_txt\n";
	}
	&R_discover;
    }
    elsif($msg_type==4){ # it's a DHCPDECLINE
	if($debug){      # print debug level 1 informations
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPDECLINE from $chaddr_txt for $requested_ip\n";
	    print DEBUG "       DHCP message recieved:$dhcp_message\n";
	}
	&R_decline;
    }
    elsif($msg_type==7){ # it's a DHCPRELEASE
	if($debug){      # print debug level 1 informations
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPRELEASE from $chaddr_txt ",inet_ntoa($ciaddr),"\n";
	}
	&R_release;
    }
    elsif($msg_type==8){ # it's a DHCPINFORM
	if($debug){      # print debug level 1 informations
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPINFORM from $chaddr_txt $ciaddr_txt\n";
	}
	&R_inform;
    }
    # else if it isn't a DHCP frame (f.e. $msg_type eq ""),
    # do nothing, get next frame
}

###############################################################################
#
# End of dhcpd2.pl
#
 END: 
{
    ($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
    print LOG "\n$time STOPING EICNDHCPD SERVICE....\n\n";
  Win32::Service::StopService('','EICNDHCPD')||
      warn "Can't stop EICNDHCPD service!\n";
    if($debug){
	print DEBUG "$time DHCPD STOPED !  (See EventLog)\n";
	close(DEBUG);
    }
    print LOG "\n\n$time DHCPD STOPED !  (See EventLog)\n\n\n";
    close(LOG);
}


###############################################################################
#
# Subroutines
#

# if the recieved frame is a DHCPDISCOVER
sub R_discover
{
    my ($mac_ok,$ligne)=&Mac; # check MAC address
    if($mac_ok){
	&Ip($ligne);          # check IP address
	&Get_conf($ligne);    # get parameters for the client
	if(($hostname eq "")or($hostname eq $client_hostname)){
	    &Send_offer;      # send a DHCPOFFER to the client
	}
	else{ # the MAC address isn't on the good computer
	    my($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);
	    print LOG "$time UNAUTHORIZED MAC ON THIS COMPUTER FROM:",
	          $chaddr_txt;
	    print LOG ",\n       HOST NAME:$client_hostname\n";
	    if($mail_mac){
		# Creating a mailing process
		pipe(READ, WRITE); # create IPC pipe for data transfert
		select(WRITE);     # select STDOUT for next apply $|=1
		$|=1;              # unbufferise WRITE
		select(STDOUT);    # select the default output handle
		open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";
		open(STDIN, "< &READ")    ||  warn "Can not redirect STDIN\n";
		select(STDIN);     # select STDIN for next apply $|=1
		$| = 1;            # unbufferise STDIN => unbufferise READ 
		select(STDOUT);    # select the default output handle
	      Win32::Process::Create($Mailprocess,
			 "e:\\perl\\bin\\perl.exe",
			 "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			 1,
			 NORMAL_PRIORITY_CLASS,
			 "e:\\eicndhcpd");
		open(STDIN, "< &SAVEIN"); # restore STDIN
		close(SAVEIN);
		print WRITE "$admin_mail\n";
		print WRITE "$smtp_server\n";
		print WRITE inet_ntoa($server_ip),"\n";
		print WRITE "DHCPD: UNAUTHORIZED MAC ON A COMPUTER\n";
		print WRITE "$time\#The $client_hostname computer have an unauthorized MAC (ethernet) address;$chaddr_txt.\#This MAC address is on $hostname computer in the database (netdata.dat).\#Someone certainly moved the network card!\#\#MAC address:$chaddr_txt\#Old host name:$hostname\#New host name:$client_hostname\#\#See the dhcpd.log file (and debug.log if DEBUG 1 or 2 in dhcpd.conf) for more information.\#\n";
		close(WRITE);
		close(READ);
	    }
	}
    }
}

# if the recieved frame is a DHCPREQUEST
sub R_request
{
    my ($mac_ok,$ligne)=&Mac;  # check MAC address 
    if($mac_ok){
	if(&Ip($ligne)){       # check IP address
	    &Get_conf($ligne); # get parameters for the client
	    if($netmask and $t1 and $t2 and $t3){ # minimum parameters
		if(($hostname eq "")or($hostname eq $client_hostname)){
		    &Send_ack; # send a DHCPACK
		}
		else{ # If the MAC address isn't on the good computer
		    &Send_nak("Network card moved"); # send a DHCPNAK
		    my($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);
		    print LOG "$time UNAUTHORIZED MAC ON THIS COMPUTER FROM:",
		          $chaddr_txt;
		    print LOG ",\n       HOST NAME:$client_hostname\n";
		    if($mail_mac){
			# Creating a mailing process
			pipe(READ, WRITE); # create IPC pipe for data transfert
			select(WRITE);     # select STDOUT for next apply $|=1
			$|=1;              # unbufferise WRITE
			select(STDOUT);    # select the default output handle
			open(SAVEIN, "< &STDIN")||
			    warn "Can not save STDIN\n";
			open(STDIN, "< &READ")||
			    warn "Can not redirect STDIN\n";
			select(STDIN);     # select STDIN for next apply $|=1
			$| = 1; # unbufferise STDIN => unbufferise READ 
			select(STDOUT);    # select the default output handle
		      Win32::Process::Create($Mailprocess,
			    "e:\\perl\\bin\\perl.exe",
			    "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			    1,
			    NORMAL_PRIORITY_CLASS,
			    "e:\\eicndhcpd");
			open(STDIN, "< &SAVEIN"); # restore STDIN
			close(SAVEIN);
			print WRITE "$admin_mail\n";
			print WRITE "$smtp_server\n";
			print WRITE inet_ntoa($server_ip),"\n";
			print WRITE "DHCPD: UNAUTHORIZED MAC ON A COMPUTER\n";
			print WRITE "$time\#The $client_hostname computer have an unauthorized MAC (ethernet) address;$chaddr_txt.\#This MAC address is on $hostname computer in the database (netdata.dat).\#Someone certainly moved the network card!\#\#MAC address:$chaddr_txt\#Old host name:$hostname\#New host name:$client_hostname\#\#See the dhcpd.log file (and debug.log if DEBUG 1 or 2 in dhcpd.conf) for more information.\#\n";
			close(WRITE);
			close(READ);
		    }
		}
	    }
	    else{ 
                # insufficant parameters in netdata.dat
                # (need t1,t2,t3 and netmask)
		
		# send a DHCPNAK:
		&Send_nak("Invalid DHCP database, netmask or lease");
		my($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);
		print LOG "$time NEED T1,T2,T3 AND NETMASK FOR:",$chaddr_txt;
		print LOG " $ipaddress\n";
		if($mail_mac){
		    # Creating a mailing process
		    pipe(READ, WRITE); # create IPC pipe for data transfert
		    select(WRITE);     # select STDOUT for next apply $|=1
		    $|=1;              # unbufferise WRITE
		    select(STDOUT);    # select the default output handle
		    open(SAVEIN, "< &STDIN")||
			warn "Can not save STDIN\n";
		    open(STDIN, "< &READ")||
			warn "Can not redirect STDIN\n";
		    select(STDIN);     # select STDIN for next apply $|=1
		    $| = 1;            # unbufferise STDIN => unbufferise READ 
		    select(STDOUT);    # select the default output handle
		  Win32::Process::Create($Mailprocess,
			 "e:\\perl\\bin\\perl.exe",
			 "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			 1,
			 NORMAL_PRIORITY_CLASS,
			 "e:\\eicndhcpd");
		    open(STDIN, "< &SAVEIN");
		    close(SAVEIN);
		    print WRITE "$admin_mail\n";
		    print WRITE "$smtp_server\n";
		    print WRITE inet_ntoa($server_ip),"\n";
		    print WRITE "DHCPD: NEED T1,T2,T3 AND NETMASK\n";
		    print WRITE "$time\#T1,T2,T3 and NETMASK needed for this computer:\#\#MAC address:$chaddr_txt\#IP address:$ipaddress\#\#Update the database (netdata.dat) for accept DHCP request from this computer.\#\#See the dhcpd.log file (and debug.log if DEBUG 1 or 2 in dhcpd.conf) for more information.\#\n";
		    close(WRITE);
		    close(READ);
		}
	    }
	}
	else{
	    &Send_nak("Invalid IP address request"); # send a DHCPNAK
	}
    }
}

# if the recieved frame is a DHCPDECLINE
sub R_decline
{
    my($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);
    print LOG "$time Host $chaddr_txt declined his lease, possible IP address";
    print LOG "\n       allready in use ($requested_ip)\n";
    print LOG "       DHCP message:$dhcp_message\n" if($dhcp_message);
    if($mail_mac){
	# Creating a mailing process
       	pipe(READ, WRITE); # create interprocess pipe for data transfert
	select(WRITE);     # select STDOUT for next apply $|=1
	$|=1;              # unbufferise WRITE
	select(STDOUT);    # select the default output handle
	open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";
	open(STDIN, "< &READ")    ||  warn "Can not redirect STDIN\n";
	select(STDIN);     # select STDIN for next apply $|=1
	$| = 1;            # unbufferise STDIN => unbufferise READ 
	select(STDOUT);    # select the default output handle
      Win32::Process::Create($Mailprocess,
			     "e:\\perl\\bin\\perl.exe",
			     "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			     1,
			     NORMAL_PRIORITY_CLASS,
			     "e:\\eicndhcpd");
	open(STDIN, "< &SAVEIN"); # restore STDIN
	close(SAVEIN);
	print WRITE "$admin_mail\n";
	print WRITE "$smtp_server\n";
	print WRITE inet_ntoa($server_ip),"\n";
	print WRITE "DHCPD: A CLIENT DECLINED HIS LEASE\n";
	print WRITE "$time\#A DHCP client declined his lease!\#THE FOLLOWING IP ADDRESS IS ALLREADY IN USE !\#\#IP address:$requested_ip\#\#Client MAC address:$chaddr_txt\#\#Please check this problem and update the database (netdata.dat) for accept this computer.\#\#See the dhcpd.log file (and debug.log if DEBUG 1 or 2 in dhcpd.conf) for more information.\#\n";
	close(WRITE);
	close(READ);
    }
}

# if the recieved frame is a DHCPRELEASE
sub R_release
{
    print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/," $chaddr_txt ",
          inet_ntoa($ciaddr)," aborted the lease\n";
}

# if the recieved frame is a DHCPINFORM
sub R_inform
{
    print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
          " $chaddr_txt $ciaddr_txt inform about his network configuration\n";
    my ($mac_ok,$ligne)=&Mac;    # Check MAC address
    if($mac_ok and &Ip($ligne)){ # if valid IP and MAC address
	&Get_conf($ligne);       # get parameters for the client

	# creating the DHCPACK frame:
	my $ack="$BOOTREPLY$HTYPE_ETHER$HLEN_ETHER\x00$xid\x00\x00$flags\x00\x00\x00\x00\x00\x00\x00\x00$server_ip$giaddr$p_chaddr$SNAME$FILE$MAGIC_COOKIE$O_DHCP_MSG_TYPE\x01$DHCPACK$O_DHCP_SERVER_ID\x04$server_ip";
	for($i=0;$requested_param=~/^.{$i}./s;$i++){
	    if(($requested_param=~/^.{$i}\x01/s or $f_netm) and $netmask)
	    {
		$f_netm=0;
		$ack=$ack."$O_SUBNET_MASK\x04$netmask";
	    }
	    elsif(($requested_param=~/^.{$i}\x03/s or $f_router) and $def_gw)
            {
		$f_router=0;
		$ack=$ack."$O_ROUTER$def_gw_len$def_gw";
	    }
	    elsif($requested_param=~/^.{$i}\x0f/s and $domain_name){
		$ack=$ack."$O_DOMAIN_NAME$domain_name_len$domain_name";
	    }
	    elsif($requested_param=~/^.{$i}\x06/s and $dns_server){
		$ack=$ack."$O_DNS_SERVER$dns_server_len$dns_server";
	    }
	    elsif($requested_param=~/^.{$i}\x2c/s and $nbns){
		$ack=$ack."$O_NETBIOS_NAME_SERVER$nbns_len$nbns$O_NETBIOS_NODE_TYPE\x01$nbnode";
	    }
	}
	$ack=$ack.$O_END;

	while(length($ack)<300){ # Complete with "\x00" because MS-DHCP don't 
	                         # support if frame is too short
	    $ack=$ack."\x00";
	}
	
	my $paddr=sockaddr_in($CLIENT_PORT,$ciaddr); # client IP addr. and port
	socket(SOCK2,PF_INET,SOCK_DGRAM,$proto) || warn "socket error: $!";
	# configure destination IP address:
	connect(SOCK2, $paddr) || warn "connect error: $!";
	print SOCK2 $ack; # send the DHCPACK frame
	close(SOCK2) || warn "close error: $!";

	if($debug){
	    # if debug level 2, print debuging informations:
	    print DEBUG "Sent to ",inet_ntoa($ciaddr),
	          " on port $CLIENT_PORT:\n",unpack("H*",$ack),
	          "\n" if($hard_debug);
	    # if debug level 1 (or 2), print debuging informations:
	    print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPACK on $requested_ip to $chaddr_txt\n";
	}
    }
    else{ # invalid MAC or IP address
	print LOG "DHCP server don't respond: invalid MAC or IP address\n";
    }
}

###############################################################################
   
# Check the client MAC address with the database (netdata.dat):
sub Mac
{
    # open netdata.dat file:
    unless(open(NETDB,"<netdata.dat")){
	warn "Cannot open netdata.dat: $!";
	&SendEvent(7,EVENTLOG_ERROR_TYPE);
	goto END;
    }
    while(<NETDB>){         # get a ligne in netdata.dat
	next if($_=~ /^\#/); # next if it's a coment ligne
	($macaddr)=($_=~ /MAC:(..-..-..-..-..-..)/s); # extract the MAC address
	$macaddr=~ tr/A-Z/a-z/;      # transform MAJ. to min.
	if($chaddr_txt eq $macaddr){
	    # MAC address is valid, return 1 and the ligne of netdata.dat:
	    close(NETDB);
	    return(1,$_);
	}
    }
    # MAC address isn't valid:
    close(NETDB);
    my $client_ip;
    if($requested_ip){
	$client_ip=$requested_ip;
    }
    elsif($ciaddr ne "\x00\x00\x00\x00"){
	$client_ip=$ciaddr;
    }
    my($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/);
    print LOG $time,
          " UNAUTHORIZED MAC ADDRESS ON THE NETWORK OR MULTIPLE SERVER WITH\n";
    print LOG " DIFFERENT DATABASE, FROM:",$chaddr_txt;
    print LOG ", REQUESTED IP:",$client_ip if($client_ip);
    print LOG ",\n       HOST NAME:",$client_hostname if($client_hostname);
    print LOG "\n";
    if($mail_mac){
	# Creating a mailing process
	pipe(READ, WRITE); # create interprocess pipe for data transfert
	select(WRITE);     # select STDOUT for next apply $|=1
	$|=1;              # unbufferise WRITE
	select(STDOUT);    # select the default output handle
	open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";
	open(STDIN, "< &READ")    ||  warn "Can not redirect STDIN\n";
	select(STDIN);     # select STDIN for next apply $|=1
	$| = 1;            # unbufferise STDIN => unbufferise READ 
	select(STDOUT);    # select the default output handle
      Win32::Process::Create($Mailprocess,
			     "e:\\perl\\bin\\perl.exe",
			     "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			     1,
			     NORMAL_PRIORITY_CLASS,
			     "e:\\eicndhcpd");
	open(STDIN, "< &SAVEIN");
	close(SAVEIN);
	print WRITE "$admin_mail\n";
	print WRITE "$smtp_server\n";
	print WRITE inet_ntoa($server_ip),"\n";
	print WRITE "DHCPD: UNAUTHORIZED MAC ADDRESS ON THE NETWORK\n";
	print WRITE "$time\#The computer with the following configuration attempt to get a IP address from the server.\#But his MAC (ethernet) address isn't in the database (netdata.dat).\#POSSIBLE WILD CONNECTION !\#OR MULTIPLE SERVER WITH DIFFERENT DATABASE !\#\#Configuration:\#MAC address:$chaddr_txt\#Requested IP:$client_ip\#Host name:$client_hostname\#\#See the dhcpd.log file (and debug.log if DEBUG 1 or 2 in dhcpd.conf) for more information.\#\n";
	close(WRITE);
	close(READ);
    }
    # return 0 and undef
    return(0);
}

# Check the client IP address with the database (netdata.dat):
sub Ip
{
    my ($ligne)=@_; # get argument (the ligne of netdata.dat)
    # extract the IP address from the ligne and next convert to 4 bytes form: 
    ($ipaddress)=($ligne=~ /IP:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
    $p_ipaddress=pack('C4',($ipaddress=~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/));
    # Check the client IP address:
    # If the recieved frame is a DHCPINFORM (type 8), the client IP address is
    # in 'ciaddr' field.
    # If it's a DHCPREQUEST, this address may be in 'ciaddr' field (renewin/
    # rebinging state) or in 'Requested IP Address' option (init/reboot state).
    # If it's a DHCPDISCOVER, this address may be in 'Requested IP Address'
    # option or may not be specified.
    if(($requested_ip eq $ipaddress)||(($ciaddr eq $p_ipaddress)
       &&($msg_type==3||8))||(($requested_ip eq "")&&($msg_type==1)))
    {
	return(1);
    }
    else{
	# invalid IP address:
	if($msg_type==3){ # DHCPREQUEST with bad IP address request
	    if($ciaddr eq "\x00\x00\x00\x00"){ # INIT-REBOOT state
		print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
		      " Unauthorized IP address request for $requested_ip\n";
	    }
	    else{ # RENEWING or REBINDING state
		print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
		      " WARNING! Invalid IP address request for ",
		      inet_ntoa($ciaddr),
		      " on\n      Renewing or Rebinding state from $chaddr_txt\n";
	    }
	}
	elsif($msg_type==1){ # DHCPDISCOVER with bad IP address request
	    print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	          " DHCPDISCOVER with an invalid IP address request\n      (",
	          $requested_ip,") from $chaddr_txt\n";
	}
	elsif($msg_type==8){ # DHCPINFORM with bad IP address
	    print LOG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/," $chaddr_txt";
	    print LOG ", host name:",$client_hostname if($client_hostname);
	    print LOG ", sent a DHCPINFORM";
	    print LOG "\n";
	    print LOG "       WARING: it will use a unautorized IP address: ",
	              inet_ntoa($ciaddr),"\n";
	}
	# return 0 if the client IP address is invalid:
	return(0);
    }
}

# Get the configuration from the ligne of netdata.dat:
sub Get_conf
{
    my ($ligne)=@_; # get argument (the ligne of netdata.dat)
     # Clear all this variables:
    ($domain_name,$hostname,$netmask,$t1,$t2,$t3,$nbns,$dns_server,
     $def_gw)= "" x 9;

    $nbnode="\x08";        # NetBIOS by default H-node->8 hex. (see option 46)
    # extract hostname and domain name from the netdata.dat ligne:
    if($ligne=~/DNS:\S+/){ 
	my($dns_name)=($ligne=~/DNS:(\S+)/);
	($domain_name)=($dns_name=~/\.(\S+)/);  # domain name
	# length of $domain_name in hexa :
	$domain_name_len=pack("h2",sprintf("%x",length($domain_name)));
	($hostname)=($dns_name=~/^(\w+)\./);    # host name
	$hostname=~ tr/a-z/A-Z/;   # convert min. to MAJ. in hostname
    }
    # extract netmask from the netdata.dat ligne:
    if($ligne=~/NETMASK:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/){
	($netmask)=($ligne=~/NETMASK:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
	# net mask in 4 bytes form:
	$netmask=pack('C4',($netmask=~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/));
    }
    # extract renewal time (t1) from the netdata.dat ligne:
    if($ligne=~/T1:\w+/){
	($t1)=($ligne=~/T1:(\w+)/);
	$t1=pack("H8",$t1);  # renewal time in hex.
    }
    # extract rebinding time (t2) from the netdata.dat ligne:
    if($ligne=~/T2:\w+/){
	($t2)=($ligne=~/T2:(\w+)/);
	$t2=pack("H8",$t2);  # rebinding time in hex.
    }
    # extract IP address lease time (t3) from the netdata.dat ligne:
    if($ligne=~/T3:\w+/){
	($t3)=($ligne=~/T3:(\w+)/);
	$t3=pack("H8",$t3);  # IP address lease time in hex.
    }
    # extract NetBIOS name servers (WINS servers) IP addresses
    # from the netdata.dat ligne:
    if($ligne=~/NETBIOSNAMESERVER:\S+/){
	my($nb)=($ligne=~/NETBIOSNAMESERVER:(\S+)/);
	for($i=0,$nbns="";$nb=~/,{$i}\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;$i++){
	    $nbns=$nbns.pack('C4',($nb=~ /,{$i}(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/));
	}
	# length of $nbns in hexa ($i*4 == length in dec.):
	$nbns_len=pack("h2",sprintf("%x",$i*4));
    }
    # extract NetBIOS node type from the netdata.dat ligne:
    if($ligne=~/NETBIOSNODETYPE:\d/){
	($nbnode)=($ligne=~/NETBIOSNODETYPE:(\d)/);
	$nbnode=pack("h1",$nbnode);            # convert dec. to hex.
    }
    # extract DNS servers IP addresses from the netdata.dat ligne:
    if($ligne=~/DNSSERVER:\S+/){
	my($dns)=($ligne=~/DNSSERVER:(\S+)/);
	for($i=0,$dns_server="";
	    $dns=~/,{$i}\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;$i++)
	{
	    $dns_server=$dns_server.pack('C4',($dns=~ /,{$i}(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/));
	}
	# length of $dns_server in hexa ($i*4 == length in dec.)
	$dns_server_len=pack("h2",sprintf("%x",$i*4));
    }
    # extract default gateways IP addresses from the netdata.dat ligne:
    if($ligne=~/DEFAULTGW:\S+/){
	my($dgw)=($ligne=~/DEFAULTGW:(\S+)/);
	for($i=0,$def_gw="";
	    $dgw=~/,{$i}\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;$i++)
	{
	    $def_gw=$def_gw.pack('C4',
		   ($dgw=~ /,{$i}(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/));
	}
	# length of $def_gw in hexa ($i*4 == length in dec.)
	$def_gw_len=pack("h2",sprintf("%x",$i*4));
    }
}

###############################################################################

# send a DHCPACK frame:
sub Send_ack
{
    my $paddr;  # IP address for DHCP reply in 4 bytes form
    if($giaddr ne "\x00\x00\x00\x00"){
	# client isn't on the same subnet =>
	# send answer to the DHCP Relay Agent on DHCP server port
	$paddr=sockaddr_in($SERVER_PORT,$giaddr);
    }
    elsif($ciaddr ne "\x00\x00\x00\x00"){
	# frame recieved in unicast mode =>
	# send an answer in unicast to the client
	$paddr=sockaddr_in($CLIENT_PORT,$ciaddr);
	# no 'Requested IP address' option in renewing or rebinding state
	# 'yiaddr' field in reply must be the same as 'ciaddr' field in request
	$p_requested_ip=$ciaddr;          # 4 bytes form
	$requested_ip=inet_ntoa($ciaddr); # ASCII form
    }
    else{
	# client is on the same subnet => broadcast answer 
	$paddr=sockaddr_in($CLIENT_PORT,$b_ipaddr);
    }

    # creating the DHCPACK frame:
    my $ack="$BOOTREPLY$HTYPE_ETHER$HLEN_ETHER\x00$xid\x00\x00$flags\x00\x00\x00\x00$p_requested_ip$server_ip$giaddr$p_chaddr$SNAME$FILE$MAGIC_COOKIE$O_DHCP_MSG_TYPE\x01$DHCPACK$O_RENEWAL_TIME\x04$t1$O_REBINDING_TIME\x04$t2$O_ADDRESS_TIME\x04$t3$O_DHCP_SERVER_ID\x04$server_ip";
    for($i=0;$requested_param=~/^.{$i}./s;$i++){
	if(($requested_param=~/^.{$i}\x01/s or $f_netm) and $netmask)
	{
	    $f_netm=0;
	    $ack=$ack."$O_SUBNET_MASK\x04$netmask";
	}
	elsif(($requested_param=~/^.{$i}\x03/s or $f_router) and $def_gw)
	{
	    $f_router=0;
	    $ack=$ack."$O_ROUTER$def_gw_len$def_gw";
	}
	elsif($requested_param=~/^.{$i}\x0f/s and $domain_name){
	    $ack=$ack."$O_DOMAIN_NAME$domain_name_len$domain_name";
	}
	elsif($requested_param=~/^.{$i}\x06/s and $dns_server){
	    $ack=$ack."$O_DNS_SERVER$dns_server_len$dns_server";
	}
	elsif($requested_param=~/^.{$i}\x2c/s and $nbns){
	    $ack=$ack."$O_NETBIOS_NAME_SERVER$nbns_len$nbns$O_NETBIOS_NODE_TYPE\x01$nbnode";
	}
    }
    $ack=$ack.$O_END;  # add. the 'end' option
    # Complete with "\x00" because MS-DHCP don't support if frame is too short:
    while(length($ack)<300){
	$ack=$ack."\x00";
    }

    # create socket:
    socket (SOCK2,PF_INET,SOCK_DGRAM,$proto) || warn "socket error: $!";
    connect(SOCK2, $paddr) || warn "connect error: $!";
    print SOCK2 $ack;  # send DHCPACK frame
    close(SOCK2) || warn "close error: $!";
    
    if($debug){
	# extract IP addr. and port where this frame has been sent:
	my ($s_port,$s_addr)=sockaddr_in($paddr) if($hard_debug);
	# if debug level 2, print debuging informations:
	print DEBUG "Sent to ",inet_ntoa($s_addr)," on port $s_port:\n",
	      unpack("H*",$ack),"\n" if($hard_debug);
	# if debug level 1 (or 2), print debuging informations:
	print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	      " DHCPACK on $requested_ip to $chaddr_txt\n";
    }
}

# send a DHCPOFFER frame
sub Send_offer
{
    my $paddr;  # IP address for DHCP reply in 4 bytes form
    if($giaddr ne "\x00\x00\x00\x00"){
	# client isn't on the same subnet =>
	# send answer to the DHCP relay agent on DHCP server port
	$paddr=sockaddr_in($SERVER_PORT,$giaddr);
    }
    elsif($ciaddr ne "\x00\x00\x00\x00"){
	# frame recieved in unicast mode =>
	# send answer (unicast) to the client
	$paddr=sockaddr_in($CLIENT_PORT,$ciaddr);
    }
    else{
	# client is on the same subnet => broadcast answer 
	$paddr=sockaddr_in($CLIENT_PORT,$b_ipaddr);
    }

    # creating the DHCPOFFER frame:
    my $offer="$BOOTREPLY$HTYPE_ETHER$HLEN_ETHER\x00$xid\x00\x00$flags\x00\x00\x00\x00$p_ipaddress$server_ip$giaddr$p_chaddr$SNAME$FILE$MAGIC_COOKIE$O_DHCP_MSG_TYPE\x01$DHCPOFFER$O_RENEWAL_TIME\x04$t1$O_REBINDING_TIME\x04$t2$O_ADDRESS_TIME\x04$t3$O_DHCP_SERVER_ID\x04$server_ip";
    for($i=0;$requested_param=~/^.{$i}./s;$i++){
	if(($requested_param=~/^.{$i}\x01/s or $f_netm) and $netmask)
	{
	    $f_netm=0;
	    $offer=$offer."$O_SUBNET_MASK\x04$netmask";
	}
	elsif(($requested_param=~/^.{$i}\x03/s or $f_router) and $def_gw)
	{
	    $f_router=0;
	    $offer=$offer."$O_ROUTER$def_gw_len$def_gw";
	}
	elsif($requested_param=~/^.{$i}\x0f/s and $domain_name){
	    $offer=$offer."$O_DOMAIN_NAME$domain_name_len$domain_name";
	}
	elsif($requested_param=~/^.{$i}\x06/s and $dns_server){
	    $offer=$offer."$O_DNS_SERVER$dns_server_len$dns_server";
	}
	elsif($requested_param=~/^.{$i}\x2c/s and $nbns){
	    $offer=$offer."$O_NETBIOS_NAME_SERVER$nbns_len$nbns$O_NETBIOS_NODE_TYPE\x01$nbnode";
	}
    }
    if($vendor_spec){
	$offer=$offer."$O_VENDOR_SPECIFIC$vendor_spec_len$vendor_spec";
    }
    $offer=$offer.$O_END;  # add. the 'end' option
    while(length($offer)<300){ # Complete with "\x00" because MS-DHCP don't 
                               # support if frame is too short
	$offer=$offer."\x00";
    }
    
    # create socket:
    socket (SOCK2,PF_INET,SOCK_DGRAM,$proto) || warn "socket error: $!";
    connect(SOCK2, $paddr) || warn "connect error: $!";
    print SOCK2 $offer; # send DHCPOFFER frame
    close(SOCK2) || warn "close error: $!";
    
    if($debug){
	# extract IP addr. and port where this frame has been sent:
	my ($s_port,$s_addr)=sockaddr_in($paddr) if($hard_debug);
	# if debug level 2, print debuging informations:
	print DEBUG "Sent to ",inet_ntoa($s_addr)," on port $s_port:\n",
	      unpack("H*",$offer),"\n" if($hard_debug);
	# if debug level 1 (or 2), print debuging informations:
	print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	      " DHCPOFFER on $ipaddress to $chaddr_txt\n";
    }
}

# send a DHCPNAK frame:
sub Send_nak
{
    my ($message)=@_; # get message for 'Message' option (Nr 56)
    my $message_len=pack("H2",length($message)); # convert from ASCII to hex.
    my $paddr; # IP address for DHCP reply in 4 bytes form
    if($giaddr eq "\x00\x00\x00\x00"){
	# client is on the same subnet => broadcast answer
	$paddr=sockaddr_in($CLIENT_PORT,$b_ipaddr);
    }
    else{
	# client isn't on the same subnet =>
	# send answer to the DHCP Relay Agent on DHCP server port
	$flags="\x80\x00"; # Set the broadcast bit
	$paddr=sockaddr_in($SERVER_PORT,$giaddr);
    }

    # creating the DHCPNAK frame:
    my $nak="$BOOTREPLY$HTYPE_ETHER$HLEN_ETHER\x00$xid\x00\x00$flags\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00$giaddr$p_chaddr$SNAME$FILE$MAGIC_COOKIE$O_DHCP_MSG_TYPE\x01$DHCPNAK$O_DHCP_SERVER_ID\x04$server_ip";
    $nak=$nak."$O_DHCP_MESSAGE$message_len$message" if($message);
    $nak=$nak.$O_END;
    while(length($nak)<300){ 
        # Complete with "\x00" because MS-DHCP don't support
	# if frame is too short
	$nak=$nak."\x00";
    }

    # create socket:
    socket (SOCK2,PF_INET,SOCK_DGRAM,$proto) || warn "socket error: $!";
    connect(SOCK2, $paddr) || warn "connect error: $!";
    print SOCK2 $nak; # send DHCPNAK frame
    close(SOCK2) || warn "close error: $!"; 
    
    if($debug){
	# extract IP addr. and port where this frame has been sent:
	my ($s_port,$s_addr)=sockaddr_in($paddr) if($hard_debug);
	# if debug level 2, print debuging informations:
	print DEBUG "Sent to ",inet_ntoa($s_addr)," on port $s_port:\n",unpack("H*",$nak),"\n" if($hard_debug);
	# if debug level 1 (or 2), print debuging informations:
	print DEBUG localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/,
	      " DHCPNAK to $chaddr_txt\n";
	print DEBUG "       DHCP message sent:$message\n";
    }
}

###############################################################################

# send a event to the EventLog:
sub SendEvent{
    # get arguments: event ID and event type:
    my($msg_eventid,$msg_eventtype)=@_; 
    my $EventLog;
    my %event=(
	       'EventID',$msg_eventid,
	       'EventType',$msg_eventtype,
	       'Category',NULL,
	       );
    $EventLog=new Win32::EventLog("EICNDHCPD") || warn $!;
    $EventLog->Report(\%event)||warn $!; # send the event
}

# backup dhcpd.log file when it's over maximum size:
sub Log_backup
{ # make a backup of .\log\dhcpd.log
    close(LOG);
    if($log2bak){ # backup to dhcpd_log.bak000, dhcpd_log.bak001, ...
	my $i=0;     # indice for the .bak number
	my $j="000"; # ASCII form of this number
	my $exist=1; # 0/1 "dhcpd_log.bak$j" file exist/don't exist
	my $k;       # ASCII form of the next backup file

	# Check the backup files if they exist:
	for($i=0;$exist;$i++){
	    if($i<10){
		$j="00$i";
	    }
	    elsif($i<100){
		$j="0$i";
	    }
	    elsif($i<1000){
		$j="$i";
	    }
	    else{
		# reset indice:
		$i=0;$j="00$i";
		# remove dhcpd_log.bak000 file:
		unlink(".\\log\\dhcpd_log.bak000");
	    }
	    # check if this backup file exist:
	    $exist=-e ".\\log\\dhcpd_log.bak$j";
	}
	
	# create the ASCII form for the next backup file:
	if($i<10){
	    $k="00$i";
	}
	elsif($i<100){
	    $k="0$i";
	}
	elsif($i<1000){
	    $k="$i";
	}
	else{
	    $k="000";
	}
	
	# remove the $j+1 backup file if it exist:
	unlink(".\\log\\dhcpd_log.bak$k");
	if(rename(".\\log\\dhcpd.log",".\\log\\dhcpd_log.bak$j")==0){ 
            # dhcp_log.bak$j exist:
	    unlink(".\\log\\dhcpd_log.bak$j");    # remove the file
	    # backup the file:
	    rename(".\\log\\dhcpd.log",".\\log\\dhcpd_log.bak$j");
	}
	
	# open the dhcpd.log file:
	open(LOG,">.\\log\\dhcpd.log") || warn "Cannot open .\\log\\dhcpd.log: $!";
    }
    else{ # backup to dhcpd_log.bak (overwrite if it already exist):
	unlink(".\\log\\dhcpd_log.bak"); # Remove dhcp_log.bak
	rename(".\\log\\dhcpd.log",".\\log\\dhcpd_log.bak")||
	    warn "Cannot rename .\\log\\dhcpd.log: $!";
	open(LOG,">>.\\log\\dhcpd.log")||
	    warn "Cannot open .\\log\\dhcpd.log: $!";

	# send a 'dhcpd.log is full' E-Mail message: 
	if($mail_log){
	    ($time)=(localtime()=~ /^\S{3}\s(\S+\s+\S+\s\S+)/); # local time
	    # Creating a mailing process
	    pipe(READ, WRITE); # create interprocess pipe for data transfert
	    select(WRITE);     # select STDOUT for next apply $|=1
	    $|=1;              # unbufferise WRITE
	    select(STDOUT);    # select the default output handle
	    open(SAVEIN, "< &STDIN")  ||  warn "Can not save STDIN\n";
	    open(STDIN, "< &READ")    ||  warn "Can not redirect STDIN\n";
	    select(STDIN);     # select STDIN for next apply $|=1
	    $| = 1;            # unbufferise STDIN => unbufferise READ 
	    select(STDOUT);    # select the default output handle
	  Win32::Process::Create($Mailprocess,
			    "e:\\perl\\bin\\perl.exe",
			    "e:\\perl\\bin\\perl.exe e:\\eicndhcpd\\dhcpdmail.pl",
			    1,
			    NORMAL_PRIORITY_CLASS,
			    "e:\\eicndhcpd");
	    open(STDIN, "< &SAVEIN"); # restore STDIN
	    close(SAVEIN);
	    print WRITE "$admin_mail\n";
	    print WRITE "$smtp_server\n";
	    print WRITE inet_ntoa($server_ip),"\n";
	    print WRITE "DHCPD: DHCPD.LOG FULL !!!!!!!!!!!!!!\n";
	    print WRITE "$time\#The dhcpd.log file is over $log_size bytes\#It was renamed dhcpd_log.bak\#If you want to keep this file, make a copy NOW!\#\n";
	    close(WRITE);
	    close(READ);
	}
    }
}







