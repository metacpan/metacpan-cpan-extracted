package WWW::Link::Tester::Complex;
$REVISION=q$Revision: 1.8 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

use Carp qw(carp cluck croak);

=head1 NAME

WWW::Link::Tester::Complex - a careful tester for broken links

=head1 SYNOPSIS

    use WWW::Link::Test::Complex
    $ua=create_a_user_agent();
    $link=get_a_link_object();
    WWW::Link::Test::Complex::test_link($ua, $link);
    WWW::Link::Tester::Simple::Test($url)


=head1 DESCRIPTION

This is a link testing module based on the work of Phil Mitchell at
Harvard College.  The aim is to test very carefully if a link is
really there.

N.B. I have done the minimum reasonable edits on the file so that any
later improvements can be easily added.  This means that the module
contains and sections of code which are not relevant to
LinkController.

=head1 ROBOT LOGIC

This system should be controlled by the robot logic of the user agent it
uses provided that the robot returns a 4xx response code.

=head1 AUTHOR

Copyright (c) 2000 by the President and Fellows of Harvard College

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

Please see the source code for further details

=cut

############################################################################
#
#   Copyright (c) 2000 by the President and Fellows of Harvard College
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or (at
#   your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#   USA.
#
#   Contact information:
#
#   Phil Mitchell
#   Office for Information Systems
#   Harvard University
#   philip_mitchell at harvard.edu
#
#############################################################################
#
# When called without args, this script reads a list of URLs, one per line,
# from $INPUT_FILE, extracts the url from each record, and tries to access
# the url using the appropriate protocol. This includes following redirects
# until either:
#    1. the target page is successfully received; or
#    2. a page cycle is detected; or
#    3. a bad server or page request is detected; or
#    4. a maximum number of redirects ($MAX_REDIRECTS) is exceeded.
#
#...deleted...
#
# Protocols supported: http, https, ftp, gopher, file, telnet.
#
# Status codes:
#    Success: All successful response codes have the form:
#    2xx. Because we limit the size of responses we accept, we get a
#    lot of 206's in addition to 200's.
#    UNSUPPORTED_PROTOCOL:
#        Linkcheck handles {http, https, ftp, gopher, file, telnet}. Other
#  	 protocols will get this error. More commonly, it is the result of a
#  	 typo (eg. "thttp://").
#    MALFORMED_URL: The url is syntactically incorrect. EG.,
#        "http:/www.domain.com".
#    TELNET_FAILURE: Couldn't open the requested telnet connection.
#    HTTP_0_9_FAIL: Failed HTTP/0.9 connection (0.9 does not return
#        status codes).
#    REDIRECT_LIMIT_EXCEEDED:
#        Too many redirections. This error code should not normally be
#        received, it is in place to catch infinite redirect cycles.
#    UNKNOWN_ERROR: Rarely, LWP or HTTP modules will die, reporting an
#        error that is not useful to us. This error code should
#        not normally be received; it
#        will generally be corrected in subsequent passes.
#
# There are various configurable parameters documented below. In
# addition to setting the input and output filenames, the most
# important ones are those that control the timeout, the number of
# retries, and the time between retries. These settings have an
# important effect on the accuracy of results.
#
# Accuracy of results:
#
# Informal tests (results can be found at the end of this script) have
# shown that: (1) a timeout of 30 sec is adequate; increasing to 60
# sec is not useful; 10 seconds is too short. (2) The absolute number
# of recheck passes is less important than spreading them over
# time. Reasonable results are obtained with 3 recheck passes, each
# separated by 8 hours of sleep.
#
# In our set of about 10,000 urls, a first pass produces about 800
# (8%) bad urls. Subsequent passes will reduce that to about 650
# (6.5%). The use of telnet retry will reach another 25% of those
# apparently bad urls. The estimate of total bad urls in our sample is
# thus 4.5%. That list of bad urls is consistent across distinct runs
# of the link checker at greater than 99%. Handchecking of a large
# sample from this final list indicates a high degree of accuracy.
#
# Notes:
#
#   - A "page cycle" is the use of a redirect or refresh tag to cycle through
#   a list of one or more pages for data refresh purposes.
#
# Design Notes:
#
#  - Cookies: This version accepts all cookies. This allows it to handle some
#  URLs which require cookies.
#
#  - Timeout bug: Due to an apparent bug in the interaction between
#  Solaris and certain web servers, some http responses come back
#  improperly terminated. As a result, LWP times out and reports a
#  server error when a (nearly) valid response has been received. To
#  avoid this, we open a telnet connection to the relevant port
#  (usually 80) and do a manual GET on the url. Telnet will also time
#  out in this case, but telnet.pm provides a dump of the partial
#  response received, and we use this.
#
#  - WWW unreliability: Any given access to a server on the web is
#  subject to various kinds of flakiness. To avoid false reports of
#  bad servers, it is essential to re-test all errors, preferably over
#  a period of hours or days. This script completes a first pass
#  through all urls, typically taking 8 hours or more on 10,000
#  urls. Then it performs additional ($RECHECKS) passes on all urls
#  that received error codes. It sleeps ($HOURS_TO_SLEEP) between
#  passes to improve the chances of getting a valid return code.
#
#  - Redirects and cycles: The challenge is to follow redirects all
#  the way to the end of the line, but know when to stop. It is
#  complicated by the fact that some sites use the meta refresh tag
#  for their redirection, and by the fact that some sites have
#  infinite loop cycles for page refresh purposes. Five distinct cases
#  have been identified:
#
#     1. Proper redirect, using Location header. (Action: Follow redirect.)
#     2. Proper meta refresh, on a single page. (Action: Detect cycle
#     and exit.)
#     3. Proper meta refresh, on a cycle of pages. (Action:Detect
#     cycle and exit.)
#     4. Redirect using meta refresh. (Action: Follow redirect.)
#     5. Redirect loop on a single page for setting cookies. (Action:
#     Follow redirect.)
#
# Maintenance and Future Development Notes:
#
#   - 401's and 403's: Currently does not handle authentication; just
#   reports these as errors.
#
#   - Cookie warnings: With perl's -w option, many warnings will be
#   received about Cookies.pm. This seems to be due to the fact that
#   Cookies.pm does not cleanly handle incorrectly formatted
#   cookies. As far as I know, these warnings may be safely ignored.

# Author: Phil Mitchell
# Date: 02/22/01
# Version: 1.5
#
#############################################################################

use WWW::Link::Tester;
@ISA="WWW::Link::Tester";

use strict;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Message;
use HTTP::Status;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Cookies;
use Net::Telnet;
#use LWP::Debug qw(+);

###########################################
#  Global variables
###########################################

use vars qw(
	    %url_hash
	    $HTTP_DEFAULT_PORT
	    $HTTP_VERSION
	    $ADMIN_EMAIL
	    $MAX_REDIRECTS
	    $RECHECKS
	    $HOURS_TO_SLEEP
	    $AGENT_TIMEOUT
	    $AGENT_MAX_RESPONSE
	    $INPUT_FILE
	    $OUTPUT_FILE
	    $TMP_FILE
	    $TELNET_LOGFILE
	    $ADMIN_LOGFILE
	    $REDIRECT_LIMIT_EXCEEDED
	    $UNSUPPORTED_PROTOCOL
	    $MALFORMED_URL
	    $HTTP_0_9_OKAY
	    $HTTP_0_9_FAIL
	    $UNKNOWN_ERROR
	    $VERBOSE
	    $DEBUG
	    $LOGGING
	    $TELNET_SUCCESS
	    $TELNET_FAILURE
	    $agent
	    $telnetAgent
	    $cookieJar
	    $redirectCount
	    );



###########################################
#  Configurable parameters
###########################################

$ADMIN_EMAIL = ''; # If non-empty, script will send confirmation and result stats.
$AGENT_TIMEOUT = 10; # In seconds, time for http agent to wait. 10 secs is often too
		     # short, leads to spurious reports of server errors. Longer than 
                     # 30 secs not usually helpful.
$AGENT_MAX_RESPONSE = 524288; # In bytes, max response to accept. Mainly want to
			      # avoid being swamped by something huge. 
$MAX_REDIRECTS = 15; # Number of redirects to tolerate before giving up. Should never hit
		     # this limit; it's here to avoid infinite loop.
$RECHECKS = 3; # Number of recheck passes to recheck urls that return error codes. Note
	       # that every server error automatically gets one retry via telnet.
$HOURS_TO_SLEEP = 0; # Number of hours to sleep between recheck passes.
$HTTP_DEFAULT_PORT = 80;
$HTTP_VERSION = 'HTTP/1.0'; # Perl's HTTP module defaults to 0.9
$INPUT_FILE  = "CURRENT.URLS.TXT";
$INPUT_FILE  = "smalltest.txt";
$OUTPUT_FILE = "OUT.URLS.TXT";
$ADMIN_LOGFILE = "admin_logfile.txt"; # Log for result stats.
$VERBOSE = 1; # If 1, print processing status to stdout
$DEBUG = 0; # If 1, provides additional output to stdout; mainly HTTP headers.
$LOGGING = 1; # Enable logging to $ADMIN_LOGFILE.

###########################################
#  Misc. initializations
###########################################

$TMP_FILE = "tmp.txt";
$TELNET_LOGFILE = "telnet_logfile.txt"; # Used internally to buffer data.

# Response codes. All successful response codes have the form: 2xx.
$REDIRECT_LIMIT_EXCEEDED = 'REDIRECT_LIMIT_EXCEEDED'; 
$UNSUPPORTED_PROTOCOL = 'UNSUPPORTED_PROTOCOL'; 
$MALFORMED_URL = 'MALFORMED_URL'; 
$TELNET_FAILURE = 'TELNET_FAILURE';
$HTTP_0_9_FAIL = 'HTTP_0_9_FAIL';
$UNKNOWN_ERROR = 'UNKNOWN_ERROR';
$TELNET_SUCCESS = 299; # Mimic a successful HTTP code
$HTTP_0_9_OKAY = 298;

=head1 test_link

This function acts as glue between follow_url and LinkController.  It
returns a constructed HTTP::Response.  This will mean that information
is lost since we actually often have created the code from another
response.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{"user_agent"}=shift;
  bless $self, $class;
}

