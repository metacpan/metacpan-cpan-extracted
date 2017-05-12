package LiveGeez::Local;
use base qw(Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT %URIS
	$DEFAULTLANG $DEFAULTSYSIN $DEFAULTSYSOUT $PROCESSURLS $CHECKFILEDATES
	$DEFAULTBGCOLOR $COOKIEDOMAIN $COOKIEEXPIRES $USEAPACHE $USEFRAMES
	$USECGI_PM $ADMINEMAIL);

	$VERSION = '0.20';

	require 5.000;
	require Exporter;

	@EXPORT = qw(
		%URIS
		$DEFAULTLANG
		$DEFAULTSYSIN
		$DEFAULTSYSOUT
		$PROCESSURLS
		$CHECKFILEDATES
		$DEFAULTBGCOLOR
		$COOKIEDOMAIN
		$COOKIEEXPIRES
		$USEAPACHE
		$USECGI_PM
		$USEFRAMES
		$ADMINEMAIL
	);


	%URIS	            =(
		webroot     => "/usr/local/apache/htdocs",	        # where you keep HTML files
		cgidir      => "/usr/local/apache/cgi-bin",		# where you keep CGI files
		zauthority  => "http://zobel.geez.org:8080",			# Zobel URL
		zpath       => "/",					# Zobel from the server root
		cacheremote => "/usr/local/apache/htdocs/cache",	# where to cache URL documents
		cachelocal  => "/usr/local/apache/htdocs/cache",	# where to cache local files
		ipath       => "/f",					# where we keep fidel images, if any
	);
	$URIS{zuri}     = $URIS{zauthority}.$URIS{zpath};
	$URIS{file_query} = $URIS{zuri}."?sys=LIVEGEEZSYS\&file=";
	$DEFAULTLANG    = "amh";      # assumed preferred language
	$DEFAULTSYSIN   = "sera";     # assume files are in this system
	$DEFAULTSYSOUT  = "GFZemen";  # default font conversion
	$PROCESSURLS    = 1;          # should we let people use our bandwidth?
	$CHECKFILEDATES = 1;          # should we compare local file dates with cache?
	$DEFAULTBGCOLOR	= "#f0f0f0";  # default background color of pages
	$COOKIEDOMAIN	= ".geez.org";
	$COOKIEEXPIRES	= "Thu, 11-Nov-01 00:00:00 GMT";
	$USEAPACHE      = 1;
	$USECGI_PM      = 0;
	$USEFRAMES      = "false";
	$ADMINEMAIL     = "support\@geez.org";

	# $NOCACHEING     = 1;
	# $ADMINPASSWORD  = "snork";

$| = 1;  # always a good idea!
}

#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Local - Site Specific Settings for Your LiveGe'ez Installation

=head1 SYNOPSIS

use LiveGeez::Local;

=head1 DESCRIPTION

Local.pm is a required module by all other LiveGe'ez modules.  Local.pm
contains site specific settings for default encoding systems, language,
and paths:

=over 4

=item '$webRoot'

Full file system path to where you publish HTML documents.

=item  '$cgiDir'

Full file system path to where you keep CGI files.

=item '$scriptURL'

Complete URL to your Zobel front end script.

=item '$scriptBase'

The same front end script with respect to the server root.

=item '$URLCacheDir'

Directory where to cache converted documents downloaded by URL.  The path may
be absolute or relative to where Zobel executes.

=item '$FileCacheDir'

Directory where to cache local converted documents.  The path may be absolute
or relative to where Zobel executes.

=item '$defaultLang'

Assumed language for processing transliterated documents and performing
date conversions.

=item '$defaultSysIn'

Assume local files are in this system for conversion input.

=item '$defaultSysOut'

The font system for outputting converted documents when no system has been
specified.

=item '$processURLs'

A 0 or 1 value to permit the processing of remote documents.  "1" is a
friendly value but heavy usage by external websites can impact your bandwidth
costs and may slow down the processing of local documents as more Perl
modules are loaded.  "0" restricts Zobel to processing only local documents.

=item '$checkFileDates'

A 0 or 1 value to force Zobel to compare cached file dates to the original
documents.  "1" makes Zobel compare dates, slightly impacting performance.
"0" prevents Zobel from checking file dates -you will then have to delete
cache by hand or use the "no-cache" pragma to refresh cached documents.

=item '$iPath'

Path with respect to the $webRoot where "Image" fidels are stored, if any.

=item '$defaultBGColor'

The font system for outputting converted documents when no system has been
specified.

=item '$cookieDomain'

Your site name or domain for setting cookies.  Ethiopia Online uses
".ethiopiaonline.net".

=item '$cookieExpires'

Date when domain cookie should expire.  Such as Menasse Zaudou's birthday
"Thu, 11-Nov-99 00:00:00 GMT".

=back

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
