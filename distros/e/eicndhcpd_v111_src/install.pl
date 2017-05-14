#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# INSTALL.PL part
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
#$Header: install.pl,v 1.11 1999/06/27
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

use Win32::Registry; # Win32::Registry module: to modify the registry
use Win32::Service;  # Win32::Service module: to start/stop/status of services
use File::CheckTree; # File::CheckTree  module: to check if a tree exist
use File::Path;      # File::Path module: for creating directory
use File::Copy;      # File::Copy module: for files copy

my $perl_path="c:\\perl\\bin\\perl.exe"; # default path of Perl
my $dhcpd_path="c:\\eicndhcpd";          # default path for EICN DHCPD

###############################################################################
# 
# Display the title
#
open(INST,"<title.txt") || warn "Cannot open title.txt: $!";
while(<INST>){
    print $_;
}
close(INST);

print "\nPLEASE, TAKE A LOOK AT THE SHORT INSTALL.TXT ";
print "BEFORE CONTINUE INSTALL !\n\n";

# Check if there is all file
my $all_file=1;
open(LST,"<file.lst") || die "Cannot open file.lst: $!";
while(<LST>){
    chomp($_);
    # if one EICNDHCPD file ins't in the install directory
    unless(-e $_){
	print "\nWARNING: Unable to find $_ file!";
	$all_file=0;
	next;
    }
}
close(LST);
unless($all_file){
    print "\n\nINSTALLATION ABORTED!\n";
    goto END;
}

###############################################################################
#
# Check if EICNDHCPD service is running
#
my %status; 
 Win32::Service::GetStatus('','EICNDHCPD',\%status);
if($status{CurrentState}==4){
    # EICNDHCPD service is running
    print "\n\nWARNING: EICNDHCPD service is running !\n";
    print "Do you want to stop this service and continue (y/n)? : ";
    $_=<STDIN>;
    if(($_ ne "y\n")&&($_ ne "Y\n")){
	print "\n\n\nUnable to continue if EICNDHCPD service is running, ";
	print "ABORTED !\n\n\n";
	goto END;
    }
    else{
	print "\n\nStoping EICNDHCPD service...\n";
      Win32::Service::StopService('','EICNDHCPD')||
	  die "Cannot stop service:$!";
	print "EICNDHCPD service stoped!\n\n";
    }
}

###############################################################################
#
# path of perl.exe
#
PERL_PATH:
{
    print "Please enter the path of perl.exe \[c:\\perl\\bin\] : ";
    $_=<STDIN>;
    if($_ eq "exit\n"){
	goto END;
    }
    unless($_ eq "\n")
    {
	$perl_path=$_;
	chomp($perl_path);
    }
    
    $dhcpd_path=~ s#/#\\#g; # replace all / by \
    
    # remove the last \ if exist:
    ($perl_path)=($perl_path=~ /(.+)\\$/) if($perl_path=~ /.+\\$/);
    
    # add \perl.exe at the end if it don't exist:
    $perl_path= $perl_path . "\\perl.exe" unless($perl_path=~ /.+perl.exe$/);
    unless(-e $perl_path)
    {
	print "\n\n\n\nUNABLE TO FIND PERL.EXE FILE !\n";
	print "\nINVALID PATH FOR PERL.EXE, TRY AGAIN!\n\n";
	print "(Enter \"exit\" form perl path to quit install.pl)\n\n";
	goto PERL_PATH;
    }
}
###############################################################################
#
# path where to install EICN DHCPD
#
print "\n\nWhere do you want to install EICNDHCPD ?\n";
print "Type the path \[$dhcpd_path\] : ";
$_=<STDIN>;
unless($_ eq "\n")
{
    $dhcpd_path=$_;
    chomp($dhcpd_path);
}
$dhcpd_path=~ s#/#\\#g; # replace all / by \
($dhcpd_path)=($dhcpd_path=~ /(.+)\\$/) if($dhcpd_path=~ /.+\\$/);  # remove the last \ if exist
# print "\n",$dhcpd_path,"\n";;
if(validate("$dhcpd_path -e")) # check if path exist
{ # if path don't exist
    print "\n$dhcpd_path don't exist, do you want to create it (y/n)? : ";
    $_=<STDIN>;
    if(($_ eq "y\n")||($_ eq "Y\n")){
	# create the path
	print "\nCreating the path...\n";
	mkpath($dhcpd_path,1,0777);
	mkpath("$dhcpd_path\\log",1,0777); # make the log directory
    }
    else{
	print "\n\n\nNO VALID EICNDHCPD DIRECTORY, ABORTED !\n\n\n\n";
	goto END;
    }
}
else{ # if path exist
    my $update=0;
    open(LST,"<file.lst") || die "Cannot open file.lst: $!";
    while(<LST>){
	chomp($_);
	# if at leaste one EICNDHCPD files is in this directory:
	if(-e $_){
	    $update=1;
	    last;
	}
    }
    close(LST);
    if($update){
	print "\nWARNING: $dhcpd_path already contains some EICNDHCPD file!\n";
	print "Do you want to continue and overwrite this old installation (y/n) \[y\]? : ";
	$_=<STDIN>;
	goto END if(($_ ne "y\n")&&($_ ne "Y\n")&&($_ ne "\n"));
    }
}

