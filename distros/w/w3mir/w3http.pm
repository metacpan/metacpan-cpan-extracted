# -*- perl -*-
# w3http.pm	--- send http requests, janl's 12" mix for w3mir
#
$VERSION=1.0.23;
#
# This implements http/1.0 requests.  We'll have problems with http/0.9
# This is in no way specific to w3mir.
#
# IMPORTANT: The caller should initialize the C locale for some of the
#   things here to work correctly (specifically the strftime function).
#
# This is a rewrite of http.pl by Oscar Nierstrasz; I copied the code he he
# copied from the camel book.  Some functions written by Gorm Haug Eriksen
# (gorm@usit.uio.no) has been used as is.
#
# Contributors:
#   Nicolai Langfeldt, janl@ifi.uio.no
#   Gorm Haug Eriksen, gorm@usit.uio.no
#   Chris Szurgot, szurgot@itribe.net
#   Bernhard Weisshuh, bkw@weisshuhn.de
# Copying and modification is governed by the "Artistic License" enclosed in
# the w3mir distribution
#
# gorm :
# &w3http::get_last_modified  return the last modified stamp on a file in
#                         the right format for use with http
#
# janl:
# &http::query: Send a http query.  A completely general function to send a
#   http query.  Will extract header values, http response code and, optionaly,
#   convert text files to local linefeed format.
#
# Variables to examine after a query
# $w3http::document: The document returned by the query, if any.
# $w3http::doclen: The length of the document
# $w3http::result: The numerical http result code.  It may take these values:
# - Normal HTTP reply codes
# -  98: OS error, permanent, errormessage in $!
# -  99: Other permanent error: see $restext.
# - 100: Transient error: Timeout/connection broken
# $w3http::restext: The english(?) HTTP result or w3http generated message
# $w3http::header: The http header returned.
# $w3http::plaintexthtml: 1 if this doc is non-content-encoded text/html
#	(as opposed to content-encoding: compressed content-type: text/html
#       which needs decompression before we can inspect the html) 
#	The tests are somewhat longwinded so I do it just once here.
# %w3http::headval: Associative array of header values
# $w3http::headval{'CONTENT-TYPE'}: Derived content type, stripped of charset
#		qualifiers and other distractions.
# $w3http::xfbytes: Transfered bytes, cumulative.  Document part only.
# $w3http::headbytes: Bytes of headers received, cumulative.
#
# Variables that change http's behaviour/requests:
# $w3http::agent: User agent, default is basename of $0
# $w3http::from: Request is from, default is user@host
# $w3http::version: The http version to use, only 1.0 is known to me.
# $w3http::timeout: How long to wait for new data to arrive, default is 600sec
# $w3http::buflen: Network read buffer size, default is 4096.  It might give a
#	speedup to tune this for specific servers' so it matches their send
#	size.  This size can be detected if we want to, I think.
# $w3http::debug: 1 debuging output, 2, more, 3 queries and replies
# $w3http::verbose: 0: say nothing, 1: print progress info
# $w3http::convert: Convert text/* documents to local newline convention?
#	The default is to do it.
# $w3http::proxyserver: The name of the proxyserver to use.
# $w3http::proxyport: The port of the proxyserver to use. 0 if no proxyserver.
# $w3http::proxyuser: If this is set proxy authentication will be used.
# $w3http::proxypasswd: The password for proxy authentication
#
# Things gotten from main:
# - $main::win32: 1 if win32 restrictions apply to this system
# - $main::nulldevice: Bit sink file/device on this system.
#
# History (european date format dd/mm/yy):
#     janl ??/??/95 -- Rewrite finished
#  szurgot ??/??/95 -- Win32 compatability
#     janl 16/05/96 -- Added SAVEBIN option, based on idea by szurgot
#  szurgot 03/05/96 -- Corrected typo in check for content-length against
#                      retreive document length. Added test for zero-length
#		       documents (Not retreived because not-modified)
#  szurgot 19/05/96 -- Win32 adaptions, fixes.
#     janl 19/05/96 -- Chris won an argument, and janl simplified http 
#		       retrival loop (-> version 1.0.4)
#     janl 09/09/96 -- Incorporated a patch submited by Michael Kriby -> 1.0.5
#     janl 16/09/96 -- Support for authorization. -> 1.0.6
#     janl 27/09/96 -- Support for Accept header, lack pointed out by
# 			charles@ermine.ox.ac.uk: ... HTTP/1.1 (§14.1) says 
#			``If no Accept header field is present, then it is
#			assumed that the client accepts all media types,
#			earlier versions of the protocol suggest that only
#			text/plain and text/html will be offered by default.''
#			This contradicts my memory of a http/1.0 draft.
#			Also added $ACCEPT option.
#     janl 20/10/96 -- Now uses HTTP::Date to produce HTTP timestamps -> 1.0.7
#     janl 27/10/96 -- Didn't use to check if gethostbyname worked -> 1.0.8
#     janl 02/12/96 -- Forgot a unlink when renaming temporary files.
#     janl 21/02/97 -- Multipele $ACCEPT options work. -> 1.0.9
#     janl 19/03/97 -- Now issues Host: header -> 1.0.10
#     janl 10/04/97 -- Changed from wwwurl to URI::URL, and various related
#                      changes. -> 1.0.11
#     janl 09/05/97 -- Microsoft ISS servers are _so_ broken -> 1.0.12
#                      (don't close the write end of the HTTP socket after
#			sending a query to them)
#     janl 12/05/97 -- New version of perl caught some typos, fixed
#			longstanding bug in the newline conversion bit.
#			-> 1.0.13
#     janl 06/06/97 -- Demand Loading of MIME::BASE64 -> 1.0.14
#     janl 01/12/97 -- FAT filesystems drops LSB of modtime.  Patch from
#			Greg Lindhorst (gregli@microsoft.com)
#                   -- whoami does not exist on win32, hardwire a default
#			value (unknown) (also Greg L.) -> 1.0.15
#     janl 01/22/98 -- Proxy authentication as outlined by Christian Geuer
#     janl 02/20/98 -- Complex 'content-type' headers handled. -> 1.0.17
#     janl 04/20/98 -- Only newline convert text/html, everything else is
#			handled as binary. -> 1.0.18
#     janl 12/05/98 -- Store tmpfile in its final destination directory
#			avoiding asking movefile move it across filesystems.
#			-> 1.0.19
#     janl 01/08/98 -- Timeout fix from Michael Gusev, also flag short doc
#			as error.
#     janl 24/09/98 -- Better error handling -> 1.0.20
#     bkw  17/12/98 -- Fixed problem with tempfile-generation when
#                      running in forget-mode (-f)
#     janl 05/01/99 -- Referer: dropped if argument not true -> 1.0.21
#     janl 13/04/99 -- Added workaround for broken win32 perl resolving.
#     janl 15/01/00 -- Patch to adapt to URI 1.0 from Takuya Tsumura and
#                      Andrey A. Chernov
#     ams  02/02/01 -- Handle URLs with spaces better (use epath)