use vars qw($redirect_count $redirects %convert);

%convert=(
	     $REDIRECT_LIMIT_EXCEEDED => RC_REDIRECT_LIMIT_EXCEEDED,
	     $UNSUPPORTED_PROTOCOL => RC_PROTOCOL_UNSUPPORTED,
	     $MALFORMED_URL => RC_PROTOCOL_UNSUPPORTED,
	     $TELNET_FAILURE => RC_NOT_FOUND,
	     $HTTP_0_9_FAIL => RC_INTERNAL_SERVER_ERROR,
	     $UNKNOWN_ERROR => RC_BAD_REQUEST,
);


sub get_response {
  my $self=shift;
  my $link=shift;
  $redirects=[];
  $redirect_count=0;
  %url_hash=();
  my $code=$self->follow_url($link->url());
  scalar (keys %convert);
 CONVERT: while (my ($key,$value) = each %convert) {
    $code eq $key && do {
      $code=$value;
      last CONVERT;
    };
  }
  print STDERR "COMPLEX generated response code $code\n" 
    if $self->{verbose};
#cluck and die here generate coredumps!!!???! in perl 5.6.0 on Linux
#  cluck STDERR "COMPLEX generated response code $code";
  die "non numeric response code generated" . $code
      unless $code =~ m/[1-9][0-9]+/;
  my $response=HTTP::Response->new($code);

  die "response: $response not reference" unless ref $response ;

  return $response, @$redirects
}

