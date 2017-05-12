@rem = '--*-Perl-*--
@echo off
perl -x -S %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#!/usr/local/web/bin/perl
### ---------------------------------------------------------------------- ###
#
# CGI Mailer - a CGI program to send formatted email from HTML forms
# 
# *Requires* perl 5.001 or greater and the LWP module.
#
# *Requires* the MailTools module if you want to use Mail::Send
# *Requires* the libnet module if you want to use Net::SMTP
#
# (c) Copyright Martin Gleeson and the University of Melbourne, 1996-1999
# Author: Martin Gleeson, <gleeson@unimelb.edu.au>
#
# This program is provided free of charge provided the Copyright notice
# remains intact. Commercial organisations should contact the author for
# licensing details if you wish to modify the source code in any form
# other than to set configuration options as directed in the Administrator
# Documentation. <http://www.unimelb.edu.au/cgi-mailer/>
# No warranty is made, either expressed or implied. USE AT YOUR OWN RISK.
#
### ---------------------------------------------------------------------- ###
#
$version = "1.9.6";
#
# Created: 23 April 1996
#
# Modified: 24 February 2000 v1.9.5
#    Bug fix: Argh! use's should have been require's.
#
# Modified: 24 February 2000 v1.9.5
#    Bug fix: bug fix with required fields again.
#
# Modified: 18 February 2000 v1.9.4
#    Bug fix: checking for required fields didn't work for radio buttons and
#    some other input types. Thanks to Adam Cooke <adam_cooke@lawyer.com>.
#
# Modified: 29 September 1999 v1.9.3
#    Bug fixes: A mis-named variable. Thanks to Al Chou <Al_Chou@CyberDude.com>.
#      Also had a doubled Subject header when using Mail::Send. Thanks to Greg
#      Ferguson <g.ferguson@motorola.com>
#
# Modified: 16 June 1999 v1.9.2
#    Bug fix: forgot a backslash!
#
# Modified: 8 June 1999 v1.9.1
#    Bug fix: bad error message when recipient not set.
#
# Modified: 20 May 1999 v1.9.0
#    New Feature: added support for CGI environment variables in mail
#      message and response page.
#
# Modified: 9th November 1998 v1.8.0
#    New Feature: added ability to specify the referring page in the form,
#      to handle proxy gateways & browsers who remove the referer header.
#
# Modified: 22 October 1998 v1.7.1
#    Bug fix: didn't check for the existence of the destination field. Thanks
#      to Richard Seidel <seidel@mindspring.com> for reporting this bug.
#
# Modified: 7 August 1998 v1.7.0
#    Added Feature: added "index-file" hidden field so that cgi-mailer can
#      deal with URLs ending in '/' that map to an index file in the directory
#
# Modified: 29 April 1998 v1.6.1
#    Bug Fix: fixed code to allow header fields to be required fields.
#
# Modified: 23 March 1998 v1.6.0
#    Change: added code to use Net::SMTP so that MacPerl and other Perl ports
#      could use cgi-mailer. Net::SMTP seems to be much more widely supported
#      by perl ports than MailTools. To use Net::SMTP, a mailhost must be set
#      in the configuration options below, and the From header must be set in
#      the web form.
#      And yes, this does make two releases in one day :-)
#
# Modified: 23 March 1998 v1.5.1
#    Fixed bug - using Mail::Send caused fatal error due to wrong method
#         call for adding From header. Only eperienced when From header
#         was set.
#
# Modified: 17 March 1998 v1.5.0
#    Added Feature:
#         Can have required fields. Have an extra file (.required) containing
#         field name<tab>description for required fields.
#    Fixed bug (cosmetic): user agent for this script had wrong version.
#
# Modified: 16 March 1998 v1.4.1
#    Fixed bug - didn't handle fields with a colon in response page and
#    format file. This meant putting mail header content (field name of
#    "header:value") in the response page or format file didn't work. Thanks
#    to Kate Edwards-Davis <k.edwards-davis@studentadmin.unimelb.edu.au>
#    for reporting this bug.
#
# Modified: 9 February 1998 v1.4.0
#    Added Feature:
#         Can use Mail::Send instead of unix sendmail program to send
#         mail. This should mean that you can use cgi-mailer on NT or
#         other OSes if they have a perl with Mail::Send and Mail::Mailer
#
# Modified: 20 January 1998 v1.3.0
#    Added Feature: just show response page if the input field name 'nodata'
#                   is set to value 'true'
#
# Modified: 9 January 1998 v1.2.1
#    Fixed bug - was dying if sendmail path wrong instead of throwing error.
#    Thanks to Bjorn Heimir <bjornhb@skyrr.is> for reporting the bug.
#
# Modified: 30 November 1997 v1.2
#    Added feature - check for referral from local disk and give
#                    appropriate error
#
# Modified: 26 November 1997 v1.1.2
#    Fixed bug - was not logging in case of error.
#    Fixed bug - wasn't stripping off port number when checking local host
#
# Modified: 17 November 1997 v1.1.1
#    Added Accept header to request object. Microsoft IIS won't properly
#    default Accept to */* when there is no Accept header. Why doesn't
#    it surprise me that I'm modifying my code to handle microsloth
#    brokenness? Am I a Real Programmer(tm) now?
#
# Modified: 5 November 1997 v1.1
#    Added domain restriction to restrict unauthorised use
#
# Modified: 21 October 1997 v1.0.1
#    Added mail headers for format file and version number
#
# Modified: 18 August 1997 v1.0
#    Added extra comments & cleaned up for release.
#
# Modified: 7 August 1997
#    Replaced rtrurl.pl functionality for retrieving data and response
#    pages with LWP module goodies.
#
# Modified: 21 July 1997
#    Fixed to handle stupid DOS 8.3 filenames
#
# Modified: 17 November 1996
#    Added user-defined response page.
#
# Created: 23 April 1996
#    Initial version. Simple filling out of a template based on
#    form fields. Collects the template from the server where the
#    form resides.
#
### ---------------------------------------------------------------------- ###
#
# Configurable settings - change these to reflect your local setup
#
### ---------------------------------------------------------------------- ###
# Do you want to use the Net::SMTP module rather than sendmail directly?

