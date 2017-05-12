package LiveGeez::Cgi;
use base qw(Exporter);


BEGIN
{
	use strict;
	use vars qw($VERSION $EMAILMESSAGE $ZOBEL_VERSION %URIS);

	$VERSION = '0.20';
	$ZOBEL_VERSION = '0.20';

	require 5.000;

	$EMAILMESSAGE =<<END;
<p>If you think that you have reached this message in error please report
to <a href="mailto:%%ADMINEMAIL%%?Subject=%%subject%%">%%ADMINEMAIL%%</a></p>
END

	use LiveGeez::Config qw(%URIS);

	$| = 1;
}


sub import
{
shift;


	if ( @_ && $_[0]->isa ( "LiveGeez::Config" ) ) {
		if ( $_[0]->{useapache} ) {
			use Apache;
			use Apache::Constants qw(:common);
			use Apache::Cookie;
		}
		else {
			require "$_[0]->{uris}->{cgidir}/cgi-lib.pl";
		}
	}
	else {
	#
	# we can't reach here any more
		# assume local
		#
		require "$URIS{cgidir}/cgi-lib.pl";
	}

}


sub print
{
my $self = shift;


	if ( $self->{apache} ) {
		$self->{apache}->print ( @_ );
	}
	else {
		print @_;
	}

}


sub TopHtml
{
my ( $self, $title, $bgcolor ) = @_;
$bgcolor ||= $self->{config}->{bgcolor};

my $head = ( $self->{sysOut}->{xfer} eq "utf8" )
           ?  "<head>\n<META HTTP-EQUIV=\"content-type\" content=\"text-html; charset=utf-8\">"
	   :  "<head>"
	 ;

<<END_OF_TEXT;
<html>
$head
<title>$title</title>
</head>
<body BGCOLOR="$bgcolor">
END_OF_TEXT

}


sub BotHtml
{
my $self = shift;

	"</body>\n</html>\n";
}


sub ParseCgi
{
my $self = shift;

	unless ( $self->{CgiParsed} ) {
		$self->{CgiParsed} = "true";
		if ( $self->{apache} ) {
			%{$_[0]} = ( $self->{apache}->method eq 'POST' ) ? $self->{apache}->content : $self->{apache}->args;
		}
		else {
			ReadParse ( $_[0] );
		}
	}
	$self->ParseCookie unless ( $self->{cookieParsed} );
}


sub HeaderPrint
{
my $self = shift;

	unless ( $self->{HeaderPrinted} ) {
		$self->{HeaderPrinted} = "true";
		if ( $self->{apache} ) {
			$self->{apache}->content_type('text/html');
			$self->{apache}->content_encoding('x-gzip')
				if ( $self->{'x-gzip'} );
			$self->{apache}->send_http_header;
		}
		else {
			my $header = "Content-type: text/html\n";
			if ( $self->{'x-gzip'} ) {
				$header .= "Content-Encoding:  x-gzip\n\n";
			}
			else {
				$header .= "\n";
			}
			print $header;
		}
	}
}


sub DieCgi
{
my $self = shift;

	$self->{'x-gzip'} = 0;
	$self->HeaderPrint;
	if ( $self->{apache} ) {
		$self->{apache}->print ( "<h1>An Error Was Encountered:</h1>\n" );
		$self->{apache}->print ( "<h1>$_[0]</h1>\n" );
	}
	else {
		CgiError ( $_[0] );
	}
	$self->print ( "<hr><p align=right><a href=\"http://libeth.sourceforge.net/Zobel/\"><i>Zobel $ZOBEL_VERSION</i></a></p>" );
	if ( $self->{apache} ) {
		$self->{apache}->exit(OK); 
	}
	else {
		exit (0);
	}
}



sub DieCgiWithEMail
{
	my $message = $EMAILMESSAGE;
	$message =~ s/%%subject%%/$_[2]/;
	$message =~ s/%%ADMINEMAIL%%/$_[0]->{config}->{adminemail}/g;
	DieCgi ( $_[0], $_[1].$message );
}



