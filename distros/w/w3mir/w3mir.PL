# -*-perl-*-

use Config;

&read_makefile;
$fullperl = resolve_make_var('FULLPERL') || $Config{'perlpath'};
$islib = resolve_make_var('INSTALLSITELIB');

$name = $0;
$name =~ s~^.*/~~;
$name =~ s~.PL$~~;

open(OUT,"> $name") || 
  die "Could open $name for writing: $!\n";

print "writing $name\n";

while (<DATA>) {
  if (m~^\#!/.*/perl.*$~o) {
    # This substitutes the path perl was installed at on this system
    # _and_ removed any (-w) options.
    print OUT "#!",$fullperl,$1,"\n";
    next;
  }
  if (/^use lib/o) {
    # This substitutes the actuall library install path
    print OUT "use lib '$islib';\n";
    next;
  }
  print OUT;
}

close(OUT);

# Make it executable too, and writeable
chmod 0755, $name;

#### The library

sub resolve_make_var ($) {

  my($var) = shift @_;
  my($val) = $make{$var};

#  print "Resolving: ",$var,"=",$val,"\n";
  
  while ($val =~ s~\$\((\S+)\)~$make{$1}~g) {}
#  print "Resolved: $var: $make{$var} -> $val\n";
  $val;
}


sub read_makefile {

  open(MAKEFILE, 'Makefile') || 
    die "Could not open Makefile for reading: $!\n";

  while (<MAKEFILE>) {
    chomp;
    next unless m/^([A-Z]+)\s*=\s*(\S+)$/;
    $make{$1}=$2;
#    print "Makevar: $1 = $2\n";
  }

  close(MAKEFILE)
}

__END__
#!/usr/bin/perl -w
# Perl 5.002 or later.  w3mir is mostly tested with perl 5.004
#
use lib '/hom/janl/lib/perl';
#
# Once upon a long time ago this was Oscar Nierstrasz's
# <oscar@cui.unige.ch> htget script.
#
# Retrieves HTML pages, creating local copies in the _current_ 
# directory. The script will check for the last-modified stamp on the
# document, and will not fetch it if the document isn't changed.
#
# Bug list is in w3mir-README.
#
# Test cases for janl to use:
#   w3mir -r -fs http://www.eff.org/ - infinite recursion!
#     --- but cursory examination seems to indicate confused server...
#   http://java.sun.com/progGuide/index.html check out the img things.
#
# Copyright Holders:
#   Nicolai Langfeldt, janl@ifi.uio.no
#   Gorm Haug Eriksen, gorm@usit.uio.no
#   Chris Szurgot, szurgot@itribe.net
#   Ed Jordan, ed@olympus.itl.net
#   Alex Knowles, aknowles@avs.com aka ark.
# Copying and modification is governed by the "Artistic License" enclosed in
# the w3mir distribution
#
# History (European format date: dd/mm/yy):
#  oscar 25/03/94 -- added -s option to send output to stdout
#  oscar 28/03/94 -- made HTTP 1.0 the default
#  oscar 30/05/94 -- special handling of directory URLs missing a trailing "/"
#   gorm 20/02/95 -- added mirror capacity + fixed a couple of bugs
#   janl 28/03/95 -- added a working commandline parser.
#   janl 18/09/95 -- Changed to use a net http library.  Removed dependency of
#		     url.pl.
#   janl 19/09/95 -- Extensive rewrite. Simplified a lot, works better. 
#		     HTML files are now saved in a new and improved manner,
#		     which means they can be recognized as such w/o fancy
#		     filename extention type rules.
# szurgot 27/01/96-- Added "Plaintextmode" wrapper to binmode PAGE. 
#                    binmode page is required under Win32, but broke modified
#                    checking
#                 -- Minor change added ; to "# '" strings for Emacs cperl-mode
# szurgot 07/02/96-- When reading in local file for checking of URLs changed
#                    local ($/) =0; to equal undef;
#   janl 08/02/96 -- Added szurgot's changes and changed them :-)
# szurgot 09/02/96-- Added code to strip /#.*$/ from urls when reading from 
#                    local file
#                 -- Added hasAlarm variable to w3http.pl. Set to 1 if you have
#                    alarm(). 0 otherwise.
#                 -- Moved code setting up the valid extensions list into the
#                    args processing where it belonged
#   janl 20/02/96 -- Added szurgot changes again.
#		  -- Make timeout code work.
#   		  -- and made another win32 test.
#   janl 19/03/96 -- Worked through the code for handling not-modified 
#    		     documents, it was a bit shabby after htmlop was intro'ed.
#   janl 20/03/96 -- -l fix
#   janl 23/04/96 -- Added -fs by request (by Rik Faith)
#   janl 16/05/96 -- Made -R mandatory, added use and support for
#			w3http::SAVEBIN
# szurgot 19/05/96-- Win95 adaptions.
#   janl 19/05/96 -- -C did not exactly work as expected.  Thanks to Petr
#		     Novak for bug descriptions.
#   janl 19/05/96 -- Changed logic for @didntget, @got and so on to use
#		     @queue and %urlstat.
#   janl 09/09/96 -- Removed -R switch.
#   janl 14/09/96 -- Added ir (initial referer) switch
#   janl 21/09/96 -- Made retry code saner.  There probably needs to be a
#                    sleep before retry comencing switch.  When no tty is
#                    present it should be fairly long.
#   gorm 15/09/96 -- Added cr (check robot) switch. Default to 1 (on)
#   janl 22/09/96 -- Modified gorms patch to use WWW::RobotRules.  Changed
#		     robot switch to be consistent with current w3mir
#                    practice.
#   janl 27/09/96 -- Spelling corrections from charles.curran@ox.ac.uk
#                 -- Folded in manual diffs from ark.
#    ark 24/09/96 -- Simple facilities to edit the incomming file(s)
#   janl 27/09/96 -- Added switch to enable <!--NOMIRROR--> editing and
#		     foolproofed ark's patch a bit.
#   janl 02/10/96 -- Added -umask switch.
#		  -- Redirected documents did not have a meaningful referer
#		     value (it was undefined).
#		  -- Got w3mir into strict discipline, found some typos...
#   janl 20/10/96 -- Mtime is preserved
#   janl 21/10/96 -- -lc switch added.  Mtime preservation works better.
#   janl 06/11/96 -- Treat 301 like 302.
#   janl 02/12/96 -- Added config file code, fetch/ignore rules, apply
#   janl 04/12/96 -- Better checking of config input.
#   janl 06/12/96 -- Putting together the URL selection/editing brains.
#   janl 07/12/96 -- Checking out some bugs.  Adding multiscope options.
#   janl 12/12/96 -- Adding to and defeaturing the multiscope options.
#   janl 13/12/96 -- Continuing work in multiscope stuff
#                 -- Unreferenced file and empty directory removal works.
#   janl 19/02/97 -- Can extract urls from adobe acrobat pdf files :-)
#		     Important: It does _not_ edit urls, so they still
#		     point at the original site(s).
#   janl 21/02/97 -- Fix -lc bug related to case and the apply things.
#		  -- only use SAVEURL if needed
#   janl 11/03/97 -- Finish work on SAVEURL conditional.
#		  -- Fixed directory removal code.
#                 -- parse_args did not abort when unknown option/argument
#		     was specified.
#   janl 12/03/97 -- Made test case for -lc.  Didn't work.  Fixed it.  I think.
#		     Realized we have bug w.r.t. hostname caseing.
#   janl 13/03/97 -- All redirected to URLs within scope are now queued.  
#		     That should make the mirror more complete, but it won't
#		     help browsability when it comes to the redirected doc.
#		  -- Moved robot retrival to the inside of the mirror loop
#		     since we now possebly mirror several sites.
#		  -- Changed 'fetch-options' to 'options'.
#                 -- Added 'proxy-options'/-pflush to controll proxy server(s).
#   janl 09/04/97 -- Started using URI::URL.
#   janl 11/04/97 -- Debugging and using URI::URL more correctly various places
#   janl 09/05/97 -- Added --agent switch
#   janl 12/05/97 -- Simplified scope checks for root URL, changed URL 'apply'
#		     processing.
#		  -- Small output formating fix in the robot rules code.
#		  -- Version is now 0.99
#   janl 14/05/97 -- htmpop no-longer puts '<!DOCTYPE...' into doc, so check 
#		     for '<HTML' instead
#   janl 11/06/97 -- Made :port optional in server part of auth-domain.
#			Always removing :80 from server part to match netloc.
#   janl 22/07/97 -- More debugging of rewrite for new features -B, -I.
#   janl 01/08/97 -- Fixed bug in RE quoting for Ignore/Fetch
#   janl 04/08/97 -- s/writepage/write_page/g
#   janl 07/09/97 -- 0.99b1 is released
#   janl 19/09/97 -- Kaj Hejer discovers omissions in non-html-url-mining code.
#                 -- 0.99b2 is released
#   janl 24/09/97 -- Matt Chapman found bug in realm-name extraction.
#   janl 10/10/97 -- Referer: header supression supressed User: header instead
#		  -- Added fixup handling, writes .redirs and .referers
#		     (no dot in win32)
#  		  -- Read .w3mirc (w3mir.ini on win32) if present
#		  -- Stop file removal code from removing these files
#   janl 16/10/97 -- process_tag was mangling url attributes in tags with more
#		     than one of them.  Problem found by Robert L. Binkley
#   janl 04/12/97 -- Fixed problem with authentication, misplaced +
#		  -- default inter-docuent pause is 0.  I figure it's better
#		     to keep one httpd occupied in a steady stream than to
#		     wait for it to die before we talk to it again.
#   janl 13/12/97 -- The arguments to index.html in the form of index.html/foo
#		     handling code was incomplete.  To make it complete would
#		     have been hard, so it was removed.
#		  -- If a URL changes from file to directory or vice versa
#		     this is now handled.
#   janl 11/01/98 -- PDF files with no URLs does not cause warnings now.
#		  -- Close REFERERS and REDIRECTS before calling w3mfix
#   janl 22/01/98 -- Proxy authentication as outlined by Christian Geuer
#   janl 04/02/98 -- Version 1pre1
#   janl 18/02/98 -- Fixed wild_re after tip by Prentiss Riddle.
#		  -- Version 1pre2
#   janl 20/02/98 -- w3http updated to handle complex content-types.
#		  -- Fix wild_re more, bug noted by James Dumser
#		  -- 1.0pre3
#   janl 18/03/98 -- Version 1.0 is released
#   janl 09/04/98 -- Added feature so user can disable newline conversion.
#   janl 20/04/98 -- Only convert newlines in HTML files. -> 1.0.2
#   janl 09/05/98 -- More carefull clean_disk code.
#		  -- Check if the redirected URL was a root url, if so
#		     issue a warning and exit.
#   janl 12/05/98 -- use ->unix_path instead of ->as_string to derive local
#		     filename.
#   janl 25/05/98 -- -B didn't work too well.
#   janl 09/07/98 -- Redirect to fragment broke us, less broken now -> 1.0.4
#   janl 24/09/98 -- Better errormessages on errors -> 1.0.5
#   janl 21/11/98 -- Fix errormessages better.
#   janl 05/01/99 -- Drop 'Referer: (commandline)'
#   janl 13/04/99 -- Add initial referer to root urls in batch mode.
#   janl 15/01/00 -- Remove some leftover print statements
#                 -- Fix also-queue problem as suggested by Sven Koch
#   janl 04/02/01 -- Use epath instead of path quite often -> 1.0.10
#
# Variable name discipline:
# - remote, umodified URL.  Variables prefixed 'rum_'
# - local, filesystem.  Variables prefixed 'lf_'.
# Use these prefixes so we know what we're working with at all times.
# Also, URL objects are postfixed _o
#
# The apply rules and scope rules work this way:
# - First apply the user rules to the remote url.
# - Check if document is within scope after this.
# - Then apply w3mir's rules to the result.  This results is the local,
#   filesystem, name.
#
# We use features introduced in 5.002.
require 5.002;

# win32 and $nulldevice need to be globals, other modules use them.
use vars qw($win32 $nulldevice);

# To figure out what kind of system this is
BEGIN {
  use Config;
  $win32 = ( $Config{'osname'} eq 'MSWin32' ); 
}
# More ways to die:
use Carp;
# Http module:
use w3http;
# html url extraction and manupulation:
use htmlop;
# Extract urls from adobe acrobat pdf files:
use w3pdfuri;
# Date computer:
use HTTP::Date;
# URLs:
use URI::URL;
# For flush method
use FileHandle;

eval '
use URI;
$URI::ABS_ALLOW_RELATIVE_SCHEME=1;
$URI::ABS_REMOTE_LEADING_DOTS=1;
';

# Full discipline:
use strict;

# Set params in the http package, HTTP protocol version:
$w3http::version="1.0";

# The defaults should be for a robotic http agent on good behaviour.
my $debug=0;			# Debug level
my $verbose=0;			# Verbosity level, -1 = quiet, 0 = normal, 1...
my $pause=0;			# Pause between http requests
my $retryPause=600;		# Pause between retries. 10 minutes.
my $retry=3;			# Max 3 stabs pr. url.
my $r=0;			# Recurse? no recursion = absolutify links
my $remove=0;			# Remove files that are not there?
my $s=0;			# 0: save on disk 1: stdout 2: just forget 'em
my $useauth=0;			# Use authorization
my %authdata;			# Authorization data
my $check_robottxt = 1;		# Check robots.txt
my $do_referer = 1;		# Send referers header
my $do_user = 1;		# Send user header
my $cache_header = '';		# The cache-control/pragma: no-cache header
my $using_proxy = 0;		# Using proxy server or not?
my $batch=0;			# Batch get URLs?
my $read_urls=0;		# Get urls from STDIN?
my $abs=0;			# Absolutify URLs?
my $immediate_redir=0;		# Immediately follow a redirect?
my @root_urls;			# This is where we start, the root documents
my @root_dirs;			# The corresponding directories.  for remove
my $chdirto='';			# Place to chdir to after reading config file
my %nodelete=();		# Files that should not be deleted
my $numarg=0;			# Number of arguments accepted.
my $list_nomir=0;		# List of files not mirrored

# Fixup related things
my $fixrc='';			# Name of w3mfix config file
my $fixup=1;			# Do things needed to run fixup
my $runfix=0;			# Run w3mfix for user?
my $fixopen=0;			# Fixup files open?

my $indexname='index.html';

my $VERSION;
$VERSION='1.0.10';
$w3http::agent = my $w3mir_agent = "w3mir/$VERSION-2001-01-20";
my $iref='';			# Initial referer.  Must evaluate to false

# Derived settings	
my $mine_urls=0;		# Mine URLs from documents?
my $process_urls=0;		# Perform (URL) processing of documents?

# Queue of urls to get.
my @rum_queue = ();
my @urls = ();
# URL status map.
my %rum_urlstat = ();
# Status codes:
my $QUEUED   = 0;		# Queued but not gotten yet.
my $TERROR   = 100;		# Transient error, retry later
my $HLERR    = 101;		# Permanent error, give up
my $GOTIT    = 200;		# Gotten. Note similarity to http result code
my $NOTMOD   = 304;		# Not modified.
# Negative codes for nonexistent files, easier to check.
my $NEVERMIND= -1;		# Don't want it
my $REDIR    = -302;		# Does not exist, redirected
my $ENOTFND  = -404;		# Does not exist.
my $OTHERERR = -600;		# Some other error happened
my $FROBOTS  = -601;		# Forbidden by robots.txt rule

# Directory/files survey:
my %lf_file;		# What files are present in FS?  Disposition?  One of:
my $FILEDEL=0;		# Delete file
my $FILEHERE=1;		# File present in filesystem only
my $FILETHERE=2;	# File present on server too.
my %lf_dir;		# Number of files/dirs in dir.  If 0 dir is 
			# eligible for deletion.

my %fiddled=();		# If a file becomes a directory or a directory
                        # becomes a file it is considered fiddled and
                        # w3mir will not fiddle with it again in this
                        # run.

# Bitbucket device, very OS dependent.
$nulldevice='/dev/null';
$nulldevice='nul:' if ($win32);

# What to get, and not.
# Text of user supplied fetch/ignore rules
my $rule_text=" # User defined fetch/ignore rules\n";
# Code ref to the rule procedure
my $rule_code;

# Code to prefix and postfix the generated code.  Prefix should make
# $_ contain the url to match.  Postfix should return 1, the default
# is to get the url/file.
my $rule_prefix='$rule_code = sub { local($_) = shift;'."\n";
my $rule_postfix=" return 1;\n}";

# Scope tests generated by URL/Also directives in cfg. The scope code
# is just like the rule code, but used for program generated
# fetch/ignore rules related to multiscope retrival.
my $scope_fetch=" # Automatic fetch rules for multiscope retrival\n";
my $scope_ignore=" # Automatic ignore rules for multiscope retrival\n";
my $scope_code;

my $scope_prefix='$scope_code = sub { local($_) = shift;'."\n";
my $scope_postfix=" return 0;\n}";

# Function to apply to urls, se rule comments.
my $user_apply_code;	# User specified apply code
my $apply_code;		# w3mirs apply code
my $apply_prefix='$apply_code = sub { local($_) = @_;'."\n";
my $apply_lc=' $_ = lc $_; ';
my $apply_postfix='  return $_;'."\n}";
my @user_apply;		# List of users apply rules.
my @internal_apply;	# List of w3mirs apply rules.

my $infoloss=0;		# 1 if any URL translations (which cause
                        # information loss) are in effect.  If this is
                        # true we use the SAVEURL operation.
my $list;		# List url on STDOUT?
my $edit;		# Edit doc? Remove <!--NOMIRROR>...<!--/NOMIRROR-->
my $header;		# Text to insert in header
my $lc=0;		# Convert urls/filenames to lowercase?
my $fetch=0;		# What to fetch: -1: Some, 0: not modified 1: all
my $convertnl=1;	# Convert newlines?

# Non text/html formats we can extract urls from.  Function must take one
# argument: the filename.
my %knownformats = ( 'application/pdf', \&w3pdfuri::list,
		     'application/x-pdf', \&w3pdfuri::list,
		   );

# Known 'magic numbers' of the known formats.  The value is used as
# key in %knownformats.  the key part is a exact match for the
# following <string> beginning at the first byte of the file.
# This should probably be made more flexible, but not until we need it.

my %knownmagic = ( '%PDF-', 'application/pdf' );

my $iinline='';	# inline RE code to make RE caseinsensitive 
my $ipost='';	# RE postfix to make it caseinsensitive

usage() unless parse_args(@ARGV);

{
  my $w3mirc='.w3mirc';
  
  $w3mirc='w3mir.ini' if $win32;
  
  if (-f $w3mirc) {
    parse_cfg_file($w3mirc);
    $nodelete{$w3mirc}=1;
  }
}

# Check arguments and options
if ($#root_urls>=0) {
  # OK
} else {
  print "URLs: $#rum_queue\n";
  usage("No URLs given");
}

# Are we converting newlines today?
$w3http::convert=0 unless $convertnl;

if ($chdirto) {
  &mkdir($chdirto.'/this-is-not-created-odd-or-what');
  chdir($chdirto) || 
    die "w3mir: Can't change working directory to '$chdirto': $!\n";
}

$SIG{'INT'}=sub { print STDERR "\nCaught SIGINT!\n"; exit 1; };
$SIG{'QUIT'}=sub { print STDERR "\nCaught SIGQUIT!\n"; exit 1; };
$SIG{'HUP'}=sub { print STDERR "\nCaught SIGHUP!\n"; exit 1; };

&open_fixup if $fixup;

# Derive how much document processing we should do.
$mine_urls=( $r || $list );
$process_urls=(!$batch && !$edit && !$header);
# $abs can be set explicitly with -abs, and implicitly if not recursing
$abs = 1 unless $r;
print "Absolute references\n" if $abs && $debug;

# Cache_controll specified but proxy not in use?
die "w3mir: If you want to control a cache, use a proxy server!\n"
  if ($cache_header && !$using_proxy);

# Compile the second order code

# - The rum scope tests
my $full_rules=$scope_prefix.$scope_fetch.$scope_ignore.$scope_postfix;
# warn "Scope rules:\n-------------\n$full_rules\n---------------\n";
eval $full_rules;
die "$@" if $@;

die "w3mir: Program generated rules did not compile.\nPlease report to w3mir-core\@usit.uio.no.  The code is:\n----\n".
  $full_rules."\n----\n"
  if !defined($scope_code);

$full_rules=$rule_prefix.$rule_text.$rule_postfix;
# warn "Fetch rules:\n-------------\n$full_rules\n---------------\n";
eval $full_rules;
die "$@!" if $@;

# - The user specified rum tests
die "w3mir: Ignore/Fetch rules did not compile.\nPlease report to w3mir-core\@usit.uio.no.  The code is:\n----\n".
  $full_rules."\n----\n"
  if !defined($rule_code);

# - The user specified apply rules

# $SIG{__WARN__} = sub { print "$_[0]\n"; confess ""; };

my $full_apply=$apply_prefix.($lc?$apply_lc:'').
  join($ipost.";\n",@user_apply).(($#user_apply>=0)?$ipost:"").";\n".
  $apply_postfix;

eval $full_apply;
die "$@!" if $@;

die "w3mir: User apply rules did not compile.\nPlease report to w3mir-core\@usit.uio.no. The code is:
----
".$full_apply."
----\n" if !defined($apply_code);

# print "user apply: $full_apply\n";
$user_apply_code=$apply_code;

# - The w3mir generated apply rules

$full_apply=$apply_prefix.($lc?$apply_lc:'').
  join($ipost.";\n",@internal_apply).(($#internal_apply>=0)?$ipost:"").";\n".
  $apply_postfix;
eval $full_apply;
die "$@!" if $@;

die "Internal apply rules did not compile.  The code is:
----
".$full_apply."
----\n" if !defined($apply_code);

# - Information loss via -lc?  There are other sources as well.
$infoloss=1 if $lc;

warn "Infoloss is $infoloss\n" if $debug;

# More setup:

$w3http::debug=$debug;

$w3http::verbose=$verbose;

my %rum_referers=();	# Array of referers, key: rum_url
my $Robot_Blob;		# WWW::RobotsRules object, decides if rum_url is 
			# forbidden to access for us.
my $rum_url_o;		# rum url, mostly the current, the one we're getting
my %gotrobots;		# Did I get robots.txt from site? key: url->netloc
my($authuser,$authpass);# Username and password for authentication with server
my @rum_newurls;	# List of rum_urls in document

if ($check_robottxt) {
  # Eval is only way to defer loading of module until we know it's needed?
  eval 'use WWW::RobotRules;';

  die "Could not load WWW::RobotRules, try -drr switch\n"
    unless defined(&WWW::RobotRules::parse);

  $Robot_Blob = new WWW::RobotRules $w3mir_agent;
}

# We have several main-modes of operation.  Here we select one
if ($r) {

  die "w3mir: No URLs?  Try 'w3mir -h' for help.\n"
    if $#root_urls==-1;

  warn "Recursive retrival comencing\n" if $debug;

  die "w3mir: Sorry, you cannot combine -r/recurse with -I/read_urls\n"
    if $read_urls;

  # Recursive
  my $url;
  foreach $url (@root_urls) {
    warn "Root url dequeued: $url\n" if $debug;
    if (want_this($url)) {
      queue($url);
      &add_referer($url,$iref);
    } else {
      die "w3mir: Inconsistent configuration: Specified $url is not inside retrival scope\n";
    }
  }
  mirror();

} else {
  if ($batch) {
    warn "Batch retrival commencing\n" if $debug;
    # Batch get
    if ($read_urls) { 
      # Get URLs from <STDIN>
      while (<STDIN>) {
	chomp;
	&add_referer($_,$iref);
	batch_get($_);
      }
    } else {
      # Get URLs from commandline
      my $url;
      foreach $url (@root_urls) {
	&add_referer($url,$iref);
      }
      foreach $url (@root_urls) {
	batch_get($url);
      }
    }
  } else {
    warn "Single url retrival commencing\n" if $debug;

    # A single URL, with all processing on
    die "w3mir: You specified several URLs and not -B/batch\n"
      if $#root_urls>0;
    queue($root_urls[0]);
    &add_referer($root_urls[0],$iref);
    mirror();
  }
}

&close_fixup if $fixup;

# This should clean up files:
&clean_disk if $remove;

warn "w3mir: That's all (".$w3http::xfbytes.'+',$w3http::headbytes.
  " bytes of it).\n" unless $verbose<0;

if ($runfix) {
  eval 'use Config;';
  warn "Running w3mfix\n";
  if ($win32) {
    CORE::system($Config{'perlpath'}." w3mfix $fixrc");
  } else {
    CORE::system("w3mfix $fixrc");
  }
}

exit 0;

sub get_document {
  # Get one document by HTTP ($1/rum_url_o).  Save in given filename ($2).
  # Possebly returning references found in the document.  Caller must
  # set up referer array, check wantedness and everything else.  We
  # handle authentication here though.

  my($rum_url_o)=shift;
  my($lf_url)=shift;
  croak("\$rum_url_o is empty") if !defined($rum_url_o) || !$rum_url_o;
  croak("$lf_url is empty") if !defined($lf_url) || !$lf_url;

  # Make sure it's an object
  $rum_url_o = url $rum_url_o 
    unless ref $rum_url_o;
  
  # Derive a filename from the url, the filename contains no URL-quoting
  my($lf_name) = (url "file:$lf_url")->unix_path;

  # Make all intermediate directories
  &mkdir($lf_name) if $s==0;

  my($rum_as_string) = $rum_url_o->as_string;

  print STDERR "GET_DOCUMENT: '",$rum_as_string,"' -> '",$lf_name,"'\n"
    if $debug;

  my $hostport;
  my $www_auth='';	# Value of that http reply header
  my $page_ref;
  my @rum_newurls;	# List of URLs extracted
  my $url_extractor;
  my $do_query;		# Do query or not?

  if (defined($rum_urlstat{$rum_as_string}) && 
      $rum_urlstat{$rum_as_string}>0) {
    warn "w3mir: Internal error, ".$rum_as_string.
      " queued several times\n";
    next;
  }

  # Goto here if we want to retry b/c of authentication
  try_again:

  # Start building the extra http::query arguments again
  my @EXTRASTUFF=();

  # We'll start by assuming that we're doing the query.
  $do_query=1;
    
  # If we're not checking the timestamp, or the file does not exist
  # then we get the file unconditionally.  Otherwise we only want it
  # if it's updated.

  if ($fetch==1) {
    # Nothing do do?
  } else {
    if (-f $lf_name) {
      if ($fetch==-1) {
	print STDERR "w3mir: ".($infoloss?$rum_as_string:$lf_name).
	  ", already have it" if $verbose>=0;
	if (!$mine_urls) {
	  # If -fs and the file exists and we don't need to mine URLs
	  # we're finished!
	  warn "Already have it, no mining, returning!\n" if $debug;
	  print STDERR "\n" if $verbose>=0;
	  return;
	}
	$w3http::result=1304;	# Pretend it was 'not modified'
	$do_query=0;
      } else {
	push(@EXTRASTUFF,$w3http::IFMODF,$lf_name);
      }
    }
  }

  if ($do_query) {

    # Does the server want authorization for this file?  $www_auth is
    # only set if authentication was requested the first time around.

    # For testing:
    # $www_auth='Basic realm="foo"';

    if ($www_auth) {
      my($authdata,$method,$realm);

      ($method,$realm)= $www_auth =~ m/^(\S+)\s+realm=\"([^\"]+)\"/i;
      $method=lc $method;
      $realm=lc $realm;
      die "w3mir: '$method' authentication needed, don't know that.\n"
	if ($method ne 'basic');
      
      $hostport = $rum_url_o->netloc;
      $authdata=$authdata{$hostport}{$realm} || $authdata{$hostport}{'*'} ||
	$authdata{'*'}{$realm} || $authdata{'*'}{'*'};

      if ($authdata) {
	push(@EXTRASTUFF,$w3http::AUTHORIZ,$authdata);
      } else {
	print STDERR "w3mir: No authorization data for $hostport/$realm\n";
	$rum_urlstat{$rum_as_string}=$NEVERMIND;
	next;
      }
    }
    
    push(@EXTRASTUFF,$w3http::FREEHEAD,$cache_header)
      if ($cache_header);

    # Insert referer header data if at all
    push(@EXTRASTUFF,$w3http::REFERER,$rum_referers{$rum_as_string}[0])
      if ($do_referer && exists($rum_referers{$rum_as_string}));

    push(@EXTRASTUFF,$w3http::NOUSER)
      unless ($do_user);

    # YES, $lf_url is right, w3http::query handles this like an url so
    # the quoting must all be in place.
    my $binfile=$lf_url;
    $binfile='-' if $s==1;
    $binfile=$nulldevice if $s==2;

    if ($pause) {
      print STDERR "w3mir: sleeping\n" if $verbose>0;
      sleep($pause);
    }

    print STDERR "w3mir: ".($infoloss?$rum_as_string:$lf_name) 
      unless $verbose<0;
    print STDERR "\nFile: $lf_name\n" if $debug;

    &w3http::query($w3http::GETURL,$rum_as_string,
		   $w3http::SAVEBIN,$binfile,
		   @EXTRASTUFF);

    print STDERR "w3http::result: '",$w3http::result,
    "' doc size: ", length($w3http::document),
    " doc type: -",$w3http::headval{'CONTENT-TYPE'},
    "- plaintexthtml: ",$w3http::plaintexthtml,"\n"
      if $debug;

    print "Result: ",$w3http::result," Recurse: $r, html: ",
    $w3http::plaintexthtml,"\n" 
      if $debug;

  } # if $do_query
    
  if ($w3http::result==200) { # 200 OK 
    $rum_urlstat{$rum_as_string}=$GOTIT;

    if ($mine_urls || $process_urls) {

      if ($w3http::plaintexthtml) {
	# Only do URL manipulations if this is a html document with no
	# special content-encoding.  We do not handle encodings, yet.

	my $page;

	print STDERR ($process_urls)?", processing":", url mining"
	  if $verbose>0;
	  
	print STDERR "\nurl:'$lf_url'\n" 
	  if $debug;

	print "\nMining URLs: $mine_urls, Process: $process_urls\n" 
	  if $debug;
	    
	($page,@rum_newurls) = 
	  &htmlop::process($w3http::document,
			   # Only get a new document if wanted
			   $process_urls?():($htmlop::NODOC),
			   $htmlop::CANON,
			   $htmlop::ABS,$rum_url_o,
			   # Only list urls if wanted
			   $mine_urls?($htmlop::LIST):(),

			   # If user wants absolute URLs do not
			   # relativize them

			   $abs?
			   ():
			   (
			    $htmlop::TAGCALLBACK,\&process_tag,$lf_url,
			    )
			  );

#	print "URL: ",join("\nURL: ",@rum_newurls),"\n";

	if ($process_urls) {
	  $page_ref=\$page;
	  $w3http::document='';
	} else {
	  $page_ref=\$w3http::document;
	}

      } elsif ($s == 0 &&
	       ($url_extractor = 
		$knownformats{$w3http::headval{'CONTENT-TYPE'}})) {

	# The knownformats extractors only work on disk files so write
	# doc to disk if not there already (non-html text will not be)
	write_page($lf_name,$w3http::document,1);

	# Now we try our hand at fetching URIs from non-html files.
	print STDERR ", mining URLs" if $verbose>=1;
	@rum_newurls = &$url_extractor($lf_name);
	# warn "URLs from PDF: ",join(', ',@rum_newurls),"\n";
      }
      
      
    } # if ($mine_urls || $process_urls)

#    print "page_ref defined: ",defined($page_ref),"\n";
#    print "plaintext: ",$w3http::plaintext,"\n";

    $page_ref=\$w3http::document 
      if !defined($page_ref) && $w3http::plaintexthtml;

    if ($w3http::plaintexthtml) {
      # ark: this is where I want to do my changes to the page strip
      # out the <!--NOMIRROR-->...<!--/NOMIRROR--> Stuff.
      $$page_ref=~ s/<(!--)?\s*NO\s*MIRROR\s*(--)?>[^\000]*?<(!--)?\s*\/NO\s*MIRROR\s*(--)?>//g 
	if $edit;
	  
      if ($header) {
	# ark: insert a header string at the start of the page
	my $mirrorstr=$header;
	$mirrorstr =~ s/\$url/$rum_as_string/g;
	insert_at_start( $mirrorstr, $page_ref );
      }
    }

    write_page($lf_name,$page_ref,0);

    # print "New urls: ",join("\n",@rum_newurls),"\n";

    return @rum_newurls;
  }

  if ($w3http::result==304 || #  304 Not modified
      $w3http::result==1304) { # 1304 Have it

    { 
      # last = out of nesting

      my $rum_urlstat;
      my $rum_newurls;
      
      @rum_newurls=();
      
      print STDERR ", not modified"
	if $verbose>=0 && $w3http::result==304;
      
      $rum_urlstat{$rum_as_string}=$NOTMOD;

      last unless $mine_urls;
      
      $rum_newurls=get_references($lf_name);

      # print "New urls: ",ref($rum_newurls),"\n";
      
      if (!ref($rum_newurls)) {
	last;
      } elsif (ref($rum_newurls) eq 'SCALAR') {
	$page_ref=$rum_newurls;
      } elsif (ref($rum_newurls) eq 'ARRAY') {
	@rum_newurls=@$rum_newurls;
	last;
      } else {
	die "\nw3mir: internal error: Unknown return type from get_references\n";
      }
      
      # Check if it's a html file.  I know this tag is in all html
      # files, because I put it there as I pull them in.
      last unless $$page_ref =~ /<HTML/i;
      
      warn "$lf_name is a html file\n" if $debug;
      
      # It's a html document
      print STDERR ", mining URLs" if $verbose>=1;
      
      # This will give us a list of absolute urls
      (undef,@rum_newurls) = 
	&htmlop::process($$page_ref,$htmlop::NODOC,
			 $htmlop::ABS,$rum_as_string,
			 $htmlop::USESAVED,'W3MIR',
			 $htmlop::LIST);
    }

    print STDERR "\n" if $verbose>=0;
    return @rum_newurls;
  }
	
  if ($w3http::result==302 || $w3http::result==301) { # Redirect
    # Cern and NCSA httpd sends 302 'redirect' if a ending / is
    # forgotten on a url.  More recent httpds send 301 'permanent
    # redirect' in this case.  Here we check if the difference in URLs
    # is just a / and if so push the url again with the / added.  This
    # code only works if the http server has the right idea about its
    # own name.
    #
    # 18/3/97: Added code to queue redirected-to-URLs that are within
    # the scope of the retrival.
    my $new_rum_url;

    $rum_urlstat{$rum_as_string}=$REDIR;

    # Absolutify the new url, it might be relative to the requested
    # document.  That's a ugly wart on some servers/admins.
    $new_rum_url=url $w3http::headval{'location'};
    $new_rum_url=$new_rum_url->abs($rum_url_o);

    print REDIRS $rum_as_string,' -> ',$new_rum_url->as_string,"\n"
      if $fixup;

    if ($immediate_redir) {
      print STDERR " =>> ",$new_rum_url->as_string,", getting that instead\n";
      return get_document($new_rum_url,$lf_url);
    }

    # Some redirect to a fragment of another doc...
    $new_rum_url->frag(undef);
    $new_rum_url=$new_rum_url->as_string;

    if ($rum_as_string.'/' eq $new_rum_url) {
      if (grep { $rum_as_string eq $_; } @root_urls) {
	print STDERR "\nw3mir: missing / in a start URL detected.  Please fix commandline/config file.\n";
	exit(1);
      }
      print STDERR ", missing /\n";
      queue($new_rum_url);
      # Initialize referer to something meaningful
      $rum_referers{$new_rum_url}=$rum_referers{$rum_as_string};
    } else {
      print STDERR " =>> $new_rum_url";
      if (want_this($new_rum_url)) {
	print STDERR ", getting that\n";
	queue($new_rum_url);
	$rum_referers{$new_rum_url}=$rum_referers{$rum_as_string};
      } else {
	print STDERR ", don't want it\n";
      }
    }
    return ();
  }

  if ($w3http::result==403 || # Forbidden
      $w3http::result==404 || # Not found
      $w3http::result==406 || # Not Acceptable, hmm, belongs here?
      $w3http::result==410) { # Gone - no forwarding address known

    $rum_urlstat{$rum_as_string}=$ENOTFND;
    &handleerror;
    print STDERR "Was refered from: ",
      join(',',@{$rum_referers{$rum_as_string}}),
      "\n" if defined(@{$rum_referers{$rum_as_string}});
    return ();
  }

  if ($w3http::result==407) {
    # Proxy authentication requested
    die "Proxy server requests authentication but failed to return the\n".
      "REQUIRED Proxy-Authenticate header for this condition\n"
	unless exists($w3http::headval{'proxy-authenticate'});

    die "Proxy authentication is required for ".$w3http::headval{'proxy-authenticate'}."\n";
  }

  if ($w3http::result==401) {
    # A www-authenticate reply header should acompany a 401 message.
    if (!exists($w3http::headval{'www-authenticate'})) {
      warn "w3mir: Server indicated authentication failure but gave no www-authenticate reply\n";
      $rum_urlstat{$rum_as_string}=$NEVERMIND;
    } else {
      # Unauthorized
      if ($www_auth) {
	# Failed when authorization data was supplied.
	$rum_urlstat{$rum_as_string}=$NEVERMIND;
	print STDERR ", authorization failed data needed for ",
	$w3http::headval{'www-authenticate'},"\n"
	  if ($verbose>=0);
      } else {
	if ($useauth) {
	  # First time failure, send back and retry at once with some known
	  # user/passwd.
	  $www_auth=$w3http::headval{'www-authenticate'};
	  print STDERR ", retrying with authorization\n" unless $verbose<0;
	  goto try_again;
	} else {
	  print ", authorization needed: ",
	    $w3http::headval{'www-authenticate'},"\n";
	  $rum_urlstat{$rum_as_string}=$NEVERMIND;
	}
      }
    }
    return ();
  }
   
  # Something else.  
  &handleerror;
}


sub robot_check {
  # Check if URL is allowed by robots.txt, if we respect it at all
  # that is.  Return 1 it allowed, 0 otherwise.

  my($rum_url_o)=shift;
  my $hostport;

  if ($check_robottxt) {
    
    $hostport = $rum_url_o->netloc;
    if (!exists($gotrobots{$hostport})) {
      # Get robots.txt from the server
      $gotrobots{$hostport}=1;
      my $robourl="http://$hostport/robots.txt";
      print STDERR "w3mir: $robourl" if ($verbose>=0);
      &w3http::query($w3http::GETURL,$robourl);
      $w3http::document='' if ($w3http::result != 200);
      print STDERR ", processing" if $verbose>=1;
      print STDERR "\n" if ($verbose>=0);
      $Robot_Blob->parse($robourl,$w3http::document);
    }

    if (!$Robot_Blob->allowed($rum_url_o->as_string)) {
      # It is forbidden
      $rum_urlstat{$rum_url_o->as_string}=$FROBOTS;
      warn "w3mir: ",$rum_url_o->as_string,": forbidden by robots.txt\n";
      return 0;
    }
  }
  return 1;
}



sub batch_get {
  # Batch get _one_ document.
  my $rum_url=shift;
  my $lf_url;

  $rum_url_o = url $rum_url;

  return unless robot_check($rum_url_o);

  ($lf_url=$rum_url) =~ s~.*/~~;
  if (!defined($lf_url) || $lf_url eq '') {
    ($lf_url=$rum_url) =~ s~/$~~;
    $lf_url =~ s~.*/~~;
    $lf_url .= "-$indexname";
  }

  warn "Batch get: $rum_url -> $lf_url\n" if $debug;

  $immediate_redir=1; # Do follow redirects immediately

  get_document($rum_url,$lf_url);
}



sub mirror {
  # Mirror (or get) the requested url(s). Possibly recursively.
  # Working from whatever cwd is at invocation we'll retrieve all
  # files under it in the file hierarchy.
  
  my $rum_url;	# URL of the document we're getting now, defined at main level
  my $lf_url;	# rum_url after apply - and 
  my $new_lf_url;
  my @new_rum_urls;
  my $rum_ref;
  
  while (defined($rum_url = pop(@rum_queue))) {

    warn "mirror: Poped $rum_url from queue\n" if $debug;

    # Unwanted URLs should not be queued
    die "Found url $rum_url that I don't want in queue!\n" 
      unless defined($lf_url=apply($rum_url));

    $rum_url_o = url $rum_url;

    next unless robot_check($rum_url_o);

    # Figure out the filename for our local filesystem.
    $lf_url.=$indexname if $lf_url =~ m~/$~ || $lf_url eq '';

    @new_rum_urls = get_document($rum_url_o,$lf_url);

    print join("\n",@new_rum_urls),"\n" if ($list);

    if ($r) {
      foreach $rum_ref (@new_rum_urls) {
	# warn "Recursive url: $rum_ref\n";
	$new_lf_url=apply($rum_ref);
	next unless $new_lf_url;

	# warn "Want it\n";
	$rum_ref =~ s/\#.*$//s;		# Clip off section marks
	
	add_referer($rum_ref,$rum_url_o->as_string);
	queue($rum_ref);
      }
    }

    @new_rum_urls=();

    # Is the URL queue empty? Are there outstanding retries?  Refill
    # the queue from the retry list.
    if ($#rum_queue<0 && $retry-->0) {
      foreach $rum_url_o (keys %rum_urlstat) {
	$rum_url_o = url $rum_url_o;
	if ($rum_urlstat{$rum_url_o->as_string}==100) {
	  push(@rum_queue,$rum_url_o->as_string);
	  $rum_urlstat{$rum_url_o->as_string}=0;
	}
      }
      if ($#rum_queue>=0) {
	warn "w3mir: Sleeping before retrying.  $retry more times left\n"
	  if $verbose>=0;
	sleep($retryPause);
      }
    }

  }
}


sub get_references {
  # Get references from a non-html-on-disk file.  Return references if
  # we know how to find them.  Return reference do the complete page
  # if it's html.  Return single numerical 0 if unknown format.

  my($lf_url)=shift;
  my($urlextractor)=shift;

  my $read; # Buffer of stuff read from file to check filetype
  my $magic;
  my $url_extractor;
  my $rum_ref;
  my $page;

  warn "w3mir: Looking at local $lf_url\n" if $debug;
	
  # Open file and read the first 10kilobytes for file-type-test
  # purposes.
  if (!open(TMPF,$lf_url)) {
    warn "Unable to open $lf_url for reading: $!\n";
    last;
  }
	
  $page=' 'x10240;
  $read=sysread(TMPF,$page,length($page),0);
  close(TMPF);
	
  die "Error reading $lf_url: $!\n" if (!defined($read));

  if (!defined($url_extractor)) {
    $url_extractor=0;

    # Check file against list of magic numbers.
    foreach $magic (keys %knownmagic) {
      if (substr($page,0,length($magic)) eq $magic) {
	$url_extractor = $knownformats{$knownmagic{$magic}};
	last;
      }
    }
  }

  # Found a extraction method, apply.
  if ($url_extractor) {
    print STDERR ", mining URLs" if $verbose>=1;
    return [&$url_extractor($lf_url)];
  }

  if ($page =~ /<HTML/i) {
    open(TMPF,$lf_url) || 
      die "Could not open $lf_url for reading: $!\n";
    # read the whole file.
    local($/)=undef;
    $page = <TMPF>;
    close(TMPF);
    return \$page;
  }

  return 0;
}


sub open_fixup {
  # Open the referers and redirects files

  my $reffile='.referers';
  my $redirfile='.redirs';
  my $removedfile='.notmirrored';

  if ($win32) {
    $reffile="referers";
    $redirfile="redirs";
    $removedfile="notmir";
  }

  $nodelete{$reffile} = $nodelete{$redirfile} = $nodelete{$removedfile} = 1;

  $removedfile=$nulldevice unless $list_nomir;

  open(REDIRS,"> $redirfile") || 
    die "Could not open $redirfile for writing: $!\n";

  autoflush REDIRS 1;

  open(REFERERS,"> $reffile") ||
    die "Could not open $reffile for writing: $!\n";

  $fixopen=1;

  open(REMOVED,"> $removedfile") ||
    die "Could not open $removedfile for writing: $!\n";

  autoflush REMOVED 1;

  eval 'END { close_fixup; 0; }';
}


sub close_fixup {
  # Close the fixup data files.  In the case of the referer file also
  # write the entire content

  return unless $fixopen;

  my $referer;

  foreach $referer (keys %rum_referers) {
    print REFERERS $referer," <- ",join(' ',@{$rum_referers{$referer}}),"\n";
  }

  close(REFERERS) || warn "Error closing referers file: $!\n";
  close(REDIRS) || warn "Error closing redirects file: $!\n";
  close(REMOVED) || warn "Error closing 'removed' file: $!\n";
  $fixopen=0;
}


sub clean_disk {
  # This procedure removes files that are not present on the server(s)
  # anymore.
  
  # - To avoid removing files that were not fetched due to network
  #   problems we only do blanket removal IFF all documents were
  #   fetched w/o problems, eventually.  
  # - In any case we can remove files the server said were not found

  # The strategy has three main parts:
  # 1. Find all files we have
  # 2. Find what files we ought to have
  # 3. Remove the difference
  
  my $complete_retrival=1;	# Flag saying IFF all documents were fetched
  my $urlstat;			# Tmp storage
  my $rum_url;
  my $lf_url;
  my $lf_dir;
  my $dirs_to_remove;

  # For fileremoval code
  eval "use File::Find;" unless defined(&find);

  die "w3mir: Could not load File::Find module.  Don't use -R switch.\n"
    unless defined(&find);
  
  # This to shut up -w
  $lf_dir=$File::Find::dir;

  # ***** 1. Find out what files we have *****
  #
  # This does two things:  For each file or directory found:
  # - Increases entry count for the container directory
  # - If it's a file: $lf_file{relative_path}=$FILEHERE;

  chop(@root_dirs);
  print STDERR "Looking in: ",join(", ",@root_dirs),"\n" if $debug;

  find(\&find_files,@root_dirs);

  # ***** 2. Find out what files we ought to have *****
  #
  # First we loop over %rum_urlstat to determine what files are not
  # present on the server(s).
  foreach $rum_url (keys %rum_urlstat) {
    # Figure out name of local file from rum_url
    next unless defined($lf_url=apply($rum_url));

    $lf_url.=$indexname if $lf_url =~ m~/$~ || $lf_url eq '';

    # find prefixes ./, we must too.
    $lf_url="./".$lf_url unless substr($lf_url,0,1) eq '/';

    # Ignore if file does not exist here.
    next unless exists($lf_file{$lf_url});
    
    # The apply rules can map several remote files to same local
    # file.  If we decided to keep file already we stay with that.
    next if $lf_file{$lf_url}==$FILETHERE;
    
    $urlstat=$rum_urlstat{$rum_url};

    # Figure out the status code.
    if ($urlstat==$GOTIT || $urlstat==$NOTMOD) {
      # Present on server.  Keep.
      $lf_file{$lf_url}=$FILETHERE;
      next;
    } elsif ($urlstat==$ENOTFND || $urlstat==$NEVERMIND ) {
      # One of: not on server, can't get, don't want, access forbiden:
      # Schedule for removal.
      $lf_file{$lf_url}=$FILEDEL if exists($lf_file{$lf_url});
      next;
    } elsif ($urlstat==$OTHERERR || $urlstat==$TERROR) {
      # Some error occured transfering.
      $complete_retrival=0;	# The retrival was not complete. Delete less
    } elsif ($urlstat==$QUEUED) {
      warn "w3mir: Internal inconsistency, $rum_url marked as queued after retrival terminated\n";
      $complete_retrival=0;	# Fishy. Be conservative about removing
    } else {
      $complete_retrival=0;
      warn "w3mir: Warning: $rum_url is marked as $urlstat.\n".
	"w3mir: Please report to w3mir-core\@usit.uio.no.\n";
    }
  }				# foreach %rum_urlstat

  # ***** 3. Remove the difference *****

  # Loop over all found files:
  # - Should we have this file?
  # - If not: Remove file and decrease directory entry count
  # Loop as long as there are directories with 0 entry count:
  # - Loop over all directories with 0 entry count:
  #   - Remove directory
  #   - Decrease entry count of parent
  
  warn "w3mir: Some error occured, conservative file removal\n"
    if !$complete_retrival && $verbose>=0;

  # Remove all files we don't want removed from list of files present:
  foreach $lf_url (keys %nodelete) {
    print STDERR "Not deleting: $lf_url\n" if $verbose>=1;
    delete $lf_file{$lf_url} || delete $lf_file{'./'.$lf_url};
  }
  
  # Remove files
  foreach $lf_url (keys %lf_file) {
    if (($complete_retrival && $lf_file{$lf_url}==$FILEHERE) ||
	($lf_file{$lf_url} == $FILEDEL)) {
      if (unlink $lf_url) {
	($lf_dir)= $lf_url =~ m~^(.+)/~;
	$lf_dir{$lf_dir}--;
	$dirs_to_remove=1 if ($lf_dir{$lf_dir}==0);
	warn "w3mir: removed file $lf_url\n" if $verbose>=0;
      } else {
	warn "w3mir: removal of file $lf_url failed: $!\n";
      }
    }
  }
  
  # Remove empty directories
  while ($dirs_to_remove) {
    $dirs_to_remove=0;
    foreach $lf_url (keys %lf_dir) {
      next if $lf_url eq '.';
      if ($lf_dir{$lf_url}==0) {
	if (rmdir($lf_url)) {
	  warn "w3mir: removed directory $lf_dir\n" if $verbose>=0;
	  delete $lf_dir{$lf_url};
	  ($lf_dir)= $lf_url =~ m~^(.+)/~;
	  $lf_dir{$lf_dir}--;
	  $dirs_to_remove=1 if ($lf_dir{$lf_dir}==0);
	} else {
	  warn "w3mir: removal of directory $lf_dir failed: $!\n";
	}
      }
    }
  }
}


sub find_files {
  # This is called by the find procedure for every file/dir found.
  
  # This builds two hashes:
  # lf_file{<file>}: 1: file exists
  # lf_dir{<dir>): Number of files in directory.
  
  lstat($_);

  $lf_dir{$File::Find::dir}++;

  if (-f _) {
    $lf_file{$File::Find::name}=$FILEHERE;
  } elsif (-d _) {
    # null
    # Bug: If an empty directory exists it will not be removed
  } else {
    warn "w3mir: File $File::Find::name has unknown type.  Ignoring.\n";
  }
  return 0;
  
}


sub handleerror {
  # Handle error status of last http connection, will set the rum_urlstat
  # appropriately and print a error message.

  my $msg;
  
  if ($verbose<0) {
    $msg="w3mir: ".$rum_url_o->as_string.": ";
  } else {
    $msg=": ";
  }

  if ($w3http::result == 98) {
    # OS/Network error
    $msg .= "$!";
    $rum_urlstat{$rum_url_o->as_string}=$OTHERERR;
  } elsif ($w3http::result == 100) {
    # Some kind of error connecting or sending request
    $msg .= $w3http::restext || "Timeout";
    $rum_urlstat{$rum_url_o->as_string}=$TERROR;
  } else {
    # Other HTTP error
    $rum_urlstat{$rum_url_o->as_string}=$OTHERERR;
    $msg .= " ".$w3http::result." ".$w3http::restext;
    $msg .= " =>> ".$w3http::headval{'location'}
    if (defined($w3http::headval{'location'}));
  }
  print STDERR "$msg\n";
}


sub queue {
  # Queue given url if appropriate and create a status entry for it
  my($rum_url_o)=url $_[0];

  croak("BUG: undefined \$rum_url_o")
    if !defined($rum_url_o);

  croak("BUG: undefined \$rum_url_o->as_string")
    if !defined($rum_url_o->as_string);

  croak("BUG: ".$rum_url_o->as_string." (fragnent) queued")
    if $rum_url_o->as_string =~ /\#/;
  
  return if exists($rum_urlstat{$rum_url_o->as_string});
  return unless want_this($rum_url_o->as_string);

  warn "QUEUED: ",$rum_url_o->as_string,"\n" if $debug;
  
  # Note lack of scope checks.
  $rum_urlstat{$rum_url_o->as_string}=$QUEUED;
  push(@rum_queue,$rum_url_o->as_string);
}


sub root_queue {
  # Queue function for root urls and directories.  One or the other might
  # be boolean false, in that case, don't queue it.

  my $root_url_o;

  my($root_url)=shift;
  my($root_dir)=shift;

  die "w3mir: No fragments in start URLs :".$root_url."\n"
    if $root_url =~ /\#/;

  if ($root_dir) {
    print "Root dir: $root_dir\n" if $debug;
    $root_dir="./$root_dir" unless substr($root_dir,0,1) eq '/' or
      substr($root_dir,0,2) eq './';
    push(@root_dirs,$root_dir);
  }


  if ($root_url) {
    $root_url_o=url $root_url;

    # URL canonification, or what we do of it at least.
    $root_url_o->host($root_url_o->host);

    warn "Root queue: ".$root_url_o->as_string."\n" if $debug;

    push(@root_urls,$root_url_o->as_string); 

    return $root_url_o;
  }

}


sub write_page {
  # write a retrieved page to wherever it's supposed to be written.
  # Added difficulty: all files but plaintext files have already been
  # written to disk in w3http.
  
  # $s == 0 save to disk
  # $s == 1 dump to stdout
  # $s == 2 forget

  my($lf_name,$page_ref,$silent) = @_;
  my($verb);

  if ($silent) {
    $verb=-1;
  } else {
    $verb=$verbose;
  }

#  confess("\n\$page_ref undefined") if !defined($page_ref);
  
  if ($w3http::plaintexthtml) {
    # I have it in memory
    if ($s==0) {
      print STDERR ", saving" if $verb>0;

      while (-d $lf_name) {
	# This will run once, maybe twice, $fiddled will be canged the
	# first time
	if (exists($fiddled{$lf_name})) {
	  warn "Cannot save $lf_name, there is a directory in the way\n";
	  return;
	}

	$fiddled{$lf_name}=1;

	rm_rf($lf_name);
	print STDERR "w3mir: $lf_name" if $verbose>=0;
      }

      if (!open(PAGE,">$lf_name")) {
	warn "\nw3mir: can't open $lf_name for writing: $!\n";
	return;
      }
      if (!$convertnl) {
	binmode PAGE;
	warn "BINMODE\n" if $debug;
      }
      if ($$page_ref ne '') {
	print PAGE $$page_ref || die "w3mir: Error writing $lf_name: $!\n";
      }
      close(PAGE) || die "w3mir: Error closing $lf_name: $!\n";
      print STDERR ": ", length($$page_ref), " bytes\n"
	if $verb>=0;
      setmtime($lf_name,$w3http::headval{'last-modified'})
	if exists($w3http::headval{'last-modified'});
    } elsif ($s==1) {
      print $$page_ref ;
    } elsif ($s==2) {
      print STDERR ", got and forgot it.\n" unless $verb<0;
    }
  } else {
    # Already written by http module, just emit a message if wanted
    if ($s==0) {
      print STDERR ": ",$w3http::doclen," bytes\n"
	if $verb>=0;
      setmtime($lf_name,$w3http::headval{'last-modified'})
	  if exists($w3http::headval{'last-modified'});
    } elsif ($s==2) {
      print STDERR ", got and forgot it.\n" if $verb>=0;
    }
  }
}


sub setmtime {
  # Set mtime of the given file
  my($file,$time)=@_;
  my($tm_sec,$tm_min,$tm_hour,$tm_mday,$tm_mon,$tm_year,$tm_wday,$tm_yday,
     $tm_isdst,$tics);

  $tm_isdst=0;
  $tm_yday=-1;

  carp("\$time is undefined"),return if !defined($time);

  $tics=str2time($time);
  utime(time, $tics, $file) || 
      warn "Could not change mtime of $file: $!\n";
}


sub movefile {
  # Rename a file.  Note that copy is not a good alternative, since
  # copying over NFS is something we want to Avoid.

  # Returns 0 if failure and 1 in case of sucess.

  (my $old,my $new) = @_;

  # Remove anything that might have the name already.
  if (-d $new) {
    print STDERR "\n" if $verbose>=0;
    rm_rf($new);
    $fiddled{$new}=1;
    print STDERR "w3mir: $new" if $verbose>=0;
  } elsif (-e $new) {
    $fiddled{$new}=1;
    if (unlink($new)) {
      print STDERR "\nw3mir: removed $new\nw3mir: $new"
	if $verbose>=0;
    } else {
      return 0;
    }

  }

  if ($new ne '-' && $new ne $nulldevice) {
    warn "MOVING $old -> $new\n" if $debug;
    rename($old,$new) || 
      warn "Could not rename $old to $new: $!\n",return 0;
  }
  return 1;
}


sub mkdir {
  # Make all intermediate directories needed for a file, the file name
  # is expected to be included in the argument!

  # Reasons for not using File::Path::mkpath:
  # - I already wrote this.
  # - I get to be able to produce as good and precise errormessages as
  #   unix and perl will allow me.  mkpath will not.
  # - It's easier to find out if it worked or not.
  
  my($file) = @_;
  my(@dirs) = split("/",$file);
  my $path;
  my $dir;
  my $moved=0;

  if (!$dirs[0]) {
    shift @dirs;
    $path='';
  } else {
    $path = '.';
  }

  # This removes the last element of the array, it's meant to shave
  # off the file name leaving only the directory name, as a
  # convenience, for the caller.
  pop @dirs;
  foreach $dir (@dirs) {
    $path .= "/$dir";
    stat($path);
    # only make if it isn't already there
    next if -d _;

    while (!-d _) {
      if (exists($fiddled{$path})) {
	warn "Cannot make directory $path, there is a file in the way.\n";
	return;
      }

      $fiddled{$path}=1;

      if (!-e _) {
	mkdir($path,0777);
	last;
      }

      if (unlink($path)) {
	warn "w3mir: removed file $path\n" if $verbose>=0;
      } else {
	warn "Unable to remove $path: $!\n";
	next;
      }
    
      warn "mkdir $path\n" if $debug;
      mkdir($path,0777) ||
	warn "Unable to create directory $path: $!\n";

      stat($path);
    }
  }
}


sub add_referer {
  # Add a referer to the list of referers of a document.  Unless it's
  # already there.
  # Don't mail me if you (only) think this is a bit like a toungetwiser:

  # Don't remember referers if BOTH fixup and referer header is disabled.
  return if $fixup==0 && $do_referer==0;

  my($rum_referee,$rum_referer) = @_ ;
  my $re_rum_referer;

  if (exists($rum_referers{$rum_referee})) {
    $re_rum_referer=quotemeta $rum_referer;
    if (!grep(m/^$re_rum_referer$/,@{$rum_referers{$rum_referee}})) {
      push(@{$rum_referers{$rum_referee}},$rum_referer);
      # warn "$rum_referee <- $rum_referer pushed\n";
    } else {
      # warn "$rum_referee <- $rum_referer NOT pushed\n";
    }
  } else {
    $rum_referers{$rum_referee}=[$rum_referer];
    # warn "$rum_referee <- $rum_referer pushed\n";
  }
}


sub user_apply {
  # Apply the user apply rules

  return &$user_apply_code(shift);

# Debug version:
#  my ($foo,$bar);
#  $foo=shift;
#  $bar=&$apply_code($foo);
#  print STDERR "Apply: $foo -> $bar\n";
#  return $bar;
}

sub internal_apply {
  # Apply the w3mir generated apply rules

  return &$apply_code(shift);
}


sub apply {
    # Apply the user apply rules.  Then if URL is wanted return result of
    # w3mir apply rules.  Return the undefined value otherwise.

    my $url = user_apply(shift);

    return internal_apply($url)
	if want_this($url);

    # print REMOVED $url,"\n";
    return undef;
}


sub want_this {
  # Find out if we want the url passed.  Just pass it on to the
  # generated functions.
  my($rum_url)=shift;

  # What about robot rules?

  # Does scope rule want this?
  return &$scope_code($rum_url) &&
    # Does user rule want this too?
    &$rule_code($rum_url) 
  
}


sub process_tag {
  # Process a tag in html file
  my $lf_referer = shift;	# User argument
  my $base_url = shift;		# Not used... why not?
  my $tag_name = shift;
  my $url_attrs = shift;

  # Retrun quickly if no URL attributes
  return unless defined($url_attrs);

  my $attrs = shift;

  my $rum_url;	# The absolute URL
  my $lf_url;	# The local filesystem url
  my $lf_url_o; # ... and it's object
  my $key;

  print STDERR "\nProcess Tag: $tag_name, URL attributes: ", 
  join(', ',@{$url_attrs}),"\nbase_url: ",$base_url,"\nlf_referer: ",
  $lf_referer,"\n" 
    if $debug>2;

  $lf_referer =~ s~^/~~;
  $lf_referer = "file:/$lf_referer";

  foreach $key (@{$url_attrs}) {
    if (defined($$attrs{$key})) {
      $rum_url=$$attrs{$key};
      print STDERR "$key = $rum_url\n" if $debug;
      $lf_url=apply($rum_url);
      if (defined($lf_url)) {

	print STDERR "Transformed to $lf_url\n" if $debug>2;

	$lf_url =~ s~^/~~;  # Remove leading / to avoid doubeling
	$lf_url_o=url "file:/$lf_url";

	# Save new value in the hash
	$$attrs{$key}=($lf_url_o->rel($lf_referer))->as_string;
	print STDERR "New value: ",$$attrs{$key},"\n" if $debug>2;

	# If there is potential information loss save the old value too
	$$attrs{"W3MIR".$key}=$rum_url if $infoloss;
      }
    }
  }
}


sub version {
  eval 'require LWP;';
  print $w3mir_agent,"\n";
  print "LWP version ",$LWP::VERSION,"\n" if defined $LWP::VERSION;
  print "Perl version: ",$],"\n";
  exit(0);
}


sub parse_args {
  my $f;
  my $i;

  $i=0;

  while ($f=shift) {
    $i++;
    $numarg++;
    # This is a demonstration against Getopts::Long.
    if ($f =~ s/^-+//) {
      $s=1,next if $f eq 's';			# Stdout
      $r=1,next if $f eq 'r';			# Recurse
      $fetch=1,next if $f eq 'fa';		# Fetch all, no date test
      $fetch=-1,next if $f eq 'fs';	# Fetch those we don't already have.
      $verbose=-1,next if $f eq 'q'; 		# Quiet
      $verbose=1,next if $f eq 'c';		# Chatty
      &version,next if $f eq 'v';		# Version
      $pause=shift,next if $f eq 'p';		# Pause between requests
      $retryPause=shift,next if $f eq 'rp';	# Pause between retries.
      $s=2,$convertnl=0,next if $f eq 'f';	# Forget
      $retry=shift,next if $f eq 't';		# reTry
      $list=1,next if $f eq 'l';		# List urls
      $iref=shift,next if $f eq 'ir';		# Initial referer
      $check_robottxt = 0,next if $f eq 'drr';	# Disable robots.txt rules.
      umask(oct(shift)),next if $f eq 'umask';
      parse_cfg_file(shift),next if $f eq 'cfgfile';
      usage(),exit 0 if ($f eq 'help' || $f eq 'h' || $f eq '?');
      $remove=1,next if $f eq 'R';
      $cache_header = 'Pragma: no-cache',next if $f eq 'pflush';
      $w3http::agent=$w3mir_agent=shift,next if $f eq 'agent';
      $abs=1,next if $f eq 'abs';
      $convertnl=0,$batch=1,next if $f eq 'B';
      $read_urls = 1,next if $f eq 'I';
      $convertnl=0,next if $f eq 'nnc';

      if ($f eq 'lc') {
	if ($i == 1) {
	  $lc=1;
	  $iinline=($lc?"(?i)":"");
	  $ipost=($lc?"i":"");
	  next;
	} else {
	  die "w3mir: -lc must be the first argument on the commandline.\n";
	}
      }

      if ($f eq 'P') {				# Proxy
	($w3http::proxyserver,$w3http::proxyport)= 
	  shift =~ /([^:]+):?(\d+)?/;
	$w3http::proxyport=80 unless $w3http::proxyport;
	$using_proxy=1;
	next;
      }
    
      if ($f eq 'd') {		# Debugging level
	$f=shift;
	unless (($debug = $f) > 0) {
	  die "w3mir: debug level must be a number greater than zero.\n";
	}
	next;
      }

      # Those were all the options...
      warn "w3mir: Unknown option: -$f.  Use -h for usage info.\n";
      exit(1);
      
    } elsif ($f =~ /^http:/) {
      my ($rum_url_o,$rum_reurl,$rum_rebase,$server);

      $rum_url_o=root_queue($f,'./');

      $rum_rebase = quotemeta( ($rum_url_o->as_string =~ m~^(.*/)~)[0] );

      push(@internal_apply,"s/^".$rum_rebase."//");
      $scope_fetch.="return 1 if m/^".$rum_rebase."/".$ipost.";\n";
      $scope_ignore.="return 0 if m/^".
	quotemeta("http://".$rum_url_o->netloc."/")."/".$ipost.";\n";

    } else {
      # If we get this far then the commandline is broken
      warn "Unknown commandline argument: $f.  Use -h for usage info.\n";
      $numarg--;
      exit(1);
    }
  }
  return 1;
}


sub parse_cfg_file {
  # Read the configuration file.  Aborts on errors.  Not good to
  # mirror something using the wrong config.

  my ( $file ) = @_ ;
  my ($key, $value, $authserver,$authrealm,$authuser,$authpasswd);
  my $i;

  die "w3mir: config file $file is not a file.\n" unless -f $file;
  open(CFGF, $file) || die "Could not open config file $file: $!\n";

  $i=0;

  while (<CFGF>) {
    # Trim off various junk
    chomp;
    s/^#.*//;
    s/^\s+|\s$//g;
    # Anything left?
    next if $_ eq '';
    # Examine remains
    $i++;
    $numarg++;

    ($key, $value) = split(/\s*:\s*/,$_,2);
    $key = lc $key;

    $iref=$value,next if ( $key eq 'initial-referer' );
    $header=$value,next if ( $key eq 'header' );
    $pause=numeric($value),next if ( $key eq 'pause' );
    $retryPause=numeric($value),next if ( $key eq 'retry-pause' );
    $debug=numeric($value),next if ( $key eq 'debug' );
    $retry=numeric($value),next if ( $key eq 'retries' );
    umask(numeric($value)),next if ( $key eq 'umask' );
    $check_robottxt=boolean($value),next if ( $key eq 'robot-rules' );
    $edit=boolean($value),next if ($key eq 'remove-nomirror');
    $indexname=$value,next if ($key eq 'index-name');
    $s=nway($value,'save','stdout','forget'),next 
      if ( $key eq 'file-disposition' );
    $verbose=nway($value,'quiet','brief','chatty')-1,next
      if ( $key eq 'verbosity' );
    $w3http::proxyuser=$value,next if $key eq 'http-proxy-user';
    $w3http::proxypasswd=$value,next if $key eq 'http-proxy-passwd';

    if ( $key eq 'cd' ) {
      $chdirto=$value;
      warn "Use of 'cd' is discouraged\n" unless $verbose==-1;
      next;
    }
    
    if ($key eq 'http-proxy') {
      ($w3http::proxyserver,$w3http::proxyport)= 
	$value =~ /([^:]+):?(\d+)?/;
      $w3http::proxyport=80 unless $w3http::proxyport;
      $using_proxy=1;
      next;
    }

    if ($key eq 'proxy-options') {
      my($val,$nval,@popts,$pragma);
      $pragma=1;
      foreach $val (split(/\s*,\*/,lc $value)) {
	$nval=nway($val,'no-pragma','revalidate','refresh','no-store',);
	# Force use of Cache-control: header
	$pragma=0 if ($nval==0);
	# use to force proxy to revalidate
	$pragma=0,push(@popts,'max-age=0') if ($nval==1);
	# use to force proxy to refresh
	push(@popts,'no-cache') if ($nval==2);
	# use if information transfered is sensitive
	$pragma=0,push(@popts,'no-store') if ($nval==3);
      }
      $cache_header=($pragma?'Pragma: ':'Cache-control: ').join(', ',@popts);
      next;
    }


    if ($key eq 'url') {
      my ($rum_url_o,$lf_dir,$rum_reurl,$rum_rebase);

      # A two argument URL: line?
      if ($value =~ m/^(.+)\s+(.+)/i) {
	# Two arguments.
	# The last is a directory, it must end in /
	$lf_dir=$2;
	$lf_dir.='/' unless $lf_dir =~ m~/$~;

	$rum_url_o=root_queue($1,$lf_dir);

	# The first is a URL, make it more canonical, find the base.
	# The namespace confusion in this section is correct.(??)
	$rum_rebase = quotemeta( ($rum_url_o->as_string =~ m~^(.*/)~)[0] );

	# print "URL: ",$rum_url_o->as_string,"\n";
	# print "Base: $rum_rebase\n";

	# Translate from rum space to lf space:
	push(@internal_apply,"s/^".$rum_rebase."/".quotemeta($lf_dir)."/");

	# That translation could lead to information loss.
	$infoloss=1;

	# Fetch rules tests the rum_url_o->as_string.  Fetch whatever
	# matches the base.
	$scope_fetch.="return 1 if m/^".$rum_rebase."/".$ipost.";\n";

	# Ignore whatever did not match the base.
	$scope_ignore.="return 0 if m/^".
	  quotemeta("http://".$rum_url_o->netloc."/")."/".$ipost.";\n";

      } else {
	$rum_url_o=root_queue($value,'./');

	$rum_rebase = quotemeta( ($rum_url_o->as_string =~ m~^(.*/)~)[0] );

	# Translate from rum space to lf space:
	push(@internal_apply,"s/^".$rum_rebase."//");

	$scope_fetch.="return 1 if m/^".$rum_rebase."/".$ipost.";\n";
	$scope_ignore.="return 0 if m/^".
	  quotemeta("http://".$rum_url_o->netloc."/")."/".$ipost.";\n";
      }
      next;
    }

    if ($key eq 'also-quene') {
      print STDERR 
	"Found 'also-quene' keyword, please replace with 'also-queue'\n";
      $key='also-queue';
    }

    if ($key eq 'also' || $key eq 'also-queue') {
      if ($value =~ m/^(.+)\s+(.+)/i) {
	my ($rum_url_o,$rum_url,$lf_dir,$rum_reurl,$rum_rebase);
	# Two arguments.
	# The last is a directory, it must end in /
	# print STDERR "URL ",$1," DIR ",$2,"\n";
	$rum_url=$1;
	$lf_dir=$2;
	$lf_dir.='/' unless $lf_dir =~ m~/$~;
	die "w3mir: The target path in Also: and Also-queue: directives must ".
	    "be relative\n"
		if substr($lf_dir,0,1) eq '/';

	if ($key eq 'also-queue') {
	  $rum_url_o=root_queue($rum_url,$lf_dir);
	} else {
	  root_queue("",$lf_dir);
	  $rum_url_o=url $rum_url;
	  $rum_url_o->host(lc $rum_url_o->host);
	}

	# The first is a URL, find the base
	$rum_rebase = quotemeta( ($rum_url_o->as_string =~ m~^(.*/)~)[0] );

#	print "URL: $rum_url_o->as_string\n";
#	print "Base: $rum_rebase\n";
#	print "Server: $server\n";

	# Ok, now we can transform and select stuff the right way
	push(@internal_apply,"s/^".$rum_rebase."/".quotemeta($lf_dir)."/");
	$infoloss=1;

	# Fetch rules tests the rum_url_o->as_string.  Fetch whatever
	# matches the base.
	$scope_fetch.="return 1 if m/^".$rum_rebase."/".$ipost.";\n";

	# Ignore whatever did not match the base.  This cures problem
	# with '..' from base in in rum space pointing within the the
	# scope in ra space.  We introduced a extra level (or more) of
	# directories with the apply above.  Must do same with 'Also:'
	# directives.
	$scope_ignore.="return 0 if m/^".
	  quotemeta("http://".$rum_url_o->netloc."/")."/".$ipost.";\n";
      } else {
	die "Also: requires 2 arguments\n";
      }
      next;
    }

    if ($key eq 'quene') {
      print STDERR "Found 'quene' keyword, please replace with 'queue'\n";
      $key='queue';
    }

    if ($key eq 'queue') {
      root_queue($value,"");
      next;
    }

    if ($key eq 'ignore-re' || $key eq 'fetch-re') {
      # Check that it's a re, better that I am strict than for perl to
      # make compilation errors.
      unless ($value =~ /^m(.).*\1[gimosx]*$/) {
	print STDERR "w3mir: $value is not a recognized regular expression\n";
	exit 1;
      }
      # Fall-through to next cases!
    }

    if ($key eq 'fetch' || $key eq 'fetch-re') {
      my $expr=$value;
      $expr = wild_re($expr).$ipost if ($key eq 'fetch');
      $rule_text.=' return 1 if '.$expr.";\n";
      next;
    }

    if ($key eq 'ignore' || $key eq 'ignore-re') {
      my $expr=$value;
      $expr = wild_re($expr).$ipost if ($key eq 'ignore');
      # print STDERR "Ignore expression: $expr\n";
      $rule_text.=' return 0 if '.$expr.";\n";
      next;
    }


    if ($key eq 'apply') {
      unless ($value =~ /^s(.).*\1.*\1[gimosxe]*$/) {
	print STDERR
	  "w3mir: '$value' is not a recognized regular expression\n";
	exit 1;
      }
      push(@user_apply,$value) ;
      $infoloss=1;
      next;
    }

    if ($key eq 'agent') {
      $w3http::agent=$w3mir_agent=$value;
      next;
    }

    # The authorization stuff:
    if ($key eq 'auth-domain') {
      $useauth=1;
      ($authserver, $authrealm) = split('/',$value,2);
      die "w3mir: server part of auth-domain has format server[:port]\n"
	unless $authserver =~ /^(\S+(:\d+)?)$|^\*$/;
      $authserver =~ s/:80$//;
      die "w3mir: auth-domain '$value' is not valid\n"
	if !defined($authserver) || !defined($authrealm);
      $authrealm=lc $authrealm;
    }

    $authuser=$value if ($key eq 'auth-user');
    $authpasswd=$value if ($key eq 'auth-passwd');

    # Got a full authentication spec?
    if ($authserver && $authrealm && $authuser && $authpasswd) {
      $authdata{$authserver}{$authrealm}=$authuser.":".$authpasswd;
      print "Authentication for $authserver/$authrealm is ".
	"$authuser/$authpasswd\n" if $verbose>=0;
      # exit;
      # Invalidate tmp vars
      $authserver=$authrealm=$authuser=$authpasswd=undef;
      next;
    }

    next if $key eq 'auth-user' || $key eq 'auth-passwd' || 
      $key eq 'auth-domain';

    if ($key eq 'fetch-options') {
      warn "w3mir: The 'fetch-options' directive has been renamed to 'options'\nw3mir: Please change your configuration file.\n";
      $key='options';
      # Fall through to 'options'!
    }

    if ($key eq 'options') {
      
      my($val,$nval);
      foreach $val (split(/\s*,\s*/,lc $value)) {
	if ($i==1) {
	  $nval=nway($val,'recurse','no-date-check','only-nonexistent',
		     'list-urls','lowercase','remove','batch','read-urls',
		     'abs','no-newline-conv','list-nonmirrored');
	  $r=1,next if $nval==0;
	  $fetch=1,next if $nval==1;
	  $fetch=-1,next if $nval==2;
	  $list=1,next if $nval==3;
	  if ($nval==4) {
	    $lc=1;
	    $iinline=($lc?"(?i)":"");
	    $ipost=($lc?"i":"");
	    next ;
	  }
	  $remove=1,next if $nval==5;
	  $convertnl=0,$batch=1,next if $nval==6;
	  $read_urls=1,next if $nval==7;
	  $abs=1,next if $nval==8;
	  $convertnl=0,next if $nval==9;
	  $list_nomir=1,next if $nval==10;
        } else {
	    die "w3mir: options must be the first directive in the config file.\n";
	}
      }
      next;
    }

    if ($key eq 'disable-headers') {
      my($val,$nval);
      foreach $val (split(/\s*,\s*/,lc $value)) {
	$nval=nway($val,'referer','user');
	$do_referer=0,next if $nval==0;
	$do_user=0,next if $nval==1;
      }
      next;
    }


    if ($key eq 'fixup') {

      $fixrc="$file";
      # warn "Fixrc: $fixrc\n";

      my($val,$nval);
      foreach $val (split(/\s*,\s*/,lc $value)) {
	$nval=nway($val,'on','run','noindex','off');
	$runfix=1,next if $nval==1;
	# Disable fixup
	$fixup=0,next if $nval==3;
	# Ignore everyting else
      }
      next;
    }

    die "w3mir: Unrecognized directive ('$key') in config file $file at line $.\n";

  }
  close(CFGF);

  if (defined($w3http::proxypasswd) && $w3http::proxyuser) {
    warn "Proxy authentication: ".$w3http::proxyuser.":".
      $w3http::proxypasswd."\n" if $verbose>=0;
  }

}


sub wild_re {
  # Here we translate unix wildcard subset to to perlre
  local($_) = shift;

  # Quote anything that's RE and not wildcard: / ( ) \ | { } + $ ^
  s~([\/\(\)\\\|\{\}\+)\$\^])~\\$1~g;
  # . -> \.
  s~\.~\\.~g;
  # * -> .*
  s~\*~\.\*~g;
  # ? -> .
  s~\?~\.~g;

  # print STDERR "wild_re: $_\n";

  return $_ = '/'.$_.'/';
}


sub numeric {
  # Check if argument is numeric?
  my ( $number ) = @_ ;
  return oct($number) if ($number =~ /\d+/ || $number =~ /\d+.\d+/);
  die "Expected a number, got \"$number\"\n";
}


sub boolean {
  my ( $boolean ) = @_ ;

  $boolean = lc $boolean;

  return 0 if ($boolean eq 'false' || $boolean eq 'off' || $boolean eq '0');
  return 1 if ($boolean eq 'true' || $boolean eq 'on' || $boolean eq '1');
  die "Expected a boolean, got \"$boolean\"\n";
}


sub nway {
  my ( $value ) = shift;
  my ( @values ) = @_;
  my ( $val ) = 0;

  $value = lc $value;
  while (@_) {
    return $val if $value eq shift;
    $val++;
  }
  die "Expected one of ".join(", ",@values).", got \"$value\"\n";
}


sub insert_at_start {
  # ark: inserts the first arg at the top of the html in the second arg
  # janl: The second arg must be a reference to a scalar.
  my( $str, $text_ref ) = @_;
  my( @possible ) =("<BODY.*?>", "</HEAD.*?>", "</TITLE.*?>", "<HTML.*?>" );
  my( $f, $done );
  
  $done=0;
  @_=@possible;
  
  while( $done!=1 && ($f=shift) ){
    # print "Searching for: $f\n";
    if( $$text_ref =~ /$f/i ){
      # print "found it!\n";
      $$text_ref =~ s/($f)/$1\n$str/i;
      $done=1;
    }
  }
}



sub rm_rf {
  # Recursively remove directories and other files
  # File::Path::rmtree does a similar thing but the messages are wrong

  my($remove)=shift;

  eval "use File::Find;" unless defined(&finddepth);

  die "w3mir: Could not load File::Find module when trying to remove $remove\n"
    unless defined(&find);

  die "w3mir: Removal safeguard triggered on '$remove'"
    if $remove =~ m~/\.\./~ || $remove =~ m~/\.\.$~ || $remove =~ m~/\.$~;

  die "rm_rf($remove); ";

  finddepth(\&remove_everything,$remove);

  if (rmdir($remove)) {
    print STDERR "\nw3mir: removed directory $remove\n" if $verbose>=0;
  } else {
    print STDERR "w3mir: could not remove $remove: $!\n";
  }
}


sub remove_everything {
  # This does the removal
  ((-d && rmdir($_)) || unlink($_)) && $verbose>=0 &&
    print STDERR "w3mir: removed $File::Find::name\n";
}



sub usage {
  my($message)=shift @_;

  print STDERR "w3mir: $message\n" if $message;
  
  die 'w3mir: usage: w3mir [options] <single-http-url>
          or: w3mir -B [-I] [options] [<http-urls>]

    Options :
	-agent <agent>	- Set the agent name.  Default is w3mir
	-abs		- Force all URLs to be absolute.
	-B		- Batch-get documents.
	-I		- The URLs to get are read from standard input.
	-c		- be more Chatty.
	-cfgfile <file> - Read config from file
	-d <debug-level>- set debug level to 1 or 2
	-drr		- Disable robots.txt rules.
	-f		- Forget all files, nothing is saved to disk.
	-fa		- Fetch All, will not check timestamps.
	-fs		- Fetch Some, do not fetch the files we already have.
	-ir <referer>	- Initial referer.  For picky servers.
	-l		- List URLs in the documents retrived.
	-lc		- Convert all URLs (and filenames) to lowercase.
				This does not work reliably.
	-p <n>		- Pause n seconds before retriving each doc.
	-q		- Quiet, error-messages only
        -rp <n>		- Retry Pause in seconds.
	-P <server:port>- Use host/port for proxy http requests
        -pflush		- Flush proxy server.
	-r		- Recursive mirroring.
        -R		- Remove files not referenced or not present on server.
	-s		- Send output to stdout instead of file
	-t <n>		- How many times to (re)try getting a failed doc?
        -umask <umask>  - Set umask for mirroring, must be usual octal format.
	-nnc		- No Newline Conversion.  Disable newline conversions.
	-v		- Show w3mir version.
';
}
__END__
# -*- perl -*- There must be a blank line here

=head1 NAME

w3mir - all purpose HTTP-copying and mirroring tool

=head1 SYNOPSIS

B<w3mir> [B<options>] [I<HTTP-URL>]

B<w3mir> B<-B> [B<options>] <I<HTTP-URLS>>

B<w3mir> is a all purpose HTTP copying and mirroring tool.  The
main focus of B<w3mir> is to create and maintain a browsable copy of
one, or several, remote WWW site(s).

Used to the max w3mir can retrive the contents of several related
sites and leave the mirror browseable via a local web server, or from
a filesystem, such as directly from a CDROM.  

B<w3mir> has options for all operations that are simple enough for
options.  For authentication and passwords, multiple site retrievals
and such you will have to resort to a L</CONFIGURATION-FILE>.  If
browsing from a filesystem references ending in '/' needs to be
rewritten to end in '/index.html', and in any case, if there are URLs
that are redirected will need to be changed to make the mirror
browseable, see the documentation of B<Fixup> in the
L</CONFIGURATION-FILE> secton.

B<w3mir>s default behavior is to do as little as possible and to be as
nice as possible to the server(s) it is getting documents from.  You
will need to read through the options list to make B<w3mir> do more
complex, and, useful things.  Most of the things B<w3mir> can do is
also documented in the w3mir-HOWTO which is available at the B<w3mir>
home-page (F<http://www.math.uio.no/~janl/w3mir/>) as well as in the
w3mir distribution bundle.

=head1 DESCRIPTION

You may specify many options and one HTTP-URL on the w3mir
command line.

A single HTTP URL I<must> be specified either on the command line or
in a B<URL> directive in a configuration file.  If the URL refers to a
directory it I<must> end with a "/", otherwise you might get surprised
at what gets retrieved (e.g. rather more than you expect).

Options must be prefixed with at least one - as shown below, you can
use more if you want to. B<-cfgfile> is equivalent to B<--cfgfile> or
even B<------cfgfile>.  Options cannot be I<clustered>, i.e., B<-r -R>
is not equivalent to B<-rR>.

=over 4

=item B<-h> | B<-help> | B<-?>

prints a brief summary of all command line options and exits.

=item B<-cfgfile> F<file>

Makes B<w3mir> read the given configuration file.  See the next section
for how to write such a file.

=item B<-r>

Puts B<w3mir> into recursive mode.  The default is to fetch only one
document and then quit.  'I<recursive>' mode means that all the
documents linked to the given document that are fetched, and all they
link to in turn and so on.  But only I<Iff> they are in the same
directory or under the same directory as the start document.  Any
document that is in or under the starting documents directory is said
to be within the I<scope of retrieval>.

=item B<-fa>

Fetch All.  Normally B<w3mir> will only get the document if it has been
updated since the last time it was fetched.  This switch turns that
check off.

=item B<-fs>

Fetch Some.  Not the opposite of B<-fa>, but rather, fetch the ones we
don't have already.  This is handy to restart copying of a site
incompletely copied by earlier, interrupted, runs of B<w3mir>.

=item B<-p> I<n>

Pause for I<n> seconds between getting each document.  The default is
30 seconds.

=item B<-rp> I<n>

Retry Pause, in seconds.  When B<w3mir> fails to get a document for some
technical reason (timeout mainly) the document will be queued for a
later retry.  The retry pause is how long B<w3mir> waits between
finishing a mirror pass before starting a new one to get the still
missing documents.  This should be a long time, so network conditions
have a chance to get better.  The default is 600 seconds (10 minutes),
which might be a bit too short, for batch running B<w3mir> I would
suggest an hour (3600 seconds) or more.

=item B<-t> I<n>

Number of reTries.  If B<w3mir> cannot get all the documents by the
I<n>th retry B<w3mir> gives up.  The default is 3.

=item B<-drr>

Disable Robot Rules.  The robot exclusion standard is described in
http://info.webcrawler.com/mak/projects/robots/norobots.html.  By
default B<w3mir> honors this standard.  This option causes B<w3mir> to
ignore it.

=item B<-nnc>

No Newline Conversion.  Normally w3mir converts the newline format of
all files that the web server says is a text file.  However, not all
web servers are reliable, and so binary files may become corrupted due
to the newline conversion w3mir performs.  Use this option to stop
w3mir from converting newlines.  This also causes the file to be
regarded as binary when written to disk, to disable the implicit
newline conversion when saving text files on most non-Unix systems.

This will probably be on by default in version 1.1 of w3mir, but not
in version 1.0.

=item B<-R>

Remove files.  Normally B<w3mir> will not remove files that are no
longer on the server/part of the retrieved web of files.  When this
option is specified all files no longer needed or found on the servers
will be removed.  If B<w3mir> fails to get a document for I<any> other
reason the file will not be removed.

=item B<-B>

Batch fetch documents whose URLs are given on the commandline.

In combination with the B<-r> and/or B<-l> switch all HTML and PDF
documents will be mined for URLs, but the documents will be saved on
disk unchanged.  When used with the B<-r> switch only one single URL
is allowed.  When not used with the B<-r> switch no HTML/URL
processing will be performed at all.  When the B<-B> switch is used
with B<-r> w3mir will not do repeated mirrorings reliably since the
changes w3mir needs to do, in the documents, to work reliably are not
done.  In any case it's best not to use B<-R> in combination with
B<-B> since that can result in deleting rather more documents than
expected.  Hwowever, if the person writing the documents being copied
is good about making references relative and placing the <HTML> tag at
the beginning of documents there is a fair chance that things will
work even so.  But I wouln't bet on it.  It will, however, work
reliably for repeated mirroring if the B<-r> switch is not used.

When the B<-B> switch is specified redirects for a given document will
be followed no matter where they point.  The redirected-to document
will be retrieved in the place of the original document.  This is a
potential weakness, since w3mir can be directed to fetch any document
anywhere on the web.

Unless used with B<-r> all retrived files will be stored in one
directory using the remote filename as the local filename.  I.e.,
F<http://foo/bar/gazonk.html> will be saved as F<gazonk.html>.
F<http://foo/bar/> will be saved as F<bar-index.html> so as to avoid
name colitions for the common case of URLs ending in /.

=item B<-I>

This switch can only be used with the B<-B> switch, and only after it
on the commandline or configuration file.  When given w3mir will get
URLs from standard input (i.e., w3mir can be used as the end of a pipe
that produces URLs.)  There should only be one URL pr. line of input.

=item B<-q>

Quiet.  Turns off all informational messages, only errors will be
output.

=item B<-c>

Chatty.  B<w3mir> will output more progress information.  This can be
used if you're watching B<w3mir> work.

=item B<-v>

Version.  Output B<w3mir>s version.

=item B<-s>

Copy the given document(s) to STDOUT.

=item B<-f>

Forget.  The retrieved documents are not saved on disk, they are just
forgotten.  This can be used to prime the cache in proxy servers, or
not save documents you just want to list the URLs in (see B<-l>).

=item B<-l>

List the URLs referred to in the retrieved document(s) on STDOUT.

=item B<-umask> I<n>

Sets the umask, i.e., the permission bits of all retrieved files.  The
number is taken as octal unless it starts with a 0x, in which case
it's taken as hexadecimal.  No matter what you set this to make sure
you get write as well as read access to created files and directories.

Typical values are: 

=over 8

=item 022

let everyone read the files (and directories), only you can change
them. 

=item 027

you and everyone in the same file-group as you can read, only you can
change them.

=item 077

only you can read the files, only you can change them.

=item 0

everyone can read, write and change everything.

=back

The default is whatever was set when B<w3mir> was invoked.  022 is a
reasonable value.

This option has no meaning, or effect, on Win32 platforms.

=item B<-P> I<server:port>

Use the given server and port is a HTTP proxy server.  If no port is
given port 80 is assumed (this is the normal HTTP port).  This is
useful if you are inside a firewall, or use a proxy server to save
bandwidth.

=item B<-pflush>

Proxy flush, force the proxy server to flush it's cache and re-get the
document from the source.  The I<Pragma: no-cache> HTTP/1.0 header is
used to implement this.

=item B<-ir> I<referrer>

Initial Referrer.  Set the referrer of the first retrieved document.
Some servers are reluctant to serve certain documents unless this is
set right.

=item B<-agent> I<agent>

Set the HTTP User-Agent fields value.  Some servers will serve
different documents according to the WWW browsers capabilities.
B<w3mir> normally has B<w3mir>/I<version> in this header field.
Netscape uses things like B<Mozilla/3.01 (X11; I; Linux 2.0.30 i586)>
and MSIE uses things like B<Mozilla/2.0 (compatible; MSIE 3.02;
Windows NT)> (remember to enclose agent strings with spaces in with
double quotes ("))

=item B<-lc>

Lower Case URLs. Some OSes, like W95 and NT, are not case sensitive
when it comes to filenames.  Thus web masters using such OSes can case
filenames differently in different places (apps.html, Apps.html,
APPS.HTML).  If you mirror to a Unix machine this can result in one
file on the server becoming many in the mirror.  This option
lowercases all filenames so the mirror corresponds better with the
server.

If given it must be the first option on the command line.

This option does not work perfectly.  Most especially for mixed case
host-names.

=item B<-d> I<n>

Set the debug level.  A debug level higher than 0 will produce lots of
extra output for debugging purposes.

=item B<-abs>

Force all URLs to be absolute.  If you retrive
F<http://www.ifi.uio.no/~janl/index.html> and it references foo.html
the referense is absolutified into
F<http://www.ifi.uio.no/~janl/foo.html>.  In other words, you get
absolute references to the origin site if you use this option.

=back

=head1 CONFIGURATION-FILE

Most things can be mirrored with a (long) command line.  But multi
server mirroring, authentication and some other things are only
available through a configuration file.  A configuration file can
either be specified with the B<-cfgfile> switch, but w3mir also looks
for .w3mirc (w3mir.ini on Win32 platforms) in the directory where
w3mir is started from.

The configuration file consists of lines of comments and directives.
A directive consists of a keyword followed by a colon (:) and then one
or several arguments.

 # This is a comment.  And the next line is a directive:
 Options: recurse, remove

A comment can only start at the beginning of a line.  The directive
keywords are not case-sensitive, but the arguments I<might> be.

=over 4

=item Options: I<recurse> | I<no-date-check> | I<only-nonexistent> | I<list-urls> | I<lowercase> | I<remove> | I<batch> | I<input-urls> | I<no-newline-conv> | I<list-nonmirrored>

This must be the first directive in a configuration file.  

=over 8

=item I<recurse>

see B<-r> switch.

=item I<no-date-check>

see B<-fa> switch.

=item I<only-nonexistent>

see B<-fs> switch.

=item I<list-urls>

see B<-l> option.

=item I<lowercase>

see B<-lc> option. 

=item I<remove>

see B<-R> option.

=item I<batch>

see B<-B> option.

=item I<input-urls>

see B<-I> option.

=item I<no-newline-conv>

see B<-nnc> option.

=item I<list-nonmirrored>

List URLs not mirrored in a file called .notmirrored ('notmir' on
win32).  It will contain a lot of duplicate lines and quite possebly
be quite large.

=back

=item URL: I<HTTP-URL> [I<target-directory>]

The URL directive may only appear once in any configuration file.

Without the optional target directory argument it corresponds directly
to the I<single-HTTP-URL> argument on the command line.  

If the optional target directory is given all documents from under the
given URL will be stored in that directory, and under.  The target
directory is most likely only specified if the B<Also> directive is
also specified.

If the URL given refers to a directory it I<must> end in a "/",
otherwise you might get quite surprised at what gets retrieved.

Either one URL: directive or the single-HTTP-URL at the command-line
I<must> be given.

=item Also: I<HTTP-URL directory>

This directive is only meaningful if the I<recurse> (or B<-r>)
option is given.

The directive enlarges the scope of a recursive retrieval to contain
the given HTTP-URL and all documents in the same directory or under.
Any documents retrieved because of this directive will be stored in the
given directory of the mirror.

In practice this means that if the documents to be retrieved are stored
on several servers, or in several hierarchies on one server or any
combination of those.  Then the B<Also> directive ensures that we get
everything into one single mirror.

This also means that if you're retrieving

  URL: http://www.foo.org/gazonk/

but it has inline icons or images stored in http://www.foo.org/icons/
which you will also want to get, then that will be retrieved as well by
entering

  Also: http://www.foo.org/icons/ icons

As with the URL directive, if the URL refers to a directory it I<must>
end in a "/".

Another use for it is when mirroring sites that have several names
that all refer to the same (logical) server:

  URL: http://www.midifest.com/
  Also: http://midifest.com/ .

At this point in time B<w3mir> has no mechanism to easily enlarge the
scope of a mirror after it has been established.  That means that you
should survey the documents you are going to retrieve to find out what
icons, graphics and other things they refer to that you want.  And
what other sites you might like to retrieve.  If you find out that
something is missing you will have to delete the whole mirror, add the
needed B<Also> directives and then reestablish the mirror.  This lack
of flexibility in what to retrieve will be addressed at a later date.

See also the B<Also-quene> directive.

=item Also-quene: I<HTTP-URL directory>

This is like Also, except that the URL itself is also quened.  The
Also directive will not cause any documents to be retrived UNLESS they
are referenced by some other document w3mir has already retrived.

=item Quene: I<HTTP-URL>

This is quenes the URL for retrival, but does not enlarge the scope of
the retrival.  If the URL is outside the scope of retrival it will not
be retrived anyway.

The observant reader will see that B<Also-quene> is like B<Also>
combined with B<Quene>.

=item Initial-referer: I<referer>

see B<-ir> option.

=item Ignore: F<wildcard>

=item Fetch: F<wildcard>

=item Ignore-RE: F<regular-expression>

=item Fetch-RE: F<regular-expression>

These four are used to set up rules about which documents, within the
scope of retrieval, should be gotten and which not.  The default is to
get I<anything> that is within the scope of retrieval.  That may not
be practical though.  This goes for CGI scripts, and especially server
side image maps and other things that are executed/evaluated on the
server.  There might be other things you want unfetched as well.

B<w3mir> stores the I<Ignore>/I<Fetch> rules in a list.  When a
document is considered for retrieval the URL is checked against the
list in the same order that the rules appeared in the configuration
file.  If the URL matches any rule the search stops at once.  If it
matched a I<Ignore> rule the document is not fetched and any URLs in
other documents pointing to it will point to the document at the
original server (not inside the mirror).  If it matched a I<Fetch>
rule the document is gotten.  If not matched by any ruøes the document
is gotten.

The F<wildcard>s are a very limited subset of Unix-wildcards.
B<w3mir> understands only 'I<?>', 'I<*>', and 'I<[x-y]>' ranges.

The F<perl-regular-expression> is perls superset of the normal Unix
regular expression syntax.  They must be completely specified,
including the prefixed m, a delimiter of your choice (except the
paired delimiters: parenthesis, brackets and braces), and any of the
RE modifiers. E.g.,

  Ignore-RE: m/.gif$/i

or

  Ignore-RE: m~/.*/.*/.*/~

and so on.  "#" cannot be used as delimiter as it is the comment
character in the configuration file.  This also has the bad
side-effect of making you unable to match fragment names (#foobar)
directly.  Fortunately perl allows writing ``#'' as ``\043''.

You must be very carefull of using the RE anchors (``^'' and ``$''
with the RE versions of these and the I<Apply> directive. Given the
rules:

  Fetch-RE: m/foobar.cgi$/
  Ignore: *.cgi

the all files called ``foobar.cgi'' will be fetched. However, if the
file is referenced as ``foobar.cgi?query=mp3'' it will I<not> be
fetched since the ``$'' anchor will prevent it from matching the
I<Fetch-RE> directive and then it will match the I<Ignore> directive
instead. If you want to match ``foobar.cgi'' but not ``foobar.cgifu''
you can use perls ``\b'' character class which matches a word
boundrary:

  Fetch-RE: m/foobar.cgi\b/
  Ignore: *.cgi

which will get ``foobar.cgi'' as well as ``foobar.cgi?query=mp3'' but
not ``foobar.cgifu''. BUT, you must keep in mind that a lot of
diffetent characters make a word boundrary, maybe something more
subtle is needed.

=item Apply: I<regular-expression>

This is used to change a URL into another URL.  It is a potentially
I<very> powerful feature, and it also provides ample chance for you to
shoot your own foot. The whole aparatus is somewhat tenative, if you
find there is a need for changes in how Apply rules work please
E-mail. If you are going to use this feature please read the
documentation for I<Fetch-RE> and I<Ignore-RE> first.

The B<Apply> expressions are applied, in sequence, to the URLs in
their absolute form. I.e., with the whole
http://host:port/dir/ec/tory/file URL. It is only after this B<w3mir>
checks if a document is within the scope of retrieval or not. That
means that B<Apply> rules can be used to change certain URLs to fall
inside the scope of retrieval, and vice versa.

The I<regular-expression> is perls superset of the usual Unix regular
expressions for substitution.  As with I<Fetch> and I<Ignore> rules it
must be specified fully, with the I<s> and delimiting character.  It
has the same restrictions with regards to delimiters. E.g.,

  Apply: s~/foo/~/bar/~i

to translate the path element I<foo> to I<bar> in all URLs.

"#" cannot be used as delimiter as it is the comment character in the
configuration file.

Please note that w3mir expects that URLs identifying 'directories'
keep idenfifying directories after application of Apply rules.  Ditto
for files.

=item Agent: I<agent>

see B<-agent> option.

=item Pause: I<n>

see B<-p> option.

=item Retry-Pause: I<n>

see B<-rp> option.

=item Retries: I<n>

see B<-t> option.

=item debug: I<n>

see B<-d> option.

=item umask I<n>

see B<-umask> option.

=item Robot-Rules: I<on> | I<off>

Turn robot rules on of off.  See B<-drr> option.

=item Remove-Nomirror: I<on> | I<off>

If this is enabled sections between two consecutive

  <!--NO MIRROR-->

comments in a mirrored document will be removed.  This editing is
performed even if batch getting is specified.

=item Header: I<html/text>

Insert this I<complete> html/text into the start of the document.
This will be done even if batch is specified.

=item File-Disposition: I<save> | I<stdout> | I<forget>

What to do with a retrieved file.  The I<save> alternative is default.
The two others correspond to the B<-s> and B<-f> options.  Only one
may be specified.

=item Verbosity: I<quiet> | I<brief> | I<chatty>

How much B<w3mir> informs you of it's progress.  I<Brief> is the
default.  The two others correspond to the B<-q> and B<-c> switches.

=item Cd: I<directory>

Change to given directory before starting work.  If it does not exist
it will be quietly created.  Using this option breaks the 'fixup'
code so consider not using it, ever.

=item HTTP-Proxy: I<server:port>

see the B<-P> switch.

=item HTTP-Proxy-user: I<username>

=item HTTP-Proxy-passwd: I<password>

These two are is used to activate authentication with the proxy
server.  L<w3mir> only supports I<basic> proxy autentication, and is
quite simpleminded about it, if proxy authentication is on L<w3mir>
will always give it to the proxy.  The domain concept is not supported
with proxy-authentication.

=item Proxy-Options: I<no-pragma> | I<revalidate> | I<refresh> | I<no-store>

Set proxy options.  There are two ways to pass proxy options, HTTP/1.0
compatible and HTTP/1.1 compatible.  Newer proxy-servers will
understand the 1.1 way as well as 1.0.  With old proxy-servers only
the 1.0 way will work.  L<w3mir> will prefer the 1.0 way.

The only 1.0 compatible proxy-option is I<refresh>, it corresponds to
the B<-pflush> option and forces the proxy server to pass the request
to a upstream server to retrieve a I<fresh> copy of the document. 

The I<no-pragma> option forces w3mir to use the HTTP/1.1 proxy
control header, use this only with servers you know to be new,
otherwise it won't work at all.  Use of any option but I<refresh> will
also cause HTTP/1.1 to be used.  

I<revalidate> forces the proxy server to contact the upstream server
to validate that it has a fresh copy of the document.  This is nicer
to the net than I<refresh> option which forces re-get of the document
no matter if the server has a fresh copy already.

I<no-store> forbids the proxy from storing the document in other than
in transient storage.  This can be used when transferring sensitive
documents, but is by no means any warranty that the document can't be
found on any storage device on the proxy-server after the transfer.
Cryptography, if legal in your contry, is the solution if you want the
contents to be secret.

I<refresh> corresponds to the HTTP/1.0 header I<Pragma: no-cache> or
the identical HTTP/1.1 I<Cache-control> option.  I<revalidate> and
I<no-store> corresponds to I<max-age=0> and I<no-store> respectively.

=item Authorization

B<w3mir> supports only the I<basic> authentication of HTTP/1.0.  This
method can assign a password to a given user/server/I<realm>.  The
"user" is your user-name on the server.  The "server" is the server.
The I<realm> is a HTTP concept.  It is simply a grouping of files and
documents.  One file or a whole directory hierarchy can belong to a
realm.  One server may have many realms.  A user may have separate
passwords for each realm, or the same password for all the realms the
user has access to.  A combination of a server and a realm is called a
I<domain>.

=over 8

=item Auth-Domain: I<server:port/realm>

Give the server and port, and the belonging realm (making a domain)
that the following authentication data holds for.  You may specify "*"
wildcard for either of I<server:port> and I<realm>, this will work
well if you only have one usernme and password on all the servers
mirrored.

=item Auth-User: I<user>

Your user-name.

=item Auth-Passwd: I<password>

Your password.

=back

These three directives may be repeated, in clusters, as many times as
needed to give the necessary authentication information

=item Disable-Headers: I<referer> | I<user>

Stop B<w3mir> from sending the given headers.  This can be used for
anonymity, making your retrievals harder to track.  It will be even
harder if you specify a generic B<Agent>, like Netscape.

=item Fixup: I<...>

This directive controls some aspects of the separate program w3mfix.
w3mfix uses the same configuration file as w3mir since it needs a lot
of the information in the B<w3mir> configuration file to do it's work
correctly.  B<w3mfix> is used to make mirrors more browseable on
filesystems (disk or CDROM), and to fix redirected URLs and some other
URL editing.  If you want a mirror to be browseable of disk or CDROM
you almost certainly need to run w3mfix.  In many cases it is not
necessary when you run a mirror to be used through a WWW server.

To make B<w3mir> write the data files B<w3mfix> needs, and do nothing
else, simply put

=over 8

  Fixup: on

=back

in the configuration file.  To make B<w3mir> run B<w3mfix>
automatically after each time B<w3mir> has completed a mirror run
specify

=over 8

  Fixup: run

=back

L<w3mfix> is documented in a separate man page in a effort to not
prolong I<this> manpage unnecessarily.

=item Index-name: I<name-of-index-file>

When retriving URLs ending in '/' w3mir needs to append a filename to
store it localy.  The default value for this is 'index.html' (this is
the most used, its use originated in the NCSA HTTPD as far as I know).
Some WWW servers use the filename 'Welcome.html' or 'welcome.html'
instead (this was the default in the old CERN HTTPD).  And servers
running on limited OSes frequently use 'index.htm'.  To keep things
consistent and sane w3mir and the server should use the same name.
Put

  Index-name: welcome.html

when mirroring from a site that uses that convention.

When doing a multiserver retrival where the servers use two or more
different names for this you should use B<Apply> rules to make the
names consistent within the mirror.

When making a mirror for use with a WWW server, the mirror should use
the same name as the new server for this, to acomplish that
B<Index-name> should be combined with B<Apply>.

Here is an example of use in the to latter cases when Welcome.html is
the prefered I<index> name:

  Index-name: Welcome.html
  Apply: s~/index.html$~/Welcome.html~

Similarly, if index.html is the prefered I<index> name.

  Apply: s~/Welcome.html~/index.html~

I<Index-name> is not needed since index.html is the default index name.

=back

=head1 EXAMPLES

=over 4

=item * Just get the latest Dr-Fun if it has been changed since the last
time

 w3mir http://sunsite.unc.edu/Dave/Dr-Fun/latest.jpg

=item * Recursively fetch everything on the Star Wars site, remove
what is no longer at the server from the mirror:

 w3mir -R -r http://www.starwars.com/

=item * Fetch the contents of the Sega site through a proxy, pausing
for 30 seconds between each document

 w3mir -r -p 30 -P www.foo.org:4321 http://www.sega.com/

=item * Do everything according to F<w3mir.cfg>

 w3mir -cfgfile w3mir.cfg

=item * A simple configuration file

 # Remember, options first, as many as you like, comma separated
 Options: recurse, remove
 #
 # Start here:
 URL: http://www.starwars.com/
 #
 # Speed things up
 Pause: 0
 #
 # Don't get junk
 Ignore: *.cgi
 Ignore: *-cgi
 Ignore: *.map
 #
 # Proxy:
 HTTP-Proxy: www.foo.org:4321
 #
 # You _should_ cd away from the directory where the config file is.
 cd: starwars
 #
 # Authentication:
 Auth-domain: server:port/realm
 Auth-user: me
 Auth-passwd: my_password
 #
 # You can use '*' in place of server:port and/or realm:
 Auth-domain: */*
 Auth-user: otherme
 Auth-user: otherpassword

=item Also:

 # Retrive all of janl's home pages:
 Options: recurse
 #
 # This is the two argument form of URL:.  It fetches the first into the second
 URL: http://www.math.uio.no/~janl/ math/janl
 #
 # These says that any documents refered to that lives under these places
 # should be gotten too.  Into the named directories.  Two arguments are
 # required for 'Also:'.
 Also: http://www.math.uio.no/drift/personer/ math/drift
 Also: http://www.ifi.uio.no/~janl/ ifi/janl
 Also: http://www.mi.uib.no/~nicolai/ math-uib/nicolai
 #
 # The options above will result in this directory hierarchy under
 # where you started w3mir:
 # w3mir/math/janl		files from http://www.math.uio.no/~janl
 # w3mir/math/drift		from http://www.math.uio.no/drift/personer/
 # w3mir/ifi/janl		from http://www.ifi.uio.no/~janl/
 # w3mir/math-uib/nicolai	from http://www.mi.uib.no/~nicolai/

=item Ignore-RE and Fetch-RE

 # Get only jpeg/jpg files, no gifs
 Fetch-RE: m/\.jp(e)?g$/
 Ignore-RE: m/\.gif$/

=item Apply

As I said earlier, B<Apply> has not been used for Real Work yet, that
I know of.  But B<Apply> I<could>, be used to map all web servers at
the university of Oslo inside the scope of retrieval very easily:

  # Start at the main server
  URL: http://www.uio.no/
  # Change http://*.uio.no and http://129.240.* to be a subdirectory
  # of http://www.uio.no/.
  Apply: s~^http://(.*\.uio\.no(?:\d+)?)/~http://www.uio.no/$1/~i
  Apply: s~^http://(129\.240\.[^:]*(?:\d+)?)/~http://www.uio.no/$1/~i


=back

There are two rather extensive example files in the B<w3mir> distribution.

=head1 BUGS

=over 4

=item The -lc switch does not work too well.

=back

=head1 FEATURES

These are not bugs.

=over 4

=item URLs with two /es ('//') in the path component does not work as
some might expect.  According to my reading of the URL spec. it is an
illegal construct, which is a Good Thing, because I don't know how to
handle it if it's legal.

=item If you start at http://foo/bar/ then index.html might be gotten
twice.

=item Some documents point to a point above the server root, i.e.,
http://some.server/../stuff.html.  Netscape, and other browsers, in
defiance of the URL standard documents will change the URL to
http://some.server/stuff.html.  W3mir will not.

=item Authentication is I<only> tried if the server requests it.  This
might lead to a lot of extra connections going up and down, but that's
the way it's gotta work for now.

=back

=head1 SEE ALSO

L<w3mfix>

=head1 AUTHORS

B<w3mir>s authors can be reached at I<w3mir-core@usit.uio.no>.
B<w3mir>s home page is at http://www.math.uio.no/~janl/w3mir/
