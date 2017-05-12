package LiveGeez::Config;
use base qw(Exporter);

BEGIN
{
	use strict;

	use vars qw( $VERSION %DEFAULTS %URIS @EXPORT_OK );

	$VERSION = '0.20';

	require 5.000;

	%URIS			=  (
		webroot		=> "/usr/local/apache/htdocs",	        # where you keep HTML files
		cgidir		=> "/usr/local/apache/cgi-bin",		# where you keep CGI files
		zauthority	=> "http://zobel.geez.org",		# Zobel URL
		zpath		=> "/",					# Zobel from the server root
		cacheremote	=> "/usr/local/apache/htdocs/cache",	# where to cache URL documents
		cachelocal	=> "/usr/local/apache/htdocs/cache",	# where to cache local files
		ipath		=> "/f",				# where we keep fidel images, if any
	);

	%DEFAULTS		=(
	URIS			=> \%URIS,
	LANG			=> "amh",      # assumed preferred language
	SYSIN			=> "sera",     # assume files are in this system
	SYSOUT			=> "UTF8",  # default font conversion
	PROCESSURLS		=> 1,          # should we let people use our bandwidth?
	CHECKFILEDATES		=> 1,          # should we compare local file dates with cache?
	BGCOLOR			=> "#f0f0f0",  # default background color of pages
	COOKIEDOMAIN		=> ".geez.org",
	COOKIEEXPIRES		=> "Thu, 11-Nov-01 00:00:00 GMT",
	USEAPACHE		=> 1,
	USECGI_PM		=> 0,
	USEFRAMES		=> "false",
	SET_LOCAL_BASE		=> 0,
	USECOOKIES		=> 0,		# use cookies instead of inserting LIVEGEEZLINK and LIVEGEEZSYS in certain places
	USEMOD_GZIP		=> 0,
	ADMINEMAIL		=> "support\@geez.org",
	REGION			=> "et",	# er, et, or "*"

	# $NOCACHEING     => 1,
	# $ADMINPASSWORD  => "snork",
	);

	$URIS{zuri}       = $URIS{zauthority}.$URIS{zpath};
	$URIS{file_query} = $URIS{zuri}."?sys=LIVEGEEZSYS\&file=";
	$URIS{file_query} =~ s|/\?|/|;

	@EXPORT_OK = qw ( %URIS );
}


sub import
{

	if ( @_ == 2 ) {
		LiveGeez::Config->export_to_level (1, @_);
		return;
	}
	shift;
	return unless @_;
	my %config = @_;
	my $uri_update = 0;
	foreach (keys %config) {
		if ( /uri_(.*)/i ) {
			my $k = lc($1);
			$uri_update = 1;
			$URIS{$k} = $config{$_} if ( exists ($URIS{$k}) );
		}
		else {
			my $k = uc($_);
			$DEFAULTS{$k} = $config{$_} if ( exists ($DEFAULTS{$k}) );
		}
	}
	if ( $uri_update ) {
		if ( grep { /(zauthority|zpath)/i } (keys %config) ) {
			$URIS{zuri}       = $URIS{zauthority}.$URIS{zpath};
			$URIS{file_query} = $URIS{zuri}."?sys=LIVEGEEZSYS\&file=";
		}
		if ( exists($config{zuri} ) || exists($config{ZURI}) ) {
			$URIS{file_query} = $URIS{zuri}."?sys=LIVEGEEZSYS\&file=";
		}
		$URIS{file_query} =~ s|/\?|/|;
	}

}


sub init
{
my $self = shift;
my %config = @_ if ( @_ );

	foreach ( keys %DEFAULTS ) {
		next if ( /URI/ );
		$self->{lc($_)} = $DEFAULTS{$_};
	}
	foreach ( keys %URIS ) {
		$self->{uris}{lc($_)} = $URIS{$_};
	}
	if ( @_ ) {
		my $uri_update = 0;
		foreach ( keys %config ) {
			if ( /uri_(.*)/i ) {
				my $k = lc($1);
				$uri_update = 1;
				$self->{uris}{$k} = $config{$_} if ( exists($self->{uris}{$k}) );
			}
			else {
				$self->{$_} = $config{$_} if ( exists($self->{$_}) );
			}
		}
		if ( $uri_update ) {
			if ( grep { /(zauthority|zpath)/i } (keys %config) ) {
			# if ( exists($config{uri_zauthority} ) || exists($config{uri_zpath}) ) {
				$self->{uris}{zuri}       = $self->{uris}{zauthority}.$self->{uris}{zpath};
				$self->{uris}{file_query} = $self->{uris}{zuri}."?sys=LIVEGEEZSYS\&file=";
			}
			if ( exists($config{uri_zuri} ) || exists($config{URI_ZURI}) ) {
				$self->{uris}{file_query} = $self->{uris}{zuri}."?sys=LIVEGEEZSYS\&file=";
			}
			$self->{uris}{file_query} =~ s|/\?|/|;
		}
	}

}


sub new
{
my $self = {};

	my $blessing = bless ( $self, shift );

	$self->init ( @_ );

	$blessing;
}


sub status
{
my ( $self, $r ) = @_;
	
	$r->print ("Package Defaults:\n");
	$r->print ("<ul>\n");
	foreach ( sort keys %DEFAULTS ) {
		next if ( /URI/ );
		$r->print ( "  <li>  $_ => $DEFAULTS{$_}\n" );
	}
	$r->print ("  <li> URI => {\n    <ul>\n");
	foreach ( sort keys %{URIS} ) {
		$r->print ( "      <li>  $_ => $URIS{$_}\n" );
	}
	$r->print ("    </ul>\n<li>  }\n</ul>\n<hr>\n");

	$r->print ("Instance Settings:\n");

	$r->print ("<ul>\n");
	foreach ( sort keys %DEFAULTS ) {
		next if ( /URI/ );
		$r->print ( "  <li>  $_ => $self->{lc($_)}\n" );
	}
	$r->print ("  <li> URI => {\n    <ul>\n");
	foreach ( sort keys %{URIS} ) {
		$r->print ( "      <li>  $_ => $self->{uris}->{lc($_)}\n" );
	}
	$r->print ("    </ul>\n<li>  }\n</ul>\n<hr>\n");

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
