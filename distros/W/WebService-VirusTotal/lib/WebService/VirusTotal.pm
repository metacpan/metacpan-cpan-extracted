#
# VirusTotal
#
# This package was insipred by Chistopher Frenz's perl script at:
#    http://perlgems.blogspot.com.es/2012/05/using-virustotal-api-v20.html
#
# Package is Copyright (C) 2013, Michelle Sullivan (SORBS) <michelle@sorbs.net>, and Proofpoint Inc.
#

package WebService::VirusTotal;

use 5.006;
use strict;
use warnings;
use Carp;

use LWP::UserAgent;
use JSON;

use Digest::SHA qw(sha1_hex sha256_hex);
use Digest::MD5 qw(md5_hex);
use List::Util qw(first);

use base qw(Exporter);

our $ID = q$Id: VirusTotal.pm 3165 2014-01-07 12:31:37Z michelle $;
our $VERSION = sprintf("1.0.%d", q$Revision 3165$ =~ /(\d+)/g);
my $TESTSTRING = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';
my $INTERNALAGENT = sprintf("%s-MIS/0.%d", $ID =~ /Id:\s+(\w+)\.pm\s+(\d+)\s+/);

#warn("[" . localtime(time()) . "] WebService::VirusTotal Revision: $VERSION (Agent: $INTERNALAGENT)\n");

sub new
{
        my $class = shift;
        my $this = {};
        my %arg = @_;

        $this->{DEBUG} = (exists $arg{debug} ? $arg{debug} : 0);
	$this->{FNLEN} = 64;

	my %scanhash = ();

	$this->{'ua'} = undef;
	$this->{'conn'} = undef;
	$this->{'scanhash'} = \%scanhash;
	
        bless ($this, $class);

        return $this;
}

sub init
{
	my $self = shift;
	$self->apiagent();
	$self->scanapi();
	$self->reportapi();
	$self->apikey();
}


sub debug
{
	my $self = shift;
	if (@_) {$self->{DEBUG} = $_[0]};
	return $self->{DEBUG};
}

sub conn_proxy
{
	my $self = shift;
	if (@_) {$self->{PROXY} = $_[0]};
	return $self->{PROXY};
}

sub apiagent
{
	my $self = shift;
	if (@_) {$self->{AGENTSTRING} = $_[0]};
	$self->{AGENTSTRING} = $INTERNALAGENT if (!defined $self->{AGENTSTRING});
	return $self->{AGENTSTRING};
}

sub conn_cache
{
	my $self = shift;
	if (@_) {$self->{CONNCACHE} = $_[0]};
	$self->{CONNCACHE} = 0 if (!defined $self->{CONNCACHE});
	return $self->{CONNCACHE};
}

sub allowlong
{
	my $self = shift;
	if (@_)
	{
		if ($_[0])
		{
			$self->{FNLEN} = 256;
		} else {
			$self->{FNLEN} = 64;
		}
	}
	return $self->{FNLEN};
}

sub cache
{
	my $self = shift;
	if (@_) {$self->{CACHE} = $_[0]};
	# if cache use is true, but the cache is not defined then init it
	if (!defined $self->{CACHE} and $self->conn_cache())
	{
		$self->{CACHE} = $self->init_cache();
	}
	# return the cache object, this could be undef if caching is not defined.
	return $self->{CACHE};
}
	
sub init_cache
{
	use LWP::ConnCache;

	my $self = shift;
	return $self->{CACHE} if defined $self->{CACHE};

	my $cache = LWP::ConnCache->new;
	$cache->total_capacity($self->cache_limit());
	return $cache;
}

sub cache_check
{
	my $self = shift;

	# if connection cache is not being used return true regardless
	return 1 if (!$self->conn_cache());

	# if the cache is not initialised return an error
	if (!defined $self->cache())
	{
		carp("Connection Cache is enabled but not intialised!");
		return undef;
	}

	# Prune dead entries
	$self->cache->prune();
	return 1;
}

sub cache_limit
{
	my $self = shift;
	if (@_) {$self->{CACHELIMIT} = $_[0]};
	$self->{CACHELIMIT} = 1 if (!defined $self->{CACHELIMIT});
	return $self->{CACHELIMIT};
}

sub reportapi
{
	my $self = shift;
	if (@_) {$self->{VTREPORTAPI} = $_[0]};
	$self->{VTREPORTAPI} = "https://www.virustotal.com/vtapi/v2/file/report" if (!defined $self->{VTPREPORTAPI});
	return $self->{VTREPORTAPI};
}