package w3http;

require 5.002;
use Socket;
use HTTP::Date;
use Sys::Hostname;
use URI::URL;

# Suplementary libwww-perl:
sub URI::URL::_generic::basename {
  my $self = shift;
  my @p = $self->path_components;
  my $old = $p[-1];
  if (@_) {
    splice(@p, -1, 1, shift);
    $self->path_components(@p)
  }
  $old;
}

# The URI 1.0 library changed the internal organization a bit
# Thanks to Andrey A. Chernov for the patch!

sub URI::_generic::basename {
  my $self = shift;
  my @p = $self->path_segments;
  my $old = $p[-1];
  if (@_) {
    splice(@p, -1, 1, shift);
    $self->path_segments(@p)
  }
  $old;
}


END { 
  # Remove tmp file and such in here.  That means that main:: gotta catch
  # interrupt signals and exit on them, so ENDs are executed.
}

use strict;
# Global variables, we want to share them:
use vars qw($GET $HEAD $GETURL $HEADURL $IFMOD $IFMODF $AUTHORIZ $REFERER);
use vars qw($SAVEBIN $ACCEPT $NOUSER $FREEHEAD $agent $version $timeout);
use vars qw($debug $convert $proxyserver $proxyport $xfbytes $headbytes);
use vars qw($verbose $result $restext $header $document);
use vars qw($plaintexthtml %headval $progress $doclen $proxyuser);
use vars qw($proxypasswd);

