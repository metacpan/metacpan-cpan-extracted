#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# DHCPD3.PL part
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
#$Header: dhcpd3.pl,v 1.11 1999/06/27
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

use Win32::Service;  # Win32::Service module: for start/stop/status of services
use Win32::EventLog; # Win32::EventLog module: for create events messages


my %status;          # status of EICNDHCPD service
my $dhcpd2_pid;      # PID of the dhcpd2.pl script
my $time_out=10;     # Wait time before killing the dhcpd2.pl process when
                     # EICNDHCPD service isn't running
my $buffer_time=3;   # Wait to be sure that the frame buffer (the pipe
                     # between dhcpd.pl and dhcpd2.pl is empty.

$dhcpd2_pid=<STDIN>; # get the PID of dhcpd2.pl process from the pipe
chomp($dhcpd2_pid);  # remove "\n" or "\r\n" at the end of the var.

while(1){
    sleep($time_out);                    # wait $time_out sec.
    # Get the status of EICNDHCPD service:
    $status{CurrentState}=0; # Clear CurrentState in %status
  Win32::Service::GetStatus('','EICNDHCPD',\%status);
    if($status{CurrentState}!=4){
	# EICNDHCPD service don't run
	print "EICNDHCPD service don't run\n";
	print "$0: killing dhcpd2.pl process !\n";
	sleep($buffer_time);             # wait $buffer_time sec.
	kill(INT,$dhcpd2_pid);           # kill dhcpd2.pl process
	goto END;
    }
}

 END:
{
    print "$0: Ending...\n";
    &SendEvent(99,EVENTLOG_INFORMATION_TYPE); # Send Event 99: stop correctly
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
