package OnSearch::WebClient; 

BEGIN { $ENV{MCarp} = 'verbose'; }

# '$Id: WebClient.pm,v 1.7 2005/08/16 05:34:03 kiesling Exp $'

use strict;
use warnings;
use Carp;
use Socket;

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
@ISA = qw(Exporter DynaLoader);
@EXPORT = (qw/get_req parse_url $VERSION/);
%EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

($VERSION) = ('$Revision: 1.7 $' =~ /.*: (\S*)/);

# Instead of importing.
my $CRLF = "\015\012";

sub get_req {
    my $url = $_[0];
    my $lineinput = '';
    my $page = '';
    my $reloc = 0;

    my ($proto_name, $server, $port) = 
	($url =~ m|(\w+):\/\/([^/:]+):?(\d*)|);
    $port = 80 unless $port;
    unless ($server) { warn "Invalid URL: $url"; return undef; }
    

    my $ra = $ENV{REMOTE_ADDR};
    my $sp = $ENV{SERVER_PORT};

my $getrequest = qq|GET $url HTTP/1.1
Host: $ra $sp
User-Agent: OnSearch $VERSION

|;

    my $addr = gethostbyname ("$server");
    if (! $addr ) { 
        ### 
	### Should there be a verbose setting to resource temporarily
	### unavailable errors for unreachable URLs....
	###
	### warn $!; 
	###
	return undef; 
    }
    
    socket (SOCKFH, PF_INET, SOCK_STREAM, getprotobyname ('tcp')) || die $!;
    my $paddr = inet_aton ($server);
    unless ($paddr) { warn $!; return undef; }
    my $sinput = sockaddr_in ($port, $paddr);
    if (!connect (SOCKFH, $sinput)) {
	###
	### See IO::Socket for error handling for concurrent connection
	### handling.
	###
	### warn $!;
	return undef;
    }
    my $deffhprev = select (SOCKFH); $| = 1; select ($deffhprev);
    $getrequest =~ s"\n"$CRLF"gs;
    if (syswrite (SOCKFH, $getrequest, length($getrequest)) 
        != length ($getrequest)) {
        warn "get_req $! PID $$.";
        return undef;
    }

    while (defined ($lineinput = <SOCKFH>)) {
	next if ($lineinput =~ /200 OK/i);
        if ($reloc && $lineinput =~ /^Location:/) {
            $lineinput =~ s"$CRLF|\n""g;
	    $page = $lineinput;
	    last;
	}
	if ($lineinput =~ m|HTTP/1.[01]\s+[45](\d+)|) {
	    $lineinput =~ s"$CRLF"\n"g;
            $lineinput =~ s"$CRLF|\n""g;
	    $page = $lineinput;
	    last;
	}
        # A redirection.  
	if ($lineinput =~ m|HTTP/1.[01]\s+3(\d+)|) {
           $reloc = 1;
	}
	$page .= $lineinput;
    }

    shutdown (SOCKFH, 2);
    $page =~ s"$CRLF"\n"gs;
    return $page;
}

