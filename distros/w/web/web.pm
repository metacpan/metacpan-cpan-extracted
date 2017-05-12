package web;
require 5.001;

##############################################################################
# $Id: web.pm,v 1.44 2002/09/12 09:38:13 unrzc9 Exp $                 
# 
# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.
# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).
#
# Copyright 1999 Wolfgang Wiese.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.
#
# This modul was mainly made to serve the computer lab of the university
# Erlangen-Nuremburg for several scripts for many purposes.
# It is based on libraries of Wolfgang Wiese (xwolf@xwolf.com),
# the CGI-Modul of Lincoln D. Stein (lstein@genome.wi.mit.edu)
# and Steve Brenner's cgi-lib.pl.
#
##############################################################################
# Last Modified on:	$Date: 2002/09/12 09:38:13 $
# By:			$Author: unrzc9 $
# Version:		$Revision: 1.44 $ 
##############################################################################

use strict;

BEGIN {
    use Exporter   ();
    use vars       qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 1.44 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
    $web::VERSION = do { my @r = (q$Revision: 1.44 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
    $web::revision = '$Id: web.pm,v 1.44 2002/09/12 09:38:13 unrzc9 Exp $';
    # The above must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&HtmlTop &HtmlBot &WriteLog &ReplaceText &ReturnFlagContent 
    			&ReadLayout &Read_Parafile
    			&NUnlock &NLock &isZeit &isDatum &isURL &isMail &Fehlermeldung
    			&ReadParse &PrintHeader &Check_Name &numerically &Get_Seconds 
    			&GetWeekDay &isLeapYear &MakeTimeLocal &GetYearDay &GetDatebyYDay 
    			&Add_Days_to_Date &CgiDie &GetSentence &GetPassedDaysbyMonth
    			&NUnlockAll &RemoveHTML &Redirect &isIP);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw();
}
use vars      @EXPORT_OK;

# FIGURE OUT THE OS WE'RE RUNNING UNDER
# Some systems support the $^O variable.  If not
# available then require() the Config library
unless ($web::OS) {
    unless ($web::OS = $^O) {
	require Config;
	$web::OS = $Config::Config{'osname'};
    }
}
if ($web::OS=~/Win/i) {
    $web::OS = 'WINDOWS';
} elsif ($web::OS=~/vms/i) {
    $web::OS = 'VMS';
} elsif ($web::OS=~/Mac/i) {
    $web::OS = 'MACINTOSH';
} elsif ($web::OS=~/os2/i) {
    $web::OS = 'OS2';
} else {
    $web::OS = 'UNIX';
}

# Allowed chars following CERT.
$web::OKCHARS ='a-zA-Z0-9_\-\.@\/';  
              		
# Get the time-values
($web::sek,$web::minute,$web::stunde,$web::tag,$web::monat,$web::jahr,$web::wtag,$web::ytag,$web::isdst) = localtime(time);
$web::monat++;

if ($web::stunde < 10) {$web::stunde="0".$web::stunde;}
if ($web::minute < 10) {$web::minute="0".$web::minute;} 
if ($web::sek < 10) {$web::sek="0".$web::sek;}
$web::jahr += 1900;
@web::tage_im_monat = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
if (isLeapYear($web::jahr)) {
  $web::tage_im_monat[1]=29;
}

# Definitions for the date
%web::US_MONATSNAME = (1, "Jan", 2, "Feb", 3, "Mar", 4, "Apr", 5, "May", 6, "Jun",  
                    	7, "Jul", 8, "Aug", 9, "Sep", 10, "Oct", 11, "Nov", 12, "Dec");
%web::GER_MONATSNAME = (1, "Januar", 2, "Februar", 3, "M&auml;rz", 4, "April", 5, "Mai", 
	      6, "Juni", 7, "Juli", 8, "August", 9, "September", 10, "Oktober", 
	      11, "November", 12, "Dezember");
@web::wochentag = ("Sonntag","Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag");
@web::weekdays = ("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
$web::schaltjahr = 2000;

$web::zeit		= $web::tag.'.'.$web::monat.'.'.$web::jahr.' - ';
$web::zeit 		= $web::zeit.$web::stunde.':'.$web::minute.':'.$web::sek;
$web::UHRZEIT 		= "$web::stunde:$web::minute:$web::sek";
$web::datum 		= "$web::tag. $web::GER_MONATSNAME{$web::monat} $web::jahr";
$web::datum_german 	= $web::datum;
$web::datum_german_long = $web::wochentag[$web::wtag].", ".$web::datum_german;
$web::datum_english 	= $web::tag.". ".$web::US_MONATSNAME{$web::monat}." ".$web::jahr;
$web::datum_english_long = $web::weekdays[$web::wtag].", ".$web::datum_english;
$web::sektime 		= $web::sek+$web::minute*60+$web::stunde*3600;
$web::tagzeit           = GetPassedDaysbyMonth($web::monat);
$web::tagzeit 		+= $web::tag;
$web::tagzeit           += 365* $web::jahr;
$web::PARACOMMENT_SIGN 	= "_comment";

$web::LOCK_LOCATION = "/tmp";
	# Where do we put our lockfiles
$web::LOCK_CRIT_SLEEPTIME = 2;
	# How long will i wait for the lock beeing freed doing nothing.
	# After this time, i'll start to check if the previous setted lock is 
	# still valid.
	# This time has to be smaller as MAX_WAITLOCK.
$web::MAX_LOCKTIME = 10;
	# How long till a setted lock is going invalid and will be removed
	# by the next try to lock this file.
$web::MAX_WAITLOCK = 4;
	# How long will i wait for the lock to get freed.
	# Notice, that this time has to be smaller as MAX_LOCKTIME.
$web::PROGPID = $$;
	# The program-pid.
$web::PROGNAME = $0;
	# The name of the program
$web::allowuploads = 1;
	# Do we allow file-uploads? 1=yes, 0=no
$web::uploadfile = "/tmp/uploader.$$";
	# Which file will be used temporary for fileuploads.
$web::ReadParse_Debug =0;
	# Set it to 1 for debugging
%web::lockliste = ();
	# This list will be filled and emptied by the locking
	# procedures. The list will be used for the function NUnlockAll().
$web::errorlayout_file = "";
	# Default Fehlerlayout-Datei fuer Fehlermeldungen. Kann von Programmen
	# ueberschrieben werden, um beim Aufruf der Funktion Fehlermeldung() sich die
	# Angabe der Layoutdatei zu ersparen.
$web::POST_MAX = 1024 * 100;
	# Maximale Groesse fuer Uebertragungen in Bytes.		
##############################################################################
# SubRoutines
##############################################################################
sub HtmlTop {
  my ($title) = $_[0];

  return <<END_OF_TEXT;
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Frameset//EN\">

<html>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
END_OF_TEXT

}
##############################################################################
sub HtmlBot {
  return "</body>\n</html>\n";
}
##############################################################################
sub RemoveHTML {
  my $htmltext = $_[0];
  
  $htmltext =~ s/\s+/ /g; 
    	# Erstmal alle Leerzeilen usw. wegmachen
  $htmltext =~ s/(.+?<.*>)\s*(.+?)\s*(<\/.*>.*)/$1$2$3/gi;
    	# Leerzeichen zwischen Tags loeschen
  my $kom_a = '<!--';
  my $kom_b = '-->';
  $htmltext =~ s/$kom_a\s*(.+?)\s*$kom_b//ig; 
    	# Kommentare loeschen
  $htmltext =~ s/<title>\s*(.+?)\s*<\/title>//ig;
    	# Den Title loeschen. Diesen haben wir vorher schon woanders gespeichert
  $htmltext =~ s/<head>\s*(.+?)\s*<\/head>//ig;
    	# Der Head ist hier uninteressant.
  $htmltext =~ s/<script\s*(.+?)\s*<\/script>//ig;
    	# Skripts loeschen
  $htmltext =~ s/&nbsp;/ /ig;
    	# Erzwungene Leerzeichen einsetzen
  $htmltext =~ s/&amp;/\&/ig;
    	# UND-Zeichen einbauen
  $htmltext =~ s/&szlig;/ss/ig;
    	# Puckel-S-Zeichen einbauen
  $htmltext =~ s/&uuml;/ue/ig;
  $htmltext =~ s/&auml;/ae/ig;
  $htmltext =~ s/&ouml;/oe/ig;
  $htmltext =~ s/&Uuml;/Ue/ig;
  $htmltext =~ s/&Auml;/Ae/ig;
  $htmltext =~ s/&Ouml;/Oe/ig;
	# Umlaute ersetzen    
  $htmltext =~ s/<br>/\n/gi;
    	# Zeilenumbrueche aus HTML nehmen
  $htmltext =~ s/<p>/\n\n/gi;
    	# Absaetze kennzeichnen
  $htmltext =~ s/<([^>]|\n)*>//ig;
    	# Alle HTML-Tags loeschen
  $htmltext =~ s/[\r\n\t ]+/ /ig; 
	# Ueberzaehlige Zeilen/Spaltenabstaende wegmachen

  return $htmltext;  
}
##############################################################################
sub WriteLog {
  my ($logfile) = $_[0];
  my ($logtext) = $_[1];
  my $userip = $ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_HOST'};
  
  if (($logfile) && ($logtext)) {
      open(LOG,">>$logfile") || return 0;
        print LOG "$web::zeit\t$userip\t$logtext\n";    
      close LOG;
      return 1; 
  } else {
      return 0;
  }
}
##############################################################################
sub ReplaceText {
  my ($insert) = $_[0];
  my ($text) = $_[1];
  my $pic;
  
  if (not $text) {
    if ($insert =~ /#TEXT#/i) {
      $insert =~ s/#TEXT#//i;    
    }
    return $insert;
  }
  if ($text =~ /<([^>]|\n)*>/) {
      $insert =~ s/#TEXT#/$text/gi;           
  } else {
      $pic = $text;  
      $pic =~ s/\n\r/\n/gi;
      $pic =~ s/[\n]/<_BR_>/gi;
      $pic =~ s/([a-z]+):\/\/([^:\s\r\n ]+)([\n\r\s]+)?/<a href=\"$1:\/\/$2\">$1:\/\/$2<\/a>$3/gi;        
      $insert =~ s/#TEXT#/$pic/i;           
      $insert =~ s/<_BR_>/\n/gi;           
  }
    
  return $insert;
}
#############################################################################
sub GetSentence {
  my $text = $_[0];
  my $search = $_[1];
  my $start = $_[2];
  my $stop = $_[3];
  my $result;
  
  if ($text =~ /$search/i) {
    if ((not $stop) || (not $start)) {
      ($result) = $text =~ m/\s*([^.!?]*$search.*?[.!?])/i;
    } else {
      my $pre = substr($text,0,index(lc($text),lc($search)));
      $pre = substr($pre, index(lc($pre),lc($start))+length($start));
      my $post = substr($text,index(lc($text),lc($search)));
      $post = substr($post,0,index(lc($post),lc($stop)));
      $result = $pre.$post;
    }
    return $result;

  } else {
    return "";
  } 
  
  # Notice:
  # I could have made the second part also with a regular expression
  # but for long strings the regular expressions become very
  # slow, if there are many linebreaks!
  # There are 1000 ways to solve a problem in perl. It's a
  # matter of personal taste how to solve it -as long it works.

}
#############################################################################
sub ReturnFlagContent {
  my $flag = $_[0];
  my $text = $_[1];
  my $result;
  if ($text =~ /<$flag>(.+?)<\/$flag>/i) {
      $result = $1;
  }  
  return $result;
}
##############################################################################
sub ReadLayout {
 my ($LAYOUTFILE)=@_;
 my (@LAYOUTDATA);
 
 &NLock($LAYOUTFILE) || &Fehlermeldung("Datei-Lock fuer die Layoutdatei $LAYOUTFILE konnte nicht gesetzt werden.");
 open(f1,"<$LAYOUTFILE") || &Fehlermeldung("Kann Layout-Datei $LAYOUTFILE nicht oeffnen!");
  while(<f1>) {
   chomp($_); 
     push(@LAYOUTDATA, $_);  
  }
 close f1;
 &NUnlock($LAYOUTFILE);
 return @LAYOUTDATA;
}
##############################################################################
sub Read_Parafile {
  my (%resulthash);
  my ($filename)=@_;
  my ($entry_name, $entry_value, $entry_comment);
  my ($kurznamebez);
  my ($entry_wertzeile);
  my ($lastcomment);
  
  $resulthash{'config_file'} = $filename;
  if (-r $filename) {
    &NLock($filename) || &Fehlermeldung("Fehler beim Setzen des Dateilocks auf $filename");
    open(f1,"<$filename");
      while(<f1>) {
        chomp($_);
        if ($_ =~ /^\s*#/) {
           if ($lastcomment) {
              $kurznamebez = $lastcomment.$web::PARACOMMENT_SIGN;
              $resulthash{$kurznamebez} .= $';     
          }        
        } else {
           ($entry_name, $entry_value) = split(/\s+/,$_,2);  
           if ($entry_name) { 
             $resulthash{$entry_name} = $entry_value;
             $lastcomment = $entry_name;

           } else {
             $lastcomment="";
           }    
        }
      }
    close f1;
    &NUnlock($filename);
    $resulthash{'status'}=200;
  } else {
    $resulthash{'status'}=404;
  }

  return %resulthash;
}
##############################################################################
sub isIP {
 my $ip = $_[0];

 # This routine was mainly made by Rolf Rost (see perldoc below)
 
 if (not ($ip =~ /\./)) { 
   return 0;
 }

 if ( $ip =~ /[^0-9\.]/ ){ 
   # An IP consists out of numbers and the dot only..
   return 0;
 } 
 
 my $val = my($a, $b, $c, $d) = split(/\./, $ip);
 # A valid IP consists out of 4 parts
 if( $val != 4 ){ 
   return 0;
 }
 
 # Check range:
 if (  ($a <0 || $a >255) || ($b <0 || $b >255) || ($c<0 || $c >255) || ($d <0 || $d >255)  ){
   return 0;
 }
 
 # All numbers at 0 is invalid too:
 if ( ($a == 0) && ($b == 0) && ($c == 0) && ($d == 0)){
   return 0;
 }
 
 # All numbers at 255 is invalid too:
 if ( ($a == 255) && ($b == 255) && ($c == 255) && ($d== 255) ){
   return 0;
 }
 
 # The syntax is valid
 return 1;

}
##############################################################################
sub isZeit {
  my ($testzeit) = @_;
  if (not $testzeit) {return 0;}
  
  if (not ($testzeit =~ /:/)) { return 0;}
  my ($dstunde, $dminute) = split(/:/,$testzeit,2);
  
  if (($dstunde < 0) || ($dstunde >24)) {
    return 0;
  }
  if (($dminute < 0) || ($dminute >59)) {
    return 0;
  }
  
  return 1;  
}
##############################################################################
sub isDatum {
  my ($testdatum) = @_;  
  if (not $testdatum) {return 0;}
  if (not ($testdatum =~ /\./)) { return 0;}
  
  my ($dtag, $dmonat, $djahr) = split(/\./,$testdatum,3);
  if (($dtag < 1) || ($dtag >31)) {
    return 0;
  }
  if (($dmonat < 1) || ($dmonat >12)) {
    return 0;
  }
  if ($djahr < 0) {
    return 0;
  }
  
  return 1;
}
##############################################################################
sub isMail {
  my ($testmail) = @_;
  
  if (not $testmail) {
    return 0;
  }
  if ($testmail =~ /^[\w.-]+\@[\w.-]+$/) {
    return 1;
  }
  return 0;
}
##############################################################################
sub isURL {
  my $askurl =$_[0];

  $askurl =~ s/[<>\|;\(\)\$^!\^\[\]\"\'\`]//g;
  if (length($askurl) < 11) {
    return 0;
  }
  if ($askurl =~ /^([a-z]+):\/\/([^:\/]+)(:[0-9]+)?/i) {
    if (index($2,".") <=0) {
      return 0;
    } else {
      if (length($2) < 5) {
        return 0;
      }
      $askurl = $1;
      if (not ($askurl =~ /^(ftp|http|https|news|telnet)/i)) {
        return 0;
      } 
      return 1;
    }
  } else {
    return 0;    
  }
}
##############################################################################
sub Fehlermeldung {  # Gibt Fehlermeldungen aus
 my ($fehlertext)=$_[0];
 my ($fehlertitel) = $_[1];
 my ($fehlerlayout) = $_[2] || $web::errorlayout_file;
 my $output;
 my $key;
 
 if (($ENV{'HTTP_USER_AGENT'}) || ($ENV{'SERVER_NAME'})) {
   if (-r $fehlerlayout) {
     print(&PrintHeader);  
     open(f8,"<$fehlerlayout");
       while(<f8>) {
        $output .= $_;
       }
     close f8;
     $output =~ s/#ZEIT#/$web::zeit/gi;
     $output =~ s/#VERSION#/$web::VERSION/gi;
     $output =~ s/#ERRORTEXT#/$fehlertext/gi;
     $output =~ s/#SYSTEMMELDUNG#/$fehlertext/gi;
     $output =~ s/#SYSTEMMESSAGE#/$fehlertext/gi;
     $output =~ s/#TITEL#/$fehlertitel/gi;
     $output =~ s/#TITLE#/$fehlertitel/gi;
     foreach $key (keys %ENV) {
       $output =~ s/#$key#/$ENV{$key}/gi;
     }
     print "$output";
    
   } else {
     print(&PrintHeader);
     print "<HTML>";
     print "<HEAD><TITLE>$fehlertitel</TITLE>\n";
     print "</head>\n";
     print "<BODY bgcolor=#ffffff>\n";
     print "<p><h2>$fehlertitel</h2><br>";
     print "<b>$fehlertext</b>\n";
     print "<p><BR>\n"; 
     print " <p><br> <address>\n";
     print "Webmaster (<a href=\"mailto:$ENV{'SERVER_ADMIN'}\">E-Mail</a>: $ENV{'SERVER_ADMIN'}), \n";
     print "$web::GER_MONATSNAME{$web::monat} $web::jahr</address>\n";
     print "</body></html>\n";
   }
 } else {
   print "$0: Error\n";
   print "$fehlertext\n";
 }
 NUnlockAll();
 exit(0);
}
##############################################################################
sub CgiDie {
  Fehlermeldung($_[0],"Error");
}
##############################################################################
sub ReadParse {
 my $buffer;
 my ($namebuffer,$valuebuffer);
 my @nvpairs;
 my $pair;
 my $boundary ="";
 my ($fieldname, $filetype);
 my ($filename);
 my ($savefile, $head);
 my (@cdargs);
 my $i;
 my $last;
 my $bytes;
 my %in;
 my $tmpsavefile = $web::uploadfile;
 my ($meth,$content_length) = ('','');
 $content_length = defined($ENV{'CONTENT_LENGTH'}) ? $ENV{'CONTENT_LENGTH'} : 0;
 $meth =$ENV{'REQUEST_METHOD'} if defined($ENV{'REQUEST_METHOD'});
 my $type = $ENV{'CONTENT_TYPE'};
 
  # Disable warnings as this code deliberately uses local and environment
  # variables which are preset to undef (i.e., not explicitly initialized)
  my $perlwarn = $^W;
  $^W = 0;
 
 if (($web::POST_MAX > 0) && ($content_length > $web::POST_MAX)) {
   $in{'status'} = "Content-Length zu gross";
   return %in;
 }
 if (($ENV{'CONTENT_TYPE'}) && ($ENV{'CONTENT_TYPE'} =~ /multipart\//)) {
   if ($ENV{'CONTENT_TYPE'} =~ /boundary=(--\S+)/) {
     $boundary="--".$1;
   }
 }
 if ($boundary ne "") {
   if ($web::ReadParse_Debug) {
     print(&PrintHeader);
   }
   $head=1;
   $fieldname="";
   $filename="";
   $filetype="";
   $savefile=0;
   while(<STDIN>) {
     if ($head) {
       chop;
       if (/^Content-Disposition:\s+(.+)\s*$/i) {
         @cdargs = split(/\s*;\s*/,$1);
         for ($i=0; $i<=$#cdargs; $i++) {
           if ($cdargs[$i] =~ /^filename="([^"]+)"/i) {
             $filename=$1;
             if ($filename =~ /([^\\:]+)$/) {
               $filename =$1;
             }
           }
           if ($cdargs[$i] =~ /^name="([^"]+)"/i) {
             $fieldname = $1;
           }
         }
       } elsif (/^Content-Type:\s+(.+)\s*$/i) {
         $filetype= $1;
       }
       
       if (/^\s*$/) {
         $head=0;
         if ($filename ne "") {
           $savefile = open(FILE,">$tmpsavefile");
           $last ="";
           $bytes=0;
         }
       }
     } elsif ($_ =~ /^$boundary/) {
       $head=1;
       if ($savefile) {
         close FILE;
         $savefile=0;
         if ($web::ReadParse_Debug) { 
           print "Datei $filename ($bytes Byte) wurde erfolgreich nach $tmpsavefile gespeichert.<BR>";
         }
         if ($web::allowuploads) {
           $filename = Check_Name($filename);
           $filename = "/tmp/".$filename;
           if (not $in{'filename'}) {
             $in{'filename'} = $filename;
           } else {
             $in{'filename'} .= ", ".$filename;
           }
           system("cp $tmpsavefile $filename");
         }
       }
       $filename = $fieldname = $filetype = "";
     } elsif ($savefile) {
       if (/([\r\n]+)$/) {
         print FILE $last.$`;
         $bytes += length($last.$`);
         $in{'bytes'} += length($last.$_);
         $last = $1;
       } else {
         print FILE $last.$_;
         $bytes += length($last.$_);
         $last ="";
         $in{'bytes'} += length($last.$_);
       }
     } elsif ($filename eq "" && $fieldname ne "") {
       $in{$fieldname} .= $_; 
     }
     if ($web::ReadParse_Debug && /^[\n\r\t\x20-\x7f\xa0-\xff]*$/) { 
       print "** $_ <br>";
     }
   }
   if ($savefile) { 
     close FILE; 
     $savefile=0;
   }
   for $i (keys(%in)) {
     $in{$i} =~ s/[\n\r]+$//;
     if ($web::ReadParse_Debug) {
       print "in{$i} = (".$in{$i}.")<br>\n";
     }
   }
   unlink($tmpsavefile); 
   return (%in); 
 } else {
#   if (!defined $meth || $meth eq '' || $meth eq 'GET' || 
#      $type eq 'application/x-www-form-urlencoded') {
#     $buffer = $ENV{'QUERY_STRING'} if defined $ENV{'QUERY_STRING'};; 
#     $buffer ||= $ENV{'REDIRECT_QUERY_STRING'} if defined $ENV{'REDIRECT_QUERY_STRING'};      
#   } else {
#  
#     read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});  
#   }
   if ($ENV{'REQUEST_METHOD'} eq "GET") { $buffer = $ENV{'QUERY_STRING'} || $ENV{'REDIRECT_QUERY_STRING'}; } 
   else { read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});  }

   if ((not $buffer) && ($ENV{'PATH_INFO'})) {   
     $buffer = $ENV{'PATH_INFO'};
     $buffer =~ s/^\///;
   } elsif (not $buffer) {
     $buffer = @ARGV; 
   }
 
   @nvpairs = split(/&/,$buffer);
   foreach $pair (@nvpairs)
    {  
      ($namebuffer, $valuebuffer) = split(/=/, $pair);
      if ($namebuffer) {
        $namebuffer =~ tr/+/ /;
        $namebuffer =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      }
      if ($valuebuffer) {
        $valuebuffer =~ tr/+/ /;
        $valuebuffer =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      }
      if (exists($in{$namebuffer})) {
        $in{$namebuffer} .= ", $valuebuffer";
      } else {
       $in{$namebuffer}=$valuebuffer;
      }
    }
  }
  return %in;
} 
################################################################################# 
sub PrintHeader {
  my $reset_cookie = shift;
  my $reprint = shift || $web::HEADER;
  my $cookies = shift;
  my $path = shift || "/";
  my $expire = shift || 30;
  my $domain = shift;
  my $key;
  my $result;
  my $SETDOMAIN;
  
  if ($reprint==1) {
    return;
  }
  if ($domain) {
    $SETDOMAIN = " domain=$domain;";
  }
  $web::HEADER = 1;
  if ($reset_cookie) {
    my ($sec,$min,$hr,$mday,$mon,$yr,$wday,$yday,$isdst) = gmtime(time + (86400*$expire)); 
    my @days = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
    my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    my $expdate = sprintf("%3s, %02d-%3s-%4d %02d:%02d:%02d GMT",$days[$wday],$mday,$months[$mon],$yr+1900,$hr,$min,$sec);
    
    if (ref($cookies) eq 'HASH') {
      foreach $key (keys %{$cookies}) {
        $result .= "Set-Cookie: $key=$cookies->{$key};";
        $result .= " expires=$expdate;";
        $result .= " path=$path;";
        $result .= "$SETDOMAIN"; 
        $result .= "\n"; 
      }
    } elsif ($ENV{'HTTP_COOKIE'}) {
      my ($name,$cid);
      my $i;
      my @cookiefeld = split(/;/,$ENV{'HTTP_COOKIE'});
      foreach $i (@cookiefeld) {
        ($name,$cid) = split(/=/,$i);
        $result .= "Set-Cookie: $name=$cid;";
        $result .= " expires=$expdate;";
        $result .= " path=$path;";
        $result .= "$SETDOMAIN";
        $result .= "\n";
        $web::COOKIES{$name} = $cid;
      }
    }  
  }
  $result .= "Content-type: text/html\n\n"; 
  return $result;
}
##############################################################################
sub Check_Name {
  my ($chk_name)=$_[0];
  $chk_name =~ s/[^$web::OKCHARS]//g;
  return $chk_name;
} 
##############################################################################
sub numerically {
  $a <=> $b;
}
################################################################################
sub Get_Seconds {
 # Returns the daytime in seconds of a given time with the format 'XX:YY:ZZ'.
 my ($giventime)=@_;
 my ($givenh,$givenm,$givens);
 if (index($giventime,':') < 0)  {return 0;}
 ($givenh,$givenm,$givens)=split(/:/,$giventime);
 return ($givenh*3600+$givenm*60+$givens); 
}
################################################################################
sub isLeapYear {
    my $year  = shift || $web::jahr;

    return 1
        if ( ( $year / 4   == int( $year / 4   ) ) &&
             ( $year / 100 == int( $year / 100 ) ) &&
             ( $year / 400 == int( $year / 400 ) )    );

    return 1
        if ( ( $year / 4   == int( $year / 4   ) ) &&
             ( $year / 100 != int( $year / 100 ) )    );

    return 0;
}
################################################################################
sub GetDatebyYDay {
  my ($yday) = $_[0];
  my $jahr = $_[1] || $web::jahr;
  my $msumme;
  my $mon;
  my $this_monat;
  my $schalt;
  my $rescue;
  
  $rescue = $web::tage_im_monat[1];
  $schalt = isLeapYear($jahr);  
  $web::tage_im_monat[1] = 28 + $schalt;
  
 
  
  if (($yday < 1) || ($yday > (365+$schalt))) {
    return;
  }
  for ($mon=0; $mon<=11; $mon++) {
    $msumme += $web::tage_im_monat[$mon];
    if ($msumme >= $yday) {
      $this_monat = $mon+1;
      $msumme -= $web::tage_im_monat[$mon];
      $yday -= $msumme;
      if ($yday==0) {
        $yday = $web::tage_im_monat[$mon-1];
        $this_monat = $mon;
      }
      last;
    }
  }
  $web::tage_im_monat[1] = $rescue;
  return "$yday.$this_monat";
}
################################################################################
sub GetWeekDay {
    my $inputdatum = shift;

    return '-1'
        unless ( isDatum( $inputdatum ) );

    my ( $mday, $mon, $year ) = split( /\./, $inputdatum, 3 );

    $year += 1900
        if ( $year < 999 );

    my $a = int( ( 14 - $mon ) / 12 );
    my $y = $year - $a;
    my $m = $mon + ( 12 * $a ) - 2;
    my $result = ( $mday + $y + int($y/4) - int($y/100) + int($y/400) + int(31/(12*$m)) ) % 7;
    return $result;
}
##############################################################################
sub MakeTimeLocal {
  my $zeit = shift;
  my ($dat_datum,$dat_uhr);
  my ($dat_tag,$dat_monat,$dat_jahr);
  my ($stunds, $mins, $seks);
  my $result;
  
  if (not $zeit) {
    return;
  }
  use Time::Local;
  ($dat_datum,$dat_uhr) = split(/ - /,$zeit,2);
  ($dat_tag, $dat_monat, $dat_jahr) = split(/[\.:]/,$dat_datum,3);
  ($stunds, $mins, $seks) = split(/:/,$dat_uhr,3);  
  $dat_monat--;
  $dat_jahr -= 1900;

  if ($dat_monat <0) { $dat_monat=0;}
  $result = timelocal($seks, $mins, $stunds, $dat_tag, $dat_monat, $dat_jahr);
  return $result;
}
################################################################################
sub GetYearDay {
  my $inputdatum = shift;
  my $res  = 0;
  my $cnt;
  my $save= $web::tage_im_monat[1];

  return '-1'
        unless ( isDatum( $inputdatum ) );

  my ( $mday, $mon, $year ) = split( /\./, $inputdatum, 3 );

  $year += 1900  if ( $year < 999 );
  $mon--;

  $web::tage_im_monat[1] = 28 + isLeapYear( $year );

  for ( $cnt = 0; $cnt < $mon; $cnt++ ) {
      $res += $web::tage_im_monat[$cnt];
  }

  $web::tage_im_monat[1] = $save;

  return ( $res + $mday );
  
}
################################################################################
sub GetPassedDaysbyMonth {
  my $monat = shift;
  my $i;
  my $count;
  
  if (($monat<=1) || ($monat > 12)) {
    return 0;
  }
  $monat--;
  
  for ($i=0; $i<$monat; $i++) {
    $count += $web::tage_im_monat[$i];
  }
  return $count;
}
################################################################################
sub Add_Days_to_Date {
  my $inputdatum = $_[0];
  my $inputtage = $_[1];
  my $tagzahl;
  my $rescue = $web::jahr;;
  my @datumsfeld;
  my $thisyear;
  my $schalt;
  
  $tagzahl = GetYearDay($inputdatum);
  if ($tagzahl < 0) {
    return $tagzahl;
  }
  if (not ($inputtage =~ /\d/)) {
    return "-2";
  }
  @datumsfeld = split(/\./, $inputdatum);  
  $thisyear = $datumsfeld[2];
  $schalt = isLeapYear($thisyear);  
  
  $tagzahl += $inputtage;
  
  if ($tagzahl > 0) {
    while ($tagzahl > (365 + $schalt)) {
      $tagzahl =  $tagzahl - (365 + $schalt);
      $thisyear++;
      $schalt = isLeapYear($thisyear); 
    }
  } else {
    while ($tagzahl <=0) {
      $thisyear--;
      $schalt = isLeapYear($thisyear); 
      $tagzahl += (365 + $schalt);
    } 
  }
  my $resultdate = GetDatebyYDay($tagzahl,$thisyear);
  $resultdate = "$resultdate.$thisyear";
  return $resultdate;
}
################################################################################
sub NLock {
  my ($file) = $_[0];
  my $SLEEP_COUNT=0;
  my @FULL_PATH = split("/", $file);
  my $LOCK_NAME = pop(@FULL_PATH);
  my $LOCK_PATH = $web::LOCK_LOCATION."/$LOCK_NAME.lck";
  my $timecount;
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime);
  my ($sec,$min,$hour,$mday,$mon,$myear);
  my $result;
 
  if ($web::OS =~ /Windows/i) {
    return 1;
    # No link() and unlink() under windows :(
    # We don't want this be a reason to make the whole program fail.
    # Instead we only make this function obsolet then...
  }
 
  if (not $file) {
    return 0;
  }
  ($web::sek,$web::minute,$web::stunde,$web::tag,$web::monat,$web::jahr,$web::wtag,$web::ytag,$web::isdst) = localtime(time);
  $web::monat++;
  $web::jahr=1900 + $web::jahr;
  $web::sektime = $web::sek+$web::minute*60+$web::stunde*3600;
  while (-l $LOCK_PATH) {
    $SLEEP_COUNT++;
    sleep 1;
    if ($SLEEP_COUNT == $web::LOCK_CRIT_SLEEPTIME) {
      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime) = lstat($LOCK_PATH); 
      ($sec,$min,$hour,$mday,$mon,$myear) = localtime($mtime);
      $timecount = $sec+$min*60+$hour*3600 + $web::MAX_LOCKTIME;
      
      if ($web::sektime > $timecount) {
         unlink $LOCK_PATH;
         if (symlink($file, $LOCK_PATH)) {
           $web::lockliste{$file} =1;
           return 1;
         } else {
           return 0;
         }
      }
    }
    if ($SLEEP_COUNT >= $web::MAX_WAITLOCK) {
      return 0;
    }
  }
  if (symlink($file, $LOCK_PATH)) {
    $web::lockliste{$file} =1;
    return 1;
  } else {
    return 0;
  }

}
################################################################################
sub NUnlock {
  my ($file) = $_[0];
  my @FULL_PATH = split("/", $file);
  my $LOCK_NAME = pop(@FULL_PATH);
  my $LOCK_PATH = $web::LOCK_LOCATION."/$LOCK_NAME.lck";
  
  if ($web::OS =~ /Windows/i) {
    return 1;
    # No link() and unlink() under windows :(
    # We don't want this be a reason to make the whole program fail.
    # Instead we only make this function obsolet then...
  }
  delete $web::lockliste{$file};
  return (unlink $LOCK_PATH);
}
################################################################################
sub NUnlockAll {
  my $key;
  my @FULL_PATH;
  my $LOCK_NAME;
  my $LOCK_PATH;

  if ($web::OS =~ /Windows/i) {
    return 1;
    # No link() and unlink() under windows :(
    # We don't want this be a reason to make the whole program fail.
    # Instead we only make this function obsolet then...
  }
  
  foreach $key (keys %web::lockliste) {
    @FULL_PATH = split("/", $key);
    $LOCK_NAME = pop(@FULL_PATH);
    $LOCK_PATH = $web::LOCK_LOCATION."/$LOCK_NAME.lck";
    unlink $LOCK_PATH;
    delete $web::lockliste{$key};
  }
  return 1;
}
################################################################################
sub Redirect {
 my ($location)=@_;
 print "Status: 302 Found\n";
 print "Location: $location\n";
 print "URI: <$location>\n";
 print "Content-type: text/html\r\n\r\n"; 
}
################################################################################
END { }       # module clean-up code here (global destructor)
1; # return true
##############################################################################
__END__

