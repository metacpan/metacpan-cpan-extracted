#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# REFRESH.PL part
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
#$Header: refresh.pl,v 1.11 1999/06/27
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

# Refresh the server database from a file like than netdata.dat,
# his name must be netdata.new or you must change this script. 

use File::Copy;      # File::Copy module: for files copy
use Win32::Service;  # Win32::Service module: to start/stop/status of services

if(-e "netdata.new"){
    # netdata.new file exist

    print "\n\nStoping EICNDHCPD service...\n\n";
  Win32::Service::StopService('',"EICNDHCPD")||
      warn "Cannot stop EICNDHCPD service: $!";

    if(-e "c:\\eicndhcpd\\netdata.old"){
	# netdata.old file exist => delete it
	print "Deleting netdata.old...\n\n";
	unlink("c:\\eicndhcpd\\netdata.old");
    }
    if(-e "c:\\eicndhcpd\\netdata.dat"){
	# move netdata.dat file to netdata.old
	print "Moving netdata.dat to netdata.old...\n\n";
	move("c:\\eicndhcpd\\netdata.dat","c:\\dhcpd\\netdata.old");
    }
    # copy netdata.new file to netdata.dat
    print "Copying netdata.new to netdata.dat...\n\n";
    copy("netdata.new","c:\\eicndhcpd\\netdata.dat");

    # waiting the complete stop of all EICNDHCPD process
    print "Please wait, waiting the complete shutdown of the service...\n";
    sleep(15);

    # start EICNDHCPD process
    print "\nStarting EICNDHCPD service...\n\n";
  Win32::Service::StartService('',"EICNDHCPD")||
      die "Cannot start EICNDHCPD service: $!";
}
else{
    # unable to find netdata.new file
    print "\n\n\n\tERROR: unable to find new database (netdata.new file) !\n";
    print "\n                          ! EICNDHCPD ISN'T STOPED !\n\n";
    print "                             ! PROCESS ABORTED !\n\n";
}
 