# Set up the web agents and helpers.
#  $agent = new LWP::UserAgent;
#  $agent->timeout($AGENT_TIMEOUT);
#  $agent->max_size($AGENT_MAX_RESPONSE);
  $cookieJar = new HTTP::Cookies;
  $telnetAgent = new Net::Telnet(Timeout => $AGENT_TIMEOUT,
  			       Errmode => 'return');

my ($url, $result, $newResult, %results, $outputStr, $urlCount,
$count, $recheckCount, %resultSummary);

###########################################
#  check_for_meta_refresh
###########################################
# Routine that searches input string for something of the form:
#    <meta http-equiv="refresh" [verbiage] url="http://some.url.com">
# It is tolerant of extra whitespace, single or no quotes instead of
# doublequotes, spaces around equals signs, and extra verbiage, and is
# case-insensitive.
# Call with: String of content to be searched
# Returns: url, if a meta refresh is found; otherwise returns
# empty string.

sub check_for_meta_refresh {
    if ($DEBUG) { print "check_for_meta_refresh()...\n"; }
    my $inputStr = shift;
    if ($inputStr =~
  m{ #"
      <meta \s+ http-equiv \s* = \s* ["']? refresh ["']? [^>]+? url
               \s* = \s* ["']? ([^"' >]+) ["']? [^>]+? >
           }ix)
     {
       return $1;
     }
     else {
       return "";
     }
}#end check_for_meta_refresh

###########################################
#  follow_url
###########################################

# Tries to access a given url. The main case is HTTP protocol, but
# also handles any protocol handled by LWP, plus telnet. For telnet,
# just tries to open a connection.  For HTTP, follows redirects until
# a final status code is received or until $MAX_REDIRECTS is
# exceeded. Accepts all cookies. To avoid infinite loops, detects page
# refresh cycles.

# Call with: url, and optional second arg of referring url which is
# used to absolutize url.

# Returns: HTTP status code, or internal response codes (see above).

sub follow_url  {
  my $self=shift;
  my $agent=$self->{"user_agent"};
  my ($url, $referrer) = @_;
  my $VERBOSE=$self->{"verbose"};

    return $MALFORMED_URL unless $url;
    my ($response, $protocol, $host, $port, $ping, $telnetResult,
	$request, $statusCode, $new_url);
    if ($VERBOSE || $DEBUG) { print "follow_url(): $url\n"; }
    $url_hash{$url} = 1; # Track all urls in each run, to detect cycles.

    # Note: It is crucial to hash this url BEFORE absolutizing it, b/c
    # we will test for cycles before absolutizing.

    if ($referrer) { $url = make_url_absolute($url, $referrer); }
    if (keys(%url_hash) > $MAX_REDIRECTS) {
	if ($VERBOSE) { print "Redirect limit exceeded.\n"; }
	return $REDIRECT_LIMIT_EXCEEDED;
    }

    # EXTRACT PROTOCOL, HOST, AND (OPTIONAL) PORT.
    $url =~ m{ ^\s* ([a-z]+) :// ([^/:]+) }ix;
    if (!($1 && $2)) {
	if ($VERBOSE) { print "URL not well-formed.\n"; }
	return $MALFORMED_URL;
    }
    else {
	$protocol = $1;
	$host = $2;
    }
    $url =~ m{ \w+ :// [^/]+ : (\d+) }x; # Extract port
    if ($1) { $port = $1; }

    # HANDLE TELNET REQUESTS -- just see if we can open the connection.
    if ($protocol =~ /^telnet$/i) {
	if ($port) {
	    $ping = $telnetAgent->open(Host => $host,
				       Port => $port);
	}
	else {
	    $ping = $telnetAgent->open(Host => $host);
	}
	if (!$ping) { return $TELNET_FAILURE; }
	else { return $TELNET_SUCCESS; }
    }

    # HANDLE ALL OTHER REQUESTS (HTTP, HTTPS, FTP, GOPHER, FILE)
    if (!$agent->is_protocol_supported($protocol))  {
	if ($VERBOSE) { print "Protocol not supported.\n"; }
	return $UNSUPPORTED_PROTOCOL;
    }
    # Use eval to avoid aborting if LWP or HTTP sends "die".
    eval {
	$request = HTTP::Request->new(GET => $url);
	$request->protocol($HTTP_VERSION);
	$cookieJar->add_cookie_header($request);
	if ($DEBUG) { print "\nRequest: \n", $request->as_string; }

	# Use simple_request so we don't follow redirects automatically
	$response = $agent->simple_request($request);
	$cookieJar->extract_cookies($response);
	$statusCode = $response->code;
    };
    if ($@)  {
	if ($VERBOSE) { print "LWP or HTTP error: $@\n"; }
	if ($LOGGING) { print STDERR "LWP or HTTP error: $@\n"; }
	return $UNKNOWN_ERROR;
    }
    if ($DEBUG) { print "Status: $statusCode\n"; }
    if ($DEBUG) { print "\nResponse Header: \n", $response->headers->as_string; }

    # Note: In case of timeout, agent sets $statusCode to server error.
    if ($statusCode =~ /2../) {
	if ($VERBOSE) { print "Good response, checking for meta refresh tag...\n"; }
	$new_url = check_for_meta_refresh($response->content);
	if ($new_url ne "") {
	    if (exists($url_hash{$new_url}))  {
		if ($VERBOSE) { print "This url already visited ... returning $statusCode.\n"; }
		return $statusCode; }
	    else  {
		if ($VERBOSE) { print "Refresh to: $new_url\n"; }
		return $self->follow_url($new_url, $url);
	    }
	}
	else { return $statusCode;}
    }
    elsif ($statusCode =~ /3../) {
        $redirect_count++;
	if ($VERBOSE) { print "Proper redirect...\n"; }
	# Note that we don't check for page cycles here. Some sites
	# will redirect to the same page while setting cookies, but
	# eventually they'll stop.
	$new_url = $response->headers->header('Location');
	push @$redirects, $new_url;
	if ($VERBOSE) { print "Redirect to: $new_url\n"; }
	return $self->follow_url($new_url, $url);
    }
    elsif ($statusCode =~ /4../) {
	if ($VERBOSE) { print "Client error...\n"; }
	return $statusCode;
    }
    elsif ($statusCode =~ /5../) {
	if ($VERBOSE) { print "Server error...\n"; }

    # You might be tempted to do a retry right here. It is problematic
    # b/c you need to do another follow_url, but that will clash with
    # url_hash -- it will look like a page cycle. But if you do the
    # retry by hand w/ a simple request, you don't handle all the
    # cases properly. What we do is retry once using telnet, and leave
    # other retries to subsequent passes following main loop.

	if ($protocol =~ /^http$/i) { # Only works for HTTP requests.
	    $telnetResult = 
	      $self->telnet_http_retry($host, $url, $request, $port);
	    if ($telnetResult ne 'FAIL') {
		$statusCode = $telnetResult;
	    }
	}
	return $statusCode;
    } # end 5xx case.
    else { # Everything else case.
	return $statusCode;
    }

} # end sub follow_url

###########################################
#  get_location_header
###########################################
# Extracts the url from the Location field of an HTTP redirect.
# Call with: ref to array of header lines, w or w/o body at end.
# Returns: URL found in Location header, or empty string.
sub get_location_header {

    if ($VERBOSE || $DEBUG) { print "Looking for location header... \n"; }
    my ($headersRef) = @_;
    my $line;

    while ($line = shift @$headersRef) {
	if ($DEBUG) { print "Checking line: $line\n"; }
	last if $line =~ /^\s$/;
	if ($line =~ m{^Location: \s* (\S+)}x) {
	if ($DEBUG) { print "Line found: $line\n"; }
	    return $1;
	}
    }
    return "";

} # end sub get_location_header

###########################################
#  make_url_absolute
###########################################
# Make a relative url absolute by appending it to path of old url.
# Call with: a fully qualified url as second arg, which will provide
# path info for relative url which is first arg.
# Returns: new absolute url
sub make_url_absolute {

    if ($DEBUG) { print "make_url_absolute()...\n"; }
    my ($new_url, $old_url) = @_;

    # Test to see if it's already absolute (starts w/ a syntactically correct scheme)
    if ($new_url =~ m{^[a-z]+://}i) {
	return $new_url;
    }
    
    if ($VERBOSE) { print "Adding path to relative url: $new_url\n"; }    
    # Case 1: new url is relative to root; it starts with slash, and
    #         should be appended to raw domain name. 
    if ($new_url =~ m{^/} ) {
	$old_url =~ m{ (\w+ :// [^/]+) }x;	
	if ($VERBOSE) { print "Case 1: append to $1\n"; }    
	return $1 . $new_url;
    }
    # For cases 2 & 3, assume new url is relative to current directory;
    # Case 2: old url contains a trailing slash, eg. http://www.fib.com/bigfib/;
    #         may or may not contain trailing filename
    elsif ($old_url =~ m{ (\w+://\S+/) }x ) {
	if ($VERBOSE) { print "Case 2: append to $1\n"; }    
	return $1 . $new_url;
    }
    # Case 3: old url has no trailing slash, eg. http://www.fab.net
    else {
	if ($VERBOSE) { print "Case 3: append to $old_url/\n"; }    
	return "$old_url/$new_url";
    }
    
} # End make_url_absolute

###########################################
#  telnet_http_retry
###########################################
# Open a telnet connection to a host and try an HTTP GET for an
# url. The response is processed according to status code similarly to
# follow_url, and calls follow_url to handle redirects. Uses an LWP
# request object b/c that's a convenient way to stick cookies into the
# request string.
# Note: Handles the Solaris/LWP bug (cf notes above) by reading the
# telnet.pm input_log if telnet times out.
# Call with: hostname, absolute url, LWP request object, and optional
# port (default is $HTTP_DEFAULT_PORT).
# Returns: status code, or 'FAIL' if can't make telnet connection.
sub telnet_http_retry {
  my $self=shift;
  if ($VERBOSE || $DEBUG) {
    print "Telnet HTTP retry...\n";
  }
  my ($host, $url, $request, $port) = @_;
  my ($telnetAgent, @lines, @buffer, $statusLine, $line, $logfileHandle,
      $httpVersion, $statusCode, $message, $contentStr, $new_url);
  open(LOGFILE, "+>$TELNET_LOGFILE") || warn "Can't open $TELNET_LOGFILE.\n";
  if (!$port || $port !~ /^\d+$/) {
    $port = $HTTP_DEFAULT_PORT;
  }
  # Create agent and open connection.
  $telnetAgent = Net::Telnet->new(Host  => $host,
				  Port  => $port,
				  Input_log => $TELNET_LOGFILE,
				  Timeout => $AGENT_TIMEOUT,
				  Errmode => "return");
  return 'FAIL' unless $telnetAgent; # Can't open telnet connection.
  $telnetAgent->max_buffer_length($AGENT_MAX_RESPONSE);

  # Send the request.
  $telnetAgent->print($request->as_string, "\n");
  # Get the response as array of lines.
  while (@buffer = $telnetAgent->getlines) {
    push (@lines, @buffer);
  }
  if ($telnetAgent->timed_out) {
    if ($VERBOSE) {
      print "Telnet http timed out. Using input log...\n";
    }
    undef @lines;
    while (<LOGFILE>) {
      push (@lines, $_);
    }
    close LOGFILE or warn "Problem closing $TELNET_LOGFILE.\n";
  }
  if (!@lines) {
    if ($VERBOSE) {
      print "No data received.\n";
    }
    return 'FAIL';
  }
  if ($DEBUG) {
    print @lines,"\n";
  }
  $statusLine = shift @lines;
  # We can only process status line and headers if the response is HTTP/1.0 or
  # better. This regexp copied from LWP::Protocol::http.pm.
  if ($statusLine =~ /^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012/) {
    # HTTP/1.0 response or better
    ($httpVersion, $statusCode, $message) = ($1, $2, $3);
    chomp $message;
    if ($VERBOSE) {
      print "Status line: $httpVersion $statusCode $message \n\n";
    }

    if ($statusCode =~ /2../) {
      while ($line = shift @lines) { # Flatten array of lines.
	$contentStr .= $line;
      }
      $new_url = check_for_meta_refresh($contentStr);
      if ($new_url ne "") {
	if (exists($url_hash{$new_url})) {
	  if ($VERBOSE) {
	    print "This url already visited ... returning $statusCode.\n";
	  }
	  return $statusCode;
	} else {
	  if ($VERBOSE) {
	    print "Refresh to: $new_url\n";
	  }
	  # Return whatever status code we get from new url
	  return $self->follow_url($new_url, $url);
	}
      } else {
	return $statusCode;
      }
    } elsif ($statusCode =~ /3../) {
      if ($VERBOSE) {
	print "Proper redirect...\n";
      }
      $new_url = get_location_header(\@lines);
      if ($new_url ne "") {
	if (exists($url_hash{$new_url})) {
	  if ($VERBOSE) {
	    print "This url already visited ... returning $statusCode.\n";
	  }
	  return $statusCode;
	} else {
	  if ($VERBOSE) {
	    print "Redirect to: $new_url\n";
	  }
	  # Return whatever status code we get from new url
	  return $self->follow_url($new_url, $url);
	}
      } else {
	return $statusCode;
      }
    } elsif ($statusCode =~ m{4.. | 5..}x) {
      return $statusCode;
    }
  }				# if valid status line
  else {
    unshift(@lines, $statusLine);
  }
  # If no status line, could be HTTP/0.9 server, which just sends
  # back content. If it contains a tag like <html...>, assume it's
  # okay.
  if ($VERBOSE) {
    print "Assuming HTTP/0.9 or less... \n";
  }
  while ($line = shift @lines) { # Flatten array of lines.
    $contentStr .= $line;
  }
  if ($contentStr =~ /<html /i) {
    return $HTTP_0_9_OKAY;
  } else {
    return $HTTP_0_9_FAIL;
  }

}				# end sub telnet_http_retry

###########################################
#  END (Unused snippets and test results, below)
###########################################

# NOTES:

# 1. It would be nice to have a robust facility for absolutizing
# URLs. I tried using URI.pm for this purpose and found it to be not
# robust. EG., it allows the construction of: http:/www.yahoo.com,
# which is not well-formed.
# 2. Tolerance of meta refresh tag match?
# 3. some duplicate code went from follow_url to the
# telnet_http_retry; could be factored.


1; #Spoilt children / happy / required even