my $hasAlarm;   # Win32 does not have any alarm
my $chime;	# Has the alarm gone off yet?
my %address;	# My own DNS cache
my $savALRM;	# Saved ALRM handler
my $savPIPE;	# Saved PIPE handler

# The main:: program should detect if we're running on win32 or not,
# somehow
if ($main::win32) {
  warn "win32\n";
  # Compensate for lacks of win32 perl. 
  $hasAlarm=0;
  # Seems to be unavailable in win32/perl5.001.  It has to be in 5.003!
#  eval "sub sockaddr_in {
#	($port, $thataddr) = @_;
#	$sockaddr = 'S n a4 x8';
#	return pack($sockaddr, &AF_INET, $port, $thataddr);
#    }";
} else {
  $hasAlarm=1;
}


# Find out some things
my $thishost = hostname();
my $proto = getprotobyname("tcp");

(my $name, undef) = gethostbyname($thishost);
chomp(my $user = $ENV{'LOGNAME'} || $ENV{'USER'} || `whoami` || 'unknown');
my $from   = "$user\@$name";

my $nl = "\r\n";
# Default values, change by assignment in using-program.
$agent  = $0; $agent =~ s~.*/~~; # Basename 
$version= "1.0";
$timeout= 600;			# Timeout while waiting for data/connection
my $buflen = 4096;		# recv buffer length
$debug = 0;			# Debuging output?
$convert = 1;			# Convert newlines of text docs to local format
$proxyserver='';		# Proxy server.
$proxyport=0;			# Proxy server port. 0 if no proxy.
$proxyuser='';			# Username for proxy authentication
$proxypasswd='';		# Password for proxy authentication
$xfbytes=0;			# 0 bytes transfered, cumulative
$headbytes=0;			# 0 bytes of headers, cumulative
$doclen=0;			# 0 bytes in doc, pr. document
my $tmpfile="w3mir$$.tmp";	# Temporary filename
$verbose=0;			# Verbosenes, 0: silent, 1: progress info

# Query opcodes
$GET = 1;			# GET query. Arg: host,port,path
$HEAD = 2;			# HEAD query. Arg: host,port,path
$GETURL = 3;			# GET query. Arg: url
$HEADURL = 4;			# HEAD query. Arg: url
# Here we lack PUT, which is not implemented
# Modify query thus:
$IFMOD = 101;			# If-modified after: Arg: HTTP-date-str
$IFMODF = 102;			# If-modified after file: Arg: local-file-name
$AUTHORIZ= 103;			# Basic authorization. Arg: 'user:password'
$REFERER = 104;			# Referer: Arg: Referer 
$SAVEBIN = 105;			# Write binary files to disk. Arg: File name
				# If this opcode is used then main must provide
				# a &main::movefile(oldname,newname) procedure
				# that handles moving the tmp file to the
				# final name/location.
$ACCEPT  = 106;			# Accept header value: Arg: value
$NOUSER  = 107;			# Don't insert user header.  Arg: none
$FREEHEAD= 999;			# Freeform header, one line.  Arg: header

