#!/usr/bin/perl 

#my $RCSRevKey = '$Revision: 1.7 $'; $RCSRevKey =~ /Revision: (.*?) /;

$VERSION = "1.28";

use Fcntl;
use IO::Handle;
use Tk;
use Tk::widgets qw (TextUndo Listbox Frame CmdLine);
use Tk::SimpleFileSelect;
use Tk::ECWarning;
use EC::ECConfig;
use EC::Attachments;
use EC::Utilities;
use EC::ECIcon;

#
# Get user info
#
my $localuser = $^O =~ /Win/ ? $ENV{USERNAME} : (getpwuid ($<))[0] or 
    die "Could not determine your login name: $!\n";

#
#  Path names for library files.  Edit these for your configuration.
#
# Icon file name
$iconpath = inc_path ('EC/ec.xpm');
#  Configuration options file.
$cfgfilename = expand_path ('~/.ec/.ecconfig');
# Server authorization file.
$serverfilename = expand_path ('~/.ec/.servers');

$headerid = "X-Mailer: EC E-Mail Client Version $VERSION";

my $datesortorder;

# Default directory for user's file opens and saves.
my $defaultuserdir;

# User's system mailbox: Usually $config->{mailspooldir} + username.
my $systemmbox;

#
#  Get X resources from ~/.Xresources, ~/.Xdefaults, or ~/Ec
#
Tk::CmdLine::SetArguments(-class => Ec);
Tk::CmdLine::LoadResources(-file => "$ENV{HOME}/.Xdefaults");
Tk::CmdLine::LoadResources(-file => "$ENV{HOME}/.Xresources");
Tk::CmdLine::LoadResources ();

#
#  Check for configuration files.
#
if ((!-d $ENV{HOME}.'/.ec') || 
    (!-f $cfgfilename) || 
    (!-f $serverfilename)) {
    print "\nConfiguration Problem:\n";
    print "The program could not find the following configuration files:\n";
    print "1. $cfgfilename\n";
    print "2. $serverfilename\n";
    print "Refer to the file, \"README,\" and ".
	"the manual page (\"man ec\").\n";
    exit 255;
}

#
# Config hash reference.  Refer to EC::ECConfig.pm
#
my $config = EC::ECConfig::new ($cfgfilename); 

#
# Override X font resources if fonts are defined in $config
# $menufont provides the default font setting
#
Tk::CmdLine::SetResources ('*font: ' . $config -> {menufont}) 
    if defined $config -> {menufont};

Tk::CmdLine::SetResources ('*Listbox*font: ' . $config -> {listfont})
    if defined $config -> {listfont};

Tk::CmdLine::SetResources ('*Button*font: ' . $config -> {buttonfont})
			   if defined $config -> {buttonfont};

Tk::CmdLine::SetResources ('*TextUndo*font: ' . $config -> {textfont}) 
			   if defined $config -> {textfont};


# Global widget references.
#   Main Window widget.
my $mw = init_main_widgets();
#   Dialog Boxes
my $savefiledialog = undef;  # File save dialogs
my $insertfiledialog = undef;  
my $warndialog = undef;
my $attachfiledialog = undef;

##
##  The following code is for Socket stuff.
##
$AF_INET = 2;        # 2 = linux, Win95/NT, solaris, and sunos
$SOCK_STREAM = 1;    # 1 = linux, AIX, and Win95/NT
                     # 2 = solaris and sunos
# padding for message list fields.  This should be enough to space
# out a completely blank header field.
my $padding = ' ' x 30;

# Text for mailbox message counter.
my $countertext = '0 Messages';

# Message ID sequence counter.
my $msgsequence = 1;

my @sortedmessages;  # Pointer to sorted header array.

# Message header fields.
my $fromfield = "From:";
my $tofield = "To:";
my $ccfield = "Cc:";
my $subjfield = "Subject:";
my $bccfield = "Bcc:";
my $fccfield = "Fcc:";
my $replytofield = "Reply-To:";
my $msgidfield = "Message-Id:";
my $msgsep = "--- Enter the message text below this line\. ---";
my $sigsep = "-- ";

my @daynames = qw (Sun Mon Tue Wed Thu Fri Sat);
my @monthnames = qw (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

my @attachments = ();  # File attachments for outgoing messages.

sub sock_close_on_err {
    print "<<<RSET\n" if ($config->{verbose});
    print SOCK "RSET\r\n";
    print "<<<QUIT\n" if ($config->{verbose});
    print SOCK "QUIT\r\n";
    close SOCK;
}

sub close_server {
    local ($status, $smsg);
    if (defined SOCK) {
	print "<<<QUIT\n" if $config -> {verbose};
	print SOCK "QUIT\r\n";
	($status, $smsg) = pop_ack ();
	if ($status ne "OK") {
	    print "<<<$smsg" if ($config -> {verbose}) and defined $status;
	    sock_close_on_err ();
	}
	close SOCK;
    }
}

sub openserver {
    my ($w, $remote, $port, $user, $passwd) = @_;
    my ($iaddr, $paddr, $proto, $status, $smsg, $sockaddr);
    my ($err, $errcode, $forwardpath);
    my $md = $config->{'maildomain'};
    my $c = $w -> Subwidget ('button_bar');
    my $servermsg = $w -> Subwidget ('servermsg');
    $| = 1;
    $c -> dchars ($servermsg, '0', 'end');
    if ($^O =~ /Win/) { 
	$c -> insert ($servermsg, 'end',
		      "12. Connecting: $remote... ");
    } else {
	$c -> insert ($servermsg, 'end',
		      "Connecting: $remote... ");
    }
    if ((substr $passwd,0,1) eq '-') {
	$passwd = passwd_dialog ($mw,$user);
	return $passwd if $passwd =~ /Cancel|OK/;
    }
    $c -> update;
    if ($^O =~ /Win/) {
	eval {
	    print "gethostbyname..." if $config->{debug}; print "XXX\n"; $remote or die;
	    ($name, $aliases, $type, $len, $iaddr) = 
		gethostbyname ($remote);
	    print "156.done\n" if $config->{debug};
	};
    } else {
	$SIG{ALRM} = sub { alarm 0; die 'gethostbyname' };
	eval {
	    alarm ($config->{servertimeout});
	    print "gethostbyname..." if $config->{debug};
	    ($name, $aliases, $type, $len, $iaddr) = 
		gethostbyname ($remote);
	    print "done\n" if $config->{debug};
	    alarm( 0 );
	};
    }

    if ($@ =~ /gethostbyname/ or not $iaddr) {
	server_error_dialog ($w, $port,
		      "$remote:\nGethostbyname function timed out:\n$!");
	close_server ();
	$errcode = 'gethostbyname';
	$err = undef;
	return $err;
    }

    $sockaddr = 'S n a4 x8';
    $paddr = pack ($sockaddr, $AF_INET, $port, $iaddr);

    print "getprotobyname..." if $config->{debug};
    $proto = getprotobyname ('tcp');
    print "done\n" if $config->{debug};

    if ($^O =~ /Win/) {
	eval {
	    print "socket..." if $config->{debug};
	    socket (SOCK, $AF_INET, $SOCK_STREAM, $proto) ||
		server_error_dialog ($w, $port, "Can\'t open socket: $!\n");
	    print "190.done\n" if $config->{debug};
	};
	print "193.$@\n";
    } else {
	$SIG{ALRM} = sub {alarm 0; die 'socket'};
	eval {
	    alarm ($config->{servertimeout});
	    print "socket..." if $config->{debug};
	    socket (SOCK, $AF_INET, $SOCK_STREAM, $proto) ||
		server_error_dialog ($w, $port, "Can\'t open socket: $!\n");
	    print "done\n" if $config->{debug};
	    alarm (0);
	};
    }

    if ($@ =~ /socket/) {
	server_error_dialog ($w, $port, "Can't connect to $remote:\n$!");
	close_server ();
	$errcode = 'socket';
	$err =  undef;
	return undef;
    }

    if ($^O =~ /Win/) {
	$SIG{ALRM} = sub {die 'timeout'};
	eval {
	    print "connect..." if $config->{debug};
	    connect (SOCK, $paddr);
	    print "done\n" if $config->{debug};
	};
    } else {
	$SIG{ALRM} = sub {alarm 0; die 'timeout'};
	eval {
	    alarm ($config->{servertimeout});
	    print "connect..." if $config->{debug};
	    connect (SOCK, $paddr);
	    print "done\n" if $config->{debug};
	    alarm( 0 );
	};
    }

    if ($@ =~ /timeout/) {
	server_error_dialog ($w, $port, "Connect timeout: $!.");
	close_server ();
	$err = undef;
	$errcode = 'socket';
	return $err;
    }

    # Catch whatever signals we need to...
    $SIG{"INT"} = 'sock_close_on_err';
    $SIG{"TERM"} = 'sock_close_on_err';
    print "select..." if $config->{debug};
    select (SOCK); $| = 1; select (STDOUT); # always flush SOCK
    print "done\n" if $config->{debug};

    if( $port eq 25 ) {
	# if SMTP, wait for server initiation
	if (! defined ( $status = smtpack (0) )) {
	    server_error_dialog ($w, $port,
			  "Timed out while waiting for server greeting.");
	    $errcode = 'servergreeting';
	    $err = undef;
	    return $err;
	};

	print "$status\n" if ($config -> {verbose}) and defined $status;
	while ($status !~ /^220|^421/) {
	    if (! defined ($status = smtpack (1))) {
		&server_error_dialog ($w, $port,
			      "Timed out during server greeting.");
		$errcode = 'SMTP Timeout';
		$err = undef;
		return $err;
	    };
	    if ($status =~ /^421/ms) {
		&close_server;
		&server_error_dialog ($w, $port,
			      "421: Service not available: $!");
		$errcode = 'SMTP Service not available.';
		$err = undef;
		return $err;
	    }
	}
	print "<<<HELO $md\n" if ($config->{verbose});
	print SOCK "HELO $md\r\n";
	if (! defined ($status = smtpack (0))) {
	    close_server ();
	    server_error_dialog ($w, $port,
			    "\'HELO $md\' timed out... resetting.");
	    $errcode = 'SMTP Greeting timed out.';
	    $err = undef;
	    return undef;
	};

	# non-readable response.
	while ($status !~ /^250|^500|^501|^504|^421/) {
	    if(! defined ($status = smtpack (0))) {
		close_server ();
		server_error_dialog ($w, $port,
	      "\'HELO $md\' error. Server said: $status... resetting.");
		$errcode = 'HELO';
		$err = undef;
		return $err
		};

	    print "$status\n" if ($config->{verbose}) and defined $status;
	    # rfc821 specified error condition
	    if ($status =~ /^500|^501|^504|^421/ ) {
		close_server ();
		server_error_dialog ($w, $port,"$status: $!... Resetting");
		$errcode = "smtp $status";
		$err = undef;
		return $err;
	    }
	}
	print "<<<MAIL FROM:$user\@$md\n" if $config->{verbose};
	print SOCK "MAIL FROM:$user\@$md\r\n";
	if (! defined ($status = &smtpack)) {
	    close_server();
	    server_error_dialog ($mw, $port,
		  "\'MAIL FROM: $user\@$md\' not acknowledged... resetting.");
	    $errcode = 'SMTP Mail From';
	    $err = undef;
	    return $err;
	};
	print "$status\n" if ($config->{verbose}) and defined $status;
	while ($status !~ /^250|^552|^451|^452|^500|^501|^421/) {
	    if (! defined ($status = &smtpack)) {
		close_server();
		server_error_dialog ($w, $port,
	     "\'$user\@$md\' error. Server said: $status ... resetting.");
		$errcode = "$status";
		$err = undef;
		return $err;
	    };
	    print "$status\n" if ($config->{verbose}) and defined $status;
	    if ($status =~ /^552|^451|^452|^500|^501|^421/ ) {
		close_server ();
		server_error_dialog ($w, $port,
     "\'MAIL FROM: $user\@$md\' error. Server said: $status ... resetting.");
		$errcode = "SMTP MAIL FROM: $status";
		$err = undef;
		return $err;
	    }
	}
	my $msgtext = $w -> Subwidget ('text') -> get ( '1.0', 'end' );
	my @addressees = addressees($msgtext);
	foreach my $addressee (@addressees) {
	    $forwardpath = envelope_addr ($addressee);
	    print "$forwardpath\n" if ($config->{debug});
	    print "<<<RCPT TO:$forwardpath\n" if $config->{verbose};
	    print SOCK "RCPT TO:$forwardpath\r\n";
	    if (! defined ($status = smtpack (0) )) {
		close_server();
		server_error_dialog ($w, $port, "Server timeout");
		$errcode = "SMTP timeout";
		$err = undef;
		return $err;
	    }
	    print "$status\n" if ($config->{verbose}) and defined $status;
	    while ($status !~ /^25/) {
		close_server ();
		server_error_dialog ($w, $port,
  "SMTP: \'RCPT TO: <$forwardpath>' error. Server said: $status ... resetting.\n");
		if (! defined ($status = smtpack (0))) {
		    print 
		 "$status\n" if ($config->{verbose}) and defined $status;
		    $errcode = "SMTP error: RCPT TO:<$forwardpath>";;
		    $err = undef;
		    return $err;
		};
	    }
	}
    }

    if ($port ne 25) {
	($status, $smsg) = pop_ack ();
	if ($status ne "OK") {
	    if ($^O =~ /Win/) {
 	    server_error_dialog ($w, $port, 
		 "Authorization error: $remote. (status = $status, msg = $smsg) [ERR0372]");
	    } else {
		server_error_dialog 
		    ($w, $port, "Authorization error: $remote.");
	    }
	    $errcode = 'auth';
	    $err = undef;
	    return $err;
	}
	print "<<<USER $user\n" if ($config->{verbose});
	print SOCK "USER $user\r\n";
	($status, $smsg) = pop_ack ();
	if ($status ne "OK") {
	    server_error_dialog ($w, $port, "Authorization error: $remote.");
	    $errcode = 'auth';
	    goto CLOSE_SERVER;
	}
	print "<<<PASS ....\n" if ($config->{verbose});
	print SOCK "PASS $passwd\r\n";
	($status, $smsg) = pop_ack ();
	if ($status !~ /OK/) {
	    server_error_dialog ($w, $port, "Authorization error: $remote.");
	    $errcode = 'auth';
	    $err = undef;
	    return $err;
	}
    }
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end', "$remote: Connected.");
    $c -> update;
    $err = 1;
    return $err;
  CLOSE_SERVER:
    if ($errcode !~ /socket|gethostbyname|auth/) {
	close_server ();
    }
    return $errcode;
}

# This unfolds To: Cc: and Bcc:'s on one line only.
sub addressees {
    my ($msg) = @_;
    my (@addressees, @addressees2);
    $msg =~ /^To:\s+(.*?)$/smi;
    @addressees = split /, */, $1;
    if ($msg =~ /^Cc:\s+(.*?)$/smi) {
	local @ccaddresses = split /, */, $1;
	push @addressees, @ccaddresses;
    }
    if ($msg =~ /^Bcc:\s+(.*?)$/smi) {
	local @bccaddresses = split /, */, $1;
	push @addressees, @bccaddresses;
    }
    return @addressees;
}

sub passwd_dialog {
    my ($mw,$user) = @_;
    require EC::PasswordDialog;
    my $passworddialog = $mw -> PasswordDialog(-username => $user);
    return $passworddialog -> WaitForInput;
}

sub server_error_dialog {
    my ($mw, $port, $msg) = @_;
    require Tk::Dialog;
    $mw -> Subwidget ('button_bar') ->
	dchars ($mw -> Subwidget('servermsg'), '0', 'end');
    my $title = ($port =~ /25/)?"SMTP Server Error":"POP3 Server Error";
    my $dialog = $mw -> Dialog (-title => $title,
	-text => $msg, -default_button => 'OK',
	-bitmap => 'error', -buttons => ['OK']) -> Show;
}

sub next_message {
    my ($mw) = @_;
    my $l = $mw -> Subwidget ('messagelist');
    my ($selection) = ($l->curselection)[0];
    return if $selection eq '';
    return if ($selection + 1) eq $l -> size;
    $l -> selectionClear ($selection);
    $selection += 1;
    $l -> selectionSet ($selection);
    $l -> see ($selection);
    displaymessage ($mw, $currentfolder);
}

sub previous_message {
    my ($mw) = @_;
    my $l = $mw -> Subwidget('messagelist');
    my ($selection) = ($l->curselection)[0];
    return if $selection eq '';
    return if $selection eq 0;
    $l -> selectionClear ($selection);
    $selection -= 1;
    $l -> selectionSet ($selection);
    $l -> see ($selection);
    displaymessage ($mw, $currentfolder);
}

sub displayserverror {
    my ($mw, $op, $msg) = @_;
    my $c = $mw -> Subwidget ('servermsg');
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end', "Can't connect to socket: $!");
}

sub nummsgs {
    print "nummsgs()..." if $config->{debug};
    print "<<<STAT\n" if $config->{verbose};
    print SOCK "STAT\r\n";
    local ($status, $messages) = pop_ack ();
    ($msgs,$octets) = split (' ', $messages);
    print "done\n" if $config->{debug};
    return ($msgs, $octets);
}

# the delay parameter is necessary to lengthen the timeout
# while server is relaying message.
sub smtpack {
    my ($delay) = @_;
    local $ack;
    $SIG{ALRM} = sub{alarm 0; die 'Time out: smtp acknowledgement\n'};
    $delay = 1 if (not $delay);
    alarm (($config->{servertimeout}) * $delay);

    eval {
	while (defined ($ack = <SOCK>)) {
	  Tk::Event::DoOneEvent (255);
	    goto RET_ACK if $ack =~ /^\d\d\d/;
	}
    };

    return undef;
  RET_ACK:
    alarm (0);
    return $ack;
}

sub pop_ack {
    # Search for common POP acknowledgments
    $search_pattern="^.\(OK|ERR|\)\(.*\)";
    my ($stat, $msg);
    $SIG{ALRM} =
	sub{alarm 0; $stat='ERR'; $msg = 'server timeout'; die};

    eval {
	alarm ($config->{servertimeout}) if $^O !~ /Win/; 
	$_ = <SOCK>;
	print $_ if $config->{verbose};
	print "" if $config->{verbose};
	# Have to do regex match outside of while loop to keep
	# the resulting $1 and $2 in proper scope
	/$search_pattern/;
	$stat = $1;
	while (! $stat) {
	    $_ = <SOCK>;
	    /$search_pattern/;
	  Tk::Event::DoOneEvent (255);
	}
	$stat = $1;
	$msg = $2;
	alarm (0) if $^O !~ /Win/; 
    };

    if ($@) {
	print "pop_ack(): server timeout\n" if $config->{debug};
	$stat = 'ERR';
	$msg = 'Timeout';
    }
    return ($stat, $msg);
}

sub retrieve {
    local($msgnum) = @_;
    my $themsg = '';
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) 
	= gmtime (time);
    my $tempfile = "/tmp/poptmp.$$";

    open (SPOOLOUT,"+>$tempfile");

    print "<<<RETR $msgnum\n" if ($config->{verbose});
    print SOCK "RETR $msgnum\r\n";
    local ($status,$smsg) = pop_ack ();
    if ($status =~ /OK/) {
	printf SPOOLOUT
	       "From popserver %s %s %2d %02d:%02d:%02d GMT %04d\n",
	       $daynames[$wday],
	       $monthnames[$mon],
	       $mday,$hour,$min,$sec,$year+1900;
	$_ = <SOCK>;
	while (!/^\.\r*$/) {
	    s/\r//g;
	    print SPOOLOUT $_ ;
	    $_ = <SOCK>;
	}
	if (! $keepmails) {
	    print "<<<DELE $msgnum\n" if ($config->{verbose});
	    print SOCK "DELE $msgnum\r\n";
	    ($status, $smsg) = pop_ack ();
	}
    }

    $mailfile = ((defined $ENV{'MAIL'}) ? $ENV{'MAIL'} :
		 ($config->{mailspooldir}."/" . $localuser));
    open (MBOX, ">>$mailfile") or eval { sock_close_on_err ();
				    show_warn_dialog ($mw, $warndialog,
       -message => "Can\'t open mailbox $mailfile - some mail is in $tempfile") };
    flock (MBOX,LOCK_EX);
   # and, in case someone appended
    # while we were waiting...
    seek (MBOX, 0, 2);
    seek (SPOOLOUT,0,0);
    while (<SPOOLOUT>){
	print MBOX $_ or eval {
	    sock_close_on_err ();
	    local $wmsg = (((defined $local_mailer)
			? "Can't pipe to local mailer"
			: "Can't write to mailbox $mailfile")
		       . "- some mail is in $tempfile");
	    show_warn_dialog ($mw, $warndialog, -message => $wmsg);
	};
    }
    close SPOOLOUT;
    unlink "$tempfile";
    flock (MBOX,LOCK_UN) unless defined $local_mailer;
    close MBOX;
}