sub ParseCookie
{
my $self = shift;

	return 1 if ( $self->{cookieParsed} );


	my $v;
	if ( $self->{apache} ) {
		my %c = Apache::Cookie->parse;
		return 1 unless ( $c{prefs} );
		$v = $c{prefs}->value;
	}
	else {
		# cookies are seperated by a semicolon and a space
		return 1 unless ( $ENV{'HTTP_COOKIE'} =~ /prefs/ );
		my ( @rawCookies ) = split ( /; /, $ENV{'HTTP_COOKIE'} );
		foreach ( @rawCookies ) {
	    		if ( /prefs/ ) {
				s/prefs\s+//;
				$v = $_;
				# print STDERR "Cookie: $v\n";
			}
		}
	}

	$v =~ s/=/,/g;
	$v =~ s/,/","/g;
	$v =~ s/^/"/g;
	$v =~ s/$/"/g;

	my %hash;
	eval ( "%hash = ($v);" ) ;

	$self->{'cookie-geezsys'}= $hash{geezsys};
	$self->{'cookie-frames'} = $hash{frames};
	$self->{'cookie-7-bit'}  = ( $hash{'7-bit'} ) ? $hash{'7-bit'} : "false";
	$self->{'cookie-lang'}   = ( $hash{lang} ) ? $hash{lang} : $self->{config}->{lang};
	$self->{cookieParsed}    = 1;

	1;
} 

 
sub SetCookie
{
my $self = shift;

	return if ( $self->{cookieset} );

	my $frames  = ( $self->{frames}            ) ? $self->{frames}            : "no";
	my $bit7    = ( $self->{sysOut}->{'7-bit'} ) ? $self->{sysOut}->{'7-bit'} : "false";
	my $lang    = ( $self->{sysOut}->{lang}    ) ? $self->{sysOut}->{lang}    : $self->{config}->{lang};
 
 	my $sysPragmaOut  =   $self->{sysOut}->{sysName};
 	$sysPragmaOut    .= ".$self->{WebFont}" if ( $self->{WebFont} );
	#
	# return if nothing has changed
	#
 	return	if ( exists ( $self->{'cookie-geezsys'} )
		&& ( $self->{'cookie-geezsys'} eq $sysPragmaOut )             
		&& ( $self->{'cookie-7-bit'}   eq $bit7         )
		&& ( $self->{'cookie-lang'}    eq $lang         )
		&& ( $self->{'cookie-frames'}  eq $frames       )
		);

	$prefs = "geezsys=$sysPragmaOut,frames=$frames,7-bit=$bit7,lang=$lang";

	if ( $self->{config}->{useapache} ) {
		my $cookie = new Apache::Cookie (
			$self->{apache},
			-name    => 'prefs',
			-value   => $prefs,
			-expires => $self->{config}->{cookieexpires},
			-path    => "/",
			-domain  => $self->{config}->{cookiedomain},
		);
		$cookie->bake;
	}
	else {
		print "Set-Cookie: prefs=$prefs; expires=$self->{config}->{cookieexpires}; path=/; domain=$self->{config}->{cookiedomain}\n";
	}

	$self->{cookieset} = 1;

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::Cgi - Parse a LiveGe'ez CGI Query

=head1 SYNOPSIS

 use LiveGeez::Request;
 use LiveGeez::Services;

 main:
 {

 	my $r = LiveGeez::Request->new;

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );

	exit (0);

 }

=head1 DESCRIPTION

Request.pm instantiates an object that contains a parsed LiveGe'ez query.
Upon instantiation the environment is checked for CGI info and cookie data
is read and used.  This does B<NOT> happen if a populated hash table is
passed (in which case the hash data is applied) or if "0" is passed as an
arguement.
The request object is required by any other LiveGe'ez function of object.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