=head1 NAME

Web - A set of useful routines for many webworking purposes

=head1 SYSTEM REQUIREMENTS

This module was primarily made for UNIX/Linux-Systems.
Parts of it cannot be used on other systems. E.g. the
procedures for file locking demand systems that
can use symlinks. 
If you use the modul on systems where symlinks
cannot be used, fatal errors may happen.

=head1 SYNOPSIS

use web;

=head1 ABSTRACT

This perl module serves users with several useful routines for many
purposes, like generating webpages, processing CGI scripts, working
with XML datafiles and net-connections.
It also uses own variants of routines, that was invented first in the 
famous libraries CGI.pm and cgi-lib.pl.

=head1 INSTALLATION

If you don't have sufficient privileges to install web.pm in the Perl
library directory, you can put web.pm into some convenient spot, such
as your home directory, or in cgi-bin itself and prefix all Perl
scripts that call it with something along the lines of the following
preamble:

        use lib '/home/myname/perl/lib';
        use web;

=head1 DESCRIPTION

=head2 NLock

This routine allows to set a filelock across NFS-boundaries.
The common used perl-routine flock() fails at this point, so this routine
is a useable alternative for bigger file-systems.
It uses the modular functions link() and unlink() to mark a file
locked. 
In addition to this, it also gives the locked file a counter: 
A file that is locked for more than $web::MAX_LOCKTIME seconds
will be freed by the next process that calls NLock() on this file.
A calling process gets either 0 or 1 as a return value, where 1
is returned if the file-locking was successful.
0 is returned only if the process waits for more than $web::MAX_WAITLOCK
seconds or if symlink() fails.