sub get_user_info {
    my (%sites);

    if (-f $serverfilename) {
	open (POPFILE, $serverfilename) or eval {
	    sock_close_on_err ();
	    show_warn_dialog ($mw, $warndialog,
		       -message => "Can't open $serverfilename file! $!");
	};
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
	  $atime, $mtime, $ctime, $blksize, $blocks) = stat POPFILE;
	if ($mode != 0100600 and $^O !~ /Win/) {
	    sock_close_on_err ();
	    show_warn_dialog ($mw, $warndialog, 
		-message => "$serverfilename needs permissions rw-------");
	}
	my $lineno = 1;
	while (<POPFILE>) {
	    next if /^$/;
	    ($host, $port, $user, $passwd) = split (/\s+/, $_);
	    show_warn_dialog ($mw, $warndialog,
		       -message => "No password for host $host - skipping.")
		if ($passwd eq '');

	    show_warn_dialog ($mw, $warndialog,
	       -message => "No hostname in line $lineno of server file - skipping.")
		if ($host eq '');

	    show_warn_dialog ($mw, $warndialog,
	       -message => "No username in line $lineno of server file - skipping.")
		if ($user eq '');

	    show_warn_dialog ($mw, $warndialog,
	       -message => "No port no. in line $lineno of server file - skipping.")
		if ($port eq '');

	    push @{$sites{"sitelist"}},
	    { 'host' => $host,
	      'port' => $port,
	      'user' => $user,
	      'pass' => $passwd };
	}
	close POPFILE;
    } else {
	show_warn_dialog ($mw, $warndialog,
		   -message => "Server file ".$serverfilename ." not found.\n" .
			   "Please read the file README.\n");
	exit (255);
    }
    if ($config->{debug}) {
	foreach (@{$sites{'sitelist'}}) {
	    print "\'host\' = ".$_ -> {'host'}."\n";
	    print "\'port\' = ".$_ -> {'port'}."\n";
	    print "\'user\' = ".$_ -> {'user'}."\n";
	    print "\'pass\' = ......\n\n";
	}
    }
    return \%sites;
}

sub visit_sites {
    my ($mw, $sites) = @_;
    my ($openstatus, $i, $msgnum);
    my $servermsg = $mw -> Subwidget ('servermsg');
    my $c = $mw -> Subwidget ('button_bar');
    foreach $i (@{$sites->{"sitelist"}}) {
	next if ( $i->{'port'} == ($config->{smtpport}) );
	$pass = $i->{"pass"};
	$host = $i->{"host"};
	$openstatus = openserver ($mw,$host,$i->{"port"},$i->{"user"},$pass);
	# from password entry
	next if $openstatus =~ /Cancel|OK/;
	goto SERV_ERROR if $openstatus =~ /socket|gethostbyname|auth/;
	my ($msgs,$octets) = nummsgs ();
	$c -> dchars ($servermsg, '0', 'end');
	$c -> insert ($servermsg, 'end', 
		      "Number of messages on host: $msgs.");
	$c -> update;
	for ($msgnum = 1; $msgnum <= $msgs; $msgnum++) {
	    $c -> dchars ($servermsg, '0', 'end');
	    $c -> insert ($servermsg, 'end', 
			  "Retrieving message $msgnum/$msgs.");
	    $c -> update;
	    retrieve ($msgnum);
	}
	close_server();
      SERV_ERROR:
    }
    $c -> dchars ($servermsg, '0', 'end');
}
	
sub format_possible_rfcdate {
    my ($s) = @_;
    my ($wday, $day, $mon, $year, $hour, $min, $sec, $tz, $r);
    return '' if (not strexist ($s));
    # RFC 822-standard date with weekday
    ($wday, $day, $mon, $year, $hour, $min, $sec, $tz) =
	($s =~ m/(\w\w\w,)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\d*):(\d*):(\d*)\s*(\S*).*/);
    if ((defined $sec) and (length $sec)) {
	$r = sprintf ("%4s %02d %s %4d %02d:%02d:%02d %s",
		      $wday,$day,$mon,
		      ((length($year)==2)?"20{$year}":$year),
		      $hour,$min,$sec,$tz) if ($sec ne '') and $sec;
	return $r if ((defined $sec) and (length $sec));
    }
    # Date with no weekday
    ($day, $mon, $year, $hour, $min, $sec, $tz) =
	($s =~ m/(\S*)\s*(\S*)\s*(\S*)\s*(\d*):(\d*):(\d*)\s*(\S*).*/);
    $r = sprintf ("%02d %s %4d %02d:%02d:%02d %s",
		  $day,$mon,
		  ((length($year)==2)?"20{$year}":$year),
		  $hour,$min,$sec,$tz);
    return $r;
}

sub timezone {
    my ($day, $mon, $year, $hour, $min, $sec, $tz) = @_;
    my ($chour, $cmin, $ztime, $ntz);
    return ($day, $mon, $year, $hour, $min, $sec)
	if (($tz =~ /^\w*$/) || ($tz =~ /UT|GMT|Z|\-0000|\+0000/));

    # also account for AM and PM in the timezone slot.
    if ($tz =~ /PM/) {
	$hour = sprintf "%02d", $hour += 12;
	if ($hour eq '24') {
	    $hour = '00';
	    $day = sprintf "%02d", $day += 1;
	}
	return ($day, $mon, $year, $hour, $min, $sec);
    }
    return ($day, $mon, $year, $hour, $min, $sec) if $tz =~ /AM/;

    $ntz = $tz;
    $ntz = '-0100' if $tz eq 'A';
    $ntz = '-0200' if $tz eq 'B';
    $ntz = '-0300' if $tz eq 'C';
    $ntz = '-0400' if $tz eq 'D';
    $ntz = '-0500' if $tz eq 'E';
    $ntz = '-0600' if $tz eq 'F';
    $ntz = '-0700' if $tz eq 'G';
    $ntz = '-0800' if $tz eq 'H';
    $ntz = '-0900' if $tz eq 'I';
    # 'J' not used
    $ntz = '-1000' if $tz eq 'K';
    $ntz = '-1100' if $tz eq 'L';
    $ntz = '-1200' if $tz eq 'M';
    $ntz = '+0100' if $tz eq 'N';
    $ntz = '+0200' if $tz eq 'O';
    $ntz = '+0300' if $tz eq 'P';
    $ntz = '+0400' if $tz eq 'Q';
    $ntz = '+0500' if $tz eq 'R';
    $ntz = '+0600' if $tz eq 'S';
    $ntz = '+0700' if $tz eq 'T';
    $ntz = '+0800' if $tz eq 'U';
    $ntz = '+0900' if $tz eq 'V';
    $ntz = '+1000' if $tz eq 'W';
    $ntz = '+1100' if $tz eq 'X';
    $ntz = '+1200' if $tz eq 'Y';
    $ntz = '-0500' if $tz =~ /EST/;
    $ntz = '-0400' if $tz =~ /EDT/;
    $ntz = '-0600' if $tz =~ /CST/;
    $ntz = '-0500' if $tz =~ /CDT/;
    $ntz = '-0700' if $tz =~ /MST/;
    $ntz = '-0600' if $tz =~ /MDT/;
    $ntz = '-0800' if $tz =~ /PST/;
    $ntz = '-0700' if $tz =~ /PDT/;

    # just return the time if there's no recognizable timezone.
    return ($day, $mon, $year, $hour, $min, $sec) if ($ntz !~ /^\+|\-\d\d\d\d/);

    ($chour,$cmin) = ($ntz =~ /(\d\d)(\d\d)/);
    if ($cmin ne '00') {
	$min = sprintf "%02d", ($ntz =~ /\+/)?$hour + $cmin:$hour - $cmin;
	if ($min gt '59') {
	    $hour = sprintf "%02d", $hour += 1;
	    $min = sprintf "%02d", $min -= 60;
	} elsif ($min lt '00') {
	    $hour = sprintf "%02d", $hour -= 1;
	    $min = sprintf "%02d", $min += 60
        }
    }
    $hour = sprintf "%02d", ($ntz =~ /\+/)?$hour + $chour:$hour - $chour;
    if ($hour gt '23') {
	$day = sprintf "%02d", $day += 1;
	$hour = sprintf "%02d", $hour -= 24;
    } elsif ($hour lt '00') {
	$day = sprintf "%02d", $day -= 1;
	$hour = sprintf "%02d", $hour += 24;
    }
    return ($day, $mon, $year, $hour, $min, $sec);
}

# sort part of the rfc 822 date fields.
sub rfcdate_compare {
    my ($ap, $bp) = @_;
    my ($a_day, $a_mon, $a_year, $a_hour, $a_min, $a_sec, $a_tz) =
	($ap =~
	 m/.*?(\d+)\s*(\S*)\s*(\S*)\s*(\d*)\:(\d*)\:(\d*)\s*(\S*)/);
    my ($b_day, $b_mon, $b_year, $b_hour, $b_min, $b_sec, $b_tz) =
	($bp =~
	 m/.*?(\d+)\s*(\S*)\s*(\S*)\s*(\d*)\:(\d*)\:(\d*)\s*(\S*)/);
    my ($a_dayz, $a_monz, $a_yearz, $a_hourz, $a_minz, $a_secz) =
	timezone ($a_day, $a_mon, $a_year, $a_hour, $a_min, $a_sec, $a_tz);
    my ($b_dayz, $b_monz, $b_yearz, $b_hourz, $b_minz, $b_secz) =
	timezone ($b_day, $b_mon, $b_year, $b_hour, $b_min, $b_sec, $b_tz);
    if (! $datesortorder) {
	return ($b_yearz cmp $a_yearz) if $a_yearz ne $b_yearz;
	if ($a_monz ne $b_monz) {
	    my ($i, $a_mno, $b_mno);
	    for ($i = 0; $i < 12; $i++) {
		$a_mno = $i if $monthnames[$i] eq $a_monz;
		$b_mno = $i if $monthnames[$i] eq $b_monz;
	    }
	    return ($b_mno <=> $a_mno);
	}
	return ($b_dayz cmp $a_dayz ) if $a_dayz ne $b_dayz;
	return ($b_hourz cmp $a_hourz) if $a_hourz ne $b_hourz;
	return ($b_minz cmp $a_minz) if $a_minz ne $b_minz;
	return ($b_secz cmp $a_secz) if $a_secz ne $b_secz;
    } else {
	return ($a_yearz cmp $b_yearz) if $a_yearz ne $b_yearz;
	if ($a_monz ne $b_monz) {
	    my ($i, $a_mno, $b_mno);
	    for ($i = 0; $i < 12; $i++) {
		$a_mno = $i if $monthnames[$i] eq $a_monz;
		$b_mno = $i if $monthnames[$i] eq $b_monz;
	    }
	    return ($a_mno <=> $b_mno);
	}
	return ($a_dayz cmp $b_dayz) if $a_dayz ne $b_dayz;
	return ($a_hourz cmp $b_hourz) if $a_hourz ne $b_hourz;
	return ($a_minz cmp $b_minz) if $a_minz ne $b_minz;
	return ($a_secz cmp $b_secz) if $a_secz ne $b_secz;
    }
    return 0;
}

sub sort_column {
    my ($l, $selectedcolumn) = @_;
    if( $config->{sortfield} eq $selectedcolumn ) {
	$l -> {'ml_sort_descending'} =
	    (($l -> {'ml_sort_descending'} =~ /0/ ) ? 1 : 0 );
	$datesortorder = $l -> {'ml_sort_descending'};
    } else {
	$config->{sortfield} = $selectedcolumn;
	$l -> {'ml_sort_descending'} =
	    (($l -> {'ml_sort_descending'} =~ /0/ ) ? 1 : 0 );
	$datesortorder = $l -> {'ml_sort_descending'};
    }
    eval {listmailfolder ($l, $currentfolder)};
    $l -> update;
}

# like the above, but for the menu options, not the list columns.
sub sort_option {
    my ($mw, $selectedcolumn) = @_;
    my $l = $mw -> Subwidget ('messagelist');
    if ($config->{sortfield} eq $selectedcolumn) {
	$l -> {'ml_sort_descending'} =
	    (($l -> {'ml_sort_descending'} =~ /0/ ) ? 1 : 0 );
	$datesortorder = $l -> {'ml_sort_descending'};
    } else {
	$config->{sortfield} = $selectedcolumn;
	$l->{'ml_sort_descending'} =
	    (($l -> {'ml_sort_descending'} =~ /0/ ) ? 1 : 0 );
	$datesortorder = $l->{'ml_sort_descending'};
    }
    eval {listmailfolder( $l, $currentfolder )};
    $l -> update;
}

sub changefolder {
    my ($mw, $f) = @_;
    eval {
	my $l = $mw -> Subwidget ('messagelist');
	my $t = $mw -> Subwidget ('text');
	my $msgcounter = $mw -> Subwidget ('msgcounter');
	$currentfolder = $f;
	$l -> delete (0, $l -> size);
	$t -> delete ('1.0', 'end');
	listmailfolder ($l, $currentfolder);
	updatemsgcount ($mw, $currentfolder);
	$mw -> configure (-title => "$currentfolder");
    };
}

sub listmailfolder {
    my ($l, $folder) = @_;
    my (@msgfiles, @msgfilelist, @subjline, @fromline, @dateline);
    my (@msgtext, $msgid, $listingstatus, @findex, @sresult);
    my ($listingdate, $listingfrom, $listingsubject, $listingid);
    watchcursor ($mw);
    eval {
	$l -> delete (0, 'end');
	$sortedmessages = undef;
	opendir MDIR, $folder or 
         show_warn_dialog ($mw, $warndialog,
	   -message => "Could not open folder $folder: $!\n");
	@msgfiles = grep /[^\.]|[^\.][^\.]/, readdir MDIR;
	closedir MDIR;
	foreach $msgid (@msgfiles) {
	    next if ($msgid =~ /\.index/) or ($msgid eq '');
	    @msgtext = content ("$folder/$msgid");
	    @subjline = grep /^Subject: /i, @msgtext;
	    @fromline = grep /^From: /i, @msgtext;
	    @dateline = grep /^Date: /i, @msgtext;
	    if (strexist ($fromline[0])) {
		chomp $fromline[0];
		$fromline[0] =~ s/From:\s*//;
	    } else {
		$fromline[0] = '';
	    }
	    if (strexist ($subjline[0])) {
		chomp $subjline[0];
		$subjline[0] =~ s/Subject:\s*//i;
	    } else {
		$subjline[0] = '';
	    }
	    if (strexist ($dateline[0])) {
		$dateline[0] =~ s/Date:\s*//i;
		chomp $dateline[0];
	    } else {
		$dateline[0] = '';
	    }
	    my $rfcdate = format_possible_rfcdate ($dateline[0]);
	    # Push array reference.
	    push @msgfilelist, [$rfcdate,$fromline[0],$subjline[0], $msgid];
	}
	if ($config->{sortfield} =~ /1/) { # sort by date
	    @sortedmessages = sort {
		rfcdate_compare (${$a}[0], ${$b}[0])
	           if ( length ${$a}[0] and  length ${$b}[0] );
	    } @msgfilelist;
	} elsif ($config->{sortfield} =~ /2/) { # sort by sender
	    @sortedmessages = sort {
		($l -> {ml_sort_descending}) ? ${$b}[1] cmp ${$a}[1] : ${$a}[1] cmp ${$b}[1];
	    } @msgfilelist;
	} elsif ($config->{sortfield} =~ /3/) { # sort by subject
	    @sortedmessages = sort {
		($l -> {ml_sort_descending}) ? 
		    ${$b}[1] cmp ${$a}[1] : ${$a}[1] cmp ${$b}[1] ;
	    } @msgfilelist;
	} else { # don't sort
	    push @sortedmessages, @msgfilelist;
	}

        # If there's no $folder/.index, create an empty index.
        # This is less annoying than showing warning dialog
        # every time messageread () tries to open a non-existent
        # .index.
        if (not -f "$folder/.index") {
            show_warn_dialog ($mw, $warndialog, 
                               -message => "Couldn't open $folder/.index - creating."); 
	    sysopen (INDEX, "$folder/.index", O_CREAT);
	    close INDEX;
        }

        foreach $hdr (@sortedmessages) {
            if (not messageread ($folder, ${$hdr}[3])) {
               $listingstatus = 'u';
            } else {
		$listingstatus = '';
            }
	    ${$hdr}[0] =~ s/^\w\w\w\, // if ($config->{weekdayindate} =~ /0/);
	    my $lline = strfill ($listingstatus, 2);
	    $lline .= ' ' . strfill (${$hdr}[0], $config -> {datewidth});
	    $lline .= '  ' . strfill (${$hdr}[1], $config -> {senderwidth});
	    $lline .= '  ' . strfill (${$hdr}[2], 45);
	    $l -> insert ('end', $lline);
        }
    }; # eval
    defaultcursor ($mw);
}

sub movemail {
    my (@msgs, $mbox, $idcnt, $msgcount, $filterfolder);
    $mbox = content_as_str ($systemmbox);
    #
    # the split gives us a 0th empty element whether or not
    # there's a match - the first message if it exists is
    # always $msgs[1], because a match of the mailbox record
    # occurs on the first line.
    #
    # The regexp has to take into account the source of the message:
    # e.g., "From root", "From popserver", etc. which means that 
    # the string containing the mail source (matched by \S+),
    # cannot contain whitespace.  Only tested on Linux and Solaris 
    # systems.
    #
    @msgs = split
	/^From \S+.*?$/ms, $mbox;
    return if ! defined shift @msgs;
    # if there is actually a message
    $msgsequence = 1;
    foreach my $message (@msgs) {
	foreach my $filter (@{$config->{filter}}) {
	    my ($pattern,$folder) = split /==/, $filter;
	    if ($message =~ /$pattern/msi) {
		$filterfolder = $config->{maildir}.'/'.$folder;
		last;
	    }
	    # fall through if no match.
	    $filterfolder = $config->{incomingdir};
	}
	# Avoid existing filenames
	while (-e "$filterfolder/$$-$msgsequence") {
	    $msgsequence++;
	}

	open MSG, ">$filterfolder/$$-$msgsequence" or eval {
	    show_warn_dialog ($mw, $warndialog,
		       -message => "Couldn't save message in $filterfolder: $!." .
		       "Saving message in " . $config->{incomingdir} . "\n");
	    close MSG;
	    $filterfolder = $config -> {incomingdir};
	    # Again, avoid existing filenames
	    while (-e "$filterfolder/$$-$msgsequence") {
		$msgsequence++;
	    }
	    open MSG, ">$filterfolder/$$-$msgsequence";
	};
	print MSG $message;
	close MSG;
	print STDERR "Saved message $$-$msgsequence\n" if $config->{debug};
	$msgsequence++;
    }
    if (! ($config->{debug})  and ! $keepmails) {
	open MBOX, ">$systemmbox" or
	    show_warn_dialog ($mw, $warndialog,
			-message => "Couldn't empty $systemmbox: $!\n");
	close MBOX;
    }
}

sub redisplaymessage {
    my ($mw) = @_;
    watchcursor ($mw);
    eval {
	my $t = $mw -> Subwidget ('text');
	$t -> delete ('1.0', 'end');
	displaymessage ($mw, $currentfolder);
    };
    defaultcursor ($mw);
}

sub displaymessage {
    my ($mw, $msgdir) = @_;
    my $l = $mw -> Subwidget ('messagelist');
    my $t = $mw -> Subwidget ('text');
    my $attachmentmenu = $mw -> Subwidget ('attachmentmenu');
    my ($ml, $line, $ofrom, $hdr, @hdrlines, $body, $msg, $msgfile, $listrow);
    $mw -> update;
    # this prevents the program from carping if there's no selection.
    my $nrow = ($l->curselection)[0];
    return if $nrow eq '';
    watchcursor ($mw);
    eval {
	$t -> delete ('1.0', 'end');
	$msgfile = ${$sortedmessages[$nrow]}[3];
	$msg = content_as_str ("$msgdir/$msgfile");
        menu_list_attachments ($msg);
	addmsgtoindex ($msgfile,$msgdir);
	updatemsgcount ($mw, $msgdir);

	# Remove the unread status entry from the list entry.
	$listrow = $l -> get ($nrow);
	$l -> delete ($nrow);
	$listrow =~ s/^u /  /;
	$l -> insert ($nrow, $listrow);
	$l -> selectionSet ($nrow);
	$l -> see ($nrow);

	($hdr, $body) = split /\n\n/, $msg, 2;
	if( $config->{headerview} eq 'full' ) {
	    @hdrlines = split /\n/, $hdr;
	    foreach (@hdrlines) {
		next if /^$/smi;
		$t -> insert ('end', "$_\n", 'header');
	    }
	    $t -> insert ('end', "\n", 'header');
	}
	if ($config->{headerview} eq 'brief') {
	    @hdrlines = split /\n/, $hdr;
	    foreach (@hdrlines) {
		next unless /^To\: |^From\: |^Date\: |^Subject\: /smi;
		$t -> insert ('end', "$_\n", 'header');
	    }
	    $t -> insert ('end', "\n", 'header');
	}
	$t -> insert ('end', "$body");
	$t -> markSet ('insert', '1.0');
	$t -> see ('insert');
	$t -> focus;
    }; # eval
    defaultcursor ($mw);
}

sub addmsgtoindex {
    my ($file, $folder) = @_;
    my $l;
    if (-f "$folder/.index") {
	open INDEX, "<$folder/.index" or
	    show_warn_dialog ($mw, $warndialog,
		       -message => "Could not open index in $folder: $!\n");
	while (defined ($l = <INDEX>)) {
	    chomp $l;
	    if ($l eq $file) {
		close INDEX;
		return;
	    }
	}
	close INDEX;
    }
    #re-open for append
    open INDEX, ">>$folder/.index" or
	show_warn_dialog ($mw, $warndialog,
			   -message => "Could not open index in $folder: $!\n");
    chomp $file;
    print INDEX "$file\n";
    close INDEX;
}

sub deletemsgfromindex {
    my ($file, $folder) = @_;
    my @msgs;
    my ($l, $newindex, $deleted);
    if (-f "$folder/.index") {
	open INDEX, "<$folder/.index" or
	    show_warn_dialog ($mw, $warndialog,
		       -message => "Could not open index in $folder: $!\n");
	while (defined ($l = <INDEX>)) {
	    chomp $l;
	    next if (! -f "$folder/$l");
	    if ($l =~ /$file/) {
		$deleted = $l;
		next;
	    }
	    chomp $l;
	    $newindex .= "$l\n";
	}
	close INDEX;
    }
    # open and clobber
    open INDEX, ">$folder/.index" or
	show_warn_dialog ($mw, $warndialog,
		   -message => "Could not open new index in $folder: $!\n");
    print INDEX $newindex if ((defined $newindex) and (length $newindex));
    close INDEX;
    return $deleted;
}

sub updatemsgcount {
    my ($mw, $folder) = @_;
    my ($f, $findex, $bname, @ffiles, $unread, $nmsg );
    my $l = $mw -> Subwidget ('messagelist');
    my $c = $mw -> Subwidget ('button_bar');
    my $m = $mw -> Subwidget ('foldermenu');
    my $msgcounter = $mw -> Subwidget ('msgcounter');
    $f = $folder;
    $f =~ /.*?([^\/]*)$/;
    $bname = ucfirst $1;
    $findex = $m -> index( $bname );
    if ($^O =~ /Win/) {
	opendir DIR, "$f" or 
	    show_warn_dialog ($mw, $warndialog,
		      -message => "Couldn't open $f: $! [ERR1168]\n");
    } else {
	opendir DIR, "$f" or 
	    show_warn_dialog ($mw, $warndialog,
			      -message => "Couldn't open $f: $!\n");
    }
    @ffiles = grep /^[^\.].*/, readdir DIR;
    $nmsgs = $#ffiles + 1;
    closedir DIR;
    $unread = 0;
    my $readed = 0;
    if (-f "$f/.index") {
	open INDEX, "<$f/.index" or
	    show_warn_dialog ($mw, $warndialog,
	       -message => "Could not open $f/.index in updatemsgcount(): $!\n");
	while (defined ($ff = <INDEX>)) {
	    chomp $ff;
	    if (-f "$f/$ff") {$readed++};
	}
	close INDEX;
    }
    $m -> entryconfigure ($findex,
		-accelerator => " ".($nmsgs-$readed)."/".$nmsgs." ");
    $c -> dchars ($msgcounter, 0, length ($countertext));
    $countertext = $l -> index ('end')." Message";
    if ($l -> index ('end') != 1) {$countertext .= 's'}
    $c -> insert ($msgcounter, 1, $countertext);
}

sub selectallmessages {
    my ($mw) = @_;
    my $l = $mw -> Subwidget ('messagelist');
    $l -> selectionSet(0, $l -> index('end') - 1);
    displaymessage ($mw, $currentfolder);
}

sub deletemsgfromindex {
    my ($file, $folder) = @_;
    my @msgs;
    my ($l, $newindex, $deleted);
    if (-f "$folder/.index") {
	open INDEX, "<$folder/.index" or
	    show_warn_dialog ($mw, $warndialog,
		       -message => "Could not open index in $folder: $!\n");
	while (defined ($l = <INDEX>)) {
	    chomp $l;
	    next if (! -f "$folder/$l");
	    if ($l =~ /$file/) {
		$deleted = $l;
		next;
	    }
	    chomp $l;
	    $newindex .= "$l\n";
	}
	close INDEX;
    }
    # open and clobber
    open INDEX, ">$folder/.index" or
	show_warn_dialog ($mw, $warndialog,
		   -message => "Could not open new index in $folder: $!\n");
    print INDEX $newindex if ((defined $newindex) and (length $newindex));
    close INDEX;
    return $deleted;
}

sub updatemsgcount {
    my ($mw, $folder) = @_;
    my ($f, $findex, $bname, @ffiles, $unread, $nmsgs );
    my $l = $mw -> Subwidget ('messagelist');
    my $c = $mw -> Subwidget ('button_bar');
    my $m = $mw -> Subwidget ('foldermenu');
    my $msgcounter = $mw -> Subwidget ('msgcounter');
    $f = $folder;
    $f =~ /.*?([^\/]*)$/;
    $bname = ucfirst $1;
    $findex = $m -> index( $bname );
    if ($^O =~ /Win/) { 
	show_warn_dialog ($mw, $warndialog,
			  -message => "Couldn't open $f: $! [ERR1246]\n");
    } else {
	opendir DIR, "$f" or 
	    show_warn_dialog ($mw, $warndialog,
		   -message => "Couldn't open $f: $!\n");
    }
    @ffiles = grep /^[^\.].*/, readdir DIR;
    $nmsgs = $#ffiles + 1;
    closedir DIR;
    $unread = 0;
    my $readed = 0;
    if (-f "$f/.index") {
	open INDEX, "<$f/.index" or
	    show_warn_dialog ($mw, $warndialog,
	       -message => "Could not open $f/.index in updatemsgcount(): $!\n");
	while (defined ($ff = <INDEX>)) {
	    chomp $ff;
	    if (-f "$f/$ff") {$readed++};
	}
	close INDEX;
    }
    $m -> entryconfigure ($findex,
		-accelerator => " ".($nmsgs-$readed)."/".$nmsgs." ");
    $c -> dchars ($msgcounter, 0, length ($countertext));
    $countertext = $l -> index ('end')." Message";
    if ($l -> index ('end') != 1) {$countertext .= 's'}
    $c -> insert ($msgcounter, 1, $countertext);
}

sub selectallmessages {
    my ($mw) = @_;
    my $l = $mw -> Subwidget ('messagelist');
    $l -> selectionSet(0, $l -> index('end') - 1);
    displaymessage ($mw, $currentfolder);
}

sub messageread {
    my ($folder, $id) = @_;
    my $ff;
    my $match = 0;
    open INDEX, "<$folder/.index" or
	    show_warn_dialog ($mw, $warndialog,
	       -message => "Could not open $f/.index in messageread(): $!\n");
    while (defined ($ff = <INDEX>)) {
	chomp $ff;
	if ($ff =~ m"$id") {
	    $match = 1;
	    last;
	}
    }
    close INDEX;
    return $match;
}

sub movemesg {
    my ($mw, $dir) = @_;
    my ($il, $sel, @selections, $omsgfile,$nmsgfile);
    my $l = $mw -> Subwidget ('messagelist');
    my $t = $mw -> Subwidget ('text');
    my $c = $mw -> Subwidget ('button_bar');
    my $msgcounter = $mw -> Subwidget ('msgcounter');
    eval {
	@selections = $l->curselection;
	if ($config->{debug}) { foreach (@selections) { print "$_\n" }}
	return if $selections[0] eq '';
	foreach $sel (@selections) {
	    $nmsgfile = $omsgfile = ${$sortedmessages[$sel]}[3];
            chomp $nmsgfile; chomp $omsgfile;
	    open INMSG, "<$currentfolder/$omsgfile"
		or show_warn_dialog ($mw, $warndialog, 
				      -message => "Couldn\'t open message file: $!\n");

            #    This is a bit ugly - better renaming for duplicate filenames?
	    $nmsgfile .= '1' while (-e "$dir/$nmsgfile");

            open OUTMSG, "+>>".$dir."/$nmsgfile"
		or show_warn_dialog ($mw, $warndialog,
				      -message => "Couldn\'nt open message file: $!\n");

            print OUTMSG $il while (defined ($il = <INMSG>));

            close INMSG;
	    close OUTMSG;

	    deletemsgfromindex ($omsgfile, $currentfolder);
	    addmsgtoindex ($nmsgfile, $dir);

	    unlink ("$currentfolder/$omsgfile");

	    $l -> delete ($sel);
	} #foreach

	$t -> delete ('1.0', 'end');
	listmailfolder ($l, $currentfolder);
	if (($selections[0]) >= $l -> index('end')) {
	    $l -> selectionSet ($l -> index('end') - 1);
	    $l -> see ($l -> index('end') - 1);
	} else {
	    $l -> selectionSet ($selections[0]);
	    $l -> see ($selections[0]);
	}
	updatemsgcount ($mw, $currentfolder);
	updatemsgcount ($mw, $dir);
	displaymessage ($mw, $currentfolder);
    }; # eval
}

sub emptytrash {
    my (@files, $utctime, $mtime, $expiresafter, $f, $tf);
    $utctime = time;
    $expiresafter = ($config->{trashdays}) * 24 * 3600;
    print "emptytrash(): UTC time: $utctime, older than $expiresafter.\n" 
	if $config->{debug};
    if ($^O =~ /Win/) {
  	show_warn_dialog ($mw, $warndialog,
	  -message => 
            "Could not open ".$config->{trashdir}.": $! [ERR1362]\n");
    } else {
	opendir TRASH, $config->{trashdir} or 
	    show_warn_dialog ($mw, $warndialog,
	      -message => "Could not open ".$config->{trashdir}.": $!\n");
    }
    @files = grep /^[^.]/, readdir TRASH;
    closedir TRASH;
    foreach $f (@files) {
	$tf = $config->{trashdir}."/$f";
	$mtime = (stat($tf))[9];
	print "$tf, mtime\: $mtime, age: ".($utctime - $mtime)."\n"
	    if $config->{debug};
	if (($utctime - $mtime) >= $expiresafter) {
	    unlink ($tf) if not $config->{debug};
	    deletemsgfromindex ($f, $config->{trashdir})
		if not $config->{debug};
	    print "unlink $tf.\n" if $config->{debug};
	}
    }
    updatemsgcount ($mw, $config->{trashdir});
    listmailfolder ($mw -> Subwidget ('messagelist', $currentfolder))
	if $currentfolder eq $config -> {trashdir};
}

sub interval_poll {
    my ($mw, $lsites) = @_;
    incoming_poll (@_);
    $mw->after (($config->{pollinterval}),
		sub{interval_poll ($mw, $lsites)})
	if $config->{pollinterval};
}

sub incoming_poll {
    my ($mw, $lsites) = @_;
    my ($hdr, $insert);
    my $l = $mw -> Subwidget ('messagelist');
    my $t = $mw -> Subwidget ('text');
    watchcursor ($mw);
    eval {
	# remember selections and insertion point if they exist
	my @selindexes = $l->curselection if defined $l;
	$insert = $t -> index ('insert') if defined $t;
	visit_sites ($mw, $lsites);
        movemail () if ($config->{usesendmail} or 
			$config->{useqmail} or
			$config->{useexim});
	listmailfolder ($l, $currentfolder);
	updatemsgcount ($mw, $_) foreach (@{$config->{folder}});
	$l -> selectionSet ($_)	foreach (@selindexes);
	$l -> see ($selindexes[0]);
	displaymessage ($mw, $currentfolder);
	if (defined $insert and defined $t) {
	    $t -> markSet ('insert', $insert);
	    $t -> see ('insert');
	}
	emptytrash ();
    };
    defaultcursor ($mw);
}

sub quitclient {
    my ($mw) = @_;
    exit 0;
}

