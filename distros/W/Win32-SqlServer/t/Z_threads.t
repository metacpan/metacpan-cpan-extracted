#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/Z_threads.t 9     15-05-24 22:23 Sommar $
#
# Tests that OlleDB is decently thread-safe.
#
# $History: Z_threads.t $
# 
# *****************  Version 9  *****************
# User: Sommar       Date: 15-05-24   Time: 22:23
# Updated in $/Perl/OlleDB/t
# Fixed date format that was not fool-proof.
# 
# *****************  Version 8  *****************
# User: Sommar       Date: 08-03-23   Time: 23:28
# Updated in $/Perl/OlleDB/t
# Handle empty provider value, so that it does not yield warnings about
# not being numeric.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 07-12-23   Time: 22:12
# Updated in $/Perl/OlleDB/t
# Renamed the script to be the very last.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 07-07-07   Time: 16:43
# Updated in $/Perl/OlleDB/t
# Added support for specifying different providers.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 07-06-18   Time: 0:11
# Updated in $/Perl/OlleDB/t
# Renamed the script to be last, since script often hangs because of a
# bug in Perl threads.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-08-06   Time: 15:46
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-06-27   Time: 22:36
# Updated in $/Perl/OlleDB/t
# Fixed really stupid errors for setting  up login properties.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-06-06   Time: 23:29
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use threads;
use Win32::SqlServer qw(:DEFAULT :consts);

use FileHandle;
use IO::Handle;
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

my($global);

sub setupsqlobject {
   my($X) = @_;
   my ($login) = $ENV{'OLLEDBTEST'};
   my ($server, $user, $pw, $dummy, $provider);
   ($server, $user, $pw, $dummy, $dummy, $dummy, $provider) =
       split(/;/, $login) if defined $login;
   $X->{Provider} = $provider if defined $provider and $provider =~ /\S/;
   $X->setloginproperty('Server', $server) if defined $server;
   if ($user) {
      $X->setloginproperty('Username', $user);
      $X->setloginproperty('Password', $pw) if defined $pw;
   }
}


sub get_appname {
    my ($X, $autoconnect) = @_;
    setupsqlobject($X);
    $X->connect() unless $autoconnect;
    my $app = $X->sql_one('SELECT app_name()', SCALAR);
    return $app;
}

sub get_hostname {
   my ($autoconnect) = @_;
   setupsqlobject($global);
   $global->connect() unless $autoconnect;
   my $host = $global->sql_one('SELECT host_name()', SCALAR);
   return $host;
}

sub get_data {
    my($autoconnect) = @_;

    my (@return, $local, $select);

    $select = "SELECT convert(datetime, '20050323 19:23') UNION " .
              "SELECT convert(datetime, '19620912 03:25') ORDER BY 1";

    setupsqlobject($global);
    $local = new Win32::SqlServer;
    $local->{AutoConnect} = $autoconnect;
    setupsqlobject($local);
    $global->connect unless $autoconnect;
    $local->connect unless $autoconnect;

    my $appthr  = threads->create(\&get_appname, $local, $autoconnect);
    my $hostthr = threads->create(\&get_hostname, $autoconnect);
    push (@return, $global->sql($select, SCALAR));
    push (@return, $local->sql($select, SCALAR));
    push (@return, $appthr->join);
    push (@return, $hostthr->join);
    return @return;
}

sub do_error {
    my($errfile1, $errfile2) = @_;

    my ($fh1, $fh2, $local, $raise, @carpmsgs);

    setupsqlobject($global);
    $global->connect();
    $local = new Win32::SqlServer;
    setupsqlobject($local);
    $local->connect();

    $fh1 = new FileHandle;
    $fh1->open($errfile1, "w") or die "Can't write to '$errfile1': $!\n";
    $global->{errInfo}{errFileHandle} = $fh1;

    $fh2 = new FileHandle;
    $fh2->open($errfile2, "w") or die "Can't write to '$errfile1': $!\n";
    $local->{errInfo}{errFileHandle} = $fh2;

    $raise = "RAISERROR('Nutidsorientering', 16, 1)";

    # Must set up a handler to keep warnings from being printed
    local $SIG{__WARN__} = sub{push(@carpmsgs, $_[0])};

    eval('$global->sql($raise)');
    my $evalglob = $@;

    eval('$local->sql($raise)');
    my $evalloc = $@;

    $fh1->close;
    $fh2->close;

    return ($evalglob, $evalloc);
}


$^W = 1;
$| = 1;

print "1..24\n";