###############################################################################
#
# copy all files to installation directory
#
print "\n\nCopying the files...\n\n";
open(LST,"<file.lst") || die "Cannot open file.lst: $!";
while(<LST>){
    chomp($_);
    next if($_ eq "instsrv.exe");
    print "Copy $_ to $dhcpd_path\\$_\n";
    copy("$_","$dhcpd_path\\$_") || die "Cannot copy $_ to $dhcpd_path\\$_: $!";
}
close(LST);

###############################################################################
#
# modify the paths in programs (dhcpd.pl, dhcpd2.pl, dhcpdmail.pl, refresh.pl)
#

# replace \ by \\
$perl_path=~ s/\\/\\\\/g;
$dhcpd_path=~ s/\\/\\\\/g;

# update these files with correct paths
&Modify_pl("dhcpd.pl");
&Modify_pl("dhcpd2.pl");
&Modify_pl("dhcpdmail.pl");
&Modify_pl("refresh.pl");

# replace \\ by \
$perl_path=~ s/\\\\/\\/g;
$dhcpd_path=~ s/\\\\/\\/g;

###############################################################################
#
# make the batch files (start_dhcpd, stop_dhcpd, refresh)
#
($pl2bat_path)=($perl_path=~ /^(.+)perl.exe/);
$pl2bat_path=$pl2bat_path . "pl2bat.bat";
`$pl2bat_path refresh.pl`;
`$pl2bat_path start_dhcpd.pl`;
`$pl2bat_path stop_dhcpd.pl`;
move("refresh.bat","$dhcpd_path\\refresh.bat");
move("start_dhcpd.bat","$dhcpd_path\\start_dhcpd.bat");
move("stop_dhcpd.bat","$dhcpd_path\\stop_dhcpd.bat");

###############################################################################
#
# install the service (inst srvany.exe)
#
$output=`instsrv.exe EICNDHCPD $dhcpd_path\\srvany.exe`;
if($output=~ /The service was successfuly added!/){
    print $output,"\n";
}
elsif($output=~ /This service has already been started!/){
    print "\n",$output,"\n";
    print "Do you want to remove old EICNDHCPD service \n";
    print "and replace with this installation (y/n) \[y\]? : ";
    $_=<STDIN>;
    $_="y\n" if($_ eq "\n"); # by default
    if(($_ eq "y\n")||($_ eq "Y\n")) 
    {
	$output=`instsrv.exe EICNDHCPD remove`; # remove old EICNDHCPD service
	print $output,"\n";
	$output=`instsrv.exe EICNDHCPD $dhcpd_path\\srvany.exe`;
	if($output=~ /The service was successfuly added!/){
	    print "\n",$output,"\n";
	}
	else{
	    print "\n$output\n\nERROR: UNABLE TO ADD EICNDHCPD SERVICE!\n\n";
	    print "NEW INSTALLATION ABORTED!\n\n\n";
	    goto END;
	}
    }
    else{
	print "\n\n\nOLD EICNDHCPD SERVICE NOT REMOVED!\n\n";
	print "NEW INSTALLATION ABORTED!\n\n\n";
	goto END;
    }
}
else{
    print "\n$output\n\nERROR: UNABLE TO ADD EICNDHCPD SERVICE!\n\n";
    print "NEW INSTALLATION ABORTED!\n\n\n";
    goto END;
}