Example 1:

	$filename = "data.txt";
	NLock($filename);
	open(f1,"$filename");
	# do something
	close f1;
	NUnlock($filename);
	
Example 2:

	#!/local/bin/perl5
	use web;

	$stat= &NLock("jump.pl");
	print "Lock: stat= $stat\n";
	$stat= &NLock("jump.pl");
	print "Lock this file again: stat= $stat\n";
	sleep 8;
	$stat= &NLock("jump.pl");
	print "Lock this file again: stat= $stat\n";
	$stat= &NUnlock("jump.pl");
	print "Unlock: stat= $stat\n";
	exit;

=head2 NUnlock

This routine removes the filelock that was set with NLock().
See NLock().

=head2 NUnlockAll

In using this command, you can remove all file-locks, that was set with 
NLock() and which wasn't removed before.
It takes the list of file-locks out of the hash %web::lockliste.

=head2 MakeTimeLocal

Translates the timesyntax of web.pm into the standard time-syntax, which
is the seconds since 1970.

=head2 GetYearDay

This routine can be used to calculate a day's position within
the year in days.
It returns -1 if the argument is no date.

Example:

	$today = "$web::tag.$web::monat.$web::jahr" || "14.9.1999";
	$number_of_days = GetYearDay($today);
	print "Date: $today; It is the ${number_of_days}th day in this year.\n";

=head2 GetWeekDay

By using this routine you'll get the weekday of a given date, which is a number
between 0 (for sunday) and 6 (for saturday).
If the argument is wrong, -1 will be returned.

Example:

	$today = "$web::tag.$web::monat.$web::jahr" || "14.9.1999";
	$weekday = GetWeekDay($today);
	print "It is $web::wochentag[$weekday], $today.\n";


=head2 isLeapYear

This function returns true, if the argument is a leapyear.
If no argument is given, the current year is used.

Example:

	$this_year = 1999;
	if (isLeapYear($this_year)) {
	  print "It's leapyear.\n";
	} else {
	  print "No leapyear.\n";
	}
	# Returns 'No leapyear.'


=head2 GetDatebyYDay

This is the opposite of the GetYearDay() routine. It calculates the date
from a day's position within a year.
It returns nothing if the argument is out of range [1..365].

Example:

	$num_of_yearday = 32;
	$date = GetDatebyYDay($num_of_yearday);
	print "The date is $date\n";
	# Returns 'The date is 1.2.1999', if $web::jahr = 1999.
	

=head2 Add_Days_to_Date

Adds a number of days to a given date. Notice, that it works for adding only.
Negative daynumbers might lead to errors in case of a number smaller than
-365.
 
Example:

	$startdate = "1.11.1999";
	$modi_days = 119;
	$enddate = Add_Days_to_Date($startdate,$modi_days);
	print " $startdate + $modi_days Day(s) = $enddate\n";
	# Will return "28.2.2000".