sub mime_headers {
    if (($#attachments >= 0) and (length ($attachments[0]))) {
	return EC::Attachments::base64_headers ();
    } else {
	return EC::Attachments::default_mime_headers ();
    }
}

sub mime_headers_as_str {
    my $s;
    my @h = mime_headers ();
    $s .= "$_\n" foreach @h;
    return $s;
}

sub sendmsg {
    my ($cw, $ct, $c, $servermsg) = @_;
    my ($openstatus, $unfolded_addressees, $i, $line, $text);
    my ($host, $port, $uname, $passwd);
    my (@msgtextlist, $fcc_file, $msghdr, $msgtext, @hdrlist, @mimehdrs);
    my (@addressees, @formatted_attachment);
    my $md = $config->{maildomain};
    watchcursor ($cw);
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Formatting message... ");
    $cw -> update;
    $text = $ct -> get ('1.0', 'end');
    ($msghdr, $msgtext) = split /$msgsep/, $text;
    @msgtextlist = split /\n/, $msgtext;
    print $msghdr if $config->{debug};
    @hdrlist = split /\n/, $msghdr;
    foreach $line ( @hdrlist ) { 
	($fcc_file) = ($line =~ s/Fcc: //i) if ($line =~ /Fcc:/i);
    }

    if ($config -> {usesendmail}) {
	sendmail_send_message ($ct -> get ('1.0', 'end'));
	write_fcc ($ct->get ('1.0', 'end'))
	    if $fcc_file ne '' and length $fcc_file;
	$cw -> destroy;
	return 1;
    }

    if ($config -> {useexim}) {
	exim_send_message ($ct -> get ('1.0', 'end'));
	write_fcc ($ct->get ('1.0', 'end'))
	    if $fcc_file ne '' and length $fcc_file;
	$cw -> destroy;
	return 1;
    }

    if ($config -> {useqmail}) {
	qmail_send_message ($ct -> get ('1.0', 'end'));
	write_fcc ($ct->get ('1.0', 'end'))
	    if $fcc_file ne '' and length $fcc_file;
	$cw -> destroy;
	return 1;
    }

    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Getting server info... ");
    $cw -> update;

    foreach $i (@{$lsites -> {'sitelist'}}) {
	if( $i -> {'port'} != ($config->{smtpport}) ) {
	    next;
	} else {
	    $host = $i -> {'host'};
	    $port = $i -> {'port'};
	    $uname = $i -> {'user'};
	    $pass = $i -> {'pass'};
	    last;
	}
    }
    if ($host eq '' or ! defined $host) {
	sock_close_on_err ("No SMTP hostname defined\!\n");
    }
    if ($port != ($config->{smtpport})) {
	sock_close_on_err ("Incorrect port $port\!\n");
    }
    if ($uname eq '' or ! defined $uname) {
	sock_close_on_err ("No user name defined\!\n");
    }
    # Probably want to make this enterable by the user...
    if ($pass eq '' or ! defined $pass) {
	sock_close_on_err ("No password defined\!\n");
    }
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Opening server... ");
    $cw -> update;

    $openstatus = openserver ($cw, $host, $port, $uname, $pass);
    goto SERVER_ERR if not defined $openstatus;
    
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Sending message header... ");
    $cw -> update;
    print "<<<DATA\n" if ($config->{verbose});
    print SOCK "DATA\r\n";
    my $dataack = smtpack (0);

    # Wait for a numeric acknowledgement code.
    while ($dataack !~ /^[2-5]/) {
	$dataack = smtpack (0);
	print "$dataack\n" if ($config->{verbose});
	if ($status =~ /^354|^50|^45|^55|^421/) {
	    $c -> dchars ($servermsg, '0', 'end');
	    $c -> insert ($servermsg, 'end', "$status: $!");
	    $cw -> update;
	    print "<<<RSET\n" if ($config->{verbose});
	    print SOCK "RSET\r\n";
	    goto SERVER_CLOSE;
	}
    }
    print "<<<Date: ". rfctime."\n"if ($config->{verbose});
    print SOCK "Date: ". rfctime."\r\n";
    my $localhost = `uname -n`;
    foreach my $mh (@mimehdrs) {
	print "<<<$mh\n" if ($config->{verbose});
	print SOCK "$mh\r\n";
    }
    my $inetmsgid = time.'ec@'.$md;
    chomp $inetmsgid;
    print "<<<$msgidfield <$inetmsgid>\n" if ($config->{verbose});
    print SOCK "$msgidfield <$inetmsgid>\r\n";
    print "<<<$fromfield <$uname\@$md>\n" if ($config->{verbose});
    print SOCK "$fromfield <$uname\@$md>\r\n";

    # Remove Bcc:, if any.
    my @msghdr = split /\n/, $msghdr;
    foreach (@msghdr) {
	next if /^Bcc: /i;
	chomp;
	print "<<<$_\n" if ($config->{verbose});
	print SOCK "$_\r\n";
    }

    # send client id
    print "<<<$headerid\n" if ($config->{verbose});
    print SOCK "$headerid\r\n";

    $c -> dchars( $servermsg, '0', 'end' );
    $c -> insert( $servermsg, 'end',
		 "Sending message body... ");
    $cw -> update;

    #
    # Text body MIME header -- Only with attachments.  The final 
    # separator gets sent after the attachments.
    #
    if (($#attachments >= 0) or (length $attachments[0])) {
	my @text_headers = EC::Attachments::text_attachment_header;
	foreach my $hline (@text_headers) {
	    print "<<<$hline\n" if ($config->{verbose});
	    chomp $hline;
	    print SOCK "$hline\r\n";
	}
    }
    # Format and send message body.
    foreach my $mline (@msgtextlist) {
	print "<<<$mline\n" if ($config->{verbose});
	chomp $mline;
	# The SMTP server will quote a period with 
	# another period, so the program might as well 
	# do it here.
	$mline = '.. ' if $mline eq '.';
	print SOCK "$mline\r\n";
    }

    # send attachment files, if any.
    if ((defined $attachments[0]) and 
	(($#attachments >= 0) or (length $attachments[0]))) {
	foreach my $filepath (@attachments) {
	    @formatted_attachment = 
	      EC::Attachments::format_attachment ($filepath);
	    foreach $line (@formatted_attachment) {
		print "<<<$line\n" if ($config->{verbose});
		print SOCK "$line\r\n";
	    }
	}
	my $outgoing_boundary = EC::Attachments::outgoing_mime_boundary;
	print "<<<\-\-$outgoing_boundary" if ($config->{verbose});
	print SOCK "\-\-$outgoing_boundary\r\n";
    }

    print "<<<\n\<<<.\n" if ($config->{verbose});
    print SOCK "\r\n\.\r\n";
    # use longer timeout to give server time to finish
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Waiting for acknowledgement... ");
    $cw -> update;

    $SIG{ALRM} = sub { alarm 0; die 'smtp acknowledgement' };
    eval {
	while() {
	    alarm ($config->{servertimeout});
	    $status = smtpack (0);
	    print "$status\n" if ($config->{verbose});
	    if ($status =~ /^250/) {
		write_fcc( $ct->get('1.0','end'))
		    if $fcc_file ne '' and length $fcc_file;
		alarm( 0 );
		goto SERVER_CLOSE;
	    }
	    if ($status =~ /^45|^55/) {
		$c -> dchars ($servermsg, '0', 'end');
		$c -> insert ($servermsg, 'end', "$status: $!");
		alarm (0);
		print "<<<RSET\n" if ($config->{verbose});
		print SOCK "RSET\r\n";
		goto SERVER_CLOSE;
	    }
	}
	alarm (0);
    };

  SERVER_CLOSE:
    $c -> dchars ($servermsg, '0', 'end');
    $c -> insert ($servermsg, 'end',
		  "Closing server... ");
    $cw -> update;
    defaultcursor ($cw);
    print "<<<QUIT\n" if ($config->{verbose});
    print SOCK "QUIT\r\n";
    local $quitack = smtpack (0);
    print "$quitack\n" if ($config->{verbose}) and defined $quitack;
    while ( $quitack !~ /^221|^500/ ) {
	$status = smtpack(0);
	print "$status\n" if ($config->{verbose});
	if ($status =~ /^500/) {
	    $c -> dchars ($servermsg, '0', 'end');
	    $c -> insert ($servermsg, 'end', "$status: $!");
	    $cw -> update;
	    print "<<<RSET\n" if ($config->{verbose});
	    print SOCK "RSET\r\n";
	    return;
	}
    }
    $#attachments = -1;
    $cw -> Subwidget ('mimedialog') -> DESTROY
	if defined $cw -> Subwidget ('mimedialog');
    $cw -> destroy;
    return 1;

  SERVER_ERR:
    defaultcursor ($cw);
    return 1;
}

sub sendmail_send_message {
    my $message = $_[0];
    my $mtaname = $config->{sendmailprog};
    my ($msghdr, $msgtext) = split /$msgsep/, $message;
    my $mimehdrs = mime_headers_as_str ();
    my @addressees = addressees ($msghdr);
    my $unfolded_addressees = "";
    foreach (@addressees) {
	local $a;
	$a = address_without_envelope ($_);
	if (!length ($unfolded_addressees)) {
	    $unfolded_addressees = "$a";
	} else {
	    $unfolded_addressees .= ", $a";
	}
    }
    if ($config->{sendmailsetfrom}) {
	if ($^O =~ /Win/) {
	    open MTA, "|$mtaname -f ".
		$config->{sendmailsetfromaddress}." ".
		    $unfolded_addressees or
			show_warn_dialog ($mw, $warndialog,
					  -message => 
	  "Couldn't run e-mail program $mtaname: $! [ERR1696]\n");
	} else {
	    open MTA, "|$mtaname -f ".
		$config->{sendmailsetfromaddress}." ".
		    $unfolded_addressees or
			show_warn_dialog ($mw, $warndialog,
					  -message => 
			  "Couldn't run e-mail program $mtaname: $!\n");
	}
    } else {
	if ($^O =~ /Win/) {
	    open MTA, "|$mtaname $unfolded_addressees" or
		show_warn_dialog ($mw, $warndialog,
				  -messages => 
		  "Couldn't run e-mail program $mtaname: $! [ERR1710]\n");
	} else {
	    open MTA, "|$mtaname $unfolded_addressees" or
		show_warn_dialog ($mw, $warndialog,
				  -messages => 
		  "Couldn't run e-mail program $mtaname: $!\n");
	}
    }
    print MTA "$msghdr$mimehdrs$headerid\n$msgtext\n";
    if ((defined $attachments[0]) and 
	(($#attachments >= 0) or (length $attachments[0]))) {
	foreach my $filepath (@attachments) {
	    @formatted_attachment = 
	      EC::Attachments::format_attachment ($filepath);
	    foreach $line (@formatted_attachment) {
		print MTA "$line\n";
	    }
	}
	my $outgoing_boundary = EC::Attachments::outgoing_mime_boundary();
	print MTA "\-\-$outgoing_boundary\n";
    }
    print MTA ".\n";
    close MTA;
}

sub exim_send_message {
    my $message = $_[0];
    my $mtaname = $config->{eximprog};
    my ($msghdr, $msgtext) = split /$msgsep/, $message;
    my $mimehdrs = mime_headers_as_str ();
    my @addressees = addressees ($msghdr);
    my $unfolded_addressees = "";
    foreach (@addressees) {
	local $a;
	$a = address_without_envelope ($_);
	if (!length ($unfolded_addressees)) {
	    $unfolded_addressees = "$a";
	} else {
	    $unfolded_addressees .= ", $a";
	}
    }
    if ($config->{eximsetfrom}) {
	if ($^O =~ /Win/) {
	    open MTA, "|$mtaname -f ".
		$config->{eximsetfromaddress}." ".
		    $unfolded_addressees or
			show_warn_dialog ($mw, $warndialog,
					  -message => 
		  "Couldn't run e-mail program $mtaname: $! [ERR1749]\n");
	} else {
	    open MTA, "|$mtaname -f ".
		$config->{eximsetfromaddress}." ".
		    $unfolded_addressees or
			show_warn_dialog ($mw, $warndialog,
					  -message => 
		  "Couldn't run e-mail program $mtaname: $!\n");
	}
    } else {
	if ($^O =~ /Win/) {
	    open MTA, "|$mtaname $unfolded_addressees" or
		show_warn_dialog ($mw, $warndialog,
				  -messages => 
		  "Couldn't run e-mail program $mtaname: $! [ERR1763]\n");
	} else {
	    open MTA, "|$mtaname $unfolded_addressees" or
		show_warn_dialog ($mw, $warndialog,
				  -messages => 
		  "Couldn't run e-mail program $mtaname: $!\n");
	}
    }
    print MTA "$msghdr$mimehdrs$headerid\n$msgtext\n";
    if ((defined $attachments[0]) and 
	(($#attachments >= 0) or (length $attachments[0]))) {
	foreach my $filepath (@attachments) {
	    @formatted_attachment = 
	      EC::Attachments::format_attachment ($filepath);
	    foreach $line (@formatted_attachment) {
		print MTA "$line\n";
	    }
	}
	my $outgoing_boundary = EC::Attachments::outgoing_mime_boundary();
	print MTA "\-\-$outgoing_boundary\n";
    }
    print MTA ".\n";
    close MTA;
}

sub qmail_send_message {
    my $message = $_[0];
    my ($msghdr, $msgtext) = split /$msgsep/, $message;
    my @addressees = addressees ($msghdr);
    my $unfolded_addressees = "";
    foreach (@addressees) {
	local $a;
	$a = address_without_envelope ($_);
	if (!length ($unfolded_addressees)) {
	    $unfolded_addressees = "$a";
	} else {
	    $unfolded_addressees .= ", $a";
	}
    }
    my $mimehdrs = mime_headers_as_str ();
    if ($^O =~ /Win/) { 
	open MTA, "|".$config->{qmailinjectpath}." ".
	    $unfolded_addressees or 
		show_warn_dialog ($mw, $warndialog,
				  -message => "Couldn't open " . 
					  $config->{qmailinjectpath} .
					  ": $! [ERR1800]\n"); 
    } else {
	open MTA, "|".$config->{qmailinjectpath}." ".
	    $unfolded_addressees or 
		show_warn_dialog ($mw, $warndialog,
				  -message => "Couldn't open " .
				  $config->{qmailinjectpath} .
				  ": $!\n"); 
	    }
    print MTA "$msghdr$mimehdrs$headerid\n$msgtext\n";
    if ((defined $attachments[0]) and 
	(($#attachments >= 0) or (length $attachments[0]))) {
	foreach my $filepath (@attachments) {
	    @formatted_attachment = 
	      EC::Attachments::format_attachment ($filepath);
	    foreach $line (@formatted_attachment) {
		print MTA "$line\n";
	    }
	}
	my $outgoing_boundary = EC::Attachments::outgoing_mime_boundary();
	print MTA "\-\-$outgoing_boundary\n";
    }
    print MTA ".\n";
    close MTA;
}

# return an RFC-compliant date/time string from configuration.
sub rfctime {
    my ($year, $dn, $mn, $tz, $sec, $min, $hour, $mday, $mon, $wday, $yday);
    if ($config->{gmtoutgoing}) {
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime (time);
	$tz = '-0000';
    } else {
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = 
	    localtime (time);
	$tz = $config->{'timezone'};
    }
    $year += 1900;
    $dn = $daynames[$wday];
    $mn = $monthnames[$mon];
    return ("$dn $mday $mn $year $hour\:$min\:$sec $tz");
}

sub write_fcc {
    my ($msg) = @_;
    my ($msghdr, $msgtext) = split /$msgsep/, $msg, 2;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = 
	gmtime(time);
    $year += 1900;
    my $dn = $daynames[$wday];
    my $mn = $monthnames[$mon];
    $msghdr =~ /^Fcc\:\s+(.*)$/smi;
    my $fccfile = $1;
    chomp $fccfile;
    print "Fcc file: $fccfile\n" if $config->{debug};
    if (defined $fccfile and (length $fccfile)) {
	$fccfile = expand_path ($fccfile);
	print "writing FCC: $fccfile\n" if $config->{debug};
	open FCC, "+>> $fccfile"
	    or 
	    show_warn_dialog ($mw, $warndialog,
               -message => "Could not open FCC file $fccfile: $!\n");
	print FCC  "\nDate: $dn, $mday $mn $year $hour\:$min\:$sec\r\n";
	print FCC "$msghdr\n\n$msgtext";
	close FCC;
    }
}

# provide at least an envelope address.
sub rfc822_addr {
    my ($s) = @_;
    $s =~ s/<|>|\"//g;
    my ($s1,$s2) = ($s =~ /(.*\s)*(.+\@.+)/ );
    $s2 =~ s/ |\t//g;
    $s = ((defined $s1) ? "$s1 <$s2>" : "<$s2>");
    return $s;
}

# format an envelope address.
sub envelope_addr {
    my ($s) = @_;
    $s =~ s/<|>|\"//g;
    my ($s1,$s2) = ($s =~ /(.*\s)*(.+\@.+)/ );
    $s2 =~ s/ |\t//g;
    return "<$s2>";
}

sub address_without_envelope {
    my ($s) = @_;
    $s =~ s/<|>|\"//g;
    my ($s1,$s2) = ($s =~ /(.*\s)*(.+\@.+)/ );
    $s2 =~ s/ |\t//g;
    return $s2;
}

sub reply {
    my ($mw) = @_;
    my ($origmsgid, $origmsg, $origbody, $fromaddr, $replyaddr, $subj);
    my ($line, $orighdr, $ccline, $bccline);
    my $cw = composewidgets ($mw);
    my $ct = $cw -> Subwidget ('text');
    my $c = $mw -> Subwidget ('button_bar');
    my $l = $mw -> Subwidget ('messagelist');
    my $servermsg = $mw -> Subwidget ('servermsg');
    my $sigfile = $config->{sigfile};
    my $fcc_file = $config->{fccfile};
    $ccline = '';
    $bccline = '';
    $origmsgid = ${$sortedmessages[($l->curselection)[0]]}[3];
    $origmsg = content_as_str ("$currentfolder/$origmsgid");
    $origmsg =~ /(.*?\n)(\n.*)/sm;
    $orighdr = $1;
    $origbody = $2;
    if( $orighdr =~ /^Reply-To\:\s+(.*?)$/smi ) {
	$replyaddr = rfc822_addr( $1 );
    } else {
	$replyaddr = '';
    }
    if ($orighdr =~ /^From\:\s+(.*?)$/smi) {
	$fromaddr = rfc822_addr ($1);
    }
    if ($replyaddr eq '') {
	$replyaddr = $fromaddr;
    } elsif ($config->{ccsender} ) {
	$replyaddr =~ /(\S\@\S)/;
	local $r1 = $1;
	$fromaddr =~ /(\S\@\S)/;
	local $f1 = $1;
	$ccline .= $fromaddr if $r1 ne $f1;
    }
    $ccline .= rfc822_addr($1) if($orighdr =~ /^CC\:\s+(.*)$/smi);
    $bccline = $1 if ($orighdr =~ /^BCC\:\s+(.*)\n/smi);
    if ($orighdr =~ /^Subject\:\s+(.*?)$/smi) {
	$subj = $1;
	if ($subj !~ /Re\:/smi) {
	    $subj = "Re: $subj";
	}
    }

    $ct->insert ('1.0',"$tofield $replyaddr\n",'header');
    $ct->insert ('end',"$ccfield $ccline\n",'header') if $ccline;
    $ct->insert ('end',"$bccfield $bccline\n",'header') if $bccline;
    $ct->insert ('end',"$subjfield $subj\n",'header');
    $ct->insert ('end', "$fccfield $fcc_file\n", 'header') if $fcc_file;
    $ct->insert ('end',"$msgsep\n\n",'header');

    $ct->insert ('end', "$fromaddr writes:\n");
    my @formattedmsg = split /\n/, $origbody;
    foreach (@formattedmsg) {
	$ct -> insert ('end', $config->{quotestring}."$_\n");
    }
    if ($config->{usesig}) {
	$ct -> insert ('end', "\n$sigsep\n");
	$ct -> insert ('end', content_as_str($sigfile));
    }
    return $cw;
}

sub compose {
    my $sigfile = $config->{sigfile};
    my $cw = composewidgets ($mw);
    my $ct = $cw -> Subwidget ('text');
    my $c = $cw -> Subwidget ('button_bar');
    my $fcc_file = $config->{fccfile};
    $#attachments = -1;
    $ct -> insert ('1.0', "$tofield \n", 'header');
    $ct -> insert ('2.0', "$subjfield \n", 'header');
    $ct -> insert ('3.0', "$fccfield $fcc_file\n", 'header') if $fcc_file;
    $ct -> insert ('end', "$msgsep\n\n", 'header');
    if ($config->{usesig}) {
	$ct -> insert ('end', "\n$sigsep\n");
	$ct -> insert ('end', content_as_str($config->{sigfile}));
    }
    return $cw;
}

sub composemenu {
    my ($w) = @_;
    my $cm = $w -> Menu(-type => 'menubar');
    my $composefilemenu = $cm -> Menu;
    my $composeeditmenu = $cm -> Menu;
    my $composeattachmentsmenu = $cm -> Menu;
    my $composeattachmentfilesmenu = $cm -> Menu;
    $w -> Advertise ('composeattachmentfilesmenu' => 
		     $composeattachmentfilesmenu);
    my $optionalfieldsmenu = $cm -> Menu;
    $cm -> add('cascade', -label => 'File', -menu => $composefilemenu);
    $cm -> add('cascade', -label => 'Edit', -menu => $composeeditmenu);
    $cm -> add('cascade', -label => 'Attachments', 
	       -menu => $composeattachmentsmenu);
    $composefilemenu -> add('command', -label => 'Insert File...',
			    -accelerator => 'Alt-I',
			    -command => sub {InsertFileDialog($w)});
    $composefilemenu -> add ('separator');
    $composefilemenu -> add ('command', -label => 'Minimize', 
			    -state => 'normal',
			    -accelerator => 'Alt-Z',
			    -command => sub{$w->toplevel->iconify});
    $composefilemenu -> add ('command', -label => 'Close',
			     -accelerator => 'Alt-W',
			     -command => sub { $w -> WmDeleteWindow});
    EditMenuItems ($composeeditmenu, ($w -> Subwidget ('text')));
    $composeattachmentsmenu -> add ('command', -label => 'Attach File...',
	    -command => sub {compose_attachment_dialog($w)});
    $composeattachmentsmenu -> add ('cascade', 
		    -label => 'Remove Attachment...',
		    -menu => $composeattachmentfilesmenu);
    my $optionalfields = OptionalFields ($w -> Subwidget ('text'));
    $optionalfieldsmenu -> AddItems (@$optionalfields);
    $composeeditmenu -> add ('separator');
    $composeeditmenu -> add ('cascade',  -label => 'Insert Field',
			   -state => 'normal', 
			   -menu => $optionalfieldsmenu);
    return $cm;
}

sub OptionalFields {
    my ($t) = @_;
    return
	[
	 [command=>'Bcc:', -command=>sub{insertfield($t,$bccfield)}],
	 [command=>'Cc:', -command=>sub{insertfield($t,$ccfield)}],
	 [command=>'Fcc:', -command=>sub{insertfield($t,$fccfield)}],
	 [command=>'Reply-To:', -command=>sub{insertfield($t,$replytofield)}],
	 ]
}

sub standard_keybindings {
    my ($w) = @_;
    $w->bind ('<Alt-c>',sub{$w -> Subwidget ('text') -> clipboardCopy});
    $w->bind ('<Alt-x>',sub{$w -> Subwidget ('text') -> clipboardCut});
    $w->bind ('<Alt-v>',sub{$w -> Subwidget ('text') -> clipboardPaste});
    $w->bind ('<Alt-u>',sub{$w -> Subwidget ('text') -> undo});
    $w->bind ('<Alt-i>',sub{InsertFileDialog ($w)});
    $w->bind ('<Alt-w>',sub{$w -> WmDeleteWindow});
    $w->bind ('<Alt-z>',sub{$w -> toplevel -> iconify});
    $w->bind ('<Alt-a>',sub{selectallmessages ($w)});
    return $w;
}

sub insertfield {
  my ($t, $field) = @_;
  my ($point);
  $point = $t -> search ('--', $msgsep, '1.0', 'end');
  $t -> insert ($point, "$field \n", 'header');
}

sub composewidgets {
    my ($mw) = @_;
    my $b_org = 55;
    my $cw = new MainWindow (-title => "New Message");
    my $ct = $cw -> Scrolled ('TextUndo', -height => 24,
			      -scrollbars => 'osoe',
			      -background => 'white',
			      -wrap => 'word',
			      -width => 80);
    $ct -> Subwidget ('xscrollbar') -> configure (-width => 10);
    $ct -> Subwidget ('yscrollbar') -> configure (-width => 10);
    $cw -> Advertise ('text' => $ct);
    $ct -> tagConfigure ('header', '-font', $config->{headerfont})
	if defined $config -> {headerfont};
    my $menu = composemenu ($cw);
    $menu -> pack (-anchor => 'w', -fill => 'x');
    $ct -> pack (-expand => 1, -fill => 'both');
    my $c = $cw -> Canvas (-height => 40, -width => 600);
    $cw -> Advertise ('button_bar' => $c);
    my $servermsg = $c -> createText (500, 20, 
				      -text => 'Composing message.',
				      -justify => 'right');
    $cw -> Advertise ('servermsg' => $servermsg);
    my $sendbutton = $cw -> Button (-text => 'Send',
				   -width => 8,
				   -underline => 0,
				   -command => sub{ bind_sendmsg( $cw, $ct,
							  $c, $servermsg)});
    my $closebutton = $cw -> Button (-text => 'Cancel',
				  -width => 8,
				   -command => sub{$cw -> WmDeleteWindow});
    my $cdcanv = $c -> createWindow (55, 18, -window => $sendbutton);
    my $cncanv = $c -> createWindow ($b_org + $closebutton -> reqwidth, 
				     18, -window => $closebutton);
    $c -> pack(-expand => '1', -fill => 'x');
    $cw -> bind ('<Alt-s>',sub{bind_sendmsg( $cw, $ct, $c, $servermsg)});
    standard_keybindings ($cw);
    return $cw;
}

sub bind_sendmsg {
    sendmsg (@_);
    return 1;
}

sub compose_attachment_dialog {
    my ($w) = @_;
    my ($ofilename);
    $ofilename = fileselect ($w, $attachfiledialog,
			      -directory => $ENV{HOME});
    push @attachments, ($ofilename);
    my $attachmentfilemenu = $w -> Subwidget ('composeattachmentfilesmenu');
    $attachmentfilemenu -> delete (1, 'end');
    foreach (@attachments) {
	$attachmentfilemenu -> add ('command', -label => $_,
			    -command => [\&compose_remove_attachment, $w,$_]);
    }
}

sub compose_remove_attachment {
    my ($w,$attachmentname) = @_;
    my @newattachments;
    foreach (@attachments) {
	push @newattachments, ($_) if ($_ !~ m"$attachmentname");
    }
    $#attachments = -1;
    foreach (@newattachments) {print "$_\n"}
    push @attachments, @newattachments;
    my $attachmentfilemenu = $w -> Subwidget ('composeattachmentfilesmenu');
    $attachmentfilemenu -> delete (1, 'end');
    foreach (@attachments) {
	$attachmentfilemenu -> add ('command', -label => $_,
			    -command => [\&compose_remove_attachment, $w,$_]);
    }
}

sub menu_list_attachments {
    my ($msg) = @_;
    my $attachmentmenu = $mw -> Subwidget ('attachmentmenu');
    $attachmentmenu -> delete (1, 'end');
    my @attachmentlist = EC::Attachments::attachment_filenames ($msg);
    if ($#attachmentlist == -1) {
	$attachmentmenu -> insert (1, 'command', -label => '(None)');
    } else {
	foreach (@attachmentlist) {
	    $attachmentmenu -> add ('command', -label => $_,
			    -command => [\&save_attachment_file, $msg,$_]);
	}
    }
}

sub save_attachment_file {
    my ($msg, $attachmentfilename) = @_;
    my $ofilename = fileselect ($mw, $savefiledialog,
				-directory => $ENV{HOME},
				-acceptlabel => 'Save',
				 -title => 'Save Attachment File',
				 -initialtext => $attachmentfilename );
    if ((strexist ($ofilename)) and (-f $ofilename)) {
	my $response = show_warn_dialog ($mw, $warndialog, 
			   -message => "File $ofilename exists.  Overwrite?");
	return if $response !~ /Ok/;
    }
    if (strexist ($ofilename)) {
	EC::Attachments::save_attachment ($msg, $attachmentfilename, $ofilename);
    }
}

if ($tkminorversionno >= 020) {
    @busyopts = (qw/-recurse 1/);
}
sub watchcursor {
    my ($mw) = @_;
    $mw -> Busy (@busyopts);
}
sub defaultcursor {
    my ($mw) = @_;
    $mw -> Unbusy (@busyopts);
}

sub browse_url {
    my ($mw) = @_;
    require Tk::DialogBox;
    require Tk::IO;
    my $index = $mw -> Subwidget('text') -> index ('insert');
    my ($bname, $lockfile, $bcommand, $bpid);
    my ($line,$col) = split /\./, ($index);
    my $cline = $mw->Subwidget ('text')->get ( "$line\.0", "$line\.end");
    my ($url) = ($cline =~ /(http\S*)/i);
    $url = '' if (not defined $url);
    my $dialog = $mw -> DialogBox (-title => 'Open URL',
				   -buttons => ['Ok', 'Cancel'],
				   -default_button => 'Ok');
    my $urlentry = $dialog -> add ('Entry',
				   -textvariable => \$url,
				   -width => 35 ) -> pack;
    return if $dialog -> Show !~ /Ok/;
    $bname = $config->{browser};
    $bhandle = Tk::IO -> new (-linecommand => sub{}, -callback => sub{});
    if ($bname =~ /netscape/) {
	$lockfile = "$ENV{HOME}/.netscape/lock" if $bname =~ /netscape/;
	if ( (-f $lockfile) || (-l $lockfile) ) {
	    $bcommand = "$bname \-remote ". "\'openURL ($url)\'";
	} else {
	    $bcommand = "$bname $url";
	}
    } elsif ($bname =~ /opera/) {
	$bcommand = "$bname \-remote \'openURL ($url)\'";
    } elsif ($bname =~ /lynx/) {
	my $xterm = $config->{xterm};
	$bcommand = "$xterm \-e lynx $url";
    } elsif ($bname =~ /amaya/) {
	$bcommand = "amaya $url";
    }
    $bpid = $bhandle -> exec ($bcommand);
}

sub deletetrashfolder {
    my ($mw) = @_;
    eval {
	watchcursor ($mw);
	require Tk::Dialog;
	my $trashdir = $config->{trashdir};
	my $dialog = $mw -> Dialog( -title => "Empty Trash",
				    -text => "Confirm empty trash?",
				    -default_button => 'No',
		-bitmap => 'question', -buttons => ['Yes', 'No'] );
	return if ($dialog -> Show) eq 'No';
	if ($^O =~ /Win/) {
	    opendir MDIR, $trashdir or 
		show_warn_dialog ($mw, $warndialog, 
	       -message => "Could not open $trashdir: $! [ERR2221]\n");
	} else {
	    opendir MDIR, $trashdir or 
		show_warn_dialog ($mw, $warndialog, 
			       -message => "Could not open $trashdir: $!\n");
	}
	@trashfiles = grep /[^\.]|[^\.][^\.]/, readdir MDIR;
	closedir MDIR;
	foreach (@trashfiles) {
	    unlink "$trashdir/$_";
	    unlink "$trashdir/.index" if -f "$trashdir/.index";
	}
    };
    updatemsgcount ($mw, $config->{trashdir});
    defaultcursor ($mw);
}

# 
#  Process command line options
#
require "getopts.pl";
$opt_errs = &Getopts("f:dhkvo");
if ($opt_h || !$opt_errs) {
    print "Usage: ec [-f filename][-hkvo]\n\n";
    print "  -f filename        Get server defaults from file filename.\n";
    print "  -o                 Offline - don't fetch mail from server.\n";
    print "  -h                 Print help file.\n";
    print "  -k                 Keep mail on server (don't delete).\n";
    print "  -v                 Print verbose messages.\n";
    print "  -d                 Print debugging information.\n";
    die "\nPlease report bugs to rkies\@cpan.org.\n";
}

if ($opt_f) { $serverfilename = $opt_c if (-f $opt_c) }
$config-> {verbose} = 1 if $opt_v;
$keepmails = 1 if $opt_k;
$config->{debug} = 1 if $opt_d;
$config->{offline} = 1 if $opt_o;

$LFILE = "/tmp/popm.$UID";

#Perl 5 - have to set PATH to known value - security feature
# $ENV{'PATH'}="/bin:/usr/bin:/usr/local/bin:/usr/lib:/usr/sbin";

# Get list of sites from configuration file: See above.
$lsites = get_user_info ();

#
# Initialize main window widgets.
#
sub init_main_widgets {
    my $mw = new MainWindow( -title => "Email Client");
    my $l = $mw -> Scrolled ('Listbox',
			     -height => 7,
			     -bd => 2, 
			     -relief => 'sunken',
			     -selectmode => 'extended',
			     -width => 80,
			     -background => 'white',
			     -foreground => 'black',
			     -scrollbars => 'osoe');
    $l -> Subwidget ('yscrollbar') -> configure (-width=>10);
    $l -> Subwidget ('xscrollbar') -> configure (-width=>10);
    $mw -> Advertise ('messagelist' => $l);
    $l -> {'ml_sort_descending'} = $config->{sortdescending};
    $datesortorder = $config->{sortdescending};
    $l -> bind ('<Button-1>', sub { displaymessage ($mw, $currentfolder) });

    my $c = init_button_bar ($mw);
    $mw -> Advertise ('button_bar' => $c);

    my $t = $mw -> Scrolled ('TextUndo', -height => 20,
			     -scrollbars => 'osoe',
			     -wrap => 'word',
			     -background => 'white',
			     -foreground => 'black',
			     -wrap => 'word',
			     -width => 80);
    $mw -> Advertise ('text' => $t);

    my $mb = init_main_menu ($mw);

    $t -> tagConfigure ('header', -font => $config->{headerfont})
	if defined $config -> {headerfont};
    $t -> Subwidget ('yscrollbar') -> configure(-width=>10);
    $t -> Subwidget ('xscrollbar') -> configure(-width=>10);
    # Unbind the text widget's popup menu
    $mw -> bind ('Tk::TextUndo','<3>', '');

    standard_keybindings ($mw);

    $mw -> bind ('<Alt-s>', sub{SaveFileAsDialog ($mw)});
    $mw -> bind ('<Alt-d>', sub{movemesg ($mw, $config->{trashdir})});
    $mw -> bind ('<Alt-n>', sub{compose ($mw)});
    $mw -> bind ('<Alt-r>', sub{reply ($mw)});
    $mw -> bind ('<Alt-o>', sub{incoming_poll ($mw, $lsites)});
    $mw -> bind ('<F1>', sub{self_help ()});
    $mw -> bind ('<Alt-e>', sub{browse_url ($mw)});
    $mw -> bind ('<Alt-Up>', sub{previous_message ($mw)});
    $mw -> bind ('<Alt-Down>', sub{next_message ($mw)});

    $mb -> pack( -anchor => 'w', -fill => 'x' );
    $l -> pack (-expand => '1', -fill => 'both', -anchor => 'w');
    $c -> pack (-expand => '1', -fill => 'x');
    $t -> pack (-expand => '1', -fill => 'both');

    return $mw;
}

sub init_button_bar {
    my ($mw) = @_;
    my $b_org = 55;
    my $c = $mw -> Canvas (-height => 40, -width => 600);
    $mw -> Advertise ('button_bar' => $c);
    my $deletebutton = $mw -> Button (-text => 'Delete',
		      -width => 8, -underline => 0,
		  -command => sub{ movemesg ($mw, $config->{trashdir})});
    my $newbutton = $mw -> Button (-text => 'New',
	   -width => 8, -underline => 0,  
	   -command => sub{compose ($mw)});
    my $replybutton = $mw -> Button (-text => 'Reply',
      -width => 8, -underline => 0, 
      -command => sub{reply ($mw)});

    my $dcanv = $c -> createWindow ($b_org, 18, -window => $deletebutton);
    my $ncanv = $c -> createWindow ($deletebutton -> reqwidth + $b_org, 
				    18, -window => $newbutton);
    my $rcanv = $c -> createWindow ($b_org + $deletebutton -> reqwidth +
				    $newbutton -> reqwidth, 18, 
				    -window => $replybutton);

    # $menufont by default
    my $msgcounter = $c -> createText (500, 15, 
	       -text => $countertext, -justify => 'right' );
    $mw -> Advertise ('msgcounter' => $msgcounter);
    my $servermsg = $c -> createText (500, 30, 
	      -text => '', -justify => 'right' );
    $mw -> Advertise ('servermsg' => $servermsg);
    return $c;
}

sub init_main_menu {
    my ($mw) = @_;
    my $mb = $mw -> Menu (-type => 'menubar');
    my $filemenu = $mb -> Menu;
    my $attachmentmenu = $mb -> Menu;
    $mw -> Advertise ('attachmentmenu' => $attachmentmenu);
    my $editmenu = $mb -> Menu;
    my $messagemenu = $mb -> Menu;
    my $foldermenu = $mb -> Menu;
    $mw -> Advertise ('foldermenu' => $foldermenu);
    my $destfoldermenu = $mb -> Menu;
    $mw -> Advertise ('destfoldermenu' => $destfoldermenu);
    my $optionmenu = $mb -> Menu;
    my $helpmenu = $mb -> Menu;
    my $headerviewmenu = $mb -> Menu;
    my $sortfieldmenu = $mb -> Menu;
    my $sortordermenu = $mb -> Menu;
    $mb -> add ('cascade', -label => 'File', -menu => $filemenu);
    $mb -> add ('cascade', -label => 'Edit', -menu => $editmenu);
    $mb -> add ('cascade', -label => 'Message', -menu => $messagemenu);
    $mb -> add ('cascade', -label => 'Folder', -menu => $foldermenu);
    $mb -> add ('cascade', -label => 'Options', -menu => $optionmenu);
    $mb -> add ('separator');
    $mb -> add ('cascade', -label => 'Help', -menu => $helpmenu);
    $filemenu -> add ('command', -label => 'Save As...', -state => 'normal',
		      -accelerator => 'Alt-S',
		  -command => sub{ SaveFileAsDialog ($mw)});
    $filemenu -> add ('command', -label => 'Empty Trash...', 
	      -state => 'normal', -command => sub{deletetrashfolder ($mw)});
    $filemenu -> add ('cascade', -label => 'File Attachments',
		      -menu => $attachmentmenu);
    $filemenu -> add ('command', -label => 'Browse URL...',
		  -state => 'normal',-accelerator => 'Alt-E',
		  -command => sub{browse_url ($mw)});
    $filemenu -> add ('separator');
    $filemenu -> add ('command', -label => 'Minimize', -state => 'normal',
		      -accelerator => 'Alt-Z',
		  -command => sub{$mw->toplevel->iconify});
    $filemenu -> add ('command', -label => 'Close', -state => 'normal',
		      -accelerator => 'Alt-W',
		  -command => sub{quitclient ($mw)});

    EditMenuItems ($editmenu, ($mw -> Subwidget ('text')));
    $messagemenu -> add ('command', -label => 'Check Server for Messages',
		 -state => 'normal', -accelerator => 'Alt-O', 
		 -command => sub{ incoming_poll ($mw,$lsites)});
    $messagemenu -> add ('separator');
    $messagemenu -> add ('command', -label => 'Compose New Message',
      -state => 'normal', -accelerator => 'Alt-N', 
      -command => sub{ compose ()});
    $messagemenu -> add ('command', -label => 'Reply', -state => 'normal',
			 -accelerator => 'Alt-R', 
                         -command => sub{reply ($mw)});
    $messagemenu -> add ('command', -label => 'Delete', -state => 'normal',
			 -accelerator => 'Alt-D',
		  -command => sub{movemesg ($mw, $config->{trashdir})});
    $messagemenu -> add ('command', -label => 'Select All Messages',
			 -state => 'normal',-accelerator => 'Alt-A',
			 -command => sub{selectallmessages($mw)});
    $messagemenu -> add ('separator');
    $messagemenu -> add ('command', -label => 'Next Message', 
		 -state => 'normal', -accelerator => 'Alt-Down',
		 -command => sub{ next_message ($mw)});
    $messagemenu -> add ('command', -label => 'Previous Message',
		 -state => 'normal', -accelerator => 'Alt-Up', 
		 -command => sub{ previous_message( $mw )});
    $messagemenu -> add ('separator');
    foreach my $fn (@{$config->{folder}}) {
	my $dirname = $fn;
	$dirname =~ s/.*\/(.*?)$/$1/;
	$destfoldermenu -> add ('command',-label => ucfirst $dirname,
			-state => 'normal', 
			-command => sub{ movemesg($mw, $fn)});
	$foldermenu -> add ('command',-label => ucfirst $dirname,
		    -state => 'normal', 
		    -command => sub{ changefolder($mw, $fn)});
    }
    $destfoldermenu -> insert (3, 'separator');
    $foldermenu -> insert (3, 'separator');
    $messagemenu -> add ('cascade', -label => 'Move To',  -state => 'normal',
			 -menu =>  $destfoldermenu);

    $optionmenu -> add ('cascade', -label => 'View Headers', 
		-state => 'normal', -menu =>  $headerviewmenu);
    $optionmenu -> add ('cascade', -label => 'Sort by', -state => 'normal',
			-menu =>  $sortfieldmenu);
    $optionmenu -> add ('cascade', -label => 'Sort Order', 
			-state => 'normal', -menu => $sortordermenu);

    $helpmenu -> add ('command', -label => 'About...', -state => 'normal',
		      -command => sub{about ($mw)});
    $helpmenu -> add ('separator');
    $helpmenu -> add ('command', -label => 'Help...', -state => 'normal',
		      -accelerator => 'F1',
		  -command => sub{self_help ()});
    $helpmenu -> add ('command', -label => 'Sample .ecconfig File...',
 		  -state => 'normal',
		  -command => sub{ sample ('ecconfig')});

    $headeritems = HeaderViews ($mw);
    $headerviewmenu -> AddItems (@$headeritems);
    $sortfielditems = SortFields ($mw);
    $sortfieldmenu -> AddItems (@$sortfielditems);
    $sortorderitems = SortOrder ($mw);
    $sortordermenu -> AddItems (@$sortorderitems);
    return $mb;
}

sub HeaderViews {
    my ($w) = @_;
    return [
	    [radiobutton => 'Full',
	     -variable => \$config->{headerview}, -value => 'full',
	     -command => sub{redisplaymessage($mw)}],
	    [radiobutton => 'Brief',
	     -variable => \$config->{headerview}, -value => 'brief',
	     -command => sub{redisplaymessage($mw)}],
	    [radiobutton => 'None',
	     -variable => \$config->{headerview}, -value => 'none',
	     -command => sub{redisplaymessage($mw)}],
	    ];
}

sub SortFields {
    my ($w) = @_;
    return [
	    [radiobutton => 'Date',
	     -variable => \$config->{sortfield}, -value => 1,
	     -command => sub{sort_option($w,1)}],
	    [radiobutton => 'Sender',
	     -variable => \$config->{sortfield}, -value => 2,
	     -command => sub{sort_option($w,2)}],
	    [radiobutton => 'Subject',
	     -variable => \$config->{sortfield}, -value => 3,
	     -command => sub{sort_option($w,3)}],
	    [radiobutton => 'None',
	     -variable => \$config->{sortfield}, -value => 0,
	     -command => sub{sort_option($w,0)}],
	    ];
}

sub SortOrder {
    my ($w) = @_;
    return [
	    [radiobutton => 'Newest First',
	     -variable => \$config->{sortdescending}, -value => 0,
	     -command => sub{sort_option($w, $config->{sortfield})}],
	    [radiobutton => 'Oldest First',
	     -variable => \$config->{sortdescending}, -value => 1,
	     -command => sub{sort_option($w, $config->{sortfield})}]
	    ];
}

sub about {
    my ($mw) = @_;
    require EC::About;
    require EC::ECIcon;
    my $aboutbox = $mw -> About (-version => $VERSION,
			 -title => 'About EC');
}

sub self_help {
    my $helpwindow;
    my $textwidget;
    my $helpfile = inc_path ('EC/ec.help');
    $help_text = content_as_str ($helpfile);
    $help_text = "Unable to open help file $helpfile"
      if ! $help_text;
    $helpwindow = new MainWindow (-title => "EC Help");
    my $textframe = $helpwindow -> Frame(-container => 0,
					  -borderwidth => 1) -> pack;
    my $buttonframe = $helpwindow -> Frame (-container => 0,
					  -borderwidth => 1) -> pack;
    $textwidget = $textframe
	-> Scrolled ('Text', -scrollbars => 'e') -> 
			 pack(-fill => 'both', -expand => 1);
    $textwidget -> Subwidget ('yscrollbar') -> configure (-width=>10);
    $textwidget -> Subwidget ('xscrollbar') -> configure (-width=>10);
    $textwidget -> insert ('end', $help_text);

    my $b = $buttonframe -> Button (-text => 'Dismiss',
		    -default => 'active', 
		    -command => sub{$helpwindow -> DESTROY}) -> pack;
    $b -> focus;
}

sub sample {
    my( $f ) = @_;
    my $helpwindow;
    my $textwidget;
    my $filename;
    if ($f =~ /ecconfig/) {
	$filename = $cfgfilename;
    } else {
	return;
    }
    my $help_text = content_as_str ($filename);
    $helpwindow = new MainWindow (-title => "$filename");
    my $textframe = $helpwindow -> Frame (-container => 0,
					-borderwidth => 1) -> pack;
    my $buttonframe = $helpwindow -> Frame (-container => 0,
					  -borderwidth => 1) -> pack;
    $textwidget = $textframe
	-> Scrolled ('TextUndo', -scrollbars => 'e')
	    -> pack (-fill => 'both', -expand => 1);
    $textwidget -> Subwidget ('yscrollbar') -> configure (-width=>10);
    $textwidget -> Subwidget ('xscrollbar') -> configure (-width=>10);
    $textwidget -> insert ('end', $help_text);
    $buttonframe -> Button (-text => 'Dismiss',
			  -command => sub{$helpwindow -> DESTROY}) ->
			    pack;
}

sub EditMenuItems {
    my ($m,$w) = @_;
    $m -> add ('command', -label => 'Undo',
		-state => 'normal',
		-accelerator => 'Alt-U',
		-command => sub{$w -> undo});
    $m -> add ('separator');
    $m -> add ('command', -label => 'Cut', -state => 'normal',
	       -accelerator => 'Alt-X', -command => sub{$w -> clipboardCut});
    $m -> add ('command', -label => 'Copy', -accelerator => 'Alt-C',
	       -state => 'normal',-command => sub{$w -> clipboardCopy});
    $m -> add ('command', -label => 'Paste', -accelerator => 'Alt-V',
	       -state => 'normal', -command => sub{$w -> clipboardPaste});
    $m -> add ('command', -label => 'Select All',
	       -accelerator => 'Ctrl-/', -state => 'normal',
	       -command => sub{$w -> selectAll});
}

sub show_warn_dialog {
    my $mw = shift;
    my $ref = shift;
    if (not defined $ref) {
	$ref = $mw -> ECWarning (@_);
    } 
    $ref -> configure(@_) if $#_;
    return $ref -> Show (@_);
}

sub fileselect {
    my $mw = shift;
    my $ref = shift;
    if (not defined $ref) {
	$ref = $mw -> SimpleFileSelect (@_);
    }
    $ref -> configure (@_) if $#_;
    return $ref -> Show (@_);
}

sub InsertFileDialog {
    my ($w)=@_;
    my $l;
    my $t = $w -> Subwidget( 'text' );
    my $name = fileselect ($w, $insertfiledialog, 
			 -directory => $config->{maildir},
			 -acceptlabel => 'Insert' );
    watchcursor ($w);
    eval {
	if (defined($name) and length($name)) {
	    chomp $name;
	    $defaultuserdir = $name;
	    $defaultuserdir =~ s/(.*)\/.*?$/$1/;
	    $t -> insert( 'insert', content_as_str( $name ) );
	    return 1;
	}
    };
    defaultcursor ($w);
    return 0;
}

sub SaveFileAsDialog {
    my ($mw)=@_;
    my $text = $mw -> Subwidget ('text');
    my $msg = $text -> get ('1.0', 'end');
    my $name = fileselect ($mw, $savefiledialog,
			    -acceptlabel => 'Save');
    if (-f $name) {
	my $r = show_warn_dialog ($mw, $warndialog, 
           -message => "File $name already exists.  Overwrite it?");
	return 0 unless $r =~ /Ok/;
    }
    if (defined($name) and length($name)) {
	chomp $name;
	watchcursor ($mw);
	eval {
	    $defaultuserdir = $name;
	    $defaultuserdir =~ s/(.*)\/.*?$/$1/;
	    if ( ! open (SAVE, ">$name")) {
		my $r1 = show_warn_dialog ($mw, $warndialog, -message => 
			   "Can\'t save file $name\: $!");
		return 0;
	    }
	    print SAVE $msg;
	    close SAVE;
	    return 1;
	};
	defaultcursor ($mw);
    }
    return 0;
}

#
#  Poll POP server, and list incoming messages.
#

$currentfolder = $config->{incomingdir};
$systemmbox = ($config->{mailspooldir})."/$localuser";
$mw -> configure( -title => $currentfolder );
$defaultuserdir = $config->{maildir};

my $icon = 
    $mw -> toplevel -> Pixmap(-data => EC::ECIcon::icondata());
$mw -> toplevel -> iconimage($icon);

# Event updates from window manager;
$SIG{WINCH} = sub{wm_update($mw)};
sub wm_update {
    my ($mw) = @_;
    $mw->update;
    $SIG{WINCH} = sub{wm_update ($mw)};
}

sub timer_update {
    my ($mw) = @_;
    return if not defined $mw;
    if ($tkminorversionno >= 20) { Tk::Event::DoOneEvent(255) }
    $mw -> update;
}

if (! $config->{offline}) {
    $mw -> repeat (100,sub{timer_update ($mw)});
    $mw -> Subwidget ('messagelist') 
	-> after (100, sub{ interval_poll($mw,$lsites)})
	    if $config->{pollinterval};
} else { # update message list without calling visit_sites
         # or interval_poll.
    updatemsgcount ($mw,$_) foreach (@{$config->{folder}});
    listmailfolder ($mw -> Subwidget ('messagelist'), 
		     $config->{incomingdir});
}

$SIG{KILL} = sub { exit 1 };

MainLoop;
unlink $LFILE;

=head1 NAME

  ec - Mail reader and composer for Unix and Perl/Tk.

=head1 SYNOPSIS

ec [C<-f> I<filename>] [C<-hkvdo>]

=head2  Command Line Options

=over 4

=item C<-f> I<filename>

Use I<filename> instead of the default server authentication file.

=item C<-h>

Print help message and exit.

=item C<-k>

Don't delete messages from POP server.

=item C<-v>

Print verbose transcript of dialogs with servers.

=item C<-d>

Print debugging information on the terminal.

=item C<-o>

Off line - don't fetch mail from server.

=back

=head1 CONTENTS

=over 4

=item DESCRIPTION

=item USING EC

=over 2

=item Sorting Messages

=item   Entering Messages

=item   File Attachments

=back

=item CONFIGURATION

=over 2

=item   Configuration Files

=item   Mail Directories and Folders

=item   Filters

=item   Mail Transport Agents

=item   Editing the Library Path Names in the Source File

=item   X Font Resources

=back

=item MAINTENANCE

=over 2

=item   Folder Indexes

=item PRINTING THE DOCUMENTATION IN DIFFERENT FORMATS

=item LICENSE

=item VERSION INFO

=item CREDITS

=back

=head1 DESCRIPTION

Ec can send and receive mail to and from remote POP3 and SMTP servers,
or route mail using B<sendmail>, B<qmail>, or B<exim>.  Ec can filter
and store incoming messages in user configurable folders.  With no
additional configuration, ec routes mail to the F<Incoming> folder.
(Ec capitalizes the first letter of directory names when creating
folder names.)  The I<Folder> menu displays the number of unread and
total messages.  Ec can move messages from folder to folder, including
the F<Trash> folder, and also encode and decode Base64 MIME
attachments.

Ec permanently deletes messages stored in the F<Trash> folder after a
user configurable period of time (two days is the default).  Mail can
be undeleted by removing messages from the F<Trash> folder.  Refer to
the section, "Configuration Files," below.

=head1 USING EC

Ec displays two windows: a list to select messages for reading,
viewing, sorting, saving, and deleting, and a text window to compose
messages.

To view a message for reading, replying, or saving to a file, click
the left mouse button, button 1, on the message header in the list
window.

Moving and deleting also operates on multiple messages by clicking on
each message with the left mouse button, button 1, while pressing the
Control key.

=head2 Starting Ec

To start ec, type at the shell prompt in an B<xterm>:

   # ec

The program displays the main window with the F<Incoming> mail folder.
If the program displays an error message that it cannot connect to the
POP mail server, use the C<-v> command line option to produce a
transcript of the dialog with the server:

  # ec -v

You can select different mail folders from the I<Folder> menu, and
move messages from one folder to another by selecting the destination
folder from the I<Message - Move To> submenu.

The I<File - Browse URL> function pops up a dialog box with the URL
under the text cursor.  Clicking, "OK," opens the browser configured
in the F<.eccconfig> file, and loads the Web page.  If the browser is
already open or iconified, ec uses that browser window to view the
URL. Ec supports B<netscape> versions 4.5-4.7, B<amaya> version 2.4,
B<opera> version 5.0, and B<lynx> in an B<xterm>.  B<Lynx> may also
need its B<xterm> options defined in the F<.ecconfig> file.

The I<Attachments - Attach File...> option in the compose window
opens a window to select files.  I<Attachments - Remove Attachment>
displays a submenu of the message's file attachments.  Refer to the
section, "File Attachments," below.

There are a number of options for quoting messages when composing a
reply.  Refer to the F<.ecconfig> file for information about these
options.

Ec also uses the X clipboard to cut and paste between windows in ec as
well as windows in other applications.  For programs that do not have
I<Cut>, I<Copy>, or I<Paste> menu options, select text in the source
application's window by holding down the left mouse button and
dragging it across the text to highlight it, then changing to the
destination window and pressing the middle mouse button (or the left
and right buttons simultaneously on mice with only two buttons).

=head2 Sorting Messages

You can select whether to sort messages by Date (the default), the
sender, or the subject, either newest first or oldest first, by
selecting the sort field from the I<Options - Sort by> submenu and the
I<Options - Sort Order> submenu, and by clicking on the headings of
the message listing.

=head2 Entering Messages

The I<New> button below the message list and I<Message - Compose New
Message> menu item opens a composer window with a new message form
with header lines for the addressee, the subject, and the name of the
FCC (File Carbon Copy) file to save a copy of the message in.  If you
have a F<~/.signature> file (refer to the F<.ecconfig> file), ec
inserts the signature at the end of the message text.

Clicking the I<Reply> button, or selecting I<Message - Reply> from the
menu opens a compose window with the address and subject of the
original message filled in, and the message quoted in the text area.
There are several options which determine how ec fills in reply
addresses and quotes original messages.

Each message contains header information and body text, separated by a
boundary line:

  --- Enter the message text below this line. ---

This line must exist for ec to process the message, but it is not
included in the outgoing message.

Outgoing messages require at least a valid mail address to be entered
on the "To:" header line.

The I<Edit - Insert Field> submenu provides optional Cc: Bcc:, Fcc:
and Reply-to: headers fields.

Ec supports a limited form of address, "unfolding."  A To:, Cc:,
Reply-To:, or Bcc: line can contain more than one mail address.
Multiple addresses must be separated by commas.


=head2 File Attachments

Ec supports a subset of the Internet MIME specification which allows
files to be sent as attachments to messages.

To save a file that is attached to an incoming message, select the
file from the I<File - Attachments> menu.  Type the name of the file
to save the attachment to in the dialog box.

To attach files to outgoing messages, select the I<Attachments -
Attach File...> menu item in the compose window.  Then select the file
from the dialog box's list or by entering its name.  The file(s) are
listed on the I<Attachments - Remove Attachment> submenu.  Selecting
an attachment removes it.

When a message contains file attachments, ec also encloses the text of
the message as a MIME C<text/plain> section, and sets the message
header's C<Content-Type:> field to C<multipart/mixed>.

=head1 CONFIGURATION

The file F<README> contains installation instructions.

=head2 Configuration Files

The program uses two configuration files, F<.ecconfig> and
F<.servers>. The default configuration directory is F<~/.ec>, which is
configurable by editing the paths in F<ec> and F<Config.pm>.  The
configuration files and directory are not visible in normal directory
listings.  Use the C<-a> option to B<ls> to view them:

  # ls -a ~/.ec

The F<.ecconfig> file contains user-settable defaults for the
program's operating parameters using E<lt>optionE<gt> E<lt>valueE<gt>
statements on each line.  The function of each setting is explained in
the F<.ecconfig> file's comments.

You can also edit the F<.ecconfig> file by selecting I< Help - Sample
.ecconfig File...>.  Pressing the right mouse button (button 3) pops
up a menu over the text area. where you can save your changes.  You
must exit and restart ec for the changes to take effect.

The F<.servers> file contains the user login name, host name, port,
and password for each POP3 and SMTP server.  Ec allows incoming mail
retrieval from multiple POP3 servers, but only allows one SMTP server
to send outgoing mail.  The format of each line is:

  <server-name> <port> <user-login-name> <password>

In standard configurations, POP3 servers use port 110, and the
single SMTP server uses port 25.

  mail.isp.net 110 info  password-for-info
  mail.isp.net 110 sales password-for-sales
  mail.isp.net 25  info  password-for-info

If there is a hyphen, C<->, in the password field, ec prompts for the
server's password.

If you need to use different addresses for outgoing messages, you
can edit the From: or Reply-to: line of message header so that 
the mail originates from the address you want and replies get
sent to the appropriate address.

The .servers file must have only user read-write permissions (0600),
otherwise the program prints a warning message.  The permissions can
be set with the command:

  # chmod 0600 .ec/.servers

You must be the owner of the file to set its permissions.

The F<.servers> file is not editable from the Help menu.

=head2 Mail Directories and Folders

EC saves messages in user-configurable "folders," or directories, and
can move messages between folders via the I<Message - Move To>
submenu.  The mail folders are subdirectories of the I<maildir>
setting, which is F<~/Mail> by default.

Assuming that a user's $HOME directory is F</home/bill>, the directories
that correspond to mail folders are:

  Option     Value      Path
  ------     -----      ----
  maildir    ~/Mail     /home/bill/Mail
  incoming   incoming   /home/bill/Mail/incoming
  trash      trash      /home/bill/Mail/trash

The Incoming and F<Trash> directories must exist before using EC.  The
program will not create them on its own.

Ec makes the first letter of folder names uppercase, regardless of
whether the directory name starts with a capital or small letter.

All other directories can be configured in the F<.ecconfig> file,
using the C<folder> directive.  You must create the directories before
ec can move messages into them.  If a directory doesn't exist, ec
prints a warning saves the message in the F<Incoming> folder.

The mail program B<mutt> also uses a directory named F<Mail> to
store messages.  You should change the name of ec's, C<maildir> option
in F<.ecconfig> so that ec's message storage does not conflict with
B<mutt>'s mail storage.

=head2 Filters

You can sort incoming mail by matching the text in an incoming message
with a specified pattern.  Each C<filter> line in the F<.ecconfig>
file is composed of a text pattern, a double equals sign, and the
folder the mail is to be saved in.  The format of a filter line in the
configuration file is:

  filter <text-pattern>==<folder-directory>

Text patterns can contain any of the metacharacters Perl recognizes
(refer to the B<perlre> man page).  Pattern matches are not case
sensitive.  The C<folder-directory> that the pattern matches must
exist.

Perl recognizes as metacharacters some characters that are also common
in mail addresses.  They must by preceded by a backslash.  These
characters include: @, [, ], <, and >.  Refer to the example filter
definitions in the F<.ecconfig> file.

=head2 Mail Transport Agents

In addition to an ISP's SMTP server, ec can send outgoing messages via
B<sendmail>, B<qmail>, or B<exim>.  In the F<.ecconfig> file, the
C<usesendmail>, C<useqmail>, and C<useexim> options determine which
MTA, if any, is used.  If the value of of any of these options is
non-zero, then outgoing mail is routed to the MTA.

If no MTA is selected, ec sends and receives messages directly to and
from a remote mail host.  In this case it will not process messages
from a local mail transport agent.

In most B<sendmail> configurations, either the local B<sendmail> must
be configured to relay messages, or have a I<smart host> defined.  The
comments in the F<.ecconfig> file describe only a few of the possible
settings.  Refer to the B<sendmail> documentation for further
information.

The B<exim> configuration (selected by setting C<useexim> to non-zero)
is similar to B<sendmail>, B<exim> allows mail routing to a remote
I<smart host> without setting a From: domain address in ec, if the
system administrator created an entry for the domain mail address in
F</etc/email-addresses>.

If the B<useqmail> option is set, make sure that you can execute the
F<qmail-inject program>, which is F</var/qmail/bin/qmail-inject> in
qmail's default configuration.  Ec still connects directly to an ISP's
POP3 server, and uses the system UNIX mailbox, usually
F</var/spool/mail/E<lt>userE<gt>>, for incoming messages.

The qmail-inject I<-f> option is not implemented.  The format of the
sender's return address can be set using environment variables.  Refer
to the B<qmail-inject> manual page for information.

=head2 Editing the Library Path Names in the Source File

If you would like to change the path names of library files, use a
text editor to edit the values of C<$iconpath>, C<$cfgfilename>,
C<$serverfilename>, and C<$base64enc> at the beginning of the library
modules they appear in.

The C<expand_path> function expands leading tildes ('~') in file and
path names to the value of the F<$HOME> environment variable,
following the convention of the UNIX Bourne shell.  Directory
separators are forward slashes ('/'), so compatibility with non-UNIX
file systems depends on the Perl environment to perform the path name
translation.

=head2 X Fonts

Consult the file, F<README> for information about setting X Window
System font resources, and the comments in F<.ecconfig> for setting
fonts with the program's configuration options.

=head1 Maintenance

=head2 Folder Indexes

Although ec attempts to maintain an accurate index of read and unread
messages in each folder, it is possible, if you upgrade to a later 
version, or backup and then delete messages manually, that the folder
indexes will not match the actual contents of the folder.  

In this case, you must delete the file named F<.index> in each of the 
folders.  For example, to delete the indexes in the Incoming and
F<Trash> folders, use these commands:

  # rm Mail/incoming/.index
  # rm Mail/trash/.index

If ec does not find the F<.index> file it will, as when you first ran
the program, display a message that it is creating a new F<.index>
file.  The messages themselves are not affected, but you need to
select them again to prevent the program from showing their status as
I<u> for, "unread."

=head1 PRINTING THE DOCUMENTATION IN DIFFERENT FORMATS

It is possible produce this documentation in various formats
using Perl's POD formatting utilities:

  pod2html <ec >doc.html
  pod2latex <ec >doc.tex
  pod2man <ec >doc.man
  pod2text <ec >doc.txt
  pod2usage <ec >doc.hlp

Refer to your system's manual pages for instructions of how
to use these utilities.

=head1 LICENSE

Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.

Ec is licensed under the same terms as Perl. Please refer to the file,
"Artistic."

$Id: ec,v 1.7 2004/03/02 22:29:54 kiesling Exp $

=head1 SEE ALSO

perl(1), Tk(1)

=head1 CREDITS

  Windows-specific routines written by Roland Bauer.

  The POP server interface is based on:
  POPMail Version 1.6 (RFC1081) Interface for Perl,
      Written by:
      Kevin Everets <flynn@engsoc.queensu.ca>
      Abhijit Kalamkar <abhijitk@india.com>
      Nathan Mahon <vaevictus@socket.net>
      Steve McCarthy <sjm@halcyon.com>
      Sven Neuhaus <sven@ping.de>
      Bill Reynolds <bill@goshawk.lanl.gov>
      Hongjiang Wang <whj@cs-air.com>

=cut
