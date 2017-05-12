#!/usr/bin/perl
##
# flail - flexible mail client
#
# Copyright (C) 1999,2000 by St. Alphonsos.  All Rights Reserved.
# Copyright (C) 2000-2008 by Sean Levy <snl@cluefactory.com>.
# All Rights Reserved.
#
# A command-line MUA in perl.  Go figure.  POD at EOF.
#
# I don't write code that looks like this anymore.  Unfortunately, I
# was still treating Perl like a toy when I first did this.  Should've
# known better.  Let this be a lesson to you all.
##
use strict;
use Cwd;
use POSIX ":sys_wait_h";                # for strftime
use Getopt::Std;
use Pod::Usage;
use IO::String;
use Term::ReadLine;                     # REPL
use Mail::Folder::Mbox;                 # need to bring these in explicitly
use Mail::Folder::Maildir;
use Mail::Internet;                     # should switch to MIME sometime
use Mail::Header;                       # blah
use Mail::Util;
use Term::ANSIColor;                    # purty colors.. hyuk
use Term::ReadKey;                      # --More--
use Time::Local;
use Time::ParseDate;
use Mail::POP3Client;
use Mail::IMAPClient;
use Net::SMTP;
use Proc::Simple;                       # for external editor processes
use Proc::SyncExec qw(sync_exec);       # actually, we use this now, no?
use SecretPipe;                         # for remembering passwords
use Symbol;                             # for PGP::GPG::MessageProcessor
use Text::Balanced qw(extract_delimited);
###
## XXX This dog-choking wad of crap has got to go, but at least we
##     can now trip through perl -cw with use strict.  Feh.
###
use vars
    qw(
      $HaveGPGMP $VERSION $BANNER $LICENSE $WARRANTY $USAGE
      $ComposerActionHelp
      $P $Mumbles $DEF_FOLDER_DIR $DEF_INCOMING $DEF_ADDRESSBOOK $DEF_HOST
      $DEF_DOMAIN $NAME $DEF_FROM_ADDR $DEF_FROM $DEF_SMTPHOST $DEF_TEMPDIR
      $DEF_EDITOR $DEF_FCC_FOLDER $DEF_CHECK_TYPE $DEF_RCFILE $DEF_NEW_LABEL
      $DEF_SIGDIR $DEF_SMTP_TOUT %COMMANDS %CONNECTIONS $FOLDER $FOLDER_NAME
      $SUBDIR $MESSAGE $MAX_PAGE_LINES $MAX_LINE_WIDTH $N_LINES $RECENT_LINES
      %SHOW_HEADERS %PASSWORDS $POP3Server $POP3User $IMAPServer $IMAPUser
      $IMAPInbox $RemoveFromServer $FromAddress $SMTPHost $SMTPPort $SMTPAuth
      $SMTPPass $SMTPDebug $SMTPCommand
      $TempDir $TempCounter $AskBeforeSending $REPL $FCCFolder
      $DontCacheConnections $CheckType $SyncImmediately $AllowCommandOverrides
      %IDENTITIES $AddressBook %ADDRESSBOOK $NoAddressBook $AskAddressBook
      $AutoAddressBook $QuietAddressBook $ExactHostMatch $AutoSyncIncoming
      $IMAPAutoExpunge $NewLabel $NoDefaultCC $PipeStdin $PlainOutput
      $DefaultSubject %HOOKS $GPGBinary $CryptoSignCmd $CryptoCryptCmd
      $AutoDotSig $SMTPTout $GPGHomeDir $DateHeaderFmt $DraftsFolder
      $NoSIGWINCH $opt_v $opt_g $RCFile $opt_D $opt_h $opt_T $opt_U
      $opt_o $opt_n $opt_e $opt_S $opt_s $opt_u $opt_c $opt_R $opt_C
      $ShowAllHeaders $opt_I $opt_1 $opt_d $opt_q $opt_G $opt_P $opt_Q
      $opt_i $opt_A $opt_a $CMD $OPT $DefaultFolderType $opt_l $opt_b
      $opt_E $opt_k $opt_F $opt_r $opt_N $Verbose $Debug %GPGHomeDirs
      $FolderDir $SignatureDir $IncomingFolder $Quiet $IMAPPreGetCmd
      $POP3PreGetCmd $N $M $F $H $M $Editor $HeadersFromStdin
      $DEF_COMPOSER_ACTION $Domain $POPInfo $IMAPInfo $opt_p $SingleCommand
      $LeftJustifyList $SpoolDir $SaveMalformedSpoolMsgs $TruncateOldBadSpool
      $SpoolFile
    );
## XXX Outdated and probably no longer works.  Switch to something else
eval "use PGP::GPG::MessageProcessor";  # give it a shot
$HaveGPGMP = 1 unless $@;               # perl needs hygenic macros

$VERSION='0.2.5';
$BANNER = <<__FooF__;
flail $VERSION - the perl mua from stalphonsos.com
Copyright (C) 1999,2000 by St.Alphonsos.  All Rights Reserved.
Copyright (C) 2000-2008 by Sean Levy <snl\@cluefactory>
Email: flail\@cluefactory.com           Web: http://flail.org
  Type "help license" for the license, "help warranty" for the non-warranty.
  Type "help brief" for a brief list of commands, "help manual" for the manual,
  and just "help" for a full list of commands and their syntax.
__FooF__
$LICENSE = <<__FooF__;
Copyright (C) 1999,2000 St. Alphonsos.
Copyright (C) 2000-2008 by Sean Levy <snl\@cluefactory.com>.
All Rights Reserved.

Redistribution and use in any form, with or without modification, are
permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer. 

2. The names "St. Alphonsos", "The Clue Factory", and "Sean Levy"
   must not be used to endorse or promote products derived from this
   software without prior written permission. To obtain permission,
   contact flail-dev\@cluefactory.com or snl\@cluefactory.com

3. Redistributions of any form whatsoever must retain the following
   acknowledgment:
   "This product includes software developed by St. Alphonsos
    http://www.stalphonsos.com/ and Sean Levy <snl\@cluefactory.com>"

THIS SOFTWARE IS PROVIDED BY ST. ALPHONSOS, THE CLUE FACTORY AND
SEAN LEVY ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL ST. ALPHONSOS NOR ITS EMPLOYEES, THE CLUE FACTORY
NOR ITS EMPLOYEES, OR SEAN LEVY BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
__FooF__
$WARRANTY = <<__FooF__;
Copyright (C) 1999,2000 by St. Alphonsos.  All Rights Reserved.
Copyright (C) 2000-2008 by Sean Levy <snl\@cluefactory.com>.  All Rights Reserved.

There is NO WARRANTY, either written or implied, provided for this software
by its author (Sean Levy).  Any damages incurred as the result of its use or
its inclusion in another work are not the fault of its author, and anyone so
using it agrees to save the author harmless in all cases.
__FooF__
$ComposerActionHelp = <<__CactioN__;
Composer actions:
  y = send, n = abort, e = (re)edit message, p = page contents, h = print this
  d = save draft
  s = attach appropriate .signature file
  a = go to addressbook for each address
  S = sign cryptographically
  E = encrypt and sign
  2 = encrypt and sign, but deal with PGP 2.6 braindamage
  |cmd = pipe entire message through cmd and re-load
  :cmd = pipe just body through cmd and re-load just body
  ,code = invoke code on message (\$M bound to message, \$H bound to header)
  multiple actions can be given at once, i.e. sSy = sign, cryptosign & send
  |, : or , actions must be the last in the chain
