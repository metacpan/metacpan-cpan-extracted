#!/perl/bin
# ------------------------------------------------------------------------ 
# EICNDHCPD v1.11 for NT4 
# EICNDHCPD Copyright (c)1998,1999 EICN & Nils Reichen <eicndhcpd@worldcom.ch> 
# All rights reserved.
# http://home.worldcom.ch/nreichen/eicndhcpd.html
# DHCPDMAIL.PL part
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
#$Header: dhcpdmail.pl,v 1.11 1999/06/27
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

use Socket;               # Socket module: for the IP connection

my($admin_mail,$smtp_server,$dhcpserver_ip,$subject,$message);

# get from the pipe:
$admin_mail=<STDIN>;      # E-Mail addresses
$smtp_server=<STDIN>;     # SMTP server IP address
$dhcpserver_ip=<STDIN>;   # DHCPD server IP address
$subject=<STDIN>;         # E-Mail subject
$message=<STDIN>;         # E-Mail message

chop($admin_mail); chop($smtp_server); chop($dhcpserver_ip);
chop($subject); chop($message);

$subject="$subject"."\r\n";               # add a "\r\n" to $subject
$message=~ s/\#/\r\n/gs;                  # replace all "\#" by "\r\n";

# Send E-Mail to "$admin_mail" from "DHCPD\@$dhcpserver_ip"
sendmail("DHCPD\@$dhcpserver_ip <dhcpd\@$dhcpserver_ip>",
	      "dhcpd\@$dhcpserver_ip",$admin_mail,
	      $smtp_server,$subject,$message)|| warn "Sendmail error: $!";


###############################################################################
# subroutine sendmail()
#
# send E-Mail
#
# in:  $from       email address of sender
#      $reply      email address for replying mails
#      $to         email address of reciever
#                  (multiple recievers can be given separated with space)
#      $smtp       name of smtp server (name or IP)
#      $subject    subject line
#      $message    (multiline) message
#
# out:  1 (TRUE)   success
#      -1          $smtphost unknown
#      -2          socket() failed
#      -3          connect() failed
#      -4          service not available
#      -5          unspecified communication error
#      -6          local user $to unknown on host $smpt
#      -7          transmission of message failed
#      -8          argument $to empty
#
# waring: don't use only "\n" but "\r\n" in $message !
#
# example:
#
#   sendmail("Bibi <bibi\@groucho.com>",
#            "bibi\@groucho.com",
#            "jack\@somewhere.com",
#            $smtp_server, $subject, $message);
#
# or
#
#   sendmail($from, $reply, $to, $smtp, $subject, $message);
#
# (sub changes $_)
# don't put a single line "\n.\n" into your message
# (it will be truncated there)
###############################################################################
sub sendmail
{
    my($from,$reply,$to,$smtp,$subject,$message)=@_;
    my($fromaddr)=$from;
    my($replyaddr)=$reply;

    $to=~ s/[ \t]+/, /g;               # pack spaces and add comma
    $fromaddr=~ s/.*<([^\s]*?)>/$1/;   # get from email address 
    $replyaddr=~ s/.*<([^\s]*?)>/$1/;  # get reply email address 
    $replyaddr=~ s/^([^\s]+).*/$1/;    # use first address
    
    unless($to){return(-8);}

    my($proto)=(getprotobyname('tcp'))[2];
    my($port)=(getservbyname('smtp','tcp'))[2];

    my($smptaddr) = ($smtp =~
/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) 
                    ? pack('C4',$1,$2,$3,$4)
                    : (gethostbyname($smtp))[4];

    unless(defined($smptaddr)) {return(-1);}
    
    unless(socket(S,PF_INET,SOCK_STREAM,$proto)) {return(-2);}
    unless(connect(S,pack('Sna4x8',PF_INET,$port,$smptaddr))) {return(-3);}

    my($oldfh)=select(S); $|=1; select($oldfh);

    $_=<S>; 
    if(/^[45]/) {close(S); return(-4);}

    print S "helo localhost\r\n";
    $_=<S>; 
    if(/^[45]/) {close(S); return(-5);}

    print S "mail from: <$fromaddr>\r\n";
    $_=<S>; 
    if(/^[45]/) {close(S); return(-5);}

    foreach(split(/,/,$to)){
        print S "rcpt to: <$_>\r\n";
        $_=<S>; 
	if(/^[45]/) {close(S); return(-6);}
    }

    print S "data\r\n";
    $_=<S>; 
    if(/^[45]/) {close(S); return(-5);}
    
    print S "To: $to\r\n";
    print S "From: $from\r\n";
    print S "Reply-to: $replyaddr\r\n" if($replyaddr);
    print S "Subject: $subject\r\n";
    print S "$message";
    print S "\r\n.\r\n";

    $_=<S>; 
    if(/^[45]/) {close(S); return(-7);}

    print S "quit\r\n";
    $_=<S>;

    close(S);
    return(1);
}