=head2 Get_Seconds

Returns the number of seconds elapsed since midnight of a given time or 0
if the time format isn't valid (hour:minute:second).

Example:

	$jetztzeit = $web::stunde.":".$web::minute.":".$web::sek;
	$textzeit = "12:00:00";
	$diff_sekunden = abs(Get_Seconds($jetztzeit)-Get_Seconds($textzeit));
	print "Time differs with $diff_sekunden seconds.\n";


=head2 GetPassedDaysbyMonth

Returns the number of days that have passed by the inputvalue, which
represend the number of a month.

Example:

	$month = 8;
	$passed_days = GetPassedDaysbyMonth($month);
	print "$passed_days days have passed, before the $month. month came\n";



=head2 Check_Name

Sometimes you need to get file names or other data from the internet.
Due to the fact that you'll never know who can touch the data, you 
need to make sure that no one can send special chars which allow the
execution of system commands.
CERT gave out a set of characters that are harmless. They are set in
the variable $web::OKCHARS as "a-z, A-Z, 0-9 _-.@/".
This routine will check the argument for other characters and remove
them from the string. That way, you can take filenames from the web
without being afraid that someone else sends a dangerous string.

Example:

	$insecure_filename = $ENV{'QUERY_STRING'};
	$secure_filename = Check_Name($ENV{'QUERY_STRING'});
	
	if (length($secure_filename) != length($insecure_filename)) {
	  print(PrintHeader);
	  print "The query-string contains invalid signs.";
	  exit;
	} else {
	  open(f1,"<$secure_filename") || Fehlermeldung("File $secure_filename not found.");
	  # do something
	  close f1;
	}