__CactioN__
($P) = reverse(split("/",$0));
$USAGE = <<__UsaGE__;
usage: $P [-hvlqs1Qncp] [-P pop3_info] [-I imap_info] [-d folder_dir] [-i incoming_folder] [-F from_addr] [-D domain] [-S smtp_host] [-T tempdir] [-e editor] [-C fcc_folder] [-R imap/pop3] [-N new_label] [-g sig_dir] [cmd]
__UsaGE__
$| = 1;                                 # for mumbling
$Mumbles = 0;
$DEF_FOLDER_DIR = $ENV{'HOME'} . "/mail";
$DEF_INCOMING = "INCOMING";
$DEF_ADDRESSBOOK = $ENV{'HOME'} . "/.flail_addressbook";
$DEF_HOST = eval { (uname())[1] } || `hostname` || undef;
if (defined($DEF_HOST)) {
  my @tmp = split(/\./, $DEF_HOST);
  if (scalar(@tmp) < 2) {
    $DEF_DOMAIN = $DEF_HOST;
  } else {
    $DEF_DOMAIN = $tmp[$#tmp - 1] . "." . $tmp[$#tmp];
  }
} else {
  $DEF_DOMAIN = 'unknown.domain'; ### CONFIGURE
}
chomp($DEF_DOMAIN);
$NAME = eval { (getpwuid($>))[6] } || $ENV{NAME} || "";
if($NAME =~ /[^\w\s]/) {
# $NAME =~ s/"/\"/g;
  $NAME = '"' . $NAME . '"';
}
# These should all be my ...
$DEF_FROM_ADDR = $ENV{'USER'} . "\@" . $DEF_DOMAIN;
$DEF_FROM = sprintf("%s <%s>", $NAME, $DEF_FROM_ADDR);
$DEF_SMTPHOST = "localhost";
$DEF_TEMPDIR = $ENV{'TMPDIR'} || "/tmp";
$DEF_EDITOR = $ENV{'EDITOR'} || "gnuclient";
$DEF_FCC_FOLDER = "carbon-copies";
$DEF_CHECK_TYPE = "pop3";
$DEF_RCFILE = $ENV{'HOME'} . "/.$P" . "rc";
$DEF_NEW_LABEL = "new";
$DEF_SIGDIR = $ENV{'HOME'} . "/.signatures";
$DEF_SIGDIR = $ENV{'HOME'} unless (-d $DEF_SIGDIR);
$DEF_SMTP_TOUT = 60;
$SUBDIR = "";
$MAX_PAGE_LINES = 24;
$MAX_LINE_WIDTH = 80;
$N_LINES = 0;
$RECENT_LINES = 0;
$IMAPInbox = "INBOX";
$RemoveFromServer = 1;
$SMTPPort = 25;
$TempCounter = 1;
$AskBeforeSending = 1;
$DontCacheConnections = 0;
$AllowCommandOverrides = 0;
$AutoSyncIncoming = 0;
$IMAPAutoExpunge = 0;
$PlainOutput = 0;
$PlainOutput = 1 if defined($ENV{'TERM'}) && ($ENV{'TERM'} =~ /^dumb|emacs$/);
#$GPGBinary = "/home/attila/gpg-1.2/bin/gpg";
$GPGBinary = "/usr/local/bin/gpg" if (-x "/usr/local/bin/gpg");
$GPGBinary ||= "/usr/bin/gpg" if (-x "/usr/bin/gpg");
$CryptoSignCmd = "$GPGBinary --clearsign";     # set in .flailrc
$CryptoCryptCmd = "$GPGBinary --armor -se";    # ditto
$AutoDotSig = undef;                    # set to automatically attach .sig
$SMTPTout = $DEF_SMTP_TOUT;
$SMTPDebug = 0;
$GPGHomeDir = $ENV{'HOME'} . "/.gnupg";
$DateHeaderFmt = "%a, %d %b %G %T %Z";
$DraftsFolder = "drafts";
$LeftJustifyList = 0;
$SpoolDir = '/var/mail' if -d '/var/mail';
$SpoolFile = $ENV{'USER'};

sub flail_eval;
sub flail_defcmd;

sub ascending { $a <=> $b }
sub descending { $b <=> $a }

sub psychochomp {
  my $in = shift(@_);
  $in =~ s/^\s+//g;
  $in =~ s/\s+$//g;
  return $in;
}

# is this strictly RFC822 compliant?  what i want is to SQUISH all
# extraneous whitespace in an address wherever it might be.
sub addresschomp {
  my $in = shift(@_);
  $in =~ s/\n/ /g;
  $in =~ s/\r/ /g;
  $in =~ s/\s+/ /g;
  $in = psychochomp($in);
  return $in;
}

# sys - like system, but redirect stdout and stderr, and die on errors
#
sub sys {
  system("@_ >/dev/null 2>&1") == 0 || die "\n$P: command: @_: $!\n";
}

# say - print a message if we're in verbose mode
#
sub say {
  return unless $Verbose;
  print "\n" if $Mumbles;
  print ">>> @_";
  print "\n" unless ("@_" =~ /\n$/);
  $Mumbles = 0;
}

# dsay - debugging say
#
sub dsay {
  return unless $Debug;
  if ($_[0] =~ /^\d+$/) {
    my $l = shift(@_);
    return unless $Debug >= $l;
  }
  print "\n" if $Mumbles;
  print ">>> @_";
  print "\n" unless ("@_" =~ /\n$/);
  $Mumbles = 0;
}

# mumble - like say, but for generating periodic status updates on one line
#
sub mumble {
  return unless $Verbose;
  if (!$Mumbles) {                      # new line starting
    print ">>>";
    $Mumbles = 1;
  }
  print " @_";
  $Mumbles = 0 if ("@_" =~ /\n$/);      # reset mumbles at EOL
}

sub headaddrs {
  my($h,$f) = @_;
  my @r = ();
  my $n = $h->count($f);
  my $j = 0;
  while ($j < $n) {
    my $x = $h->get($f, $j);
    my @t = split(/,/, $x);
    foreach my $q (@t) {
      push(@r, psychochomp($q));
    }
    ++$j;
  }
  return wantarray? @r : \@r;
}

sub headaddr0 {
  my($h,$f) = @_;
  my @r;
  my $x = $h->get($f, 0);
  my @t = split(/,/, $x);
  return psychochomp($t[0]);
}

# This is most definitely not how you do this:
sub get_noecho {
  my $junk = `stty -echo`;
  my $i = <STDIN>;
  $junk = `stty echo`;
  print "\n";
  chomp($i);
  return $i;
}

# bogus, should make this more robust or use a class from CPAN
sub address_email {
  my $e = shift(@_);
  dsay "address_email $e";
  $e = $1 if ($e =~ /<(.*)>/);
  dsay "e is now $e";
  my @tmp = split("\@", $e);
  return lc($tmp[0]), lc($tmp[1]);
}

# extract a word-like thing using Text::Balanced
sub word_extract {
    my($string) = @_;
    my($x,$str) = extract_delimited($string,q{\"\'},'','\\');
    if ($x) {
        $x = substr($x,1,length($x)-2);
        $str =~ s/^\s+//;
    } elsif ($string =~ /^(\S+)\s+(\S.*)$/) {
        ($x,$str) = ($1,$2);
    } else {
        ($x,$str) = ($string,'');
    }
    return($x,$str);
}

# Turn a string into a list of "words" ala word_extract
sub wordify {
    my($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    my @words = ();
    my($word,$rest) = word_extract($string);
    while ($word) {
        push(@words, $word);
        ($word,$rest) = word_extract($rest);
    }
    return @words;
}

# Turn a string containing a possibly semicolon-delimited list of
# commands that contain quoted phrases into a vector of vectors
# with the quotes stripped off.  The outer vector contains one
# sub-vector per command, the inner vectors contain one element
# per "word".
sub commandify {
    my @words = wordify(shift(@_));
    my $commands;
    my($wantref0,$wantref1) = (0,0);
    if (@_ && (ref($_[0]) eq 'ARRAY')) {
        $wantref0 = 1;
        $commands = shift(@_);
        if ((@$commands == 1) && (ref($commands->[0]) eq 'ARRAY') && !scalar(@{$commands->[0]})) {
            shift(@$commands);
            $wantref1 = 1;
        }
    } else {
        $commands = [];
    }
    my $cmd = [];
    while (@words > 0) {
        my $word = shift(@words);
        if ($word =~ /^;(.*)$/) {
            my $c = $1;
            if (@$cmd) {
                push(@$commands,$wantref1 ? $cmd : join(' ',@$cmd));
                $cmd = [];
            }
            if ($c && length($c)) {
                push(@$cmd, (!$wantref1 && ($c =~ /\s/)) ? qq|"$c"| : $c);
            }
        } elsif ($word =~ /^([^;].*);$/) {
            my $c = $1;
            if ($c && length($c)) {
                push(@$cmd, (!$wantref1 && ($c =~ /\s/)) ? qq|"$c"| : $c);
            }
            push(@$commands,$wantref1 ? $cmd : join(' ',@$cmd));
            $cmd = [];
        } elsif ($word && length($word)) {
            push(@$cmd, (!$wantref1 && ($word =~ /\s/)) ? qq|"$word"| : $word);
        }
    }
    if (@$cmd) {
        push(@$commands,$wantref1 ? $cmd : join(' ',@$cmd));
    }
    return $wantref0 ? $commands : @$commands;
}

# gpg_op - run gpg on a message
sub gpg_op {
  my($msg,$op,$recips) = @_;
  $op = 's' unless $op;
  dsay "gpg_op: $op\n";
  my $head = $msg->head();
  my $fa;
  if ($op =~ /d/i) {
    $fa = headaddr0($head, "To");
  } else {
    $fa = headaddr0($head, "From");
  }
  my($fauser,$fahost) = address_email($fa);
  my $faf = $fauser . '@' . $fahost;
  dsay "fauser=$fauser,fahost=$fahost";
  my $faemail = "$fauser\@$fahost";
  if (!defined($recips)) {
    $recips = headaddrs($head, "To");
  }
  dsay "gpg recips:";
  dsay join("  \n", @$recips);
  my $mp = new PGP::GPG::MessageProcessor;
  my $ghd = $GPGHomeDirs{$faf} || $GPGHomeDirs{$fauser} || $GPGHomeDir;
  $mp->{homedir} = $ghd if $ghd;
  my $p = get_password("GPG/$faf", "Passphrase for $faf");
  while (!$mp->passphrase_test($p)) {
    print "Bad passphrase.\n";
    forget_password("GPG/$faf");
    $p = get_password("GPG/$faf", "Passphrase for $faf");
  }
  my $input = gensym;
  my $output = gensym;
  my $error = gensym;
  my $status = gensym;
  $mp->{encrypt} = 0;
  $mp->{sign} = 0;
  $mp->{encrypt} = 1 if $op =~ /e/i;
  dsay "[encrypting]\n" if $mp->{encrypt};
  $mp->{sign} = 1 if $op =~ /s/i;
  $mp->{clearsign} = 1 if $mp->{sign};
  dsay "[signing]\n" if $mp->{sign};
  $mp->{passphrase} = $p;
  $mp->{recipients} = $recips;
  if ($op =~ /i/i) {
    $mp->{interactive} = 1;
    $mp->{extraArgs} = [ '--allow-non-selfsigned-uid' ];
  } else {
    $mp->{interactive} = 0;
}
  $mp->{noTTY} = 0;
  $mp->{armor} = 1;
  my $pid;
  if ($op =~ /d/i) {
    $pid = $mp->decipher($input, $output, $error, $status);
  } else {
    $pid = $mp->cipher($input, $output, $error, $status);
  }
  my $bod = $msg->body();
  foreach my $line (@$bod) {
    print $input $line;
    print $input "\n" unless ($line =~ /\n$/);
  }
  close($input);
  my @result = <$output>;
  my @err = <$error>;
  my @s = <$status>;
  if ($Verbose) {
    print "Status from the GPG operation:\n";
    foreach my $statline (@s) {
      print "  $statline";
    }
    print "Error output from the GPG operation:\n";
    foreach my $errline (@err) {
      print "  $errline"
    }
  }
  close($output);
  close($error);
  close($status);
  if (!scalar(@result) && (scalar(@$bod) > 0)) {
    print "An error occured calling GnuPG on this message:\n";
    print join("\n  ", @err);
    return 0, $msg;
  }
  my @r2;
  foreach my $line (@result) {
    $line .= "\n" unless $line =~ /\n$/;
    push(@r2, $line);
  }
  say "waiting for child $pid ...";
  my $pid2;
  do {
    $pid2 = waitpid(-1,&WNOHANG);
  } until $pid2 == -1;
  #$pid2 = waitpid($pid,0);
  return 1, new Mail::Internet (Header => $head, Body => \@r2);
}

sub host_tld {
  my $host = shift(@_);
  my @parts = split("\\.", $host);
  while (scalar(@parts) > 2)  {
    shift(@parts);
  }
  my $tld = join(".", @parts);
  dsay "host_tld($host) => $tld";
}

# this could be made arbitrarily complex
sub hosts_match {
  my($h1,$h2) = @_;
  dsay "hosts_match $h1,$h2";
  return 1 if ($h1 eq $h2);
  dsay "... no exact match";
  return 1 if ((host_tld($h1) eq host_tld($h2)) && !$ExactHostMatch);
  dsay "no tld match";
  return 0;
}

sub addresses_match {
  my($a1,$a2) = @_;
  dsay "addresses_match $a1,$a2";
  my($u1,$h1) = address_email($a1);
  my($u2,$h2) = address_email($a2);
  dsay "u1,h1=$u1,$h1 u2,h2=$u2,$h2";
  my $hm = hosts_match($h1,$h2);
  dsay "hosts_match => $hm";
  return 0 unless $hm;
  return 1 if ($u1 eq $u2);
  if ($u1 =~ /^([^+]+)\+.*/) {
    my $u1 = $1;
    dsay "after + removal, u1=$u1";
    return 1 if ($u1 eq $u2)
  }
  if ($u2 =~ /^([^+]+)\+.*/) {
    my $u2 = $1;
    dsay "after + removal, u2=$u2";
    return 1 if ($u1 eq $u2);
  }
  dsay "no address match";
  return 0;
}

sub address_is_mine {
  my $addr = shift(@_);
  dsay "checking primary identity $FromAddress against $addr";
  return $FromAddress if addresses_match($addr, $FromAddress);
  foreach my $k (keys %IDENTITIES) {
    my $v = $IDENTITIES{$k};
    dsay "checking identity: $k ($v) against $addr";
    return $v if addresses_match($addr, $v);
  }
  dsay "address $addr is not mine";
  return undef;
}

sub reopen_current_folder {
  if (defined($FOLDER)) {
    my $cur = $FOLDER->current_message;
    $FOLDER->sync;
    $FOLDER->close;
    my $fn = "$FolderDir/$FOLDER_NAME";
    $FOLDER = undef;
    my $folder = new Mail::Folder('AUTODETECT', $fn);
    if (!defined($folder)) {
      print "could not reopen folder $FOLDER_NAME";
      $FOLDER_NAME = undef;
      return;
    }
    $FOLDER = $folder;
    if ($cur >= $FOLDER->qty) {
      $cur = $FOLDER->qty;
      $FOLDER->current_message($cur);
    }
  }
}

sub push_range {
  my $range = shift(@_);
  my $low = shift(@_);
  my $high = shift(@_);
  my $dirn = 1;
  $dirn = -1 if ($low > $high);
  push(@$range, ($low .. $high)) if ($dirn == 1);
  push(@$range, sort descending ($high .. $low)) if ($dirn == -1);
}

sub range_elt {
  my $elt = shift(@_);
  return unless defined($elt);
  my $cur = shift(@_) || ($FOLDER? $FOLDER->current_message: 1);
  my $max = shift(@_) || ($FOLDER? $FOLDER->qty: 999);
  if ($elt eq "\$") {
    $elt = $max;
  } elsif ($elt eq '.') {
    $elt = $cur;
  } elsif ($elt =~ /^\.\+(\d+)$/) {
    $elt = $cur + $1;
  } elsif ($elt =~ /^\.-(\d+)$/) {
    $elt = $cur - $1;
  } elsif ($elt =~ /\$-(\d+)$/) {
    $elt = $max - $1;
  } elsif ($elt !~ /^\d+$/) {
    $elt = undef;
  }
  return $elt;
}

sub parse_range {
  my $str = shift(@_);
  my $dirn = shift(@_);
  my @parts = split(/[,\s]/, $str);
  my @range = ();
  while (my $part = shift(@parts)) {
    if ($part =~ /^-(\w+)$/) {
      my $label = $1;
      if (!defined($FOLDER)) {
        warn("no current folder: cannot use $part syntax in range - skipped\n");
        next;
      }
      my @msgs = $FOLDER->select_label($label);
      push(@range,sort ascending @msgs);
      next;
    }
    my $i;
    my $j;
    ($part =~ /^([^\:]+):(\S+)$/) && ($i = $1, $j = $2);
    ($part =~ /^([^\:]+)$/) && ($i = $1, $j = undef);
    say "part=$part i=$i,j=$j";
    $i = range_elt($i);
    $j = range_elt($j);
    if (defined($i) && defined($j)) {
      push_range(\@range, $i, $j);
    } elsif (defined($i)) {
      push(@range, $i);
    } else {
      die "invalid element in range: $part (j=$j)";
    }
  }
  return (sort descending @range) if ($dirn < 0);
  return (sort ascending @range)  if ($dirn > 0);
  return @range;
}

sub init_pager {
  $N_LINES = 0;
  $RECENT_LINES = 0;
}

sub colored_ {
  return shift(@_) if $PlainOutput;
  return colored(@_);
}

sub print_paged_line {
  my($line,$dont_chop_up) = @_;
  my $junk;
  while (defined($line)) {
    if ($N_LINES >= ($MAX_PAGE_LINES - 1)) {
      print colored_("--More (q to quit, SPACE to continue) [$RECENT_LINES]--",
                    "cyan");
#      system("stty cbreak -echo </dev/tty >/dev/tty 2>&1");
      ReadMode 4;
      $junk = ReadKey 0;
      ReadMode 0;
#      system("stty -cbreak echo </dev/tty >/dev/tty 2>&1");
      print "\n";
      return -1 if $junk =~ /^q/;
      if ($junk eq "\n") {
        $N_LINES--;                     # one more line
      } else {
        $N_LINES = 0;
      }
    }
    if ($dont_chop_up) {
      print "$line\n";
      ++$N_LINES;
      ++$RECENT_LINES;
      $line = undef;
    } else {
      my $p = substr($line, 0, $MAX_LINE_WIDTH);
      print "$p\n";
      ++$N_LINES;
      ++$RECENT_LINES;
      $line = substr($line, $MAX_LINE_WIDTH);
      $line = undef if ($line eq "");
    }
  }
  return 0;
}

sub interesting_header {
  my $h = shift(@_);
  $h = lc($h);
  return 1 if $ShowAllHeaders;
  return 1 if $SHOW_HEADERS{$h};
  #return 0 if ($h =~ /^X-/);
  return 0;
}

sub page_header_lines {
  my($msg,$all_hdrs) = @_;
  my @lines;
  my $head = $msg->head();
  my @tags = $head->tags();
  foreach my $tag (@tags) {
    next unless ($all_hdrs || interesting_header($tag));
    my $n = $head->count($tag);
    my $j = 0;
    while ($j < $n) {
      my $v = $head->get($tag, $j);
#      chomp($v);
      $v = psychochomp($v);
      $v =~ s/\n+/ /gs;
      $v =~ s/\s{2,}/ /gs;
      ++$j;
      my $x = colored_("$tag: ", "bold red") . colored_("$v", "magenta");
      return -1 if (print_paged_line($x, 1) < 0);
    }
  }
  return 0;
}

sub default_signature_file {
  my $addr = shift(@_);
  my ($u, $h) = address_email($addr);
  my $email = $u . '@' . $h;
  my $rez = $ENV{'HOME'} . "/.signature";
  if (defined($SignatureDir) && (-d $SignatureDir)) {
    my $sig = $SignatureDir . "/$email";
    $rez = $sig if (-f $sig);
  }
  $rez = undef unless (-f $rez);
  return $rez;
}

sub sign_msg {
  my $msg = shift(@_);
  my $sigfile = shift(@_);
  if (!defined($sigfile)) {
    my $h = $msg->head();
    #my $f = $h->get("From");
    my $f = headaddr0($h,"From");
    $sigfile = default_signature_file($f);
    say "signature file for $f => $sigfile";
  }
  return unless (-f $sigfile);
  $msg->add_signature($sigfile);
  return $msg;
}

sub page_msg {
  my($msg,$all_hdrs) = @_;
  init_pager();
  unless ($OPT->{'noheader'} || $OPT->{'noheaders'}) {
    return -1 if (page_header_lines($msg,$all_hdrs) < 0);
  }
  unless ($OPT->{'nosep'}) {
    print colored_("-" x 76, "cyan"),"\n" ;
  }
  my $body = $msg->body();
  foreach my $line (@$body) {
    chomp($line);
    return -1 if (print_paged_line($line) < 0);
  }
  return 0;
}

sub get_password {
  my($name,$prompt) = @_;
  my $cage = $PASSWORDS{$name};
  my $pass;
  if (defined($cage)) {
    $pass = $cage->reveal();
    if (!defined($pass)) {
      print "($name) $prompt: ";
      $pass = get_noecho();
    }
    $cage->hide($pass);
    return $pass
  }
  print "{$name} $prompt: ";
  $pass = get_noecho();
  $cage = new SecretPipe;
  $cage->hide($pass);
  $PASSWORDS{$name} = $cage;
  return $pass;
}

sub remember_password {
  my($name,$pass) = @_;
  my $cage = $PASSWORDS{$name};
  if (defined($cage)) {
    $cage->reset();
  } else {
    $cage = new SecretPipe;
    $PASSWORDS{$name} = $cage;
  }
  $cage->hide($pass);
  #undef $pass;
}

sub forget_password {
  my($name) = @_;
  my $cage = $PASSWORDS{$name};
  if (defined($cage)) {
    $cage->finish();
  }
  delete $PASSWORDS{$name};
}

sub forget_passwords {
  my @keys = @_;
  if ($#keys < 0) {
    @keys = keys %PASSWORDS;
  }
  foreach my $k (@keys) {
    my $c = $PASSWORDS{$k};
    $c->finish() if defined($c);
    delete $PASSWORDS{$k};
    print "forgot password for $k\n";
  }
}

sub open_incoming_folder {
  my($quiet) = @_;
  my $inc = $IncomingFolder;
  $inc = &$inc if ref($inc) eq 'CODE';
  my $incfn = $FolderDir . "/" . $inc;
  my $incoming =
      Mail::Folder->new(
        'AUTODETECT',
        $incfn,
        Create => 1,
        DefaultFolderType => $DefaultFolderType || 'Mbox',
      );
  if (!$incoming) {
    print "could not open incoming folder $incfn: $!\n";
    return(undef,-1);
  }
  my $msgn = $incoming->qty;
  print "incoming folder $IncomingFolder opened with $msgn messages\n"
      unless $quiet;
  return($incoming,$msgn);
}

sub open_cached_connection {
  my($type,@args) = @_;
  no strict 'refs';
  my $routine = "connect_".$type;
  return &$routine(@args) if ($DontCacheConnections || $type eq 'pop3');
  my($uid,$server) = @args;
  my $ckey = join("/", $type, $uid, $server);
  my $conn = $CONNECTIONS{$ckey};
  unless (defined($conn)) {
    $conn = &$routine(@args);
    $CONNECTIONS{$ckey} = $conn if defined($conn);
  }
  return $conn;
}

sub close_connection {
  my($conn,$force) = @_;
  $force ||= 0;
  if ($force) {
    eval { $conn->Close(); };
    return;
  }
  return unless $DontCacheConnections;
  my $closed = undef;
  foreach my $k (keys %CONNECTIONS) {
    my $c = $CONNECTIONS{$k};
    if ($conn == $c) {
      my $success = 0;
      if ($k =~ /^imap/) {
        eval { $c->disconnect(); $success = 1; };
      } elsif ($k =~ /^pop/) {
        eval { $c->Close(); $success = 1; };
      }
      print "close_connection($k) failure: $@\n" unless $success;
      $closed = $k;
      last;
    }
  }
  if (defined($closed)) {
    delete($CONNECTIONS{$closed});
  } else {
    if (ref($conn) eq 'Mail::IMAPClient') {
      eval { $conn->disconnect(); };
    } elsif (ref($conn) eq 'Mail::POP3Client') {
      eval { $conn->Close(); };
    } else {
      eval { $conn->close(); };
    }
  }
}

sub clear_connection_cache {
  foreach my $key (keys %CONNECTIONS) {
    my $conn = $CONNECTIONS{$key};
    if (defined($conn)) {
      print "[Closing cached connection $key: $conn]\n" unless $Quiet;
      if ($key =~ /^imap/) {
        eval { $conn->disconnect(); };
      } elsif ($key =~ /^pop/) {
        eval { $conn->Close(); };
      } else {
        warn("do not know how to close $key!\n");
      }
    }
    delete($CONNECTIONS{$key});
  }
}

sub connect_imap {
  if (defined($IMAPPreGetCmd)) {
    system($IMAPPreGetCmd) == 0
        or print qq{error executing "$IMAPPreGetCmd": $!\n};
  }
  my $user = shift(@_) || $IMAPUser || $ENV{'USER'};
  my $server = shift(@_) || $IMAPServer || "localhost";
  my $password = shift(@_) || get_password("IMAP/$user.$server",
                                           "IMAP password for $user\@$server");
  my $port = 143;
  ($server,$port) = ($1,$2) if $server =~ /^([^:]+):(\d+)$/;
  my $imap =
      Mail::IMAPClient->new(
        Server => $server,
        Port => $port,
        User => $user,
        Password => $password,
        Uid => 1,
      );
  $password = undef; # does this work?
  if (!defined($imap)) {
    print "could not connect to imap server $server as $user\n";
  } else {
    $IMAPUser = $user;
    $IMAPServer = $server . ":$port";
  }
  return $imap;
}

sub check_imap {
  my $imap = open_cached_connection('imap',@_);
  return unless defined($imap);
  $imap->select($IMAPInbox);
  my @all = $imap->search('ALL');
  print "imap mailbox $IMAPUser\@$IMAPServer has ".scalar(@all)." messages\n";
  for (my $i = 1; $i <= scalar(@all); $i++) {
    my $msgid = $all[$i-1];
    my $headers = $imap->parse_headers($msgid,"From","Subject");
    # ... scan for From and Subject headers
    my($from,$subj) = (
      map { join("\n    ",@$_) }
      map { $headers->{$_} } 
      qw(From Subject)
    );
    print "[$i #$msgid] ".colored_($from || "-No From-","blue")."\n";
    print "[$i #$msgid] ".colored_($subj || "-No Subj-","blue")."\n";
  }
  close_connection($imap);
}

sub get_imap {
  my $imap = open_cached_connection('imap',@_);
  return unless defined($imap);
  $imap->select($IMAPInbox);
  my @all = $imap->search('ALL');
  print "reading ".scalar(@all)." messages from imap drop $IMAPUser\@$IMAPServer\n";
  $| = 1;
  my($incoming,$msgn) = open_incoming_folder();
  if (!defined($incoming)) {
    close_connection($imap);
    return;
  }
  for (my $i = 1; $i <= scalar(@all); $i++) {
    my $msgid = $all[$i-1];
    my $headers = $imap->parse_headers($msgid,'From','Subject');
    my $nmsgn = $msgn + 1; ## clearly wrong?
    my $msg_string = $imap->message_string($msgid);
    my $lines = [ map { $_ =~ s|\r$||s; "$_\n"; } split(/\n/, $msg_string) ];
    foreach (@$lines) {
      last if /^\s*$/;
      my $str = $_;
      $str =~ s|\n$||s;
      /^From:/ and print "[$i:$nmsgn] ".colored_($str,"blue")."\n";
      /^Subject:/ and print "[$i:$nmsgn] ".colored_($str,"cyan")."\n";
      say "$_: $str";
    }
    my $msg = Mail::Internet->new($lines);
    if ($msg) {
      $incoming->append_message($msg);
      $imap->delete_message([$msgid]);
      ++$msgn;
      if ($NewLabel) {
        say "adding label $NewLabel to msgno $msgn";
        say "add_label failed" unless $incoming->add_label($msgn, $NewLabel);
        say "$NewLabel messages: " .
          join(",", $incoming->select_label($NewLabel));
      }
      if ($AutoSyncIncoming) {
        print '.' if $Debug;
        $incoming->sync();
      }
      if ($IMAPAutoExpunge > 1) {
        print '!' if $Debug;
        $imap->expunge();
      }
#      if ($Debug) {
#        print "just expunged $msgid and appended message:\n\n".$msg->as_string()."\n";
#        $incoming->close();
#        $Quiet = 0;
#        addressbook_checkpoint(1);
#        clear_connection_cache();
#        exit(0);
#      }
    } else {
      print "[error reading msg $i -- skipped]";
    }
  }
  say "$NewLabel messages: " . join(",", $incoming->select_label($NewLabel));
  if (($IMAPAutoExpunge == 1) && !$DontCacheConnections) {
    print "[Expunging INBOX]\n" if $Verbose;
    $imap->expunge();
  }
  $incoming->sync();
  $incoming->close();
  if ($NewLabel) {
    ($incoming,$msgn) = open_incoming_folder(1);
    run_message_hooks($NewLabel, $incoming, 1);
    $incoming->sync();
    $incoming->close();
  }
  close_connection($imap);
}

sub connect_pop3 {
  if (defined($POP3PreGetCmd)) {
    system($POP3PreGetCmd) == 0
      or print qq{error executing "$POP3PreGetCmd": $!\n};
  }
  my $user = shift(@_) || $POP3User || $ENV{'USER'};
  my $server = shift(@_) || $POP3Server || "localhost";
  my $password = shift(@_) || get_password("POP3/$user.$server",
                                           "POP3 password for $user\@$server");
  my $port = 110;
  ($server,$port) = ($1,$2) if $server =~ /^([^:]+):(\d+)$/;
  my $pop =
      Mail::POP3Client->new(
        USER => "$user",
        PASSWORD => "$password",
        HOST => "$server",
        PORT => $port,
        AUTH_MODE => "PASS"
      );
  $password = undef;
  if (!defined($pop)) {
    print "could not connect to pop3 server $server as $user\n";
  } else {
    $POP3User = $user;
    $POP3Server = $server . ":$port";
  }
  return $pop;
}

sub check_pop3 {
  my $pop = open_cached_connection('pop3',@_);
  return unless defined($pop);
  print "pop3 mailbox $POP3User\@$POP3Server has ". $pop->Count(). " messages\n";
  for (my $i = 1; $i <= $pop->Count(); $i++) {
    foreach ($pop->Head($i)) {
      /^From:\s+/i and print "[$i] ", colored_("$_", "blue"), "\n";
      /^Subject:\s+/i and print "[$i] ", colored_("$_", "cyan"), "\n";
    }
  }
  close_connection($pop,1);
}

sub get_pop3 {
  my $pop = open_cached_connection('pop3',@_);
  return unless defined($pop);
  my($incoming,$msgn) = open_incoming_folder();
  if (!defined($incoming)) {
    close_connection($pop,1);
    return;
  }
  print "reading ", $pop->Count(), " messages from pop3 drop $POP3User\@$POP3Server\n";
  $| = 1;
  for (my $i = 1; $i <= $pop->Count(); $i++) {
    my @content = ();
    my $nmsgn = $msgn + 1;
    foreach ($pop->Head($i)) {
      /^From:\s+/i and print "[$i:$nmsgn] ", colored_("$_", "blue"), "\n";
      /^Subject:\s+/i and print "[$i:$nmsgn] ", colored_("$_", "cyan"), "\n";
      push(@content, "$_\n");
      say "$_";
    }
    push(@content, "\n");
    push(@content, "\n");
    say "--separator--";
    foreach ($pop->Body($i)) {
      push(@content, "$_\n");
      say "$_";
    }
    say "content:\n" . join("", @content);
    my $msg = Mail::Internet->new(\@content);
    if ($msg) {
      $incoming->append_message($msg);
      $pop->Delete($i) if $RemoveFromServer;
      ++$msgn;
      if ($NewLabel) {
        say "adding label $NewLabel to msgno $msgn";
        say "add_label failed" unless $incoming->add_label($msgn, $NewLabel);
        say "$NewLabel messages: " .
          join(",", $incoming->select_label($NewLabel));
      }
      $incoming->sync() if $AutoSyncIncoming;
    } else {
      print "[error reading msg $i -- skipped]";
    }
  }
  say "$NewLabel messages: " . join(",", $incoming->select_label($NewLabel));
  $incoming->sync();
  $incoming->close();
  if ($NewLabel) {
    ($incoming,$msgn) = open_incoming_folder(1);
    run_message_hooks($NewLabel, $incoming, 1);
    $incoming->sync();
    $incoming->close();
  }
  close_connection($pop,1);
}

sub spool_file_path {
  my($file) = @_;
  return $file if defined($file) && (-f $file);
  $file ||= $SpoolFile;
  return "$SpoolDir/$file" if -f "$SpoolDir/$file";
  warn(qq{could not find spool "$file"\n});
  return undef;
}

sub check_spool {
  my($file) = spool_file_path(@_);
  return unless defined $file;
  if (!(-f $file)) {
    print qq{spool "$file" does not exist\n};
    return;
  }
  my @msgs = Mail::Util::read_mbox($file);
  if (!@msgs) {
    print qq{could not read spool "$file" - correct format?\n}  unless -z $file;
    return;
  }
  print qq{spool "$file" has }.scalar(@msgs)." messages\n";
  for (my $i = 1; $i <= scalar(@msgs); $i++) {
    my $msg = $msgs[$i-1];
    foreach (@$msg) {
      last if /^\s*$/;
      chomp;
      /^From:/i and print "[$i] ".colored_($_,"blue")."\n";
      /^Subject:/i and print "[$i] ".colored_($_,"cyan")."\n";
    }
  }
}

sub flush_spool {
  my($file,$ok,$msgvec) = @_;
  if ($SaveMalformedSpoolMsgs && (scalar(keys %$ok) < scalar(@$msgvec))) {
    my $badfile = "$file.bad";
    if ((-f $badfile) && !$TruncateOldBadSpool) {
      open(BADFILE, ">> $badfile") or die(qq{could not open "$badfile" for append: $!\n});
    } else {
      open(BADFILE, "> $badfile") or die(qq{could not open "$badfile" for write: $!\n});
    }
    my $saved = 0;
    for (my $i = 0; $i < scalar(@$msgvec); $i++) {
      my $msg = $msgvec->[$i];
      unless ($ok->{$i}) {
        print BADFILE join("", @$msg);
        ++$saved;
      }
    }
    close(BADFILE);
    if (!$saved) {
      unlink($badfile);
    } else {
      print "saved $saved malformed messages from $file => $badfile\n";
    }
  }
  say "[Truncating spool: $file]";
  open(SPOOL, "> $file") or die(qq{could not open spool "$file" for writing: $!\n});
  close(SPOOL);
}

sub get_spool {
  my($file) = spool_file_path(@_);
  if (!(-f $file)) {
    print qq{spool "$file" does not exist\n};
    return;
  }
  my @msgs = Mail::Util::read_mbox($file);
  if (!@msgs) {
    print qq{could not read spool "$file" - correct format?\n}  unless -z $file;
    return;
  }
  my($incoming,$msgn) = open_incoming_folder();
  if (!defined($incoming)) {
    return;
  }
  print "reading ".scalar(@msgs)." from spool: $file\n";
  my %ok = ();
  for (my $i = 1; $i <= scalar(@msgs); $i++) {
    my $spool_msg = $msgs[$i-1];
    my $nmsgn = $msgn+1;
    foreach (@$spool_msg) {
      last if /^\s+$/;
      chomp;
      /^From:\s+/i and print "[$i:$nmsgn] ".colored_("$_", "blue")."\n";
      /^Subject:\s/i and print "[$i:$nmsgn] ".colored_("$_", "cyan")."\n";
    }
    my $msg = Mail::Internet->new($spool_msg);
    if ($msg) {
      $incoming->append_message($msg);
      $ok{$i-1} = 1;
      ++$msgn;
      if ($NewLabel) {
        say "adding label $NewLabel to msgno $msgn";
        say "add_label failed" unless $incoming->add_label($msgn, $NewLabel);
        say "$NewLabel messages: " .
          join(",", $incoming->select_label($NewLabel));
      }
      $incoming->sync() if $AutoSyncIncoming;
    } else {
      print "[error reading msg $i -- skipped]";
    }
  }
  say "$NewLabel messages: ".join(",",$incoming->select_label($NewLabel));
  $incoming->sync();
  $incoming->close();
  if ($NewLabel) {
    ($incoming,$msgn) = open_incoming_folder(1);
    run_message_hooks($NewLabel, $incoming, 1);
    $incoming->sync();
    $incoming->close();
  }
  flush_spool($file,\%ok,\@msgs);
}

sub flail_check {
  if ($_[0] eq "imap") {
    $CheckType = shift(@_);
  } elsif ($_[0] eq "pop3") {
    $CheckType = shift(@_);
  } elsif ($_[0] eq "spool") {
    $CheckType = shift(@_);
  }
  if ($CheckType eq "imap") {
    check_imap(@_);
  } elsif ($CheckType eq "pop3") {
    check_pop3(@_);
  } elsif ($CheckType eq "spool") {
    check_spool(@_);
  } else {
    print "don't know how to check for new mail\n";
  }
}

sub run_message_hooks {
  my $label = shift(@_);
  return unless $label;
  my $folder_name = shift(@_) || $IncomingFolder;
  my $clear_label_after = shift(@_);
  my $folder;
  $folder = $folder_name if ref($folder_name);
  $folder = $FOLDER unless defined($folder);
  my $opened_it = 0;
  if (!defined($folder)) {
    say "opening folder $folder_name";
    my $incfn = $FolderDir . "/" . $folder_name;
    $folder = new Mail::Folder('AUTODETECT', $incfn,
                               Create => 1,
                               DefaultFolderType => 'Mbox');
    if (!$folder) {
      print "could not open folder $incfn: $!\n";
      return;
    }
    $opened_it = 1;
  }
  say "running $label hooks over folder: " . $folder->foldername();
  my @args = @_;
  my @msgnos = $folder->select_label($label);
  say "$label messages: " . join(",", @msgnos);
  return unless (scalar(@msgnos) > 0);
  my $hook_list = $HOOKS{$label};
  say "$label hooks: " . scalar(@$hook_list);
  return unless (scalar(@$hook_list) > 0);
  foreach my $msgno (@msgnos) {
    local $N = $msgno;
    local $M = $folder->get_message($msgno);
    local $F = $folder;
    local $H = $M->head();
    say "running $label hook over message $N";
    foreach my $hook (@$hook_list) {
      eval {
        local $SIG{INT} = sub { die "$label hook interrupted..."; };
        local $SIG{TERM} = sub { die "$label hook interrupted..."; };
        local $SIG{QUIT} = sub { die "$label hook interrupted..."; };
        &$hook(@args);
      };
      if ($@) {
        my $msg = "$@";
        chomp($msg);
        $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
        $| = 1;
        print "\n$msg\n";
      }
    }
  }
  $folder->clear_label($label) if $clear_label_after;
  if ($opened_it) {
    $folder->sync();
    $folder->close();
  }
}

sub flail_add_hook {
  my $label = shift(@_);
  my $proc = shift(@_);
  if (!defined($HOOKS{$label})) {
    $HOOKS{$label} = [ $proc ];
  } else {
    my $hooks = $HOOKS{$label};
    push(@$hooks, $proc);
  }
}

sub flail_get {
  if ($_[0] eq "imap") {
    $CheckType = shift(@_);
  } elsif ($_[0] eq "pop3") {
    $CheckType = shift(@_);
  } elsif ($_[0] eq "spool") {
    $CheckType = shift(@_);
  }
  if ($CheckType eq "imap") {
    get_imap(@_);
    reopen_current_folder();
#    run_message_hooks($NewLabel, $IncomingFolder, 1) if $NewLabel;
  } elsif ($CheckType eq "pop3") {
    get_pop3(@_);
    reopen_current_folder();
#    run_message_hooks($NewLabel, $IncomingFolder, 1) if $NewLabel;
  } elsif ($CheckType eq "spool") {
    get_spool(@_);
    reopen_current_folder();
  } else {
    print "don't know how to get new mail\n";
  }
}

sub flail_run_hooks {
  my $label = shift(@_) || "marked";
  if (!defined($FOLDER)) {
    print "no folder open\n";
    return;
  }
  run_message_hooks($label);
}

sub flail_emit { print "@_"; } ## kludge

sub flail_echo {
  print "[echo: ".scalar(@_)." args]\n" if $Verbose;
  print "@_\n";
}

sub flail_open {
  my $fname = shift(@_);
  if ($fname eq "..") {
    if (defined($FOLDER)) {
      $FOLDER->sync;
      $FOLDER->close;
      $FOLDER = undef;
      $FOLDER_NAME = undef;
      if ($SUBDIR eq "") {
        print "you are in a twisty maze of folders, all alike (try ls)\n";
      } else {
        print "now in subfolder $SUBDIR\n" unless $Quiet;
      }
    } elsif ($SUBDIR eq "") {
      print "you are in a mazy of twisty folders, all alike (try ls)\n";
    } else{
      my @x = split("/", $SUBDIR);
      pop(@x);
      $SUBDIR = join("/", @x);
      print "now in folder: $SUBDIR\n" unless $Quiet;
    }
    return;
  }
  my $fn = $FolderDir . "/" . $fname;
  if (-d $fn) {
    $SUBDIR = $fname;
    if (defined($FOLDER)) {
      $FOLDER->sync;
      $FOLDER->close;
      $FOLDER = undef;
      $FOLDER_NAME = undef;
    }
    print "now in subfolder $SUBDIR\n" unless $Quiet;
    return;
  }
  if (!(-f $fn)) {
    print "no such folder: $fn\n";
    return;
  }
  my $folder = new Mail::Folder('AUTODETECT', $fn);
  if (!defined($folder)) {
    print "$fname: could not open ($fn): $!\n";
    return;
  }
  $FOLDER->sync if defined($FOLDER);
  $FOLDER->close if defined($FOLDER);
  $FOLDER = $folder;
  $FOLDER_NAME = $fname;
  print "$fname: openend with ", $folder->qty, " messages\n" unless $Quiet;
}

sub flail_stat {
  if (!defined($FOLDER)) {
    if ($SUBDIR eq "") {
      print "you are in a twisty maze of mail folders, all alike (try ls)\n";
    } else {
      print "in subfolder $SUBDIR\n";
    }
    return;
  }
  print "$FOLDER_NAME currently open with ", $FOLDER->qty, " messages\n";
  print "current message: ", $FOLDER->current_message, "\n";
}

sub flail_prompt_msg_summary {
  say "msg_summary entered" if $Debug;
  return "" unless defined($FOLDER);
  my $n = $FOLDER->qty;
  return "$FOLDER_NAME " if !$n;
  say "have folder in msg_summary, $n msgs" if $Debug;
  my $i = $FOLDER->current_message;
  say "got msg $i in msg_summary" if $Debug;
  my $m = $FOLDER->get_message($i);
  my $h = $m->head();
  my $f = $h->get("From");
  $f = '?@?' unless defined($f);
  chomp($f);
  my($fe,$fh) = address_email($f);
  $f = $fe . '@' . $fh;
  my ($junk,$k) = addressbook_lookup($f);
  $f = $k if defined($k);
  say "f=$f in msg_summary" if $Debug;
  $f = (substr($f, 0, 17) . "...") if (length($f) > 20);
  my $s = $h->get("Subject");
  $s = '?' unless defined($s);
  chomp($s);
  say "s=$s in msg_summary" if $Debug;
  $s = (substr($s, 0, 17) . "...") if (length($s) > 20);
  return "$f:\"$s\" $FOLDER_NAME $i/$n ";
}

sub prompt_str {
  my $rez = undef;
  my $proc = $HOOKS{'__PROMPT'};
  if (defined($proc)) {
    eval {
      $rez = &$proc();
    };
    print "$P: prompt_hook: $@\n" if $Debug;
    $rez = undef if $@;
  }
  if (!defined($rez)) {
    my $sum = flail_prompt_msg_summary();
    $rez .= $sum . "$P> ";
  }
  return $rez;
}

sub get_term_size {
  return($MAX_PAGE_LINES,$MAX_LINE_WIDTH) if (!(-t STDIN));
  my $junk = `stty -a`;
  my @stuff = split(';', $junk);
  my %size;
  foreach my $ent (@stuff) {
    ($ent =~ /rows\s+(\d+)$/) && ($size{'rows'} = $1);
    ($ent =~ /(\d+)\s+rows$/) && ($size{'rows'} ||= $1);
    ($ent =~ /columns\s+(\d+)$/) && ($size{'cols'} = $1);
    ($ent =~ /(\d+)\s+col/) && ($size{'cols'} ||= $1);
    last if (defined($size{'rows'}) && defined($size{'cols'}));
  }
  return ($size{'rows'} || $MAX_PAGE_LINES,
          $size{'cols'} || $MAX_LINE_WIDTH);
}

sub flail_headers {
  init_pager();
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  push(@_, $FOLDER->current_message) if !defined($_[0]);
  my @tmp;
  eval { @tmp = parse_range("@_"); };
  @_ = @tmp unless $@;
  foreach my $n (@_) {
    my $msg = $FOLDER->get_message($n);
    if (!defined($msg)) {
      print "could not get message: $n\n";
      return;
    }
    page_header_lines($msg, 1);
  }
}

sub addressbook_load {
  return if $NoAddressBook;
  say "opening addressbook $AddressBook";
  if (!dbmopen(%ADDRESSBOOK, $AddressBook, 0755)) {
    print "opening addressbook $AddressBook: $!\n";
    $NoAddressBook = 1;
  }
}

sub addressbook_checkpoint {
  my $dont_reopen = shift(@_);
  return if $NoAddressBook;
  say "checkpointing addressbook $AddressBook";
  if (!dbmclose(%ADDRESSBOOK)) {
    print "flushing addressbook $AddressBook: $!\n";
    $NoAddressBook = 1;
  }
  return if $dont_reopen;
  addressbook_load();
}

sub addressbook_add {
  return if $NoAddressBook;
  my($key,$val,$overwrite) = @_;
  my $oldval = $ADDRESSBOOK{$key};
  if (defined($oldval) && !$overwrite) {
    my $yorn = $REPL->readline(colored_("Addressbook already has an entry for $key (= $oldval); overwrite? y/[n] ", "red"));
    chomp($yorn);
    return unless ($yorn =~ /^[yY]/);
  }
  $ADDRESSBOOK{$key} = $val;
}

sub addressbook_import_ldif {
  return if $NoAddressBook;
  my $ldif_file = shift(@_);
  open(LDIF, "<$ldif_file");
  my %entry = ();
  while (<LDIF>) {
    chomp;
    if (/^$/) {
      my $nick = $entry{'xmozillanickname'} || $entry{'givenname'};
      my $mail = $entry{'mail'};
      if (!$mail) {
        print "[skipping bogus entry in $ldif_file...]\n" unless $Quiet;
        %entry = ();
        next;
      }
      if (!$nick) {
        my @foo = split("\@", $mail);
        $nick = $foo[0];
        my $foo = $REPL->readline("Nickname $mail? [$nick] ");
        chomp($foo);
        $nick = $foo unless ($foo eq '');
      }
      addressbook_add($nick,$mail,0);
      %entry = ();
    } elsif (/^(\S+):\s+(\S.*)$/) {
      $entry{$1} = $2;
    }
  }
  close(LDIF);
}

sub addressbook_import_csv {
  return if $NoAddressBook;
  my $csv_file = shift(@_);
  open(CSV, "<$csv_file") || die "$csv_file: $!";
  my $line;
  while (<CSV>) {
    $line = psychochomp($_);
    my ($name,$nick,$addr) = split(/,/, $line, 3);
    if ($nick eq '') {
      print "[skipping bogus entry in $csv_file: $line]\n";
      next;
    }
    my $email = $addr;
    $email = ($name . ' <' . $addr . '>') if ($name ne '');
    print "[Adding entry $nick => $email]\n";
    addressbook_add($nick,$email,0);
  }
  close(CSV);
}

sub addressbook_delete {
  return if $NoAddressBook;
  foreach my $k (@_) {
    if (defined($ADDRESSBOOK{$k})) {
      say "deleting address book entry: $k";
      delete $ADDRESSBOOK{$k};
    }
  }
}

sub addressbook_matches {
  my($name,$key) = @_;
  return 1 if (lc($name) eq lc($key));
  return 1 if ($name =~ /$key/i);
  my $val = $ADDRESSBOOK{$key};
  return addresses_match($name,$val);
  #return 1 if ($name =~ /$val/i);
  #return 0;
}

sub addressbook_lookup {
  return undef if $NoAddressBook;
  my $name = shift(@_);
  my $x;
  if (defined($x = $ADDRESSBOOK{$name})) {
    return($x,$name);
  }
  if (defined($x = $ADDRESSBOOK{lc($name)})) {
    return($x,$name);
  }
  foreach my $k (keys %ADDRESSBOOK) {
    if (addressbook_matches($name, $k)) {
      return $ADDRESSBOOK{$k}, $k;
    }
  }
  return undef, undef;
}

sub take_addrs {
  return if $NoAddressBook;
  my $force = shift(@_);
  my $hdrs = $M->head();
  foreach my $tag (qw(From To Cc Sender)) {
    my $n = $hdrs->count($tag);
    my $j = 0;
    say "$n $tag headers";
    while ($j < $n) {
      my $hv = $hdrs->get($tag, $j);
      chomp($hv);
      ++$j;
      my @vals = split(",", $hv);
      foreach my $v (@vals) {
        $v = psychochomp($v);
        say "$tag [$j] = $v";
        next if defined(address_is_mine($v));
        my ($a,$k) = addressbook_lookup($v);
        if ($a) {
          if (!$force) {
            print "[$v already in addressbook under $k: $a]\n";
          } else {
            my $nick = $k;
            my $foo = $REPL->readline("Nickname for $v [$k,^C to quit]? ");
            chomp($foo);
            addressbook_add($foo, $v, 0) if ($foo ne '');
          }
        } else {
          my $nick =
            $REPL->readline("Nickname for $v (RET to skip,^C to quit)? ");
          chomp($nick);
          addressbook_add($nick, $v, 0) if ($nick ne '');
        }
      }
    }
  }
}

sub flail_addressbook {
  if ($NoAddressBook) {
    print "no address book.\n";
    return;
  }
  my $subcmd = shift(@_);
  if ($subcmd =~ /^add$/i) {
    my $key = shift(@_);
    my $val = "@_";
    addressbook_add($key, $val, 0);
  } elsif ($subcmd =~ /^show$/i) {
    if ("@_" =~ /^\"(.*)\"/) {
      @_ = ( $1 );
    }
    foreach my $key (@_) {
      my $val = $ADDRESSBOOK{$key};
      if ($val) {
        print "  $key: $val\n";
      } else {
        print "  $key not in addressbook\n";
      }
    }
    return;
  } elsif ($subcmd =~ /^list$/i) {
    if ("@_" =~ /^\"(.*)\"/) {
      @_ = ( $1 );
    }
    my $re = "@_";
    my @keys = sort keys %ADDRESSBOOK;
    if (!scalar(@keys)) {
      print "Addressbook is empty.\n";
      return;
    }
    print "Addressbook has ", scalar(@keys), " entries:\n";
    foreach my $key (@keys) {
      my $val = $ADDRESSBOOK{$key};
      print "  $key: $val\n" if (($re eq "") ||
                                 ($key =~ /$re/i) || ($val =~ /$re/i));
    }
    return;
  } elsif ($subcmd =~ /^del$/i) {
    if ("@_" =~ /^\"(.*)\"/) {
      @_ = ( $1 );
    }
    foreach my $key (@_) {
      addressbook_delete($key);
    }
  } elsif ($subcmd =~ /^import$/i) {
    foreach my $file (@_) {
      if ($file =~ /\.ldif$/) {
        print "Importing LDIF file: $file\n";
        addressbook_import_ldif($file);
      } elsif ($file =~ /\.csv$/) {
        print "Importing CSV file: $file\n";
        addressbook_import_csv($file);
      } else {
        print "I'm not sure what kind of file $file is...\n";
        print "I support LDIF and CSV; please rename it to one of those\n";
      }
    }
  } elsif ($subcmd =~ /^take$/i) {
    if (!defined($FOLDER)) {
      print "no current folder\n";
      return;
    }
    my $label = shift(@_) || "cur";
    my $force = shift(@_) || undef;
    $force = 1 if defined($force);
    flail_eval("map $label { take_addrs($force); }"); # sick, but effective
  } else {
    if (($subcmd eq '') || ($subcmd =~ /^help$/i)) {
      print "Addressbook subcommands:\n";
      print "  add nick mail  - add an entry that maps nick -> mail\n";
      print "  import file... - import LDIF-format file(s)\n";
      print "  show nick...   - show specific entries\n";
      print "  list [regexp]  - list whole addressbook, or matching entries\n";
      print "  take [tag]     - take addresses from the current message\n";
      print "                   or from all messages with the given tag\n";
      print "  del nick...    - delete entries\n";
    } else {
      print "Addressbook: bad cmd $subcmd; one of add,import,show,list,del\n";
    }
    return;
  }
  addressbook_checkpoint();
}

sub flail_read {
  #dump_OPT() if $Verbose;
  my $do_decrypt = defined($OPT->{decrypt})? 1: 0;
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $n = $_[0];
  if (!defined($n)) {
    my $msg = $FOLDER->get_message($FOLDER->current_message);
    if (!defined($msg)) {
      print "could not get current message\n";
    } else {
      if ($do_decrypt) {
        my $won;
        ($won,$msg) = gpg_op($msg, "d", undef);
        print "[GPG operation failed; displaying encrypted message]\n"
            unless $won;
      }
      page_msg($msg);
    }
  } else {
    my @tmp;
    eval { @tmp = parse_range("@_"); };
    @_ = @tmp unless $@;
    while ($n = shift(@_)) {
      if (!$FOLDER->message_exists($n)) {
        print "no such message: $n\n" unless $Quiet;
        $n = shift(@_);
        next;
      }
      my $msg = $FOLDER->get_message($n);
      if (!defined($msg)) {
        print "$FOLDER_NAME: no message number $n\n";
        return;
      }
      if ($do_decrypt) {
        print "[Decrypting...]\n" if $Verbose;
        my $won;
        ($won,$msg) = gpg_op($msg, "d", undef);
        print "[GPG operation failed; displaying encrypted message]\n"
            unless $won;
      }
      page_msg($msg);
      $FOLDER->current_message($n);
    }
  }
}

sub flail_pipe {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my @msgs = ($FOLDER->current_message);
  if ($_[0] =~ /^-/) {
    my $seq = shift(@_);
    my @tmp;
    eval { @tmp = parse_range($seq); };
    if ($@) {
      print "failed to parse range expression \"$seq\": $@\n";
      return;
    }
    @msgs = @tmp;
  }
  if (!@msgs) {
    print "No messages to pipe\n";
    return;
  }
  if (!@_) {
    print "No command given\n";
  }
  my $cmd = "@_";
  print "[Piping ".scalar(@msgs)." messages through: $cmd]\n" unless $Quiet;
  pipe_cat_msg($cmd,$FOLDER->get_message($_),$OPT->{'noheader'}? 1: 0)
      foreach (sort { $a <=> $b } @msgs);
}

sub flail_demung {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $n = $_[0];
  if (!defined($n)) {
    print "you must specify at least one message\n";
    return;
  }
  my @tmp;
  eval { @tmp = parse_range("@_"); };
  @_ = @tmp unless $@;
  while (defined(my $n = shift(@_))) {
    if (!$FOLDER->message_exists($n)) {
      print "no such message: $n\n" unless $Quiet;
      next;
    }
    my $msg = $FOLDER->get_message($n);
    if (!defined($msg)) {
      print "$FOLDER_NAME: no message number $n\n";
      next;
    }
    
  }
}

sub flail_decrypt {
  $OPT->{decrypt} = 1;
  flail_read(@_);
}

sub flail_next {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $inc;
  my $n = shift(@_);
  if (!defined($n)) {
    $inc = 1;
  } else {
    $inc = $n;
  }
  my $cur = $FOLDER->current_message;
  $cur += $inc;
  if ($FOLDER->message_exists($cur)) {
    $FOLDER->current_message($cur);
    print "$FOLDER_NAME: current message is now $cur/", $FOLDER->qty, "\n"
      unless $Quiet;
  } else {
    print "$FOLDER_NAME: no such message as $n\n";
  }
}

sub flail_prev {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $n = shift(@_);
  my $inc;
  if (!defined($n)) {
    $inc = 1;
  } else {
    $inc = $n;
  }
  my $cur = $FOLDER->current_message;
  $cur -= $inc;
  if ($FOLDER->message_exists($cur)) {
    $FOLDER->current_message($cur);
    print "$FOLDER_NAME: current message is now $cur/", $FOLDER->qty, "\n"
      unless $Quiet;
  } else {
    print "$FOLDER_NAME: no such message as $n\n";
  }
}

sub flail_goto {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $n = shift(@_);
  my @tmp;
  eval { @tmp = parse_range("$n"); };
  $n = shift(@tmp) if (scalar(@tmp) > 0);
  if (!defined($n)) {
    print "no message specified\n";
    return;
  }
  if (!$FOLDER->message_exists($n)) {
    print "invalid message number: $n\n";
    return;
  }
  $FOLDER->current_message($n);
  print "$FOLDER_NAME: current message is $n\n" unless $Quiet;
}

sub get_cur_msg {
  my $msg = undef;
  $msg = $FOLDER->get_message($FOLDER->current_message) if defined($FOLDER);
  return $msg;
}

sub get_header {
  my $name = shift(@_);
  my $lcname = lc($name);
  say "get_header($name), OPT says: ", $OPT->{$lcname};
  my $val = $OPT->{$lcname} || $REPL->readline(colored_("$name: ", "red"));
  chomp($val);
  return $val;
}

sub get_default_header {
  my $name = shift(@_);
  my $hdrs = shift(@_);
  my $lcname = lc($name);
  my $val = $OPT->{$lcname};
  $hdrs->add($name, $val) if $val;
}

sub temp_file_name {
  my $i = $TempCounter;
  while (-f "$TempDir/flail-temp-$i.txt") {
    ++$i;
  }
  $TempCounter = $i;
  my $fname = "$TempDir/flail-temp-$i.txt";
  return $fname;
}

sub call_editor {
  my $fname = shift(@_);
  if ($PipeStdin) {
    $PipeStdin = 0;
  } else {
    say "calling editor: $Editor $fname";
#    my $proc = Proc::Simple->new();
#    $proc->kill_on_destroy(1);
#    $proc->start("$Editor $fname");
#    while ($proc->poll()) {
#      sleep 2;
#    }
#    $proc->kill();
    my $edpid = sync_exec(sub { delete $ENV{'TMPDIR'} }, "$Editor $fname");
    my $kid;
    do { $kid = waitpid($edpid,0) } until ($kid == $edpid);
  }
  say "editor process done";
  return 0;
}

sub dump_msg_to_tmp {
  my($msg,$no_headers) = @_;
  my $name = temp_file_name();
  local *TMP;
  open(TMP, ">$name") || die "$P: could not open temp file $name: $!\n";
  if ($PipeStdin) {
    $msg->print_header(\*TMP) unless $HeadersFromStdin;
    my $in_headers = 0;
    $in_headers = 1 if $HeadersFromStdin;
    my $from_header = undef;
    while (<STDIN>) {
      print TMP "From: $FromAddress\n"
        if ($in_headers && ($_ =~ /^[\r\n\s]+$/) && !defined($from_header));
      $in_headers = 0 if ($_ =~ /^[\r\n\s]+$/);
      $in_headers && !defined($from_header) && (/^From:\s+(\S.*)$/) &&
        ($from_header = $1);
      print TMP "$_";
    }
    close(TMP);
    return $name;
  }
  say "tmp file is $name:";
  print $msg->as_string if $Verbose;
  say "Writing temp file $name";
  #print TMP $msg->as_string();
  $msg->print_header(\*TMP) unless $no_headers;
  print TMP "\n" unless $no_headers;
  my $bodyref = $msg->body();
  foreach my $line (@$bodyref) {
    $line .= "\n" if ($line !~ /.*\n$/);
    print TMP "$line";
  }
  close(TMP);
  return $name;
}

sub filter_addresses {
  my $msg = shift(@_);
  my $interactive = shift(@_);
  my $hdrs = $msg->head();
  foreach my $h (qw(To Cc Bcc)) {
    my @alist = headaddrs($hdrs, $h);
    next if scalar(@alist) == 0;
    my @xlist = ();
    foreach my $v (@alist) {
      my ($a,$k) = addressbook_lookup($v);
      if ($a && ($a ne $v)) {
        if ($interactive) {
          my $yorn =
            $REPL->readline("Addressbook: $v => $a; replace $h? [y]/n ");
          chomp($yorn);
          if ($yorn =~ /^[nN]/) {
            push(@xlist, $v);
            next;
          }
        }
        say "addressbook: $v => $a";
        print "[Addressbook: $v => $a]\n" unless $QuietAddressBook;
        push(@xlist, $a);
      } else {
        push(@xlist, $v);
      }
    }
    $hdrs->delete($h);
    $hdrs->add($h, join(", ", @xlist));
  }
}

sub edit_msg {
  my $msg = shift(@_);
  my $name = dump_msg_to_tmp($msg);
  if (call_editor($name) < 0) {
    print "editor died: $!\n";
    return undef;
  }
  say "done with editor";
  open(TMP, "<$name") || return -1;
  my $edited = new Mail::Internet(\*TMP);
  say "after new internet mail message";
  close(TMP);
  if (!$edited) {
    print "could not parse edited message\n";
    unlink($name) unless $OPT->{'keep'};
    return undef;
  }
  say "parsed back message";
  unlink($name) unless $OPT->{'keep'};
  filter_addresses($edited,$AskAddressBook)
    unless ($NoAddressBook || !$AutoAddressBook);
  sign_msg($edited) if $AutoDotSig;
  return $edited;
}

sub invoke_code_on_msg {
  my $msg = shift(@_);
  my $code = shift(@_);
  local $M = $msg;
  local $H = $M->head();
  say "running code \"$code\" over msg $M";
  eval {
    local $SIG{INT} = sub { die "hook interrupted..."; };
    local $SIG{TERM} = sub { die "hook interrupted..."; };
    local $SIG{QUIT} = sub { die "hook interrupted..."; };
    eval "$code";
  };
  if ($@) {
    my $msg = "$@";
    chomp($msg);
    $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
    $| = 1;
    print "\n$msg\n";
  }
}

sub save_msg {
  my $msg = shift(@_);
  my $fccfn = shift(@_) || $FCCFolder;
  my $what = shift(@_) || "fcc";
  say "fccfn in save_fcc is $fccfn";
  return unless $fccfn;
  my $fn = $fccfn;
  if (!(-f $fn)) {
    local *FCC;
    open(FCC, ">$fn") || die "$P: could not make fcc folder $fn: $!\n";
    close(FCC);
  }
  my $fcc = new Mail::Folder('AUTODETECT', $fn, Create => 1,
                             DefaultFolderType => 'Mbox');
  if (!$fcc) {
    print "could not create empty fcc folder $fn: $! ($@)\n";
    return;
  }
  my $bodyref = $msg->body();
  my @newbody = ();
  foreach (@$bodyref) {
    $_ .= "\n" unless /\n$/;
    push(@newbody, $_);
  }
  my $head = $msg->head();
  my $copy = new Mail::Internet(Header => $head, Body => \@newbody);
  $fcc->append_message($copy);
  $fcc->sync;
  $fcc->close;
  print "$what saved to $fccfn\n" unless $Quiet;
}

sub save_fccs {
  my $msg = shift(@_);
  foreach my $fcc (@_) {
    $fcc = psychochomp($fcc);
    $fcc = $FCCFolder if ($fcc eq '.');
    save_msg($msg, $fcc);
  }
}

sub pipe_cat_msg {
  my($cmd,$msg,$no_headers) = @_;
  my $name = dump_msg_to_tmp($msg,$no_headers);
  my $newmsg;
  local *PIPE;
  open(PIPE, "$cmd <$name|") || return;
  print $_ while (<PIPE>);
  close(PIPE);
  unlink($name) unless $Debug;
  return undef;
}

sub pipe_msg {
  my($cmd,$msg,$no_headers) = @_;
  my $name = dump_msg_to_tmp($msg,$no_headers);
  my $newmsg;
  local *PIPE;
  open(PIPE, "$cmd <$name|") || return;
  if (!$no_headers) {
    $newmsg = new Mail::Internet(\*PIPE);
  } else {
    my $hdrs = $msg->head();
    my $dup = $hdrs->dup();
    my @body = ();
    while (<PIPE>) {
      chomp;
      push(@body, $_);
    }
    $newmsg = new Mail::Internet(Header => $dup, Body => \@body);
  }
  close(PIPE);
  unlink($name) unless $Debug;
  return $newmsg;
}

sub prepare_to_send {
  my($edited) = @_;
  my $hdrs = $edited->head;
  my $use_from = $hdrs->get("From");
  $hdrs->replace("Sender", $use_from);
  $hdrs->replace("X-Mailer", "flail $VERSION - http://flail.org");
  $hdrs->replace("Date", POSIX::strftime($DateHeaderFmt, localtime));
  my @recips = headaddrs($hdrs, "To");
  my @tmp = headaddrs($hdrs, "Cc");
  foreach my $t (@tmp) {
    push(@recips, $t);
  }
  @tmp = headaddrs($hdrs, "Bcc");
  foreach my $t (@tmp) {
    push(@recips, $t);
  }
  $hdrs->delete("Bcc");
  my $fccfn = $hdrs->get("Fcc");
  say "fccfn is $fccfn";
  $hdrs->delete("Fcc");
  return($fccfn,$hdrs,@recips);
}

sub send_via_smtp {
  my($edited) = @_;
  say "sending message via SMTP host $SMTPHost";
  my %smtp_opts = (
      Port => $SMTPPort,
      Hello => $Domain,
      Timeout => $SMTPTout,
  );
  $smtp_opts{'Debug'} = 1 if $OPT->{debug};
  my $smtp = new Net::SMTP($SMTPHost,%smtp_opts);
  if (!$smtp) {
    flail_emit("ERROR: cannot connect to SMTP server $SMTPHost:$SMTPPort\n");
    return;
  }
  say "smtp connection initialized to $SMTPHost: $smtp";
  my($fccfn,$hdrs,@recips) = prepare_to_send($edited);
  my $ha = $hdrs->header;
  my $use_from = $hdrs->get("Sender");
  $smtp->mail($use_from);
  $smtp->to(@recips);
  say "MAIL/RCPT sent for @recips";
  $smtp->data();
  foreach (@$ha) {
    say "header $_";
    $smtp->datasend($_);
  }
  $smtp->datasend("\n");
#  $smtp->datasend("\n");
  my $body = $edited->body;
  foreach (@$body) {
    say "body @recips: $_";
    $_ .= "\n" if ($_ !~ /.*\n$/);
    $smtp->datasend("$_");
  }
  $smtp->dataend();
  $smtp->quit;
  return($fccfn,@recips);
}

sub send_via_program {
  my($edited) = @_;
  if (!$SMTPCommand) {
    die(qq{no SMTP command defined!\n});
  }
  say "sending message via SMTP command $SMTPCommand";
  my($fccfn,$hdrs,@recips) = prepare_to_send($edited);
  open(PROGRAM, "|$SMTPCommand")
      or die(qq{could not fork smtp command "$SMTPCommand": $!\n});
  $edited->print(\*PROGRAM);
  close(PROGRAM);
  return($fccfn,@recips);
}

sub send_internal {
  #dump_OPT() if $Verbose;
  my $srcmsg = shift(@_);
  my $newmsg = shift(@_);
  my $use_from = shift(@_) || $FromAddress;
  my $hdrs;
  if (defined($newmsg)) {
    $hdrs = $newmsg->head();
    if (defined($_[0])) {
      $hdrs->add("To", join(", ", @_));
    } elsif (!$HeadersFromStdin) {
      my $nto = $hdrs->count("To");
      if (!$nto) {
        my $x = get_header("To");
        $hdrs->add("To", $x) if defined($x);
      }
    }
    $hdrs->add("From", $use_from) if !$hdrs->count("From");
    $hdrs->delete("Mail-From");
    $hdrs->delete("Status");
  } else {
    say "consing up new message: @_";
    $hdrs = new Mail::Header;
    my $x;
    $hdrs->add("From", $use_from);
    if (defined($_[0])) {
      $hdrs->add("To", join(", ", @_));
    } elsif (!$HeadersFromStdin) {
      ($x = get_header("To")) and $hdrs->add("To", $x);
    }
    if (!$HeadersFromStdin) {
      $x = $DefaultSubject || get_header("Subject");
    }
    $hdrs->add("Subject", $x) if defined($x);
    if (!$NoDefaultCC) {
      while ($x = get_header("Cc")) {
        last if ($x eq "");
        $hdrs->add("Cc", $x);
      }
    }
    $newmsg = new Mail::Internet(Header => $hdrs);
    say "new, empty message:";
    $newmsg->print(\*STDOUT) if $Verbose;
  }
 EDIT:
  $hdrs = $newmsg->head();
  get_default_header("Fcc", $hdrs);
  get_default_header("Bcc", $hdrs);
  say "before editing:";
  print $newmsg->as_string if $Verbose;
  my $edited = edit_msg($newmsg);
  if (!$edited) {
    print "send aborted\n";
    return;
  }
  if ($AskBeforeSending) {
    my $done = 0;
    my $first_time = 1;
    my $def_ans_str = "";
    $def_ans_str = "<" . $DEF_COMPOSER_ACTION . "> "
      if defined($DEF_COMPOSER_ACTION);
    while (!$done) {
      my $def = "";
      $def = $def_ans_str if $first_time;
      my $yorn =
        $REPL->readline(colored_("Action? [y=send,n=abort,h=help] $def", "cyan"));
      chomp($yorn);
      $yorn = $DEF_COMPOSER_ACTION
        if ($first_time && !length($yorn) && defined($DEF_COMPOSER_ACTION));
      $first_time = 0;
      my $won = 0;
      while (defined($yorn)) {
        ($yorn =~ /^[h\?]/) && print $ComposerActionHelp;
        ($yorn =~ /^[yY]/) && ($done = 1,$yorn=undef);
        ($yorn =~ /^[nN]/) && ($done = -1,$yorn=undef);
        ($yorn =~ /^d/) &&(save_msg($edited,$DraftsFolder,"draft"),$done=-1,$yorn=undef);
        ($yorn =~ /^e/) && ($done = 2,$yorn=undef);
        ($yorn =~ /^[pP]/) && page_msg($edited);
        ($yorn =~ /^s/) && sign_msg($edited);
        ($yorn =~ /^[aA]/) && filter_addresses($edited,$AskAddressBook);
        ($yorn =~ /^S/ && !$HaveGPGMP) &&
          ($edited = pipe_msg($CryptoSignCmd, $edited, 1));
        ($yorn =~ /^S/ && $HaveGPGMP)&&
                     (($won,$edited)=gpg_op($edited, "s", undef));
        ($yorn =~ /^E/ && !$HaveGPGMP) &&
          ($edited = pipe_msg($CryptoCryptCmd, $edited, 1));
        ($yorn =~ /^E/ && $HaveGPGMP) &&
                     (($won,$edited)=gpg_op($edited,"se",undef));
        ($yorn =~ /^2/ && $HaveGPGMP) &&
                     (($won,$edited)=gpg_op($edited,"sei",undef));
        ($yorn =~ /^\|(.*)$/) && ($edited = pipe_msg($1, $edited),$yorn=undef);
        ($yorn =~ /^\:(.*)$/) && ($edited =pipe_msg($1,$edited,1),$yorn=undef);
        ($yorn =~ /^,(.*)$/) && (invoke_code_on_msg($edited, $1),$yorn=undef);
        $yorn = substr($yorn, 1);
        $yorn = undef if ($yorn eq "");
      }
    }
    if ($done < 0) {
      print "send aborted\n";
      return;
    }
    if ($done == 2) {
      $newmsg = $edited;
      goto EDIT;
    }
  }
  my @recips;
  my $fccfn;
  if (!$SMTPCommand) {
    ($fccfn,@recips) = send_via_smtp($edited);
  } else {
    ($fccfn,@recips) = send_via_program($edited);
  }
  if ($#recips < 0) {
    print "message not sent\n" unless $Quiet;
  } else {
    print "message sent to:\n    " . join("\n    ", @recips) . "\n"
      unless $Quiet;
  }
  my @fcclist = split(/,/, $fccfn);
  push(@fcclist, $FCCFolder) unless defined($fcclist[0]);
  save_fccs($edited, @fcclist);
}

sub send_internal_old {
  #dump_OPT() if $Verbose;
  local($SMTPDebug) = (1) if $OPT->{debug};
  local($Verbose) = (1) if $OPT->{verbose};
  my $srcmsg = shift(@_);
  my $newmsg = shift(@_);
  my $use_from = shift(@_) || $FromAddress;
  my $hdrs;
  if (defined($newmsg)) {
    $hdrs = $newmsg->head();
    if (defined($_[0])) {
      $hdrs->add("To", join(", ", @_));
    } elsif (!$HeadersFromStdin) {
      my $nto = $hdrs->count("To");
      if (!$nto) {
        my $x = get_header("To");
        $hdrs->add("To", $x) if defined($x);
      }
    }
    $hdrs->add("From", $use_from) if !$hdrs->count("From");
    $hdrs->delete("Mail-From");
    $hdrs->delete("Status");
  } else {
    say "consing up new message: @_";
    $hdrs = new Mail::Header;
    my $x;
    $hdrs->add("From", $use_from);
    if (defined($_[0])) {
      $hdrs->add("To", join(", ", @_));
    } elsif (!$HeadersFromStdin) {
      ($x = get_header("To")) and $hdrs->add("To", $x);
    }
    if (!$HeadersFromStdin) {
      $x = $DefaultSubject || get_header("Subject");
    }
    $hdrs->add("Subject", $x) if defined($x);
    if (!$NoDefaultCC) {
      while ($x = get_header("Cc")) {
        last if ($x eq "");
        $hdrs->add("Cc", $x);
      }
    }
    $newmsg = new Mail::Internet(Header => $hdrs);
    say "new, empty message:";
    $newmsg->print(\*STDOUT) if $Verbose;
  }
 EDIT:
  $hdrs = $newmsg->head();
  get_default_header("Fcc", $hdrs);
  get_default_header("Bcc", $hdrs);
  say "before editing:";
  print $newmsg->as_string if $Verbose;
  my $edited = edit_msg($newmsg);
  if (!$edited) {
    print "send aborted\n";
    return;
  }
  if ($AskBeforeSending) {
    my $done = 0;
    my $first_time = 1;
    my $def_ans_str = "";
    $def_ans_str = "<" . $DEF_COMPOSER_ACTION . "> "
      if defined($DEF_COMPOSER_ACTION);
    while (!$done) {
      my $def = "";
      $def = $def_ans_str if $first_time;
      my $yorn =
        $REPL->readline(colored_("Action? [y=send,n=abort,h=help] $def", "cyan"));
      chomp($yorn);
      $yorn = $DEF_COMPOSER_ACTION
        if ($first_time && !length($yorn) && defined($DEF_COMPOSER_ACTION));
      $first_time = 0;
      my $won = 0;
      while (defined($yorn)) {
        ($yorn =~ /^[h\?]/) && print $ComposerActionHelp;
        ($yorn =~ /^[yY]/) && ($done = 1,$yorn=undef);
        ($yorn =~ /^[nN]/) && ($done = -1,$yorn=undef);
        ($yorn =~ /^d/) &&(save_msg($edited,$DraftsFolder,"draft"),$done=-1,$yorn=undef);
        ($yorn =~ /^e/) && ($done = 2,$yorn=undef);
        ($yorn =~ /^[pP]/) && page_msg($edited);
        ($yorn =~ /^s/) && sign_msg($edited);
        ($yorn =~ /^[aA]/) && filter_addresses($edited,$AskAddressBook);
        ($yorn =~ /^S/ && !$HaveGPGMP) &&
          ($edited = pipe_msg($CryptoSignCmd, $edited, 1));
        ($yorn =~ /^S/ && $HaveGPGMP)&&
                     (($won,$edited)=gpg_op($edited, "s", undef));
        ($yorn =~ /^E/ && !$HaveGPGMP) &&
          ($edited = pipe_msg($CryptoCryptCmd, $edited, 1));
        ($yorn =~ /^E/ && $HaveGPGMP) &&
                     (($won,$edited)=gpg_op($edited,"se",undef));
        ($yorn =~ /^2/ && $HaveGPGMP) &&
                     (($won,$edited)=gpg_op($edited,"sei",undef));
        ($yorn =~ /^\|(.*)$/) && ($edited = pipe_msg($1, $edited),$yorn=undef);
        ($yorn =~ /^\:(.*)$/) && ($edited =pipe_msg($1,$edited,1),$yorn=undef);
        ($yorn =~ /^,(.*)$/) && (invoke_code_on_msg($edited, $1),$yorn=undef);
        $yorn = substr($yorn, 1);
        $yorn = undef if ($yorn eq "");
      }
    }
    if ($done < 0) {
      print "send aborted\n";
      return;
    }
    if ($done == 2) {
      $newmsg = $edited;
      goto EDIT;
    }
  }
  say "sending message via SMTP host $SMTPHost";
  my $smtp =
      Net::SMTP->new(
        $SMTPHost,
        Port => $SMTPPort,
        Hello => $Domain,
        Timeout => $SMTPTout,
        Debug => $SMTPDebug
      );
  if (!$smtp) {
    flail_emit("ERROR: cannot connect to SMTP server $SMTPHost:$SMTPPort\n");
    return;
  }
  if ($SMTPAuth) {
    my $pass = $SMTPPass;
    if (!defined($pass)) {
      flail_emit("WARNING: No SMTP password defined for user $SMTPAuth - assuming it is empty\n")
          if $SMTPDebug;
      $pass = '';
    }
    my $okay = $smtp->auth($SMTPAuth,$pass);
    if (!$okay) {
      flail_emit("ERROR: SMTP authentication failed for $SMTPAuth\@$SMTPHost:$SMTPPort; try with /debug\n");
      $smtp->quit();
      return;
    }
    flail_emit("[SMTP: authenticated as $SMTPAuth to $SMTPHost:$SMTPPort]\n") if $Verbose;
  }
  say "smtp connection initialized to $SMTPHost: $smtp";
  my @recips = ();
  $hdrs = $edited->head;
  $use_from = $hdrs->get("From");
  $hdrs->replace("Sender", $use_from);
  $hdrs->replace("X-Mailer", "flail $VERSION - http://flail.org");
  $hdrs->replace("Date", POSIX::strftime($DateHeaderFmt,localtime));
  my $body = $edited->body;
  my $ha = $hdrs->header;
  @recips = headaddrs($hdrs, "To");
  my @tmp = headaddrs($hdrs, "Cc");
  foreach my $t (@tmp) {
    push(@recips, $t);
  }
  @tmp = headaddrs($hdrs, "Bcc");
  foreach my $t (@tmp) {
    push(@recips, $t);
  }
  $hdrs->delete("Bcc");
  my $fccfn = $hdrs->get("Fcc");
  say "fccfn is $fccfn";
  $hdrs->delete("Fcc");
  $ha = $hdrs->header;
  $smtp->mail($use_from);
  $smtp->to(@recips);
  say "MAIL/RCPT sent for @recips";
  $smtp->data();
  foreach (@$ha) {
    say "header $_";
    $smtp->datasend($_);
  }
  $smtp->datasend("\n");
#  $smtp->datasend("\n");
  foreach (@$body) {
    say "body @recips: $_";
    $_ .= "\n" if ($_ !~ /.*\n$/);
    $smtp->datasend("$_");
  }
  $smtp->dataend();
  $smtp->quit;
  if ($#recips < 0) {
    print "message not sent\n" unless $Quiet;
  } else {
    print "message sent to:\n    " . join("\n    ", @recips) . "\n"
      unless $Quiet;
  }
  my @fcclist = split(/,/, $fccfn);
  push(@fcclist, $FCCFolder) unless defined($fcclist[0]);
  save_fccs($edited, @fcclist);
}

sub hack_as {
  my $as = shift(@_);
  say "hack_as($as)";
  if (defined($as)) {
    my $tmp = address_is_mine($as);
    $as = $tmp if defined($tmp);
    $as = $FromAddress unless defined($tmp);
    say "hack_as as => $as";
  }
  return $as;
}

sub flail_send {
#  sys("gnudoit '(vm-mail)'");        # cheezy
  my $as = hack_as($OPT->{as});
  my $msg = undef;
  if ($OPT->{draft}) {
    $msg = get_cur_msg();
    if (!defined($msg)) {
      print "no current message to edit as draft\n";
      return;
    }
  }
  say "calling send as $as: @_";
  send_internal(undef, $msg, $as, @_);
}

sub flail_forward {
  my $cur = get_cur_msg();
  my $as = hack_as($OPT->{as});
  $as = $FromAddress unless $as;
  if (!defined($cur)) {
    print "no current message to forward\n";
    return;
  }
  my $cur_hdr = $cur->head();
  my $cur_subj = $cur_hdr->get("Subject");
  chomp($cur_subj);
  my $forw_body_str = ("-" x 20) . " Forwarded message follows\n\n";
  $forw_body_str .= $cur->as_string();
  my @lines = split("\n", $forw_body_str);
  my $i = 0;
  while ($i <= $#lines) {
    $lines[$i] .= "\n";
    ++$i;
  }
  my $hdr = new Mail::Header;
  $hdr->add("From", $as);
  $hdr->add("Subject", "[Fwd: $cur_subj]");
  my $forw = new Mail::Internet(Header => $hdr, Body => \@lines);
  send_internal($cur, $forw, $as, @_);
}

sub flail_resend {
  my $cur = get_cur_msg();
  my $as = hack_as($OPT->{as});
  if (!defined($cur)) {
    print "no current message to resent\n";
    return;
  }
  my $cur_hdr = $cur->head();
  my $cur_subj = $cur_hdr->get("Subject");
  my $cur_from = $cur_hdr->get("From");
  chomp($cur_subj);
  chomp($cur_from);
  my $hdr = $cur_hdr->dup();
  $hdr->replace("To", $_[0]) if defined($_[0]);
  $hdr->replace("From", $as);
  $hdr->replace("X-Original-Sender", $cur_from);
  $hdr->replace("Subject", "[Resent from $cur_from: $cur_subj]");
  my $resend = new Mail::Internet(Header => $hdr, Body => $cur->body());
  send_internal($cur, $resend, $as, @_);
}

sub flail_reply {
  my $cur = get_cur_msg();
  my $as = hack_as($OPT->{as});
  if (!defined($cur)) {
    print "no current message to reply to\n";
    return;
  }
  my $to_all = defined($OPT->{all});
  my $ohdrs = $cur->head();
  my $reply = $cur->reply();
  my $hdrs = $reply->head();
  # try to automatically figure out the right From: field based on who
  # the message was to
  my $from = $as;
  foreach my $field (qw(To Cc)) {
    my $n = $ohdrs->count($field);
    my $j = 0;
    while ($j < $n) {
      my $to = $ohdrs->get($field, $j);
      foreach my $id (keys %IDENTITIES) {
        my $src = $IDENTITIES{$id};
        if ($to =~ /$id/i) {
          $from = $src unless $from;
          last unless $to_all;
        }
      }
      if (!$to_all) {
        last if defined($from);
      }
      $hdrs->add($field, $to) if $to_all;
      ++$j;
    }
    if (!$to_all) {
      last if defined($from);
    }
  }
  $from = $FromAddress unless defined($from);
  $hdrs->replace("From", $from);
  send_internal($cur, $reply, $as, @_);
}

sub flail_mkdir {
}

sub flail_decode {
}

sub msg_label_summary {
  return "" unless defined($FOLDER);
  my $j = shift(@_);
  my %labels;
  my @labels = $FOLDER->list_labels($j);
  say "summary, label set is: " . join(",", @labels);
  map { $labels{$_} = 1; } @labels;
  say "converted to hash";
  my $m = $labels{marked}? "M": " ";
  my $n = $labels{seen}? " ": "N";
  my $d = $labels{deleted}? "D": " ";
  my $f = $labels{filed}? "F": " ";
  my $r = $labels{replied}? "R": " ";
  my $w = $labels{forwarded}? "W": " ";
  return "$m$n$d$f$r$w";
}

sub flail_range {
  my @range = parse_range("@_");
  my $n = scalar(@range);
  my $results = ($n == 1)?"1 result":"$n results";
  my $rangestr = !$n? ".": ": ".join(", ", @range);
  print "$results in range$rangestr\n";
  return undef;
}

sub flail_list {
  init_pager();
  if (defined($FOLDER)) {
    my $cur = $FOLDER->current_message;
    if (!defined($_[0])) {
      my $n = $FOLDER->qty;
      @_ = (1 .. $n);
    } else {
      my @tmp;
      eval { @tmp = parse_range("@_"); };
      @_ = @tmp unless $@;
    }
    foreach my $j (sort ascending @_) {
      next unless $FOLDER->message_exists($j);
      my $msg = $FOLDER->get_message($j);
#      say "got msg $j: $msg";
      my $line = "";
      my $tmp;
#      say "tmp is $tmp";
      $tmp = msg_label_summary($j); # 6
      $tmp .= sprintf("[%3d]", $j); # 3+2=5
      $line .= colored_($tmp, "red");
      $tmp = "";
      if ($j == $cur) {
        $tmp .= "*";
      } else {
        $tmp .= " ";
      }
      $line .= colored_($tmp, "cyan"); # 1
      my $hdrs = $msg->head();
      my $x = $hdrs->get("Date", 0);
      chomp($x);
      $x =~ s|\s+| |gs;
      my $t = parsedate($x);
      my @x = gmtime($t);
      $tmp = sprintf("%04d/%02d/%02d %02d:%02d", 1900+$x[5], $x[4]+1, $x[3],
                       $x[2], $x[1]);
      $line .= colored_($tmp, "red"); # 4+2+2+3+2+1+2=16
      $x = $hdrs->get("From", 0);
      chomp($x);
      $x =~ s|\s+| |gs;
      $tmp = sprintf(" %-20.20s", $x); # 21 + 16 + 1 + 5 + 6 = 49
      $line .= colored_($tmp, "blue");
      $x = $hdrs->get("Subject", 0);
      chomp($x);
      $x =~ s|\s+| |gs;
      my $maxw = 29;
      if (defined($MAX_LINE_WIDTH) && ($MAX_LINE_WIDTH > 0)) {
        $maxw = $MAX_LINE_WIDTH - 50;
        $maxw = 29 if $maxw <= 0;
      }
      $tmp = sprintf(sprintf(q{ %%%s%d.%ds}, $LeftJustifyList? '-': '', $maxw, $maxw), $x);
      $line .= colored_($tmp, "cyan");
      if (print_paged_line($line, 1) < 0) {
        $FOLDER->current_message($cur);
        return;
      }
    }
  } else {
    if ($SUBDIR eq "") {
      print "top level of folder hierarchy:\n";
    } else {
      print "folders in $SUBDIR:\n";
    }
    open(LS, "ls -C $SUBDIR|") || die "$P: could not ls $SUBDIR: $!\n";
    while (<LS>) {
      chomp;
      last if (print_paged_line($_, 1) < 0);
    }
    close(LS);
  }
}

sub flail_move {
  if ($#_ < 1) {
    print "need at least two arguments\n";
    return;
  }
  if (defined($FOLDER)) {
    my $target = pop(@_);
    my $fn = $FolderDir . "/" . $target;
    my $nmv = 0;
    sys("touch $fn") if (!(-f $fn)); ## k-lam3
    my $tfolder = Mail::Folder->new('AUTODETECT', $fn, Create => 1,
                                   DefaultFolderType => 'Mbox');
    if (!$tfolder) {
      print "could not open or create target folder $target\n";
      return;
    }
    say "mv: target = $tfolder: $fn";
    my @tmp;
    eval { @tmp = parse_range("@_"); };
    if ($@) {
      warn("range expression bad: $@\n");
      return;
    }
    @_ = @tmp;
    say "mv: range => @tmp";
    foreach my $i (@tmp) {
      my $msg = $FOLDER->get_message($i);
      if (!$msg) {
        print "could not get message $i in $FOLDER_NAME\n";
      } else {
        $tfolder->append_message($msg);
        $FOLDER->delete_message($i);
        $FOLDER->add_label($i, "filed");
        print "moved message $i\n" unless $Quiet;
        $nmv++;
      }
    }
    $tfolder->sync();
    $tfolder->close();
    reopen_current_folder() if $SyncImmediately;
    print "moved $nmv messages from $FOLDER_NAME to $target\n" unless $Quiet;
  } else {
    my $target = pop(@_);
    my $tfn = "$FolderDir/$target";
    if (!(-d $tfn)) {
      if (-f $tfn) {
        print "target $target already exists\n";
        return;
      }
      if ($#_ != 0) {
        print "can only take two arguments in this form\n";
        return;
      }
      my $sfn = "$FolderDir/$_[0]";
      if (!(-f $sfn)) {
        print "source folder $_[0] does not exist\n";
        return;
      }
      rename($sfn, $tfn);
      print "folder $_[0] renamed to $target\n";
    } else {
      foreach my $s (@_) {
        my $sfn = "$FolderDir/$s";
        if (!(-e $sfn)) {
          print "source $s does not exist -- skipping\n";
        } else {
          my $t = "$tfn/$s";
          rename($s, $t) || print "could not move $s to $t: $!\n";
        }
      }
    }
  }
}

sub flail_copy {
  if ($#_ < 1) {
    print "need at least two arguments\n";
    return;
  }
  if (defined($FOLDER)) {
    my $target = pop(@_);
    my $fn = $FolderDir . "/" . $target;
    my $ncp = 0;
    sys("touch $fn") if (!(-f $fn));
    my $tfolder = new Mail::Folder('AUTODETECT', $fn, Create => 1,
                                   DefaultFolderType => 'Mbox');
    if (!$tfolder) {
      print "could not open or create target folder $target\n";
      return;
    }
    my @tmp;
    eval { @tmp = parse_range("@_"); };
    if ($@) {
      warn("range expression bad: $@\n");
      return;
    }
    @_ = @tmp;
    say "cp: range => @tmp";
    foreach my $i (@tmp) {
      my $msg = $FOLDER->get_message($i);
      if (!$msg) {
        print "could not get message $i in $FOLDER_NAME\n";
      } else {
        $tfolder->append_message($msg);
        $FOLDER->add_label($i, "filed");
        print "copied message $i\n" unless $Quiet;
        $ncp++;
      }
    }
    $tfolder->sync();
    $tfolder->close();
    print "copied $ncp messages from $FOLDER_NAME to $target\n" unless $Quiet;
  } else {
    print "no folder open\n";
  }
}

sub flail_remove {
  if (defined($FOLDER)) {
    my $cur = $FOLDER->current_message;
    if (!defined($_[0])) {
      print "deleting message $cur in $FOLDER_NAME\n" unless $Quiet;
      $FOLDER->delete_message($cur);
    } else {
      my @tmp;
      eval { @tmp = parse_range("@_"); };
      @_ = @tmp unless $@;
      print "deleting messages @_ in $FOLDER_NAME\n" unless $Quiet;
      $FOLDER->delete_message(@_);
    }
    reopen_current_folder() if $SyncImmediately;
  } else {
    print "no folder open\n";
  }
}

sub flail_sync {
  if (defined($FOLDER)) {
    reopen_current_folder();
    print "folder $FOLDER_NAME sync'ed\n" unless $Quiet;
  }
}

sub flail_reset {
  my($what,@args) = @_;
  if (!$what) {
    print "usage: reset all|passwords|connections\n";
    return;
  }
  forget_passwords(@args) if ($what =~ /^all|pass/);
  clear_connection_cache() if ($what =~ /^all|conn/);
  print "state cleared\n";
}

sub flail_map_proc {
  my $label = shift(@_);
  my $proc = shift(@_);
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  if (!defined($label)) {
    print "map requires a label to map over\n";
  }
  my @msgnos;
  if ($label =~ /^all$/i) {
    @msgnos = $FOLDER->message_list();
  } elsif ($label =~ /^cur$/i) {
    @msgnos = ( $FOLDER->current_message );
  } else {
    @msgnos = $FOLDER->select_label($label);
    if (!scalar(@msgnos)) {
      eval {
        @msgnos = parse_range($label, 0);
      };
      @msgnos = () if ($@);
    }
  }
  if (!scalar(@msgnos)) {
    print "no messages in \"$label\"\n" unless $Quiet;
    return;
  }
  my $args = defined($_[0])? "@_": undef;
  foreach my $n (sort ascending @msgnos) {
    my $cargs = $args;
    if (!defined($cargs)) {
      $cargs = "$n";
    } else {
      $cargs =~ s/%n/$n/g;
    }
    my @args = split(" ", $cargs);
    local $N = $n;
    local $M = $FOLDER->get_message($n);
    local $F = $FOLDER;
    local $H = $M->head();
    eval {
      local $SIG{INT} = sub { die "map interrupted..."; };
      local $SIG{TERM} = sub { die "map interrupted..."; };
      local $SIG{QUIT} = sub { die "map interrupted..."; };
      &$proc(@args)
    };
    if ($@) {
      my $msg = "$@";
      chomp($msg);
      $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
      $| = 1;
      print "\n$msg\n";
      last;
    }
  }
}

sub flail_map {
  my $label = shift(@_);
  my $cmd = shift(@_);
  say "flail_map label=$label cmd=$cmd rest=(@_)";
  my $snippet;
  my $proc;
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  if (!defined($label)) {
    print "map requires a label to map over\n";
  }
  if (!defined($cmd)) {
    print "map requires a command to map\n";
  } elsif ($cmd =~ /^\{/) {
    $snippet = "$cmd";
    while (my $c = shift(@_)) {
      $snippet .= " $c";
      last if ($c =~ /\}$/);            # XXX this is bogus
    }
    $proc = sub { eval $snippet; die "$@" if $@; };
  } else {
    my $cinfo = $COMMANDS{$cmd};
    if (!defined($cinfo)) {
      print "unknown command: $cmd\n";
      return;
    }
    $proc = $cinfo->[0];
  }
  flail_map_proc($label, $proc, @_);
#   my @msgnos;
#   if ($label =~ /^all$/i) {
#     @msgnos = $FOLDER->message_list();
#   } elsif ($label =~ /^cur$/i) {
#     @msgnos = ( $FOLDER->current_message );
#   } else {
#     @msgnos = $FOLDER->select_label($label);
#     if (!scalar(@msgnos)) {
#       eval {
#         @msgnos = parse_range($label, 0);
#       };
#       @msgnos = () if ($@);
#     }
#   }
#   if (!scalar(@msgnos)) {
#     print "no messages in \"$label\"\n" unless $Quiet;
#     return;
#   }
#   my $args = defined($_[0])? "@_": undef;
#   foreach my $n (sort ascending @msgnos) {
#     my $cargs = $args;
#     if (!defined($cargs)) {
#       $cargs = "$n";
#     } else {
#       $cargs =~ s/%n/$n/g;
#     }
#     say "[$cmd $cargs]";
#     my @args = split(" ", $cargs);
#     local $N = $n;
#     local $M = $FOLDER->get_message($n);
#     local $F = $FOLDER;
#     local $H = $M->head();
#     eval {
#       local $SIG{INT} = sub { die "map interrupted..."; };
#       local $SIG{TERM} = sub { die "map interrupted..."; };
#       local $SIG{QUIT} = sub { die "map interrupted..."; };
#       &$proc(@args)
#     };
#     if ($@) {
#       my $msg = "$@";
#       chomp($msg);
#       $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
#       $| = 1;
#       print "\n$msg\n";
#       last;
#     }
#   }
}

sub flail_mark {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  if (!defined($_[0])) {
    my $cur = $FOLDER->current_message;
    if (!defined($cur))  {
      print "no current message\n";
      return;
    }
    push(@_, $cur);
  } elsif ($_[0] =~ /^all$/i) {
    @_ = $FOLDER->message_list();
  } elsif ($_[0] =~ /^\{/) {
    my $snippet = "@_";
    say "snippet: $snippet";
    my $func = sub { eval $snippet };
    @_ = $FOLDER->select($func);
    say "select: @_";
  } elsif ("@_" =~ /^,(.*)$/) {
    my $snippet = "{ my \$msg = shift(\@_); $1 }";
    $snippet =~ s/%m/\$msg/g;
    say "snippet: $snippet";
    my $func = sub { eval $snippet };
    @_ = $FOLDER->select($func);
    say "select: @_";
  } else {
    my @tmp;
    eval { @tmp = parse_range("@_"); };
    @_ = @tmp unless $@;
  }
  foreach my $n (@_) {
    if (!$FOLDER->message_exists($n)) {
      print "no such message: $n\n" unless $Quiet;
      next;
    }
    $FOLDER->add_label($n, "marked");
    print "[message $n marked]\n" unless $Quiet;
  }
}

sub flail_unmark {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $label = "marked";
  if ($_[0] =~ /^-(\S+)/) {
    $label = $1;
    shift(@_);
  }
  if (!defined($_[0])) {
    my $cur = $FOLDER->current_message;
    if (!defined($cur))  {
      print "no current message\n";
      return;
    }
    push(@_, $cur);
  } elsif ($_[0] =~ /^all$/i) {
    my $n = $FOLDER->clear_label($label);
    print "[$n messages unmarked]\n" unless $Quiet;
    return;
  } elsif ($_[0] =~ /^\{/) {
    my $snippet = "@_";
    my $func = sub { eval $snippet };
    @_ = $FOLDER->select($func);
  } else {
    my @tmp;
    eval { @tmp = parse_range("@_"); };
    @_ = @tmp unless $@;
  }
  foreach my $n (@_) {
    if (!$FOLDER->message_exists($n)) {
      print "no such message: $n\n" unless $Quiet;
      next;
    }
    $FOLDER->delete_label($n, $label);
    print "[message $n unmarked]\n" unless $Quiet;
  }
}

sub flail_count {
  if (!defined($FOLDER)) {
    print "no folder currently open\n";
    return;
  }
  my $do_list = 0;
  if (defined($_[0])) {
    if ($_[0] =~ /^-list$/) {
      shift(@_);
      $do_list = 1;
    }
  }
  if (!defined($_[0])) {
    push(@_, "marked");
  }
  foreach my $label (@_) {
    my @msgs = $FOLDER->select_label($label);
    print "$label: ", scalar @msgs, " messages";
    print ": @msgs" if $do_list;
    print "\n";
  }
}

sub bind_alias_args {
  my $str = shift(@_);
  say "bind_alias_args(@_) str=$str";
  my $a = "@_";
  my $n = 1;
  $str =~ s/%\*/$a/g;
  foreach my $arg (@_) {
    $str =~ s/%$n/$arg/g;
    ++$n;
  }
  say "bind_alias_args => $str";
  return $str;
}

sub flail_alias {
  my $name = shift(@_);
  if (!defined($name)) {
    print "need at least an alias name\n";
    return;
  }
  my $def = "@_";
  my $old = $COMMANDS{$name};
  if (defined($old)) {
    if (($old->[1] !~ /^alias:/) && !$AllowCommandOverrides) {
      print "cannot override built-in command $name with an alias\n";
      return;
    }
    if (!defined($_[0])) {
      my $doc = $old->[1];
      $doc =~ s/^alias:\s*//;
      print "$name: $doc\n";
      return;
    }
    delete $COMMANDS{$name};
  }
  my $func = sub { my $str = bind_alias_args($def, @_); flail_eval($str); };
  flail_defcmd($name, $func, "alias: $def");
}

sub flail_unalias {
  if (!defined($_[0])) {
    print "need a list of aliases to undefine\n";
    return;
  }
  foreach my $name (@_) {
    my $def = $COMMANDS{$name};
    if (!defined($def)) {
      print "$name undefined\n";
    } elsif ($def->[1] !~ /^alias:/) {
      print "$name is not an alias\n";
      return;
    } else {
      print $def->[1], "\n";
      delete $COMMANDS{$name};
    }
  }
}

sub print_paged_string {
  my $str = shift(@_);
  my @lines = split("\n", $str);
  init_pager();
  foreach my $line (@lines) {
    last if print_paged_line($line) < 0;
  }
}

sub show_warranty {
  print_paged_string($WARRANTY);
}

sub show_license {
  print_paged_string($LICENSE);
}

sub flail_help {
  my $x = 0;
  my $specific = 0;
  my $all = 0;
  if (!defined($_[0])) {
    @_ = sort keys %COMMANDS;
    $all = 1;
  } else {
    if ($OPT->{brief} || (!$#_ && ($_[0] =~ /^brief$/i))) {
      my $brief = '';
      my $col = 0;
      my @cmds = sort keys %COMMANDS;
      my $max = $MAX_LINE_WIDTH - 1;
      $max = 79 if ($max <= 0);
      print scalar(@cmds)." commands:\n" unless $Quiet || $OPT->{quiet};
      while (defined(my $cmd = shift(@cmds))) {
        my $cmdc = $cmd;
        $cmdc .= "," if @cmds;
        my $l = length($cmdc);
        if (!$col) {
          $brief .= $cmdc;
          $col = $l;
        } elsif ($col+$l >= $MAX_LINE_WIDTH) {
          $brief .= "\n$cmdc";
          $col = $l;
        } else {
          $brief .= " $cmdc";
          $col += $l + 1;
        }
      }
      print "$brief\n";
      return;
    } elsif (($#_ == 0) && ($_[0] =~ /^warranty$/i)) {
      show_warranty();
      return;
    } elsif (($#_ == 0) && ($_[0] =~ /^license$/i)) {
      show_license();
      return;
    } elsif (($#_ == 0) && ($_[0] =~ /^version|copyright$/i)) {
      print $BANNER;
      return;
    } elsif (($#_ == 0) && ($_[0] =~ /^manual|pod$/i)) {
      pod2usage(-exitval => 'NOEXIT', -verbose => 2);
      return;
    }
    $specific = 1;
  }
  init_pager();
  foreach my $key (@_) {
    my @show = ();
    if (exists($COMMANDS{$key})) {
      @show = ($key);
    } else {
      @show = (
        sort { $a cmp $b }
        grep { $_ =~ m/$key/ }
        keys %COMMANDS
      );
    }
    foreach my $what (@show) {
      my $info = $COMMANDS{$what};
      my $descr = undef;
      $descr = $info->[1] if ref($info);
      $x = print_paged_line(sprintf("%20s: %s", $what, $descr));
      last if $x < 0;
    }
    last if $x < 0;
  }
  if (!$specific && ($x >= 0)) {
    return if print_paged_line("") < 0;
    return if print_paged_line("     !<cmd> exec shell command") < 0;
    return if print_paged_line("     |<cmd> pipe current msg to cmd") < 0;
    return if print_paged_line("     ,<exp> evaluate perl expression") < 0;
  }
}

sub do_shell_esc {
  my $cmd = shift(@_);
  if ($cmd =~ /^!(.*)$/) {
    $cmd = $1;
    my $here = getcwd;
    chdir($ENV{HOME});
    eval { system($cmd); };
    chdir($here);
  } else {
    my $x = `$cmd`;
    print $x;
  }
}

sub do_shell_pipe {
  my $cmd = shift(@_);
  if (!defined($FOLDER)) {
    print "no current message to pipe into $cmd\n";
    return;
  }
  my $msg = $FOLDER->get_message($FOLDER->current_message);
  open(PIPE, "|$cmd") || return;
  print PIPE $msg->as_string;
  close(PIPE);
}

## XXX Get rid of I/O in signal handlers damnit

sub on_interrupt {
  $| = 1;
  if ($@) {
    print "\n$P: fatal error: $@\n$P: cleaning up;";
  } else {
    print "\n$P: interrupted;";
  }
  if ($FOLDER) {
    print " folder: sync...";
    $FOLDER->sync();
    print " close...";
    $FOLDER->close();
    print " ok.";
  }
  if (!$NoAddressBook) {
    print " addressbook: close...";
    addressbook_checkpoint(1);
    print " ok.";
  }
  $Quiet = 0;
  clear_connection_cache();
  print " bye.\n";
  exit(0);
}

sub sigwinch {
  ($MAX_PAGE_LINES, $MAX_LINE_WIDTH) = get_term_size();
  print "[TTY: ".$MAX_LINE_WIDTH." x ".$MAX_PAGE_LINES."]\n"; # XXX NO!
  $N_LINES = 0;
  $RECENT_LINES = 0;
}

sub parse_mail_server {
  my $str = shift(@_);
  my $server;
  my $user;
  my $pass;
  if ($str =~ /^(\S*)\@(\S*)$/) {
    $user = $1;
    $server = $2;
    if ($server =~ /^(\S+):(\S+)$/) {
      $server = $1;
      $pass = $2;
    }
  } else {
    $server = $str;
    $user = $ENV{'USER'};
  }
  return $server, $user, $pass;
}

sub flail_defcmd {
  my($name,$func,$help) = @_;
  die "$P: no command name given to flail_defcmd\n" unless defined($name);
  die "$P: command $name not given a function\n" unless defined($func);
  die "$P: command $name not given any help\n" unless defined($help);
  die "$P: command $name already defined\n"
    if (defined($COMMANDS{$name} && !$AllowCommandOverrides));
  $COMMANDS{$name} = [ $func, $help ];
  return $name;
}

sub flail_defcmd1 {
#  return if defined($COMMANDS{$name});
  local($AllowCommandOverrides) = (1);
  return flail_defcmd(@_);
}

#sub flail_defcmd {
#  my $cmd = shift(@_);
#  my $proc = shift(@_);
#  my $help = shift(@_);
#  my $override = shift(@_);
#  if (defined($COMMANDS{$cmd})) {
#    die "$P: flail command \"$cmd\" already defined" unless $override;
#    delete $COMMANDS{$cmd};
#  }
#  $COMMANDS{$cmd} = [ $proc, $help ];
#}

# parses: /opt:val/opt:val ...
sub parse_cmd_opts {
  my $optstr = shift(@_);
  $optstr = substr($optstr, 1) if ($optstr =~ /^\//);
  my @opts = split(/\//, $optstr);
  my %opthash = ();
  foreach my $o (@opts) {
    say "parsing opt: $o";
    my($k,$v) = split(':', $o, 2);
    $v = $1 if ($v =~ /^\"(.*)\"$/);
    $v = 1 unless defined($v);
    $opthash{lc($k)} = $v;
    say "opthash: " . lc($k) . " => " . $v;
  }
  return \%opthash;
}

sub expand_words {
  my @words;
  foreach (@_) {
    my $word = $_;
    if ($word =~ /^\`(.*)$/) {
      my $exp = '';
      $exp = eval "$1";
      $Verbose && warn("expand_words($word): $exp ($@)\n");
      warn("error: $word: $@\n") if $@;
      $word = $exp;
    }
    push(@words, $word);
  }
  return @words;
}

sub flail_eval {
  my $line = shift(@_);
  my $commands = commandify($line,[[]]);
  my $quit = 0;
  foreach my $cmd (@$commands) {
    $quit = flail_eval_($cmd);
    last if $quit;
  }
  return $quit ? -1 : 0;
}

sub flail_eval_ {
  my($cmdvec) = @_;
  return 0 unless ($cmdvec && @$cmdvec);
  my $cmd = shift(@$cmdvec);
  my @words = @$cmdvec;
  my $line = join(' ', map { ($_ =~ /\s/) ? qq|"$_"| : $_ } @words);
  @words = expand_words(@words);
  my $opthash = {};
  if ($cmd =~ /^([^\/]+)(\/.*)$/) {
    $cmd = $1;
    my $optstr = $2;
    $opthash = parse_cmd_opts($optstr);
  } elsif ($words[0] =~ /^\//) {
    my $optstr = shift(@words);
    $opthash = parse_cmd_opts($optstr, $opthash);
  }
  say("flail_eval cmd=$cmd words=(@words) opthash={".join(", ", map { my $v = $opthash->{$_}; qq|$_="$v"| } sort keys %$opthash)."}");
  my $cinfo;
  my $proc;
  $cmd = lc($cmd);
  return -1 if $cmd =~ /^quit$/;
  if ($cmd =~ /^!(.+)$/) {
    my $x = $1;
    unshift(@words, $x);
    $x = join(" ", map { ($_ =~ /\s/) ? qq|"$_"| : $_ } @words);
    do_shell_esc($x);
    return 0;
  } elsif ($cmd =~ /^\|(.+)$/) {
    my $x = $1;
    unshift(@words, $x);
    $x = join(" ", map { ($_ =~ /\s/) ? qq|"$_"| : $_ } @words);
    do_shell_pipe($x);
    return 0;
  } elsif ($cmd =~ /^,(.+)$/) {
    my $string = $1;
    $string .= " $line" if ($line && length($line));
    print "[eval: $string]\n" unless $Quiet;
    eval $string;
    print "\n";
    print "whoops: $@\n" if ($@);
    return 0;
  }
  say "... after processing, words=(@words)";
  $cinfo = $COMMANDS{$cmd};
  $proc = undef;
  $proc = $cinfo->[0] if defined($cinfo);
  if (defined($proc)) {
    eval {
      local $SIG{INT} = sub { die "flail_eval interrupted..."; };
      local $SIG{TERM} = sub { die "flail_eval interrupted..."; };
      local $SIG{QUIT} = sub { die "flail_eval interrupted..."; };
      local $CMD = $cmd;
      local $OPT = $opthash;
      local $Verbose = 1 if $opthash->{verbose};
      local $Quiet = 1 if ($opthash->{quiet} || $opthash->{q});
      &$proc(@words);
    };
    if ($@) {
      my $msg = "$@";
      chomp($msg);
      $msg =~ s/^(.*)\s+at\s\S+\sline\s\d+/$1/;
      $| = 1;
      print "\n$msg\n";
    }
  }
  print "$cmd: undefined command - \"help\" for help\n" unless defined($proc);
  return 0;
}

# command table
$COMMANDS{'check'}   = [ \&flail_check, "check [imap|pop3|spool] file|mailbox [server]" ];
$COMMANDS{'get'}     = [ \&flail_get, "get [imap|pop3] mailbox [server [folder]]" ];
$COMMANDS{'cd'}      = [ \&flail_open, "cd foldername" ];
$COMMANDS{'pwd'}     = [ \&flail_stat, "show current folder" ];
$COMMANDS{'next'}    = [ \&flail_next, "go to next message" ];
$COMMANDS{'prev'}    = [ \&flail_prev, "go to previous message" ];
$COMMANDS{'cat'}     = [ \&flail_read, "show a message's content" ];
$COMMANDS{'decrypt'} = [ \&flail_decrypt, "decrypt and show a message" ];
$COMMANDS{'send'}    = [ \&flail_send, "send a message" ];
$COMMANDS{'forward'} = [ \&flail_forward, "forward a message" ];
$COMMANDS{'resend'}  = [ \&flail_resend, "resend a message" ];
$COMMANDS{'reply'}   = [ \&flail_reply, "reply to a message" ];
$COMMANDS{'mkdir'}   = [ \&flail_mkdir, "create new folder" ];
$COMMANDS{'decode'}  = [ \&flail_decode, "decode a MIME message" ];
$COMMANDS{'range'}   = [ \&flail_range, "expand a range expression" ];
$COMMANDS{'ls'}      = [ \&flail_list, "list messages and subfolders" ];
$COMMANDS{'mv'}      = [ \&flail_move, "move a message or folder" ];
$COMMANDS{'cp'}      = [ \&flail_copy, "copy a message or folder" ];
$COMMANDS{'rm'}      = [ \&flail_remove, "remove a message or folder" ];
$COMMANDS{'help'}    = [ \&flail_help, "help [pod|license|warranty|version|brief|cmd|regexp ...]" ];
$COMMANDS{'quit'}    = [ sub {}, "quit $P" ];
$COMMANDS{'sync'}    = [ \&flail_sync, "sync current folder state" ];
$COMMANDS{'goto'}    = [ \&flail_goto, "go to a specific message" ];
$COMMANDS{'reset'}   = [ \&flail_reset, "reset all|pass|conns - reset various bits of state" ];
$COMMANDS{'map'}     = [ \&flail_map, "map label cmd ..." ];
$COMMANDS{'mark'}    = [ \&flail_mark, "mark msg ..." ];
$COMMANDS{'unmark'}  = [ \&flail_unmark, "unmark msg ..." ];
$COMMANDS{'count'}   = [ \&flail_count, "count [-list] [label ...]" ];
$COMMANDS{'alias'}   = [ \&flail_alias, "alias name cmds..." ];
$COMMANDS{'unalias'} = [ \&flail_unalias, "unalias name [name...]" ];
$COMMANDS{'headers'} = [ \&flail_headers, "headers [msgno ...]" ];
$COMMANDS{'address'} = [ \&flail_addressbook, "address {add|show|list|del|import|help} [...]" ];
$COMMANDS{'run'}     = [ \&flail_run_hooks, "run [label] - run hooks for label, default=marked" ];
$COMMANDS{'echo'}    = [ \&flail_echo, "echo whatever - print out a message" ];
$COMMANDS{'pipe'}    = [ \&flail_pipe, "pipe [msgseq] cmd...- pipe message or messages into a command" ];

# standard headers to show
$SHOW_HEADERS{'from'} = 1;
$SHOW_HEADERS{'to'} = 1;
$SHOW_HEADERS{'subject'} = 1;
$SHOW_HEADERS{'date'} = 1;
$SHOW_HEADERS{'cc'} = 1;

## main program
die $USAGE unless getopts('cqoQlhsp1vr:d:P:I:i:F:D:S:T:e:C:R:A:nakEbN:g:Gu:U');
$Verbose = $opt_v;
if (defined($opt_h)) {
  die($USAGE) unless $Verbose;
  pod2usage(-verbose => 2);
}
($MAX_PAGE_LINES, $MAX_LINE_WIDTH) = get_term_size();
$RCFile = $opt_r || $DEF_RCFILE;
$AllowCommandOverrides = $opt_o;
$Quiet = defined($opt_Q)? 1: 0;
$SyncImmediately = defined($opt_s)? 1: 0;
$Debug = $opt_G;
$RemoveFromServer = defined($opt_l)? 0: 1;
$Domain = $opt_D || $DEF_DOMAIN;
$FromAddress = $opt_F || $DEF_FROM;
$TempDir = $opt_T || $DEF_TEMPDIR;
$SMTPHost = $opt_S || $DEF_SMTPHOST;
$Editor = $opt_e || $DEF_EDITOR;
$AskBeforeSending = defined($opt_q)? 0: 1;
$CheckType = $opt_R || $DEF_CHECK_TYPE;
die "$P: unknown remote folder type $CheckType\n$USAGE\n"
  unless ($CheckType =~ /^(pop3|imap)$/i);
$NoAddressBook = $opt_n;
$AddressBook = $opt_A || $DEF_ADDRESSBOOK;
$AutoAddressBook = $opt_a;
$AskAddressBook = $opt_k;
$ExactHostMatch = $opt_E;
$QuietAddressBook = $opt_b;
$NoDefaultCC = $opt_c || $opt_p;
$PipeStdin = $opt_p;
$DefaultSubject = $opt_u;
$HeadersFromStdin = $opt_U if $PipeStdin;
$NewLabel = $opt_N || $DEF_NEW_LABEL;
$FCCFolder = $opt_C || $DEF_FCC_FOLDER;
$FolderDir = $opt_d || $DEF_FOLDER_DIR;
$POPInfo = $opt_P;
my $pass;
($POP3Server, $POP3User, $pass) = parse_mail_server($POPInfo)
  if defined($POPInfo);
if (defined($pass)) {
  remember_password("POP3/$POP3User", $pass);
  $pass = undef;
}
$IMAPInfo = $opt_I;
($IMAPServer, $IMAPUser, $pass) = parse_mail_server($IMAPInfo)
  if defined($IMAPInfo);
if (defined($pass)) {
  remember_password("IMAP/$IMAPUser", $pass);
  $pass = undef;
}
$IncomingFolder = $opt_i || $DEF_INCOMING;
$SingleCommand = $opt_1;
$SignatureDir = $opt_g || $DEF_SIGDIR;
$REPL = new Term::ReadLine $P;
$REPL->ornaments(0);
$SIG{INT} = \&on_interrupt;
$SIG{TERM} = \&on_interrupt;
$SIG{QUIT} = \&on_interrupt;
#$SIG{__DIE__} = sub { print "$@\n"; on_interrupt(); }
if (-f $RCFile) {
  do $RCFile || (print("\n$@") && die "$P: could not load $RCFile\n");
}
die "$P: no folder dir\n$USAGE\n" unless -d $FolderDir;
$SIG{WINCH} = \&sigwinch unless $NoSIGWINCH;
chdir($FolderDir) || die "$P: could not cd to $FolderDir: $!\n";
$CryptoSignCmd = "$GPGBinary --clearsign";     # set in .flailrc
$CryptoCryptCmd = "$GPGBinary --armor -se";    # ditto
$ENV{TMPDIR} = $TempDir if $TempDir;
$Quiet = 0 if $Verbose;
addressbook_load();
print $BANNER unless $Quiet;
my $line = undef;
$line = join(" ", @ARGV) if defined($ARGV[0]);
while (1) {
  $line = $REPL->readline(prompt_str()) unless defined($line);
  chomp($line);
  if (!length($line)) {
    $line = undef;
    next;
  }
  last if flail_eval($line) < 0;
  last if $SingleCommand;
  $line = undef;
}
addressbook_checkpoint(1);
clear_connection_cache();
exit(0);

__END__

=pod

=head1 NAME

flail - a hacker's mailer in Perl

=head1 SYNOPSIS

  # to run a single flail command:
  $ flail -1 -other_options [cmd ... args ...]

  # to get into the interactive command loop
  $ flail

  # to get a usage message:
  $ flail -h

  # to get the whole manual
  $ flail -hv

=head1 DESCRIPTION

flail is a hacker's mailer, written in Perl, and sporting a
command-line interface.  It currently supports pop3 and imap for
access to remote maildrops, as well as regular old Unix mail spool
files for local maildrops (e.g. because you use fetchmail).

The commands are vaguely Unix-like (rm, cp, mv, cat, ls).  There are
facilities for mapping bits of perl code over some subset of the
messages in a folder, crypto, external editors, and user-defined
commands.

=head1 COMMAND-LINE OPTIONS

You naturally invoke flail on the command-line.  It takes
single-letter options, just like Pan intended.  Where it makes sense,
we note the name of the config variable corresponding to each option
in parentheses.

=over 4

=item -c ($NoDefaultCC)

Do not ask for Cc: addresses by default in the composer

=item -q ($AskBeforeSending)

Confirm with user before sending message

=item -o ($AllowCommandOverrides)

Allow the alias command to override built-in commands.

=item -Q ($Quiet)

Be Vewy Quiet: Only produce error messages and explicitly
request output (e.g. ls)

=item -l ($RemoveFromServer)

Remove messages from server during C<get> processing.

=item -h

When by itself, display usage message.
When specified with -v, display this POD.

=item -s ($SyncImmediately)

Automatically sync the current folder after operations that change it,
e.g.  mv, rm, ...

=item -p ($PipeStdin)

Read message from stdin; really only useful in conjunction with <-1>.
Implies C<-c>.

=item -1

Run a single flail command, specified as arguments on the command line.
For instance

  $ flail -1 send rms@mit.edu

can be used to send a single message to someone famous.

=item -v ($Verbose)

Make ourselves verbose.

=item -r rcfile

Specify an alternate rc file.  The default is C<~/.flailrc>

=item -d folderdir ($FolderDir)

Specify an alternative directory for mail folders.  The default
is C<~/mail>

=item -i incfolder ($IncomingFolder)

Specify an alterntive incoming mail folder name.  The default
is C<INCOMING>

=item -P pop3info

=item -I imapinfo

These options are largely outdated, but can still be useful, especially
in conjunction with C<-1>.

In both cases, a string of the form C<user@server:port>, where
C<user> and C<port> are both optional, and given the obvious
default values if left unspecified.

=item -F fromaddr ($FromAddress)

=item -D domain ($Domain)

=item -S smtphost ($SMTPHost)

These are also probably only really useful with C<-1>, since your
C<~/.flailrc> will probably arrange to set them in less obvious ways.
These options set the From address, domain, and SMTP relay used to
send a message.

=item -T tempdir ($TempDir)

Set the temp dir used for e.g. message composition.

=item -e editor ($Editor)

Set the external editor used from the composer.  Defaults
to your C<$EDITOR> environment variable.

=item -C fccfolder ($FCCFolder)

Set the folder name in which to automatically file outgoing messages.

=item -R pop3|imap ($CheckType)

Outdated: specify default message check method, pop3 or imap.  Since you
can have more than one account of each kind, sort of silly.  If you do
not specify any arguments to C<check>, we use C<$CheckType> as the default.

=item -A abook ($AddressBook)

File containing your addressbook as a dbm file.

=item -n ($NoAddressBook)

Do not use an addressbook.

=item -a ($AutoAddressBook)

Automatically try to look up all outgoing addresses in our
addressbook.

=item -k ($AskAddressBook)

Interactively prompt the user for address book matches before sending.

=item -E ($ExactHostMatch)

Only match two addresses if the hostnames are identical.

=item -b ($QuietAddressBook)

Make addressbook functionality quiet.

=item -N newlabel ($NewLabel)

Label all incoming messages with C<newlabel> by default.

=item -g dot.sig.dir ($SignatureDir)

Look for dot.sigs in dot.sig.dir

=item -G ($Debug)

Turn on debugging output.  Not useful for ordinary use.

=item -u defaultsubj ($DefaultSubject)

Set the default subject for outgoing email.  None by default

=item -U ($HeadersFromStdin)

If C<-p> is specified, then C<-U> says that the entire message,
including headers, is coming in on stdin.

=back


=head1 COMMAND LANGUAGE

The command language is vaguely Unixy.  Commands look like:

  word [arg arg...]

Some commands take slash-style options, ala TOPS-20:

  send/as:someone@somewhere ...

Many (most?) commands at least will pay attention to options
named C<debug>, C<verbose> and C<quiet>.  For instance, to
turn on SMTP debugging when you send an email:

  send/debug to@some.one

The first character of a command might specify another action than a
normal command:

=over 8

=item !cmd

Execute Unix command C<cmd> and display results on stdout

=item |cmd

Pipe the current message through C<cmd> and display the results on stdout

=item ,code

Evaluate the perl code C<code>.  Does not display results by default,
if you want them, use the C<print> statement, e.g.

  ,print $Editor

=back

Other than those special cases, we look at our first word and
dispatched based on it.  The complete list of built-in commands
follows, grouped by function.  For information on adding your own
commands, see the section on CONFIGURATION, below.

Message Sequences (also called "Range Expressions") are an important
part of the flail command language.  The following are all valid
range expressions:

=over

=item 1

Message 1

=item 1:3

Messages 1 through 3

=item 3:$

Messages 3 through the end of the folder.

=item $-3:$

The last three messages in a folder

=item 1,3,5,$-3:$-1

The first, third, and fifth messages, as well as the second two
from the end (not including the last one)

=back

In addition, you can specify C<-label> to include all messages tagged
with the given label, so the range expression C<-marked> expands to
all marked messages.

Many commands take message sequences in place of single message
numbers.  Some do not.  Hopefully, I'll do a good job of telling you
which is which.


=head2 Checking and Retrieving Mail

Commands to query and fetch mail from mail spools.

=head3 check: check pop3, imap or local spool mailbox

Check a mailbox for mail.  The full syntax is

  check type user server

e.g.

  check pop3 attila mailserver

looks for mail using pop3 on mailserver as the user attila.  You will
be prompted for a password, unless flail remembers what it is.  The
C<remember_password> internal function can be useful in your
configuration file to keep you from having to type your password all
the time.  If you insist, you can specify your password as the final
argument on the command line, but we don't recommend it.

To check a local spool file, use

  check spool /path/to/spool

The default spool is C</var/mail/yourusername>, so if this is correct
you can just
do

  check spool

to check your local mail spool.  You can override both the file name
and directory with the C<$SpoolFile> and C<$SpoolDir> configuration
variables in your C<~/.flailrc>.

=head3 get: download mail from a remote mailbox

Just like the C<check> command, except that we fetch the mail and
incorporate it into the incoming folder.  It takes the same C<type>
parameter as its first argument, e.g.

  get spool

grabs (and expunges) your local mail spool.



=head2 Navigating and Managing Messages

These commands are for stumbling around in the folder tree and looking
at messages.

If you have a folder selected, flail shows you what it is in your
prompt.  If your prompt is simply

  flail>

then you are not in any folder, and many of these commands
will fail with an error.

=head3 next: goto next message

Move to the next message.

=head3 prev: goto previous message

Move to the previous message.

=head3 goto: goto arbitrary message by number

Go to a message by number, e.g.

  goto 3

moves to the message numbered 3 in the output of C<ls>

=head3 cat: display message contents

Displays the current message, or one by number if specified.  Output
is paginated if we know how to do that on your terminal.

=head3 headers: display message headers in detail

The C<cat> command normally shows abbreviated headers.
The C<headers> command shows only the headers for a message,
and it shows them all.

=head3 decode: decode a MIME message

Not yet implemented.

=head3 cp: copy a message to another folder

Copy a message to another folder, e.g.

  cp 3 spam

copies message 3 to the folder named SPAM

=head3 mv: move a message to another folder

Like C<cp>, but removes the message from the current folder
after it is copied.  If C<$SyncImmediately> is true, we
sync the folder afterwards.  Otherwise, the message appears
with the C<D> (Deleted) flag turned on until you C<sync>.

A message sequence can be specified, e.g.

  mv 1,2,$-3:$ odd_folder


=head3 rm: delete a message

Delete a message or messages, e.g.

  rm 1:$

deletes all messages in the current folder. 



=head2 Folder-Related Commands

flail uses L<Mail::Folder>, and can thus support any type of mail
folder that it supports.  Generally, we use mbox folders, which
are single files containing multiple messages.  None the less,
we treat "folders" as if they were directories from the command
language, for consistency.

=head3 cd: enter a folder

Change the object of your affections to another folder, e.g.

  cd INCOMING

=head3 pwd: display current folder

Show the current folder and your state in it.

=head3 ls: list folder contents

List the contents of the folder, one message per line.  If
C<$PlainOutput> is not true, we try to color it nicely for ttys that
support ANSI color sequences, like C<xterm>.  If a message sequence is
specified, we only show those messages.  Output is paginated.

If you are not in a folder, then ls shows you the subfolders in
whatever part of the folder tree you happen to be in.  If you are at
top level, this is all of the top-level folders under the root.

You can specify an arbitrary range expression to ls, as you can with
many other commands.  For instance,

  ls -marked

will list all marked messages.

=head3 mkdir: create a folder

Not yet implemented.  For now, use the following idiom

  !touch foldername

to create a new blank folder (remember: we chdir to your
C<$FolderDir> on startup...).



=head2 Sending Messages

Things that call the composer.  See MESSAGE COMPOSITION INTERFACE,
below, for details.

=head3 send: send a new message

Send a message to the addresses given as arguments.  The C<From>
address can be set explicitly with the C<as> option, e.g.

  send/as:bozo@clown.com gosper@mathematicians.org

If there is a problem, you might re-trying the C<send> command with
the C<debug> option, which turns on L<Net::SMTP> debugging and will
produce a large amount of output.

We invoke the external editor of your choice for composition, which
should return a valid status code.  You will generally have a chance
to go over it, re-edit it, abort, cryptosign, attach .sig, etc. after
you're done editing.

=head3 reply: reply to a message

Like C<send>, but replies to the sender of a previous message.

=head3 forward: forward a message to a new recipient

Like C<send>, but forwards an existing message to a third party.

=head3 resend: resend a bounced message

Like C<send>, but resends a message that was bounced.



=head2 The Address Book

=head3 address: interface to the address book

The C<address> command has several subcommands to help you
manage your addresses.  Flail stores these in a dbm file,
typically called C<~/.flail_addressbook>.

Subcommands:

=over 8

=item add nickname email

Add a new entry.  Nickname must be unique in your addressbook.

=item show nickname

Show the address associated with the given nickname.

=item list [regexp]

Search the addressbook by regexp, or list the whole thing
if no regexp specified

=item del nickname

Remove an entry by nickname

=item import filename

Import address book data stored in a file.  The two kinds of files we
currently support are LDIF and CSV; files should have extensions that
reflect their type, e.g C<.ldif> or C<.csv>.

=item take [label]

Extract email addresses from one or more messages and import them
into your addressbook.  If no label is specified, the current message
is examined; otherwise, all messages in the current folder with
the specified label are examined.

=back


=head2 Marking, Mapping and Other Fun Stuff

Messages can have an arbitrary set of labels associated with them.
Some, such as C<deleted> and C<filed>, have meaning to flail itself.
Some, such as C<marked> or whatever other string you might use, are
just for your own purposes.  Marking messages lets you apply code to
them, so flail users do it alot.

=head3 mark: add a label to a message

In the absence of any arguments, applies the C<marked> label to
the current message.

If a message sequence is specified, then all messages in that sequence
get the C<marked> label.  If the word C<all> is specified, then all
messages get C<marked>.

If the first character of our first argument is a comma, then the rest
of the arguments are treated as a bit of perl code that is invoked for
every message in the folder.  The token C<%m> will be substituted for
a variable that is bound to an L<Mail::Internet> object representing
each message in the folder on subsequence calls.

For instance, if we have in our configuration

  sub is_blue { shift->get("Subject") =~ /\[blue\]/; }

Then we can do

  mark ,is_blue(%m)

to mark all messages whose C<Subject> headers contain the string
C<[blue]>.

=head3 unmark: remove a label from a message

Unmark takes the same argumentology as mark, but removes the C<marked>
label instead.

=head3 map: map a piece of code over some messages

  map label ...

Run a command or piece of code over a set of messages, specified by
a label.  If the label is C<all>, then all messages have the action
applied to them.  The action can be a flail command, or a piece of
random Perl code.  In the latter case, the first character of
the code should be a curly brace, and the code should end with
one as well, e.g.

  map marked { grep_msg('Foo'); }

Runs the given code for each message.  The code is called in a
context where the following globals are available in the C<main>
namespace:

=over 8

=item $N the message number in the folder

=item $M a Mail::Internet object that represents the message

=item $F the Mail::Folder object corresponding to the folder

=item $H the Mail::Header object associated with $M

=back

If there are no curly braces, the command should be a legal
flail command.  In both cases, two additional substitutions
take place:

=over 8

=item %n is substituted with the message number

=item %* is substituted for any arguments that appear C<after> the command

=back

This last substitution is a bit odd, and requires explaining.

Supposing we have our hypothetical sub C<grep_msg> (which does in fact
come with the C<dot.flailrc> in the distribution).  It wants a regexp as
its argument.  It uses C<$M>, etc. to get at the message it is
grepping.  Supposing we want to be able to type

  mgrep pattern

to run C<grep_msg("pattern")> over each message.  How do we do it?

  alias mgrep map all { grep_msg("%*"); }

Now, when we type

  mgrep pattern

The C<%*> is substituted with C<pattern>.  This is why C<map> is
useful even when operating on a single message.

Another enlightening example:

  alias mmv map marked mv %n %*

This creates an alias, C<mmv>, which can be used thusly:

  # arrange to mark the messages that are spam,
  # either by hand ...
  mark 1,3,5

  # or by some automated oracle
  mark ,is_spam(%m)

  # now, move it all to a folder named spam
  mmv spam

Of course this is just a contrived example, since you can accomplish
the same thing with labels, e.g.

  mv -marked spam

will move all marked messages to the folder named C<spam>.

=head3 count: count labeled messages

Given a label, count the messages that match it.  If no label is specified,
C<marked> is assumed.

=head3 run: run message hooks for label

Given a label, run all of the message hooks associated with that label
over every message that has that label in the current folder.  See the
discussion on message hooks in Hacking Flail, below.


=head2 State Management

=head3 sync: flush changes to the current folder

Flush any changes to the current folder to disk.  This includes
expunging messages labeled C<deleted>.

=head3 reset: reset various bits of state

Resets the password cache and/or the connection cache.



=head2 Crypto

=head3 decrypt: decrypt a PGP-encrypted message

This needs a rewrite, as my crypto fu relies on outdated modules and
must be rewritten.


=head2 Other Commands

=head3 alias: create a new command

Create a new command.  You cannot overwrite existing command table
entries this way; use Perl code in your config file instead.

Example:

  alias mvspam map marked mv %n spam


=head3 unalias: remove an alias

Remove an alias.

=head3 help: get help

You can ask for help on any specific command or alias by using
it as an argument, e.g.

  help ls

Invoking help with no arguments produces a list of commands.

In addition to commands, you can ask for help on the following
subjects

=over 8

=item pod

spit out the flail manual (thanks to Pod::Usage)

=item version

show our version information

=item license

show our full license

=item warranty

show our warranty

=back


=head3 quit: exit flail

Bug out, flushing all changes.

If you want to bug out without saving anything, use Perl:

  ,exit


=head1 MESSAGE COMPOSITION INTERFACE

When you are sending a message, you will be generally be prompted
before it goes out.  The prompt allows you to perform some fairly
complex sequences of actions with a few keystrokes, and is usually
called the composer.

XXX Write more.


=head1 CONFIGURATION

flail is a hacker's mailer.  Configuring flail means writing Perl
code.  If this does not fill you with joy, you're in the wrong bar.

=head2 Your .flailrc

Flail loads C<~/.flailrc> upon startup.  An extensive example comes
with the distribution (dot.flailrc).  You can specify another file
with the C<-c> command-line option.

Command-line options will already have been parsed by the time your rc
file is loaded.  This means you can check for the value of
e.g. C<$SingleCommand> to see if C<-1> was specified on the command
line, etc.

=head2 Managing Multiple Identities and Mailboxes

=head2 Passwords and the Pipe Trick

=head2 Hacking Flail

Flail is ultimately just a bunch of Perl subs.  It currently all lives
in the C<main> package, which is where your flailrc is loaded as well.
This means you can write code that calls any flail primitive, add new
primitives, or extend the command set using the same API (if you want
to diginfy it with that name) that I use.

WARNING: I will be rewriting flail to use OO techniques in the very
near future.  You should get on the C<flail-dev> mailing list if you
are interested.

=head2 Alphabetical Listing of All Configuration Variables



=head1 BUGS / TODO

Too many bugs to count at the moment...

=over 8

=item Finish the OO/modular rewrite

=item Get rid of all I/O in signal handlers

=item Move main into a MAIN: { } block

=item Re-write this turkey so it's not so fugly

=item Just finally stop reading email already, everybody is already so over email.

=back


=head1 CREDITS

Sean Levy <snl@cluefactory.com> wrote this thing, sometime in or
around 2000 most likely, although he can't quite remember the exact
year.  It started out as a pile of hacks and has matured and blossomed
into a GREAT FREAKING HUGE PILE OF HACKS.

Sean is also known as attila <attila@stalphonsos.com>, for historical
reasons almost entirely under his control.  That's "Saint Alphonsos".

=head1 VERSION HISTORY

B<Alice>: Well I must say I've never heard it that way before...

B<Caterpillar>: I know, I have improved it. 

Z<>

  0.2.5    06 Sep 08     attila  found some lost hacks from a source
                                 tree recovered from a dead laptop:
                                 semi-colon-separated commands,
                                 send_via_program, a couple other things.
  0.2.4    05 Aug 08     attila  revived from the dead AGAIN after
                                 t-bird screwed me hard.
  0.2.3    30 Jun 06     attila  released on freshmeat
  0.2.2    26 Jun 06     attila  wrote pod, use strict, blah blah
                                 added local spools
  0.2.1    25 Jun 06     attila  fixed horrible bug in get_imap
  0.2.0    24 Jun 06     attila  resurrected after i got sick of VM
  0.1.28   26 Feb 03     attila  0.1.28 released
  0.1.?    ?? ??? 02     attila  Somewhere around 2002 I found myself
                                 using flail everyday and thought perhaps
                                 I should release it or something
  0.0.0    ?? ??? 00     attila  Sometime in y2k I had a brain schizm
                                 and decided to write an MUA in perl



=head1 COPYRIGHT AND LICENSE

  Copyright (C) 1999,2000 St. Alphonsos.
  Copyright (C) 2000-2008 by Sean Levy <snl@cluefactory.com>.
  All Rights Reserved.

  Redistribution and use in any form, with or without modification, are
  permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer. 

  2. The names "St. Alphonsos", "The Clue Factory", and "Sean Levy"
     must not be used to endorse or promote products derived from this
     software without prior written permission. To obtain permission,
     contact info@stalphonsos.com or snl@cluefactory.com

  3. Redistributions of any form whatsoever must retain the following
     acknowledgment:
     "This product includes software developed by St. Alphonsos
      http://www.stalphonsos.com/ and Sean Levy <snl@cluefactory.com>"

  THIS SOFTWARE IS PROVIDED BY ST. ALPHONSOS, THE CLUE FACTORY AND
  SEAN LEVY ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES,
  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL ST. ALPHONSOS NOR ITS EMPLOYEES, THE CLUE FACTORY
  NOR ITS EMPLOYEES, OR SEAN LEVY BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

=cut

# Local variables:
# tab-width: 2
# perl-indent-level: 2
# indent-tabs-mode: nil
# comment-column: 40
# End:
