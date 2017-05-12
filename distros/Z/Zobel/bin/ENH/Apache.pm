package ENH::Apache;

BEGIN
{
	use strict;
	use vars qw( $config );
	use Apache::Constants qw(:common);
	use Apache::Request;
	use Apache::URI;

	use LiveGeez::Request;
	use LiveGeez::Services;

	# use diagnostics;
	use ENH;

	require LiveGeez::Config;
	$config = new LiveGeez::Config(
		uri_webroot	=> "/usr/local/apache/htdocs/enh",
		uri_zauthority	=> "http://www.ethiozena.net",
		# uri_cachelocal	=> "/usr/local/apache/htdocs/enh/cache",
		uri_cachelocal	=> "/usr/local/apache/htdocs/cache/local.enh",
		bgcolor		=> "#fffffh",
		usecookies	=> 1,
		cookiedomain	=> ".ethiozena.net",
		cookieexpires	=> "Thu, 11-Nov-02 00:00:00 GMT",
		useapache 	=> 1,
		checkfiledates 	=> 0,
		processurls 	=> 0,
		# usemod_gzip 	=> 0,
	);
}


sub CheckBrowser
{
my ( $brand, $version);

	my @browser = split(/ /, $_[0]);

	if ($browser[0]=~/Mozilla/) { 
		my @model      = split(/\//, $browser[0]);
		$brand   = $model[0];	
		$version = $model[1];
	}
	( ( ($version >= 2) && ($brand eq "Mozilla") ) || ( ($version >= 3) && ($browser[0] =~ /MSIE/) ) )
	  ? "yes"
	  : "no"
	;
}


sub handler
{
my $r = LiveGeez::Request->new ( $config, $_[0], 0 ); # don't parse input



	my $path =  $r->{apache}->filename;
	# printf STDERR "PATHINFO1 = $path\n";
	# $config->status( $r );

	my $args;
	if ( $args = $r->{apache}->args ) {
	return (OK) if ( $args =~ /skip$/o );
		$args =~ s|/$||;  # happens with http://abc.com?foo=
		                  # but not with  http://abc.com/?foo=
	}

	#
	#  If the URL is in the form http://www.us.com/X.pl/SYSTEM/
	#                         or http://www.us.com/X.pl/SYSTEM/index.html
	#
	#  we extract the SYSTEM and assume the default file is index.sera.html
	#  we process and exit.
	#
	$path =~ s|$config->{uris}->{webroot}(/?)||;
	# printf STDERR "PATHINFO2 = $path\n";
	unless ( $path ) {
		$path = "index.sera.html";
	}
	else {
		$path =~ s|^http://www.ethiozena.net||oi;
		$path =~ s|^http://www.ethiopiannews.net||oi;
		$path =~ s/index.html/index.sera.html/;
	}

	# printf STDERR "PATHINFO2 = $path\n";

	$args = $path if ( $path =~ /=/ );
	$args = "file=$path" unless ( $args =~ /(file|cal(In)?|number)=/o );

	# printf STDERR "ARGS1 = $args\n";

	$r->ParseCookie;

	# printf STDERR "Cookie:  $r->{'cookie-geezsys'}\n";

	my $hostname = $r->{apache}->hostname;
	if ( $hostname eq "pfr.ethiozena.net" ) {
		$args .= "&sysOut=AmharicBook.PFR";
		delete ($r->{'cookie-geezsys'}) if ( exists($r->{'cookie-geezsys'}) );
	}
	elsif ( $hostname =~ /^(utf8|unicode)/ ) {
		$args .= "&sysOut=UTF8";
		delete ($r->{'cookie-geezsys'}) if ( exists($r->{'cookie-geezsys'}) );
	}
	elsif ( $args !~ /sys(Out)?=/ ) {
		$args .= "&sysOut=";
		$args .= ( $r->{'cookie-geezsys'} )
		         ? $r->{'cookie-geezsys'}
		         : "FirstTime"
		       ;
		#
		#  hope this is still a good idea...
		#
		unless ( $args =~ /7-bit/ ) {
    			my $userAgent = $r->{apache}->header_in("User-Agent");
			$args .= ( $r->{'cookie-7-bit'} )
			         ? ( $r->{'cookie-7-bit'} eq "true" )
			           ? "&pragma=7-bit"
			           : ""
			         : ( $userAgent =~ /Mac/i )
			           ? "&pragma=7-bit"
			           : ""
			       ;
		}
	}
	#
	# no frames for the time being.
	#
	# $input{frames}  = ( $r->{'cookie-frames'} )
	#                 ? ( $r->{'cookie-frames'} )
	#                 : CheckBrowser ( $userAgent )
	#                 ;
	#
	# my @fileString    =  split ( '/', $path );
	# my $sys           =  $fileString[1];
	# if ( $#fileString == 1 || $fileString[2] eq "index.html" ) {
	# 	$input{file}  = "/index.sera.html";
	# }
	# else {
	#		$input{file}  =  $path;
	#		$input{file}  =~ s/\/$sys//;
	#		$input{file} .=  "/index.sera.html"
	#			if ( $input{file} !~ /htm(l)?$/ );
	# }


	print STDERR "ARGS2: $args\n";
	$r->{apache}->args ( $args );


	# check if we still need to pass an %input
	$r->ParseQuery;  # cookie is set here
	# print $r->show;


	if ( $r->{type} eq "file" ) {

		$r->{isArticle} = "true" if ( $r->{file} =~ /[0-9]\.sera/ );

		#
		# The code below is here for frame handling which ENH no longer
		# supports.  It is kept around should we one day be able to afford
		# it again.
		#
		# if ( $0 =~ "NoFrames" ) {
			$r->{frames}     =  "no";
		# 	$r->{scriptURL}  =~ s/G.pl/NoFrames.pl/;
		# 	$r->{scriptBase} =~ s/G.pl/NoFrames.pl/;
		# }
		if ( $r->{isArticle} ) {
			$r->{cache_check_override} = 1;  # don't loose time with articles
			# if ( $r->{frames} eq "skip" ) {
				ProcessFramesFile ( $r );
			# } elsif ( $r->{frames} eq "no" ) {
			# 	ProcessNoFramesFile ( $r );
			# } else {
			# 	OpenFrameSet ( $r, "/misc/Frames/frame.html" );
			# }
		} else {
			# printf STDERR "Processing main page\n";
			if ( $r->{file} =~ m#^/?index.sera.html# ) {
				$r->{mainPage} = "true";
				# $r->{file} =~ s/index.sera.html/index.$r->{sysOut}->{lang}.sera.html/;
				# $r->{uri}->{_uri}->path ( $r->{file} );
 				my $sysPragmaOut  =   $r->{sysOut}->{sysName};
			 	$sysPragmaOut    .= ".$r->{WebFont}" if ( $r->{WebFont} );
				# print STDERR "$sysPragmaOut =? $r->{'cookie-geezsys'}\n" if ( exists($r->{'cookie-geezsys'}) );
				$r->SetCookie if ( $args !~ /setcookie/ && exists($r->{'cookie-geezsys'}) && ( $sysPragmaOut ne $r->{'cookie-geezsys'} ) );
			}
			ProcessFramesFile ( $r );
			# print STDERR "Complete[$$]\n";
		}

	} else {
		ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );
	}


	OK;

}
1;

__END__


=head1 NAME

ENH/Tobia Zobel -- Remote Processing of Ethiopic Web Pages

=head1 SYNOPSIS

http://www.xyz.com/G.pl?sys=MyFont&file=http://www.zyx.com/dir/file.html

or

% G.pl sys=MyFont file=http://www.zyx.com/dir/file.html

=head1 DESCRIPTION

G.pl is the ENH & Tobia front version of the Zobel default "Z.pl" script.
Requires the ENH.pm module found in the same directory G.pl is distributed
in.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