sub scanapi
{
	my $self = shift;
	if (@_) {$self->{VTSCANAPI} = $_[0]};
	$self->{VTSCANAPI} = "https://www.virustotal.com/vtapi/v2/file/scan" if (!defined $self->{VTPSCANAPI});
	return $self->{VTSCANAPI};
}

sub apikey
{
	my $self = shift;
	if (@_) {$self->{APIKEY} = $_[0]};
	$self->{APIKEY} = undef if (!defined $self->{APIKEY});
	return $self->{APIKEY};
}

sub timeout
{
	my $self = shift;
	if (@_) { $self->{CONNTIMEOUT} = $_[0] };
	$self->{CONNTIMEOUT} = 30 if (!defined $self->{CONNTIMEOUT});
	return $self->{CONNTIMEOUT};
}

# Public method for accessing VirusTotal
sub scan
{
	my $self = shift;
	my $file = shift;
	my ($filename, $infected, $description) = (undef, undef, undef);
	my $tmpfile = 0;
	my $result = 0;
	carp("Entered scan()...") if $self->debug();
	if (length($file) > $self->allowlong() && $file !~ /\//)
	{
		$tmpfile++;
	} else {
		if ( -r $file && $file !~ /\.\./ )
		{
			# this is a filename and I can read it (and does not contain '..')
			$filename = $file;
		} else {
			$tmpfile++;
		}
	}
	if ($tmpfile)
	{
		$filename = "/tmp/nofilename-$$.tmp";
		open FILE, ">$filename";
		while (<$file>)
		{
			print FILE;
		}
		close FILE;
	}

	carp("Filename for scanning is: $filename") if $self->debug();
	if ($self->_connect())
	{
		carp("Connected to VT, scanning...") if $self->debug();
		# We are connected we can proceed....
		#
		open FILE, "<$filename";
		my $scankey = sha256_hex(<FILE>);
		close FILE;
		
		#
		# Check the internal checksums against the hash, if found we don't need to submit to VT
		# If not found we need to call the private method _submit() and actually submit it
		# If it is found we can call the private method _result() to get any results.
		if (exists $self->{'scanhash'}->{$scankey})
		{
			carp("Found a hash.. checking for a result..") if $self->debug();
			($infected, $description) = $self->_result($scankey);
			# return any result or undef if we have to wait for a result...
			if (!defined $infected)
			{
				# an error occurred, could be that the file has not completed scanning
				$description = "Please try later..";
			}
		} else {
			carp("Did not find a hash.. submitting for a scan...") if $self->debug();
			# scan key not found, so we need to submit it...
			$result = $self->_submit($scankey, $filename);
			if (defined $result)
			{
				# scan submission was successful, pause 15 seconds then check to see if there is a response
				if ($result ne 1)
				{
					carp("Scan returned something other than done so pausing 15 seconds...") if $self->debug();
					sleep 15;
				}
				($infected, $description) = $self->_result($scankey);
				# return any result or undef if we have to wait for a result...
				if (!defined $infected)
				{
					carp("Result check was an error, tempfailing...") if $self->debug();
					# an error occurred, could be that the file has not completed scanning
					$description = "Please try later..";
				}
			}
		}
	} else {
		# Not connected (and unable to connect) so return an error
		carp("Not connected to VirusTotal API, check your configuration!");
		$infected = undef;
		$description = "Not connected to VirusTotal API, check your configuration!";
	}
	unlink($filename) if ($tmpfile);
	return ($infected, $description);
}

# Private method to test the connection state and if not connected/tested to try a connection.
sub _connect
{
	my $self = shift;
	if (!ref $self or !ref $self->{'scanhash'})
	{
		croak("You cannot call _connect() before calling new() (and you shouldn't do it!)");
	}

	if (defined $self->{'valid_conn'} && $self->{'valid_conn'} && defined $self->{'ua'})
	{
		# We have previously connected
		return $self->{'valid_conn'};
	}

	if (!defined $self->{'valid_conn'})
	{
		# No valid connection tried, so setup LWP
		if (!defined $self->{'ua'})
		{
			$self->{'ua'} = LWP::UserAgent->new(
				ssl_opts => { verify_hostname => 1 },
				agent => $self->apiagent(),
				timeout => $self->timeout(),
				conn_cache => $self->cache(),
			);
			if (defined $self->conn_proxy())
			{
				$self->{'ua'}->proxy('https', $self->conn_proxy());
			}
		}
		$self->{'valid_conn'} = 0;
	}
	# A connection was previously tried and failed, or this is a new connection
	if (!$self->{'valid_conn'} and $self->{'last_conn_check'} < (time() - 300))
	{
		# test the connection by sending the EICAR string..
		carp("Connecting to " . $self->reportapi() . " for the EICAR test..") if $self->debug();
		my $response = $self->{'ua'}->post( $self->reportapi(),
			Content_Type => 'multipart/form-data',
			Content => [
					'apikey' => $self->apikey(),
					'resource' => sha256_hex($TESTSTRING),
				],
			);
		if (!$response->is_success)
		{
			my $a = ( $response->status_line =~ /403 Forbidden/ ) ? " (Have you set your API key?)" : "";
			carp("Unable to connect to VirusTotal using " . $self->scanapi() . " error: " . $response->status_line . "$a\n");
		} else {
			my $results=$response->content;
			carp("Parsing test response: $results") if $self->debug();
			# pulls the sha256 value out of the JSON response
			# Note: there are many other values that could also be pulled out
			my $json = JSON->new->allow_nonref;
			my ($decjson, $sha, $respcode) = (undef, undef, undef);
			eval {
				$decjson = $json->decode($results);
			};
			if (defined $decjson)
			{
				# if json->decode() fails it will call croak, so we catch it and display the returned text
				$sha = $decjson->{"sha256"};
				$respcode = $decjson->{"response_code"};
				if (defined $sha && $sha ne "")
				{
					# we were able to submit successfully so we can set valid_conn to true
					$self->{'scanhash'}->{'test'}->{'key'} = $sha;
					$self->{'scanhash'}->{'test'}->{'submitted'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
					$self->{'scanhash'}->{'test'}->{'last_checked'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
					$self->{'scanhash'}->{'test'}->{'infected'} = $decjson->{"positives"};
					$self->{'scanhash'}->{'test'}->{'result'} = first { $_->{detected} } values %{ $decjson->{scans} };
					$self->{'valid_conn'} = 1;
					carp("Validated connection...") if $self->debug();
				} else {
					carp("Unable to parse test, VirusTotal responded with: $results");
				}
			}
		}
		$self->{'last_conn_check'} = time();
	}
	return $self->{'valid_conn'};
}

# Private method, will send the request to VirusTotal
sub _submit
{
	#Code to submit a file to Virus Total
	my $self = shift;
	my $res = undef;
	carp("Entered _submit()") if $self->debug();
	croak ("You can't call this directly! Use the scan() method!") if (!ref $self);
	croak ("You cannot call _submit() before calling new() (and you shouldn't do it!") if (!ref $self->{'scanhash'});

	if (!defined $self->{'valid_conn'} && !$self->{'valid_conn'})
	{
		carp("Not connected to VirusTotal, please check your connection before calling _submit()!");
		return $res;
	}

	my $scankey = shift; # This is our internally generated scan key to be used to lookup the result key
	my $file = shift; # This is the file name and location of the file to check

START:	carp("Sending file ($file)..") if $self->debug();
	my $response = $self->{'ua'}->post(
		$self->scanapi,
    		Content_Type => 'multipart/form-data',
    		Content => [
			'apikey' => $self->apikey(),
    			'file' => [$file]
		]
  	);
	if (!$response->is_success)
	{
		carp("Unable to post to '" . $self->scanapi() . "' error: " . $response->status_line . "\n");
		return $res;
	}
	my $results=$response->content;
	
	carp("Got response: $results") if $self->debug();
	#pulls the sha256 value out of the JSON response
	#Note: there are many other values that could also be pulled out
	my $json = JSON->new->allow_nonref;   
	my ($decjson, $sha, $respcode) = (undef, undef, undef);
	eval {
		$decjson = $json->decode($results);
	};
	if (defined $decjson)
	{
		# if json->decode() fails it will call croak, so we catch it and display the returned text
		$sha = $decjson->{"sha256"};
		$respcode = $decjson->{"response_code"};
		if (defined $respcode)
		{
			carp("Got response code $respcode") if $self->debug();
			if ($respcode eq "1")
			{
				# we were able to submit successfully and we got a report embedded
				$self->{'scanhash'}->{$scankey}->{'key'} = $sha;
				$self->{'scanhash'}->{$scankey}->{'submitted'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
				$self->{'scanhash'}->{$scankey}->{'last_checked'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
				$self->{'scanhash'}->{$scankey}->{'infected'} = $decjson->{"positives"};
				$self->{'scanhash'}->{$scankey}->{'result'} = first { $_->{detected} } values %{ $decjson->{scans} };
				$self->{'valid_conn'} = 1;
			} elsif ($respcode eq "-2" or $respcode eq "0") {
				# we were able to submit successfully and we got a response indicating queued
				$self->{'scanhash'}->{$scankey}->{'key'} = $sha; 
				$self->{'scanhash'}->{$scankey}->{'submitted'} = time();
				$self->{'scanhash'}->{$scankey}->{'last_checked'} = 0;
				$self->{'scanhash'}->{$scankey}->{'infected'} = undef;
				$self->{'scanhash'}->{$scankey}->{'result'} = $decjson->{"verbose_msg"};
				$self->{'valid_conn'} = 1;
			} elsif ($respcode eq "-1") {
				carp("Transient Error occured, restarting...\n");
				carp("Got response code -1 (so restarting..)") if $self->debug();
				goto START;
			} else {
				carp("Got response code $respcode (" . $decjson->{"verbose_msg"} . ")") if $self->debug();
				$self->{'scanhash'}->{$scankey}->{'result'} = $decjson->{"verbose_msg"};
			}
		} else {
			carp("Unable to parse $scankey, VirusTotal responded with: $results");
		}
	} else {
		carp("Unable to parse $scankey, VirusTotal responded with: $results");
		carp("JSON decoder returned: $decjson [$@]");
	}
	return $respcode;
}

# Private method, will get the request from VirusTotal
sub _result
{
	#Code to retrieve a result from VirusTotal
	my $self = shift;
	carp("Entered _result()") if $self->debug();
	croak ("You can't call this directly! Use the scan() method!") if (!ref $self);
	croak ("You cannot call _result() before calling new() (and you shouldn't do it!") if (!ref $self->{'scanhash'});

	my $scankey = shift; # This is our internally generated scan key to be used to lookup the result key

	if (!defined $self->{'valid_conn'} && !$self->{'valid_conn'})
	{
		carp("Not connected to VirusTotal, please check your connection before calling _result()!");
		return undef;
	}

	if (!exists $self->{'scanhash'}->{$scankey} || !defined $self->{'scanhash'}->{$scankey}->{'key'})
	{
		carp("Attempted to retrieve a result for a key that doesn't exist!");
		return undef;
	}

	# Check to see if we checked in the last 5 minutes.  If we did return the same result.
	unless ($self->{'scanhash'}->{$scankey}->{'last_checked'} && $self->{'scanhash'}->{$scankey}->{'last_checked'} > (time() - 300))
	{
		# Code to retrieve the results that pertain to a submitted file by hash value
		# FIXME: Original code had neither content_type or content .. are they needed (probably not, but should we include) for readability?
RESTART:	carp("Sending filehash ($scankey)..") if $self->debug();
		my $response = $self->{'ua'}->post(
			$self->reportapi(),
			Content_Type => 'multipart/form-data',
			Content => [
				'apikey' => $self->apikey(),
				'resource' => $scankey
			]
		);
	
		if (!$response->is_success)
		{
			carp("Unable to post to '" . $self->reportapi() . "' error: " . $response->status_line . "\n");
			return (undef, undef);
		}
		my $results=$response->content;
		carp("Got response: $results") if $self->debug();
		
		# pulls the sha256 value out of the JSON response
		# Note: there are many other values that could also be pulled out
		my $json = JSON->new->allow_nonref;
		my ($decjson, $sha, $respcode) = (undef, undef, undef);
		eval {
			$decjson = $json->decode($results);
		};
		if (defined $decjson)
		{
			# if json->decode() fails it will call croak, so we catch it and display the returned text
			$sha = $decjson->{"sha256"};
			$respcode = $decjson->{"response_code"};
			if (defined $respcode)
			{
				if ($respcode eq "1")
				{
					# we were able to submit successfully so we can set valid_conn to true
					$self->{'scanhash'}->{$scankey}->{'key'} = $sha;
					$self->{'scanhash'}->{$scankey}->{'submitted'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
					$self->{'scanhash'}->{$scankey}->{'last_checked'} = sprintf("%d", $decjson->{"scanid"} =~ /^[1234567890abcdef]+-(\d+)$/);
					$self->{'scanhash'}->{$scankey}->{'infected'} = $decjson->{"positives"};
					$self->{'scanhash'}->{$scankey}->{'result'} = first { $_->{detected} } values %{ $decjson->{scans} };
					$self->{'valid_conn'} = 1;
					carp("Got response code $respcode") if $self->debug();
				} elsif ($respcode eq "-2" or $respcode eq "0") {
					# we were able to submit successfully and we got a response indicating queued
					$self->{'scanhash'}->{$scankey}->{'key'} = $sha; 
					$self->{'scanhash'}->{$scankey}->{'submitted'} = time();
					$self->{'scanhash'}->{$scankey}->{'last_checked'} = 0;
					$self->{'scanhash'}->{$scankey}->{'infected'} = undef;
					$self->{'scanhash'}->{$scankey}->{'result'} = $decjson->{"verbose_msg"};
					$self->{'valid_conn'} = 1;
					carp("Got response code $respcode") if $self->debug();
				} elsif ($respcode eq "-1") {
					carp("Transient Error occured, restarting...\n");
					carp("Got response code $respcode (transient error, restarting)") if $self->debug();
					goto RESTART;
				} else {
					carp("Got unknown response code $respcode") if $self->debug();
					$self->{'scanhash'}->{$scankey}->{'result'} = $decjson->{"verbose_msg"};
				}
			} else {
				carp("Unable to parse $scankey, VirusTotal responded with: $results");
			}
		} else {
			carp("Unable to parse $scankey, VirusTotal responded with: $results");
		}
	}
	return ($self->{'scanhash'}->{$scankey}->{'infected'}, $self->{'scanhash'}->{$scankey}->{'result'}->{'result'});
}

1;

__END__

=head1 NAME

Webservice::VirusTotal - Interface for accessing the VirusTotal APIv2

=head1 SYNOPSIS

        use Webservice::VirusTotal;

        my $VT=Webservice::VirusTotal->new();

        $VT->apikey("YourAPIKeyHere");
        $VT->conn_cache(1);

        my ($infected, $description) = $VT->scan("/tmp/file.txt");

        if (!defined $infected)
        {
                my $error = (defined $description) ? $description : "Unknown error";
                croak("An error occured: $error\n");
        } elsif ($infected) {
                print "Virus found: $description\n";
        } else {
                print "File didn't have any detected virus..\n";
        }

=head1 DESCRIPTION

This is a simple to use interface to the VirusTotal API (v2) for checking
viruses against multiple Anti-Virus databases.

=head1 METHODS

=head2 new ( [ debug => [0|1] ], [ allowlong => [0|1] ] )

Create a new Webservice::VirusTotal object, with optional configuration options:

=over 4

=item debug

True or false to output debug data (default: 0)

=item allowlong

True or false to allow or disallow long filename support (default: 0)

When set to false L<Webservice::VirusTotal> will assume any filename over 64 characters
long with no '/' char is actually file data.  When set to True this limit
is increased to 256 chars.

B<Note:> Any file name including '..' will automatically be treated as
filedata rather than as a filename to prevent many hack attempts.  Of course
/etc/passwd is not caught along with a whole host of other file-path
hacks, so becarful with your implementation!

=back

=head2 debug ( 0 | 1 )

Will turn off/on debug information (default: off)

=head2 conn_proxy ( $proxystring )

Sets the URL of a proxy server to use for requests.

=head2 apiagent ( $agentstring )

Sets the string to use as a User-Agent when connecting to the VirusTotal API

=head2 conn_cache ( 0 | 1 )

Will turn off/on use of L<LWP:ConnCache> (default: off)

=head2 allowlong ( 0 | 1 )

Will turn off/on whether to allow long (upto 256) characters before
assuming the bytes passed are actually a file to scan.

=head2 cache ( $handler )

Pass an external connection cache handler to LWP (normally you wouldn't use
this instead just setting conn_cache() to true.)

=head2 cache_check ( )

Will prune dead connections from the connection cache (if any)
will return true if conn_cache is not set.

=head2 cache_limit ( $limit )

Sets the maximum number of cached connections in the connection cache.

=head2 reportapi ( $report_API_URL )

Sets/Gets the report API URL (default: https://www.virustotal.com/vtapi/v2/file/report )

=head2 scanapi ( $scan_API_URL )

Sets/Gets the file subission API URL (default: https://www.virustotal.com/vtapi/v2/file/scan )

=head2 apikey ( $apikey )

Sets/Gets the API key to use when connecting to VirusTotal you B<MUST> set
this or the API will return an Error and the module will Croak.

=head2 timeout ( $timeout )

Sets/Gets the connection timeout in seconds (default: 30 seconds)

=head2 scan ( $file )

Invoke a connection to the API and will sent the file specified by $file, or
if the file does not appear to be a filename ( > 64 bytes )  will write it
to a temporary file and submit that.

B<NOTE:> This is not thread safe!  The tempfile created uses the process-id.

=head1 DEPENDENCIES

L<LWP::UserAgent>, L<JSON>, L<Digest::MD5>, L<Digest::SHA>, L<List::Util>, L<Carp>


=head1 AUTHOR

Michelle Sullivan, C<< <cpan@sorbs.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-virustotal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-VirusTotal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::VirusTotal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-VirusTotal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-VirusTotal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-VirusTotal>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-VirusTotal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Michelle Sullivan, SORBS & Proofpoint Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