sub query {
  # Build and send a HTTP query.  And also receive response - janl 95/09/18
  #
  # Return codes: 0 if it didn't work.  1 if it did work.
  # HTTP style result code in w3http::$result and message in w3http::$restext
  
  # We do next to no argument type checking btw.
  
  my($host,$port,$request,$query,$method,$inp,$linp,$saveto,$save,$arg);
  my($start,$wantbytes,$thataddr,$err,$headb,$tmpf,$ldoc,$nouser,$q,$accept);
  my($origreq,$req_o,$plaintext);
  
  # Something ought to be said
  $result=99;
  $restext='w3http: internal error';
  $nouser=0;
  
  if ($version ne '1.0') {
    warn "Unknown HTTP version $version, no request sent\n";
    return 0;
  }
  
  $accept=$saveto=$query='';
  
  # Find out what to ask for
  
  while (defined($arg=shift)) {
    if ($arg == $GET) {
      $host=shift;
      $port=shift;
      $request=shift;
      $req_o=url 'http://'.$host.':'.$port.$request;
      if ($proxyport) {
	$query.='GET http://'.$req_o->as_string;
      } else {
	$query.='GET '.$req_o->epath;
      }
      $query.=' HTTP/'.$version.$nl;
    } elsif ($arg == $HEAD) {
      $host=shift;
      $port=shift;
      $request=shift;
      $req_o=url 'http://'.$host.':'.$port.$request;
      if ($proxyport) {
	$query.='HEAD '.$req_o->as_string;
      } else {
	$query.='HEAD '.$req_o->epath;
      }
      $query.=' HTTP/'.$version.$nl;
    } elsif ($arg == $GETURL) {
      $req_o=shift;
      $req_o=url $req_o unless ref $req_o;
      ($method,undef,undef,$host,$port,$request,undef,$q) = $req_o->crack;
      if ($proxyport) {
	$query.='GET '.$req_o->as_string;
      } else {
	$q=$req_o->equery;
	$query.='GET '.($req_o->epath).($q?"?$q":'');
      }
      $query.=' HTTP/'.$version.$nl;
    } elsif ($arg == $HEADURL) {
      $req_o=shift;
      $req_o=url $req_o unless ref $req_o;
      if ($proxyport) {
	$query.='HEAD '.$req_o->as_string;
      } else {
	$q=$req_o->equery;
	$query.='HEAD '.$req_o->epath.($q?"?$q":'');
      }
      $query.=' HTTP/'.$version.$nl;
    } elsif ($arg == $IFMOD) {
      $query.='If-Modified-Since: '.(shift).$nl;
    } elsif ($arg == $IFMODF) {
      $query.='If-Modified-Since: '.&last_modified(shift).$nl;
    } elsif ($arg == $AUTHORIZ) {
      # Demand-load MIME::Base64
      if (!defined(&MIME::Base64::encode)) {
	eval "use MIME::Base64;";
	die "w3http: Could not load MIME::Base64 module necessary for authentication\n"
	  unless defined(&MIME::Base64::encode);
      }
      $query.='Authorization: Basic '.MIME::Base64::encode(shift,'').$nl;
    } elsif ($arg == $REFERER) {
      my($referer)=shift;
      $query.='Referer: '.$referer.$nl if $referer;
    } elsif ($arg == $SAVEBIN) {
      $saveto=shift;
    } elsif ($arg == $ACCEPT) {
      $accept.='Accept: '.(shift).$nl;
    } elsif ($arg == $NOUSER) {
      $nouser=1;
    } elsif ($arg == $FREEHEAD) {
      $query.=(shift).$nl;
    } else {
      warn "Unknown http query opcode: $arg\n";
    } 
    # Insert the last parts of the query:
  }
  
  $query.='Host: '.$req_o->netloc.$nl;
  $query.='From: '.$from.$nl unless $nouser;

  $accept='Accept: */*'.$nl unless $accept;

  if ($proxyport) {
    # Use proxy instead of originserver
    $host=$proxyserver;
    $port=$proxyport;

    # Add authentication stuff to query
    if ($proxyuser) {
      # Demand-load MIME::Base64
      if (!defined(&MIME::Base64::encode)) {
	eval "use MIME::Base64;";
	die "w3http: Could not load MIME::Base64 module necessary for authentication\n"
	  unless defined(&MIME::Base64::encode);
      }
      
      $query.='Proxy-Authorization: Basic '.
	MIME::Base64::encode($proxyuser.':'.$proxypasswd);

      print STDERR "\nProxyuser: [$proxyuser]\nProxypasswd: [$proxypasswd]\n"
	if $debug>=2;
    }
  }
  
  $query.='User-Agent: '.$agent.$nl.$accept.$nl;
  
  # If we're using proxy then set up things...
  print STDERR "\nQUERY:\n",$query,"---\n" if $debug>=2;

  # win32 fix: this should be added in case of troubles with
  # gethostbyname. possible reason: nameserver down?
  if ($host =~ /^\d+(\.\d+){3}$/) {
    # in case gethostbyname will not work ... ;-)
    $address{$host} = pack 'C4', (split /\./, $host);
  }
  
  # Find out who to ask, check if we know already
  if (exists($address{$host})) {
    # We know
    $thataddr=$address{$host};
  } else {
    # Cache miss, get and remember.
    (my $fqdn, undef, undef, undef, $thataddr) = gethostbyname($host);
    # Hostname lookup failure?  Cache even misses.
    if (defined($fqdn)) {
      print STDERR "Lookup of $host:\nFQDN: $fqdn\n"
	if $debug;
      $address{$host}=$thataddr;
      $address{$fqdn}=$thataddr if $fqdn ne $host;
    } else {
      $thataddr=$address{$host}=undef;
    }
  }    

  # Check if lookup failure, return
  if (!defined($thataddr)) {
    $restext='Host lookup failure';
    return;
  }

  $port=80 unless defined($port) && $port;

  # When connected we might receive SIGPIPE.  I'm not sure if the
  # default behaviour of dying is beneficial in that case.  If we get
  # alarm a timeout has expired.
  $savPIPE = $SIG{'PIPE'};
  $savALRM = $SIG{'ALRM'};

  $chime=0;			# There has been no alarm yet
  $SIG{'ALRM'} = \&timeout;
  $SIG{'PIPE'} = \&ignore;

  # Close the socket, just in case, and ignore error returns
  close(FS);
  
  socket(FS, AF_INET, SOCK_STREAM, $proto) or return &oserror;
  warn "Got my socks on\n" if $debug;
  
  my $paddr = sockaddr_in($port, $thataddr);
  connect(FS, $paddr) or return &oserror;
  warn "Connected\n" if $debug;
  
  # Arrange timeout
  alarm($timeout) if $hasAlarm;
  
  # We have, in fact, received SIGPIPE on this line:
  send(FS,$query,0) or return &oserror;

  if ($chime) {
    $result=100;
    $restext='timeout sending query';
    return &resetsign;
  }
  
  $header='';
  $document='';
  $inp=' 'x$buflen;
  $doclen=$chime=$plaintext=$plaintexthtml=$save=0;

  # Breaks some M$ ISS servers:
  # shutdown(FS,1);  # Half-close socket, sending now not allowed
  
  print STDERR ", receiving header" if $verbose>0;
  
  # Retrive HTTP response HEADER.  Why do I use recv and not <FS>?
  # Because then the timeout can work correctly!
  while (1) {
    # Set up alarm to ensure recv returns within a reasonable timeframe
    alarm($timeout) if $hasAlarm;
    $err = recv(FS,$inp,$buflen,0);
    # recv returned, cancel alarm.
    alarm(0) if $hasAlarm;
    
    # If there has been a timeout, then we quit now.  The recv man page
    # does not seem to allow recv to return the bytes received up to
    # the timeout.
    if ($chime) {
      $result=100;  
      $restext='timeout fetching document';
      $!=0;
      if ($save) {
	unlink($tmpf) || 
	  warn "Could not unlink $tmpf: $!\n";
      }
      return &resetsign;
    }
    
    # recv returnes the undefined value on error
    if (!defined($err)) {
      warn "Error in recv: $!\n";
      last;
    }
    
    $linp=length($inp);
    
    # If the returned input was 0 in length then we've gotten to the 
    # end of the response.
    last unless $linp;
    
    # Accounting
    $xfbytes += $linp;
    $doclen += $linp;
    
    # Accumulate input
    $header.=$inp;

    # eof(SOCKET) has strange semantics it seems
    # last if eof(FS);
    
    # Check if header is complete
    last if ($header =~ m/(\r?\n\r?\n)/);
  }

  my $orighead = $header;
  
  if (length($header)==0) {
    $restext='the HTTP reply header is empty!';
    return &resetsign;
  }

  if ($header =~ m/(\r?\n\r?\n)/) {
    if ($`) {
      $header=$`;
      $document=$';
    }
  }
  
  # Adjust accounting
  $headb = length($header)+length($1);
  $headbytes += $headb;
  $xfbytes -= $headb;
  $doclen -= $headb;
  
  # Pick headers to pieces
  ($result,$restext,%headval)=&analyze_header($header);

  if (!$result) {
    print "\n\nw3mir: BOGUS HTTP REPLY:\n-----\n$header\n-----\n";
    print "\n\nw3mir: UNPROCESSED REPLY:\n-----\n$orighead\n-----\n";
    print "\nw3mir: QUERY WAS:\n-----\n$query\n-----\n";
    die;
  }
  
  print STDERR "REPLY:\n",$header,"\n---\n" if $debug>=2;

  # Check if the document is a non-encoded text document. The contents
  # could be (x-)?compress or (x-)gzip coded (compressed in other
  # words).
  
  $plaintext=defined($headval{'CONTENT-TYPE'}) &&
    (substr($headval{'CONTENT-TYPE'},0,5) eq 'text/' || 0) &&
      !defined($headval{'content-encoding'});
  $plaintexthtml=$plaintext && 
    ($headval{'CONTENT-TYPE'} eq 'text/html');

  if ($result==200) {
    
    # Save this to a file, or not?  Never save html files.
    if ($saveto && !$plaintexthtml) {
      # We're going to save this document directly into a file.  This
      # stresses the VM less when getting the large binares so often
      # found at cool sites.
      $save=1;

      # Find a temporary filename
      $tmpf=url "file:$saveto";
      $tmpf->basename($tmpfile);
      $tmpf=$tmpf->unix_path;
      
      # Find suitable final filename, one with no URL escapes
      $saveto=(url "file:$saveto")->unix_path;

      # If output to stdout then send it directly there rather than
      # using disk unnecesarily.
      $tmpf='-' if ($saveto eq '-');

      # If output is nulldevice (running -f), use it also for tmpfile,
      # since it would otherwise try to create it in /dev under unix.
      $tmpf=$main::nulldevice if ($saveto eq $main::nulldevice);
      
      warn "USING TMPFILE: $tmpf\n" if $debug;
      
      open(SAVE,">$tmpf") || 
	die "Could not open tmp file: $tmpf: $!\n";
      binmode SAVE;		# It's a binary file...
    }
    
    if ($verbose>0) {
      print STDERR ", document";
      print STDERR "->disk" if $save;
    }
    
    # Now retrive document itself.  Se comments in header loop
    $start=time;
    $wantbytes = defined($headval{'content-length'})?
      $headval{'content-length'}:0;
    
    $ldoc=length($document);
    
    while (1) {
      alarm($timeout) if $hasAlarm;
      recv(FS,$inp,$buflen,0);
      alarm(0) if $hasAlarm;
      
      if ($chime) {
	$result=100;
	$restext='timeout fetching document';
	$!=0;
	if ($save) {
	  unlink($tmpf) || 
	    warn "Could not unlink $tmpf: $!\n";
	}
	return &resetsign;
      }
      
      $linp=length($inp);
      
      last unless $linp || $ldoc;
      $ldoc = 0;
      
      $xfbytes += $linp;
      $doclen += $linp;
      
      if ($verbose>0 && time-$start>5) {
	# Write progress info ... 
	if ($wantbytes) {
	  $progress = sprintf " %3d%%", $doclen/$wantbytes*100;
	} else {
	  $progress = sprintf " %d", $doclen;
	}
	print STDERR $progress, "\ch"x(length($progress));
	# ...every 5 seconds
	$start=time;
      }
      
      $document.=$inp;
      
      if ($save) {
	$err = print SAVE $document;
	die "Error writing $tmpf: $!\n" unless $err;
	$document='';
      }

      # The eof test seems to work very oddly for sockets.
      # last if eof(FS);
    }

    close(FS);  # Close socket completely
    
    print STDERR "DOCUMENT:\n----\n",$document,"\n----\n" if $debug>=255;
  
    if ($wantbytes &&
	$wantbytes != $doclen) {
      $result=100;
      $restext='transfer error; too many bytes in document';
      $restext='document was incomplete' if ($wantbytes > $doclen) ;
      print STDERR "SHORT DOCUMENT" if $debug>=16;
      if ($save) {
	unlink($tmpf) || warn "Could not unlink $tmpf: $!\n";
      }
      return &resetsign;
    }
    
    # warn "XFB: $xfbytes, DL: $doclen\n";
    if ($save) {
      close(SAVE);
      &main::movefile($tmpf,$saveto);
    }
    
    # If this is a non-encoded text file and we're supposed to convert
    # foreign newlines then we do it. It would be faster to do this
    # with each chunk of input in the input loop, but this gives us
    # two problems:
    # - A \r\n newline could be split into two chunks.  Thus escaping
    #   newline conversion.
    # - It messes up the received bytes accounting rather badly.
    #
    # This used to be a test for $plaintext, the problem is that too
    # many documents were typed as text/plain and so we corrupted
    # binary files. This is bad. So now we're more paranoid about it:
    # Only HTML gets converted.
    if ($convert && $plaintexthtml) {
      # Change non unix newlines to unix newlines. bare \r is known
      # from macintosh (they hadta be different didn't they?), \r\n is
      # known as 'network format' and from numerous systems, among
      # them ms-dos.
      $document =~ s~\r~\n~g unless $document =~ s~\r\n~\n~g;
      warn "Newlines converted(?)\n" if $debug;
    }
    
  }				# if $result == 200
  
  &resetsign;
  return 1;
}