foreach my $i (0..2) {
   $global = testsqllogin();
   $global->{DatetimeOption} = DATETIME_ISO;
   $global->{AutoConnect} = 0;
   $global->{ErrInfo}{MaxSeverity} = 11;
   $global->{ErrInfo}{PrintLines} = 11;

   my ($data1) = threads->create(\&get_data, 0);
   my ($err1)  = threads->create(\&do_error, 'thread.1a', 'thread.1b');
   $global->{DatetimeOption} = DATETIME_STRFMT;
   $global->{AutoConnect} = 1;
   $global->{ErrInfo}{MaxSeverity} = 17;
   $global->{ErrInfo}{PrintLines} = 17;
   my ($err2)  = threads->create(\&do_error, 'thread.2a', 'thread.2b');
   my ($data2) = threads->create(\&get_data, 1);
   my (@errret2) = $err2->join;
   my (@errret1) = $err1->join;
   my (@dataret1) = $data1->join;
   my (@dataret2) = $data2->join;

   my ($expect, @file, $testno);

   $testno = 8 * $i + 1;
   $expect = ["eq '1962-09-12 03:25:00.000'", "eq '2005-03-23 19:23:00.000'",
              "eq '1962-09-12 03:25:00.000'", "eq '2005-03-23 19:23:00.000'",
              "eq 'Z_threads.t'",             "eq '" . $ENV{'COMPUTERNAME'} . "'"];
   if (compare(\@dataret1, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 2;
   $expect = ["eq '19620912 03:25:00.000'",   "eq '20050323 19:23:00.000'",
              "eq '1962-09-12 03:25:00.000'", "eq '2005-03-23 19:23:00.000'",
              "eq 'Z_threads.t'",             "eq '" . $ENV{'COMPUTERNAME'} . "'"];
   if (compare(\@dataret2, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 3;
   $expect = ["=~ /^Terminating/", "=~ /^Terminating/"];
   if (compare(\@errret1, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 4;
   $expect = ["eq ''", "=~ /^Terminating/"];
   if (compare(\@errret2, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 5;
   open(F, 'thread.1a');
   @file = <F>;
   close F;

   $expect = [' =~ /50000, Severity 16/', '=~ /Line 1/',
              ' =~ /Nutidsorientering/', '=~ /\s+1>\s+RAISERROR/'];
   if (compare(\@file, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }


   $testno = 8 * $i + 6;
   open(F, 'thread.1b');
   @file = <F>;
   close F;

   $expect = [' =~ /50000, Severity 16/', '=~ /Line 1/',
              ' =~ /Nutidsorientering/', '=~ /\s+1>\s+RAISERROR/'];
   if (compare(\@file, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 7;
   open(F, 'thread.2a');
   @file = <F>;
   close F;

   $expect = [' =~ /50000, Severity 16/', '=~ /Line 1/',
              ' =~ /Nutidsorientering/'];
   if (compare(\@file, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }

   $testno = 8 * $i + 8;
   open(F, 'thread.2b');
   @file = <F>;
   close F;

   $expect = [' =~ /50000, Severity 16/', '=~ /Line 1/',
              ' =~ /Nutidsorientering/', '=~ /\s+1>\s+RAISERROR/'];
   if (compare(\@file, $expect)) {
      print "ok $testno\n";
   }
   else {
      print "not ok $testno\n";
   }
}

exit;



sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         $result = eval("q!$x! $y");
         warn "no match: <$x> <$y>" if not $result;
         return $result;
      }
      else {
         $result = (not defined $x and not defined $y);
         warn  'Left is ' . (defined $x ? "'$x'" : 'undefined') .
               ' and right is ' . (defined $y ? "'$y'" : 'undefined')
               if not $result;
         return $result
      }
   }
   elsif ($refx ne $refy) {
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         warn  "Left has upper index $#$x and right has upper index $#$y.";
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      my $nokeys_x = scalar(keys %$x);
      my $nokeys_y = scalar(keys %$y);
      if ($nokeys_x == $nokeys_y and $nokeys_x == 0) {
         return 1;
      }
      if ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key} and defined $$x{$key}) {
                warn "Left has key '$key' which is missing from right.";
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
      }
      return 0 if not $result;
      foreach $key (keys %$y) {
         if (not exists $$x{$key} and defined $$y{$key}) {
             warn "Right has key '$key' which is missing from left.";
             return 0;
         }
      }
      return $result;
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      $result = ($x eq $y);
      warn "no match: <$x> <$y>" if not $result;
      return $result;
   }
}