sub parse_url {
    my ($proto_name, $server, $port, $path) =
	($_[0] =~ m|(\w+)://([^/:]+):?(\d*)(/?.*)|);
    $path = '/' unless $path;
    $port = 80 unless $port;
    return ($proto_name, $server, $port, $path);
}

package OnSearch::WebBot;

use OnSearch;
use OnSearch::AppConfig;
use OnSearch::Utils;

my $logfunc = \&OnSearch::WebLog::clf;

sub new {
    my $class = shift || __PACKAGE__;
    my $webcachepath = web_cache_path ();
    my $self = { level => 0,
		 urls => [],
		 cachedurls => [],
		 unavailurls => [],
		 disallowedurls => [],
		 cachedir => $webcachepath,
	     };
    bless ($self, $class);
    return $self;
}

sub siteindex {
    my $self = shift;
    my $url = $_[0];

    my ($chldpid, $gchldpid);

  FORK:
    if ($chldpid = fork ()) {
	$self -> {chldpid} = $chldpid;
	return $chldpid;
    } elsif (defined $chldpid) {
	setpgrp (0,0);
    } elsif ($! =~ /No more processes|Resource temporarily unavailable/) {
	sleep 2;
	redo FORK;
    } else {
	die "siteindex () error PID $chldpid: $!";
    }

    ###
    ###  Completely detach the indexer from the terminal.  The 
    ###  calling script should return as soon as possible, or the user
    ###  faces a blank screen while the server connection is alive but 
    ###  idle.  Even worse, when the Web server closes an idle 
    ###  connection, sends a SIGTERM, and respawns, it causes the
    ###  foreground script to restart.
    ###

  FORK2:
    if ($gchldpid = fork ()) {
	$self -> {gchldpid} = $gchldpid;
	###
	### Indicate that we're returning from the child process,
	### so we don't run the CGI script twice.  Do the same 
	### below also.
	###
	return 0; 
    } elsif (defined $gchldpid) {
	###
        ###  A real daemon would set its euid and egid
        ###  here, but because the Web server is running the
        ###  script, the uid and gid should already be correct.
	###
	chdir '/' || die "OnSearch: Could not chdir /: $!\n";
	close STDIN;
	close STDOUT;
	close STDERR;
    } elsif ($! =~ /No more processes|Resource temporarily unavailable/) {
	sleep 2;
	redo FORK2;
    } else {
	die "siteindex () error PID $chldpid: $!";
    }

    &$logfunc ('notice', "WebIndex started PID $$.");
    $self -> fetch_page_urls ($url);
    sigwrapper (qw/CHLD/, undef, \&run_onindex);

    return 0;
}

##
##  Server responses. Upper/lower case may vary.
##
## Server:
## MIME-version:
## Content-Type:
## Last-modified:
## Content-length:
## Connection:
## Cache-Control:
## Pragma:
## Transfer-Encoding:
## Upgrade:
## Content-Location: 
## Location:
## Via:
## Accept-Ranges:
## Age:
## Proxy-Authenticate:
## Public:
## Retry-After:
## Server:
## Set-Cookie:
## Vary:
## Warning:
## WWW-Authenticate:

sub fetch_page_urls {
    my $self = shift;
    my $url = $_[0];

    my ($cfg, $verbose, $nontargeturls, $r);
    my ($urldefault);
    my (@furls, $fpage);
    my ($fbaseurl, $fbasepath, $fservername);

    $cfg = OnSearch::AppConfig -> new;
    $verbose = $cfg -> str ('VerboseWebIndexer');

    ++$self -> {level};

    my ($fproto_name, $fserver, $fport, $fpath) = 
	OnSearch::WebClient::parse_url ($url);

    unless ($fproto_name && $fserver && $fpath) {
	&$logfunc ('notice', 
	       "WebIndex ".$self -> {level} . ". url $url is unparseable.")
	    if $verbose;
	  --$self -> {level}; 
	return 1;
      } else {
	  ($fbasepath) = ($fpath =~ /(.*)\//);
	  $fbaseurl = "$fproto_name://$fserver:$fport$fbasepath";
	  $fservername = ((length ($fport) || ($fport =~ /80/)) ? 
			     "$fproto_name://$fserver:$fport" : "$fproto_name://$fserver");
      }

    &$logfunc ('notice',"WebIndex ".$self -> {level}.". url $url") if $verbose;

    $fpage = OnSearch::WebClient::get_req ($url);
    if ($!) {
	&$logfunc ('warning', "WebClient get_req ($url): $!");
    }
    if (! $fpage) {
	push @{$self -> {unavailurls}}, ($url);
	--$self -> {level}; 
	return 1;
    }

    ###
    ### Response is a redirection header.
    ###
    if ($fpage =~ /^Location/) {
	my ($flabel, $floc) = split /:\s+/, $fpage;
	&$logfunc ('notice', 
		   "WebIndex ".$self->{level}.". Page %s redirected to %s.", 
		   $url, $floc)
	    if $verbose;
	my $r = $self -> fetch_page_urls ($floc);
    }
    ###
    ### Response is an error. Try retrieving "URL/index.html"
    ### if the URL doesn't specify a HTML page.
    ###
    if ($fpage =~ m|HTTP/1.[01]\s+[45](\d+)|) {
	if ($fpath eq '/') {
	    $urldefault = $url . 'index.html';
	    &$logfunc ('notice', 
       "WebIndex ".$self->{level}.". Page %s: %s. Trying %s.", 
		       $url, $fpage, $urldefault)
		if $verbose;
	    $fpage = $self -> fetch_page_urls ($urldefault);
	    --$self -> {level}; 
	    return 0;
	} else {
	    &$logfunc ('notice', 
       "WebIndex ".$self->{level}.". Page %s: %s.", $url, $fpage)
		if $verbose;
	      --$self -> {level};
	    push @{$self -> {unavailurls}}, ($url);
	    return 1;
	}
    }

    @furls = OnSearch::Utils::document_urls ($fpage, $fbaseurl);
    if ($! || $@) {
	warn  "Error finding URLS in $url: $! $@.";
	undef $!; undef $@;
	return 1;
    }

    $self -> cache_page ($fpage, $url);

    FU: foreach my $fu (@furls) { 
	foreach my $c (@{$self -> {cachedurls}}) {
	    if ($fu eq $c) { 
		next FU;
	    }
	}
	foreach my $c (@{$self -> {unavailurls}}) {
	    if ($fu eq $c) { 
		next FU;
	    }
	}

	unless ($r = $self -> url_disallowed ($fservername, $fu)) {
	    $r = $self -> fetch_page_urls ($fu) 
	} else {
	    &$logfunc ('notice', 
		       "WebIndex ".$self->{level}.". $fu disallowed.");
	    next FU;
	}
	
	if ($!) {
	    &$logfunc ('warning', 
       "Webindex ".$self->{level}. ". fetch_page_urls ($fu): $!.");
	    undef $!;
	    ###
	    ### Not necessary to return here.
	    ###
	}
    }

    --$self -> {level};
    return 0;
}

sub cache_page {
    my $self = shift;
    my $page = $_[0];
    my $url = $_[1];

    my ($cfg, $verbose, $content_location);

    $cfg = OnSearch::AppConfig -> new;
    $verbose = $cfg -> on (qw/VerboseWebIndexer/);

    my ($proto_name, $server, $port, $path) = 
	OnSearch::WebClient::parse_url ($url);

    ###
    ### If the URL ends in "/," determine if there's a 
    ### Content-Location header and use that value as the 
    ### file name. Otherwise, report an error.
    ###
    ### Trailing slashes added above.
    ###
    if ($path =~ /^.*\/$/) {
	($content_location) = ($page =~ /^Content-Location:\s+(.*?)$/ism);
	if ($content_location) {
	    $path .= $content_location;
	    &$logfunc ('notice', 
       "WebIndex ".$self->{level}.". Page %s\'s Content-Location is %s.", 
		       $url, $content_location)
		if $verbose;
	} else {
	    &$logfunc ('error', 
    "WebIndex ".$self->{level}.". Couldn't find Page %s\'s Content-Location.", 
		       $url) 
		if $verbose;
	    return;
	}
    }

    push @{$self -> {cachedurls}}, ($url);

    my $filepath = ($port) ? $self -> {cachedir} . "/$server:$port/$path" : 
	$self -> {cachedir} . "/$server/$path";

    my ($dirpath) = ($filepath =~ /(.*)\//);

    $self -> mkdirtree ($dirpath, 0755);
    if ($!) {
	&$logfunc ('warning', "mkdirtree ($dirpath): $!");
    }

    if (! -d $filepath) {
	eval {
	    open (WEBPAGE, "> $filepath") or do {
		warn "cache_page $filepath: $!.";
		return;
	    };
	    print WEBPAGE $page;
	    close WEBPAGE;
	};
    }
}

sub mkdirtree {
    my $self = shift;
    my ($dir, $mask) = @_;
    $dir =~ s/\/\//\//g;

    my $verbose = 0;

    my ($parent) = 
	($dir =~ /(.*)\/.*$/);

    return unless ($dir && length ($dir));

    if (! -d $parent) {
	$self -> mkdirtree ($parent, $mask);
	&$logfunc ('warning', "mkdirtree parent ($parent): $!") if $verbose;
	undef $!;
    } 

    if (! -d $dir) {
        mkdir ($dir, $mask) || do { 
	    &$logfunc ('error', "Could not make directory $dir: $!\n");
	};

        &$logfunc ('warning', "mkdirtree ($dir): $!")
	    if $verbose;
	undef $!;
    }
}

sub url_disallowed {
    my $self = shift;
    my ($server, $url) = @_;

    ###
    ### URL is not on the target server.
    ###
    if ($url !~ m"$server"i) {
	return 1;
    }

    ###
    ### URL is not a HTTP reference.
    ###
    if ($url !~ /http\:/) {
	return 1;
    }

    return undef;
}

sub web_cache_path { 
    my $cfg = OnSearch::AppConfig -> new;
    my $onsearchdir = $cfg -> str (qw/OnSearchDir/);
    undef $cfg;
    return $ENV{DOCUMENT_ROOT} . "/$onsearchdir/websites"; 
}

1;