sub analyze_header {
  my($header)=@_;
  my($result,$restext,%headval,$hdln,$key,$value);
  
  # Summary of the http spec on headers (with my comments):
  # - Each header line ends in CRLF (or just LF, or maybe even just CR,
  #   anyways, it's easier if all is LF).
  $header =~ s/\r/\n/mg unless $header =~ s/\r\n/\n/mg;
  # - If a line starts with space then it's a continuation of the previous
  #   line (these I fold into one line).
  $header =~ s/\n\s/ /mg;
  # - The header field names are case insensitive (so I convert them to
  #   lowercase)
  # - A field may appear twice, that is equivalent to listing the values
  #   in a comma separated list (so I fold them into a comma separated list)n
  # - The field name and the field value are separated by ': '
  ($result,$restext) = $header =~ m~^HTTP/\d\.\d (\d\d\d) (.*)~;
  # Shave off http result code from the header
  $header =~ s~^.*\n~~;
  
  warn "Header:\n$header\n---\n" if $debug>=3;
  
  warn "Result: $result, Text: $restext\n" if $debug>=2;
  
  %headval=();
  
  foreach $hdln (split(/\r?\n/m,$header)) {
    ($key,$value)=split(': ',$hdln,2);
    $key="\L$key";
    # Strip leading&trailing space off the reply, some servers use
    # copious space after.
    $value =~ s/^\s+|\s+$//g;
    print STDERR "K: '$key', V: '$value'\n" if $debug>=2;
    if (defined($headval{$key})) {
      $headval{$key}.=", ".$value;
    } else {
      $headval{$key}=$value;
    }
  }

  # See if there are any type parameters in the content-type header
  # and if so remove them.
  if (defined($headval{'content-type'})) {
    my $val=$headval{'content-type'};
    ($val,undef)=split(';',$val,2) if ($val =~ /;/);
    $headval{'CONTENT-TYPE'}=$val;
  }
  
  return ($result,$restext,%headval);
}