Using Check_Name(), query strings like 
	"/tmp/something|+'/bin/term+-display+131.188.3.9" 
won't work.
		

=head2 PrintHeader

Returns the string "Content-type: text/html\n\n", if it wasn't returned before.
Additionally it can reset cookies if there were some before on this domain
or set new cookies by using a hash-reference.
The additional parameters are:

Arguments:

	   1		Activates the setting of cookies. If new cookies
	   		are defined by argument 3, these will be set. Otherwise
	   		the cookies as given by $ENV{'HTTP_COOKIES'} are
	   		used.
	   2		On default, PrintHeader() will return nothing, if it
	   		was called before. By setting this argument unlike 1
	   		it will ignore previous calls.
	   3		A hash-reference, which defines the cookies to be set.
	   4		The path-value for the cookies. On default its set to
	   		"/".
	   5		The lifetime-value for cookies in days. On default its
	   		set to 30.




=head2 ReadParse

Reads the query string and/or the standard input and returns them
as a hash. If the content-type is marked as multipart, it
allows file uploads as long the variable $web::allowuploads
is true. In this case, the new file is stored under its name,
or to be precise, what Check_Name() makes of its name.

Example:

	%in = ReadParse;
	print(PrintHeader);
	print "<ul>\n";
	foreach $key (keys %in) {
	  print "<li><b>$key</b>  &nbsp;  $in{$key}</li>\n";
	}
	print "</ul>\n";