# $net_smtp = "yes";

# You will also need to set a mailhost to use to send the message if you
# use this option

# $mailhost = "mailhost.wherever.com";

### ---------------------------------------------------------------------- ###
# Do you want to use the Mail::Send module rather than sendmail directly?

# $mail_send = "yes";

### ---------------------------------------------------------------------- ###
# If you're not using the Mail::Send module or the Net::SMTP, then you'll
# need to set the full path to sendmail on your machine

$sendmail = "/usr/sbin/sendmail";

### ---------------------------------------------------------------------- ###
# Full path to log file (for logging cgi-mailer usage).

$log = "/servers/http/logs/cgi-mailer.log";

### ---------------------------------------------------------------------- ###
# Domain name(s) of your local network
#
# This restricts the use of cgi-mailer to those within your organisation,
# or the domains named. Syntax is 'domain.abc.xyz$' or '^128.250.' or
# 'domain.one.xyz$|domain.two.xyz$|^128.250.|domain.four.xyz$', etc
#
# comment the line out if you don't want to restrict access (not recommended)

$local_network = 'unimelb.edu.au$|mu.oz.au$|^128.250|mup.com.au$';

### ---------------------------------------------------------------------- ###
#   End of configurable settings - no editing required below this line.
### ---------------------------------------------------------------------- ###

### ---------------------------------------------------------------------- ###

### ---------------------------------------------------------------------- ###
#
# Header for default CGI response page

$preamble = '
<html>
 <head>
  <title>CGI-Mailer Response
 </title>
</head>
 <body bgcolor="#FFFFFF">
  <h2>CGI-Mailer Response
 </h2>
';

### ---------------------------------------------------------------------- ###
# Footer for default CGI response page

$footer = '
  <!-- =================================================================== -->
  <hr>
  <p>Produced by <a href="http://www.unimelb.edu.au/cgi-mailer/">cgi-mailer.</a>
 </p>
  <!-- =================================================================== -->
  <hr>
 </body>
</html>
';

# $debug=1;

use LWP::UserAgent;

$http_header = "Content-type: text/html\n\n";

$method = $ENV{REQUEST_METHOD};