sub last_modified {
  # will return the last modified time for a local file as a HTTP
  # timestamp.
  
  my(@tmp) = stat($_[0]);	# file doesn't exist ok to fetch

  # FAT file systems strip the LSB of the file time.  Add it back in
  # here before asking the server about a modified file.  The only way
  # this can fail is if the newer server file was saved one second
  # after the first version (very unlikely).  This isn't needed for
  # NTFS file systems, but there is no good portable Perl way to
  # determine the file system type.
  $tmp[9] = $tmp[9] | 1 if ( $main::win32 );

  # now we got the last modified in a 32 bit integer.  time to convert
  # it and return
  return time2str($tmp[9]);
}


sub timeout {
  # Set timeout flag.  The using procedure has to set other result codes.
  $chime=1;			# When this is 1 then the alarm has gone off
  print STDERR "TIMEOUT!!!!\n" if $debug>=16;
}


sub ignore {
  warn "I got SIGPIPE, ignoring it...\n";
}


sub resetsign {
  return 0 if !defined($savALRM);
  $SIG{'ALRM'}=$savALRM;
  undef $savALRM;
#  $SIG{'PIPE'}=$savPIPE;
  return 0;
}


sub oserror {
  
  resetsign;

  $result=98;
  $restext='w3http: OS error';
  return 0;

}


1;