=head2 Fehlermeldung

This routine can be used to print out error messages. It also replaces CgiDie()
from cgi-lib.pl. In addition to the former CgiDie(), this routine can
also take a layout file to produce a better designed output.
It takes the error message, the error title and the file name
of an optional layout file as arguments.

This layout file is a common HTML file, but it can contain the
strings #ZEIT#, #ERRORTEXT# and #TITEL#. These strings will be replaced
with the arguments.
In using the global variable $web::errorlayout_file you can 
predefine a layout-file till the end of the program.

The routine checks for the environment variables HTTP_USER_AGENT and
SERVER_NAME to see whether it was called from of a CGI script. If so, it also
prints the content-type.
To avoid file-locking problems, this routine also executes NUnlockAll.

Example:

	if (not (-r "hallo.html")) {
	  Fehlermeldung("Die Datei hallo.html konnte nicht gelesen werden. 
	  Bitte ueberpruefen Sie die Dateirechte.","Datei nicht lesbar");
	}


=head2 isURL

Checks if the argument has a valid URL syntax.
Returns true if the syntax is ok.

Example:

	$url = "http://www.xwolf.com";
	if (isURL($url)) {
	  print "Valid URL: $url\n";
	}


=head2 isMail

Checks if the argument's syntax is allowed for email addresses.
Returns true if it looks ok.
Notice that it doesn't check whether the email really exists!

Example:

	$mail = 'xwolf@xwolf.com';
	if (isMail($mail)) {
	  print "Mail address $mail looks correct.\n";
	}
	


=head2 isDatum

Checks if the argument is a valid German date. The syntax for a date
was set to: DD.MM.YYYY.


=head2 isIP

Checks the given argument for a valid IP-syntax. It returns TRUE
on success. (This routine was invoked by Rolf Rost, http://www.-i-netlab.de)


=head2 isZeit

Checks if the argument is a valid time. The syntax of a time
was set to: HH:MM:SS.


=head2 Read_Parafile

In Unix many people define configuration files in a way that
variable names and arguments are divided by one or more tabs and comments
are preceded by a '#'.
Variable names start with the first char of a line.

This routine allows reading such a file and returns its content within
a hash. Comments of variables are saved into the hash too, but
with the string $web::PARACOMMENT_SIGN as appendix
(Notice that comments here are put after the variables, not before).

If the file could not be read, the hash value 'status' is set to 400, otherwise
it is set to 200.

Example:

	$configfile = "config";
	%CONFIG = Read_Parafile($configfile);
	if ($CONFIG{'status'}==400) {
	  Fehlermeldung("Could not read the config file.");
	}
	foreach $key (keys %CONFIG) {
	  if (not ($key =~ /$web::PARACOMMENT_SIGN/i)) {
	    print "$key \t $CONFIG{$key}\n";
	  }
	}


=head2 ReadLayout

Reads a file and returns its content in an array.


=head2 ReturnFlagContent

Returns everything between a given HTML flag.

Example:

	$text = "<b>Startseite</b>";
	$content = ReturnFlagContent("b",$text);
	print "$content\n";
	# Prints 'Startseite'


=head2 ReplaceText

This function does two things: It replaces the string #TEXT# with
a given string and sets a <a href=""></a> around every URL within
the text.
This routine was made mainly because a simple search and replace
for s/#TEXT#/$newtext/gi needs a long time if $newtext contains
linebreaks. Therefore, all linebreaks are first replaced with
<_BR_>, then the text will be replaced and after this all
<_BR_>'s are set to linebreaks again.
It's a small and dirty trick, but it works.

Example:

	$text = "Here\n is\n something\n many\n lines.\n Insert here: #TEXT#\n\n";
	$insert = "This was inserted.";
	$text = ReplaceText($insert, $text);


=head2 WriteLog

This routine puts a line into a file together with the time and the
IP/host which the script was executed on.

Example:

	WriteLog("debug.log","Files updated.");

=head2 GetSentence

This procedure was made as an additional search-procedure for textparsing.
It will return the full sentence of a long text, if a the search-word is
in it.
Notice, that this function fails, if there are shortcuts of words and
the sentence was defined as something between two dots.

Example:

	use web;
	$text = "It's an old story of a lost world, calling itself the
		Realm of Magic. Duncan Idaho, the famous warrior killed
		one elven maid too much. The mortals gathered and
		formed a powerful group to kill him. But then something
		happened...";
	$search = "Duncan";
	print(GetSentence($text,$search));
	# Returns "Duncan Idaho, the famous warrior killed  
	#          one elven maid too much"


=head2 RemoveHTML

RemoveHTML() will remove all HTML-Tags and Specifications out of a given string.

Example:
	
	$asciitext = RemoveHTML($htmltext);
	

=head2 HtmlTop

Returns a HTML head. Stolen out of cgi-lib.pl.
Use with print(HtmlTop);

=head2 HtmlBot

Returns the ending tags of a HTML-document. Stolen out of cgi-lib.pl.
Use with print(HtmlBot);

=head2 Redirect()

Makes a redirection towards another URL.

Example:

	Redirect("http://www.xwolf.com/");
	# will tell the server to set the location to the given url.

	

=head1 AUTHOR INFORMATION

Copyright 1999-2000 Wolfgang Wiese.  All rights reserved.
It may be used and modified freely, but I do request that this copyright
notice remain attached to the file.  You may modify this module as you 
wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
xwolf@xwolf.com

=head1 CREDITS

Thanks very much to:

=over 4

=item Johannes Schritz (johannes@schritz.de)

=item Gert Buettner (g.buettner@rrze.uni-erlangen.de)

=item Manfred Abel (m.abel@rrze.uni-erlangen.de)

=item Rolf Rost (rolfrost@yahoo.com)

=item Harald Mattern (webmaster@tsmweb.de)

=cut



# EOF
##############################################################################