###############################################################################
#
# modify the registry for the services
#
&Set_service_reg;

###############################################################################
#
# modify the registry for the eventlog
#
&Set_eventlog_reg;


###############################################################################
#
# End message
#
print "\n\n\n";
print "                       MODIFY THE DHCPD.CONF FILE NOW !\n\n";
print "      AND NEXT CREATE THE NETDATA.DAT FILE, SEE NETDATA.TXT FOR EXAMPLE.\n\n";
print "                  PLEASE READ THE SHORT INSTALL.TXT FILE!\n\n";
print "                      AND THEN REBOOT THE COMPUTER TOO !\n\n\n";
print " Have a nice day !\n";

 END:
{
    print "\n";
    <STDIN>
}


###############################################################################
#
# Subroutines
#

# Modify the paths of other script or program in a script file
sub Modify_pl
{
    my($file)=@_; # get argument: name of the script file to modify
    # open original file:
    open(PL,"<$file") || warn "Cannot open dhcpd.pl: $!";
    # open installed file:
    open(PL2,">$dhcpd_path\\$file") || warn "Cannot open dhcpd-m.pl: $!";
    while(<PL>){
	if($_=~ /c:\\\\dhcpd/){
	    # replace old script path with installation path:
	    $_=~ s/c:\\\\dhcpd/$dhcpd_path/;
	}
	if($_=~ /c:\\\\perl\\\\bin\\\\perl.exe/){
	    # replace old Perl path with the user specified path of Perl:
	    $_=~ s/c:\\\\perl\\\\bin\\\\perl.exe/$perl_path/;
	}
	print PL2 $_; # write the ligne to the installed script
    }
    close(PL2);
    close(PL);
}

# Modify the registry to add service parameters
sub Set_service_reg 
{
    my $REG;
    my $regkey="SYSTEM\\CurrentControlSet\\Services";
    $HKEY_LOCAL_MACHINE->Open($regkey,$REG) || die "Open: $!";
    
    # create "EICNDHCPD" key, if already exist, open it:
    $REG->Create("EICNDHCPD",$REG);
    $REG->Create("Parameters",$REG);
    # set the lauched application path (<perl path>\perl.exe here):
    $REG->SetValueEx("Application",undef,REG_SZ,$perl_path)||
	die "SetValueEx: $!";
    # set the parameters for this application (<dhcpd path>\dhcpd.pl here):
    $REG->SetValueEx("AppParameters",undef,REG_SZ,"$dhcpd_path\\dhcpd.pl")||
	die "SetValueEx: $!";
    # set the working directory of this application (<dhcpd path> here):
    $REG->SetValueEx("AppDirectory",undef,REG_SZ,"$dhcpd_path")||
	die "SetValueEx: $!";

    $REG->Close();
}

# Modify the registry to add EventLog parameters
sub Set_eventlog_reg
{
    my $REG;
    my $regkey="SYSTEM\\CurrentControlSet\\Services\\EventLog\\System";
    $HKEY_LOCAL_MACHINE->Open($regkey,$REG) || die "Open: $!";
    
    # create "EICNDHCPD" key, if already exist, open it:
    $REG->Create("EICNDHCPD",$REG);
    # set path of the resource-only DLL (where there is ID<->message relation):
    $REG->SetValueEx("EventMessageFile",undef,REG_SZ,
		     "$dhcpd_path\\eicndhcpdmsg.dll") || die "SetValueEx: $!";
    # set a needed standard value:
    $REG->SetValueEx("TypesSupported",undef,REG_DWORD,"7")||
	die "SetValueEx: $!";
    
    $REG->Close();
}