if( $method eq "GET" )
{
	$data = "  <h2>Incorrect METHOD</h2>\n" .
		"  <p>This CGI Program should be referenced with \n" .
	        "     a METHOD of POST.</p>\n";
	print $http_header;
	print $preamble;
	print $data;
	print $footer;
	exit(0);

}
elsif( $method eq "POST" )
{
	%INPUT = &get_input(POST);
	
	# get the format file location
	$url = $ENV{'HTTP_REFERER'} || $INPUT{'CgiMailerReferer'};

	if(! $url) {
		&error("Your browser or proxy server is not sending a Referer header
			and CGI-Mailer needs one to work. Please notify the maintainer
			of the form and ask them to add the appropriate field to the form.");
	}

	# remove named anchor, if any
	$url =~ s/\#.+$//;

	# remove query string, if any
	$url =~ s/\?.+$//;

	# store the original page URL for later reference
	$orig_url = $url;

	# check if user is mistakenly using page on local hard disk
	&error("The form you are submitting is on your hard disk.
		It needs to be on a web server for cgi-mailer to work.\n")
		if( $url =~ /^file:\/\/\//i);

	# check the domain is OK
	if($local_network) {
		# get the hostname
		$host = $url;
		# strip off the leading protocol://
		$host =~ s/^\w+:\/\///;
		# strip off the trailing /abc/def/xyz.html
		$host =~ s/([^\/]+)\/.*/$1/;
		# strip off the trailing :port, if any
		$host =~ s/\:\d+$//;
		if( $host !~ m/$local_network/i ) {
			$local_network =~ s/[\^\$]//g;
			@domains = split(/\|/,$local_network);
			$domains = join(', ',@domains);
			&error("cgi-mailer can only be used within the domains $domains");
		}
	}
	$url = $orig_url;
	if($url =~ /\/$/){
		if( $INPUT{'index-file'} ) {
			$orig_url = $orig_url . "/" . $INPUT{'index-file'};
		} else {
			$err_text = "If you want to use cgi-mailer with an index file (i.e. a URL ending with '/'),<br>" .
				"you must add a hidden field to specify the name of the index file:<br>" .
				"&lt;input type=&quot;hidden&quot; name=&quot;index-file&quot; " .
				"value=&quot;index.html&quot;&gt;<br>".
				"(or the name of your index file if it isn't &quot;index.html&quot;";
			&error($err_text);
		}
	}

	# get the required fields, if any
	$url = $orig_url;
	if($url =~ /html$/){
		$url =~ s/html$/required/;
	} else {
		$url =~ s/htm$/req/;
	}
	$req_url = $url;
	$req = &URLget($url);
	if($req !~ /%%%ERROR%%%/) {
		$required_fields = 1;
		@lines = split(/\n/,$req);
		foreach $line (@lines) {
			$line =~ s/^\s*$//;
			next if $line =~ /^$/;
			($field_name,$description) = split(/\t/,$line,2);
			$required{$field_name} = $description;
			push(@required_fields,$field_name);
		}
	} else {
		$required_fields = 0;
	}
	push(@required_fields, 'destination') if(!grep(/^destination$/,@required_fields));

	foreach $key (keys(%INPUT)) {

		# get the mail headers from the form input
		if($key =~ /header:/i) {
			$header_name = $key;
			$header_name =~ s/header://i;
			$header_name = &title_case($header_name);
			$headers{$header_name} = $INPUT{$key};
		}
	}
	# check if required fields have been filled in
	foreach my $r_field (@required_fields) {
		my $content = $INPUT{$r_field};
		$content =~ s/^\s*$//;
		if(! $content || length($content) == 0) {
			$data = "  <h2>Error.</h2>\n" .
	        		"  <p>An error has occurred while attempting to submit your form:</p>\n" .
	        		"  <blockquote>The input field <strong>$required{$r_field}</strong> " .
				"           is <font color=\"#FF0000\">required</font>\n" .
				"           and must be filled in before you can submit the form.\n" .
				" </blockquote>\n" .
				"  <p>Please go back, fill in the required field and re-submit the form.</p>\n";

			select STDOUT;
			print $http_header;
			print $preamble;
			print $data;
			print $footer;
			&log_access();
			exit(0);
		}
	}

	# get necessary info for mail headers
	$destination = $INPUT{'destination'};
	if(!$destination) {
		$err_text = "You must add a hidden field to specify the destination of the email:<br>" .
			"&lt;input type=&quot;hidden&quot; name=&quot;destination&quot; " .
			"value=&quot;foo\@bar.com&quot;&gt;";
		&error($err_text);
	}
	$subject = $INPUT{'subject'};
	$reply_to = $INPUT{'replyto'} || $headers{'Reply-To'}; delete $headers{'Reply-To'};
	$from_addr = $headers{'From'}; delete $headers{'From'};

	$url = $orig_url;
	if( $INPUT{'nodata'} ne 'true') {
		# get the location of the format file
		if($url =~ /html$/){
			$url =~ s/html$/data/;
		} else {
			$url =~ s/htm$/dat/;
		}
		$format_url = $url;
	
		# grab the format file
		$format = &URLget($url);
	
		&error("Couldn't get format file: $url") if( $format =~ /%%%ERROR%%%/ );

		# substitute values for variables in the format file
		$format =~ s/\$ENV\{\'?([a-zA-Z0-9\_\-\:]+)\'?\}/$ENV{$1}/g;
		$format =~ s/\$([a-zA-Z0-9\_\-\:]+)/$INPUT{$1}/g;
	}

	$url = $orig_url;
	# get the response file if there is one
	if($url =~ /html$/){
		$url =~ s/html$/response/;
	} else {
		$url =~ s/htm$/res/;
	}
	$response_url = $url;
	$response = &URLget($url);
	$response =~ s/\$ENV\{\'?([a-zA-Z0-9\_\-\:]+)\'?\}/$ENV{$1}/g;
	$response =~ s/\$([a-zA-Z0-9\_\-\:]+)/$INPUT{$1}/g;

	$default = "true" if($response =~ /%%%ERROR%%%/);

	# if there if no response file, set up the default response
	if($response !~ /%%%ERROR%%%/) {
		$data = $response if($response);
	} else {
		$data = "  <h3>Submission Successful</h3>\n" .
		        "  <p>Your form has been successfully submitted by the server\n </p>";
	}

	if( $INPUT{'nodata'} ne 'true') {
		# mail the formatted message
		if($mail_send) {
			require Mail::Send;
			require Mail::Mailer;

			$msg = new Mail::Send Subject=>$subject, To=>$destination;

			$msg->add('From',$from_addr) if($from_addr);
			$msg->add('Reply-To',$reply_to) if($reply_to);

			foreach $header (keys(%headers)) {
				$msg->set($header, $headers{$header});
			}
			$msg->set("X-Generated-By","CGI-Mailer v$version: http://www.unimelb.edu.au/cgi-mailer/");
			$msg->set("X-Form","$ENV{'HTTP_REFERER'}");

			# Launch mailer and set headers. 
			$fh = $msg->open;
			print $fh $format;
			# complete the message and send it
			$fh->close;

		} elsif($net_smtp) {
			require Net::SMTP;

			&error("You must specify a From address using the field name <font colour=\"#FF0000\">header:From</font>")
				if(! $from_addr);

			$smtp = Net::SMTP->new($mailhost);

			$smtp->mail($from_addr) if $from_addr;
			$smtp->to($destination);

			$smtp->data();
			$smtp->datasend("To: $destination\n");
			foreach $header (keys(%headers)) {
				$smtp->datasend("$header: $headers{$header}\n");
			}
			$smtp->datasend("Subject: $subject\n");
			$smtp->datasend("X-Generated-By: CGI-Mailer v$version: http://www.unimelb.edu.au/cgi-mailer/\n");
			$smtp->datasend("X-Form: $ENV{'HTTP_REFERER'}\n");
			$smtp->datasend("\n");
			$smtp->datasend($format);
			$smtp->dataend();

			$smtp->quit;
		} else {
			if( ! -e "$sendmail") { &error("Couldn't find sendmail [$sendmail]: $!"); }
			open(MAIL,"| $sendmail -t") or &error("Couldn't open sendmail process: $!");
			select MAIL;
			print "To: $destination\n";
			print "Subject: $subject\n";
			print "From: $from_addr\n" if $from_addr;
			print "Reply-to: $reply_to\n" if $reply_to;
			foreach $header (keys(%headers)) {
				print "$header: $headers{$header}\n";
			}
			print "X-Generated-By: CGI-Mailer v$version: http://www.unimelb.edu.au/cgi-mailer/\n";
			print "X-Form: $ENV{'HTTP_REFERER'}\n";
			print "\n";
			print "$format";
			close MAIL;
		}
	}

	&log_access();

	select STDOUT;
	print $http_header;
	print $preamble if $default;
	print $data if $default;
	print $response unless $default;
	print $footer if $default;
	exit(0);
}
### ---------------------------------------------------------------------- ###
sub error {
	my $errstr = pop(@_);
	$data = "  <h2>Error.</h2>\n" .
	        "  <p>An error has occurred while attempting to submit your form</p>\n" .
	        "  <p>The Error is: </p>\n<blockquote><b>$errstr</b></blockquote>\n" .
	        "  <p>Please report this error to the maintainer of the form</p>\n";

	select STDOUT;
	print $http_header;
	print $preamble;
	print $data;
	print $footer;

	&log_access($errstr);

	exit(0);
}
### ---------------------------------------------------------------------- ###
sub get_input{

	$method = pop(@_);
	
	local( $len, $postinput, $param, $value, $item, @INPUT, %INPUT_ARRAY );

	if( $method eq "GET") {
		$QUERY = $ENV{QUERY_STRING};
		$QUERY =~ s/\+/ /g;             # Change +'s to spaces
		$QUERY =~ s/%([\da-f]{1,2})/pack(C,hex($1))/eig;

		@QUERY_LIST = split( /&/, $QUERY);
		foreach $item (@QUERY_LIST) {
			($param, $value) = split( /=/, $item);
			$INPUT_ARRAY{$param} .= $value;
		}
	} elsif( $method eq "POST") {
		$len = $ENV{CONTENT_LENGTH};
		$postinput=<STDIN>;
		$postinput =~ s/\n|\r/ /g;
		$postinput =~ s/\+/ /g;
		@INPUT = split( /&/, $postinput);

		foreach $item (@INPUT) {
			($param, $value) = split( /=/, $item);
			$value =~ s/%([\da-f]{1,2})/pack(C,hex($1))/eig;
			$param =~ s/%([\da-f]{1,2})/pack(C,hex($1))/eig;
			if( $INPUT_ARRAY{$param} ) {
				$INPUT_ARRAY{$param} .= ",$value";
			} else {
				$INPUT_ARRAY{$param} = $value;
			}
		}
	}
	return (%INPUT_ARRAY);
}
### ---------------------------------------------------------------------- ###
sub title_case {
	$_ = pop(@_);
	$_ = "\L$_";
	s/(\b[a-z])/\U$1/g;
	$_;
}
### ---------------------------------------------------------------------- ###
sub URLget{
	my $URL = pop(@_);
	my $ret;

	# Create a user agent object
	$ua = new LWP::UserAgent;
	$ua->agent("cgi-mailer.pl/$version " . $ua->agent);

	# Create a request
	my $req = new HTTP::Request GET => "$URL";

	# Accept all data types. This is specifically for Microsloth's
	# IIS, which won't properly default to */* and throws a 406.
	$req->header('Accept' => '*/*');

	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);

	# Check the outcome of the response
	if ($res->is_success) {
		$ret = $res->content;
	} else {
		$ret = '%%%ERROR%%%';
	}
	return $ret;
}
### ---------------------------------------------------------------------- ###
sub time_now {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	my %months = ( '0','Jan', '1','Feb', '2','Mar', '3','Apr',
		'4','May', '5','Jun', '6','Jul', '7','Aug',
		'8','Sep', '9','Oct', '10','Nov', '11','Dec');
	my $now;

        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        $year += 1900; $hour = "0" . $hour if($hour < 10);
        $min = "0" . $min if($min < 10); $sec = "0" . $sec if($sec < 10);

        $now = "$hour:$min:$sec $mday $months{$mon} $year";

        return $now;
}
### ---------------------------------------------------------------------- ###
sub log_access {
	my $errstr = pop(@_);
	my $date;

	# log the access
	$date = &time_now();
	open LOG,">> $log" or die(" Couldn't open log file [$log]: $!");
	print LOG "[$date] host=[$ENV{'REMOTE_HOST'}] referer=[$ENV{'HTTP_REFERER'}] data=[$format_url] " .
		"resp=[$response_url] to=[$destination] subject=[$subject] reply-to=[$reply_to]";
	print LOG " ERROR=[$errstr]" if $errstr;
	print LOG " from=[$from_addr]" if $from_addr;
	print LOG "\n";
	close LOG;

	return;
}
__END__
:endofperl
