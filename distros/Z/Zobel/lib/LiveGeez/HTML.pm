package LiveGeez::HTML;
use base qw(HTML::Filter Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT);

	$VERSION = '0.20';

	require 5.000;

	@EXPORT = qw(FileBuffer);

	use LiveGeez::WebFonts;
	require Convert::Ethiopic;
	# use Convert::Ethiopic::System;
	require LiveGeez::Directives;
	require HTML::Entities;
}



sub UpdateForSysOut
{
my $file;
	
	($file, $_ ) = @_;

	my $sysOut = $file->{request}->{sysOut}->{sysName};

	my $menuFont = $sysOut;
	$menuFont .= ".$file->{request}->{WebFont}" if ( $file->{request}->{WebFont} );
	
	#
	# This updates the font menus:
	#
	s/(value="$menuFont") LIVEGEEZSYS(OUT|IN)>/$1 selected>/g;
	s/ LIVEGEEZSYS(OUT|IN)>/>/g;


	$sysOut      .= ".$file->{request}->{sysOut}->{xfer}"
	             if ( $file->{request}->{sysOut}->{xfer} ne "notv" );
	$sysPragmaOut = ( $file->{request}->{pragma} )
	              ?  "$sysOut&pragma=$file->{request}->{pragma}"
	              :  $sysOut
	              ;


	s/LIVEGEEZSYS/$sysPragmaOut/g;


	#
	#  Legacy Calendar Links
	#
	s/cal=/sys=$sysPragmaOut&cal=/g unless ( $file->{request}->{usecookies} );

	my $langOut = $file->{request}->{sysOut}->{lang};
	s/(value="$langOut") LIVEGEEZLANG(OUT|IN)>/$1 selected>/g;
	s/ LIVEGEEZLANG(OUT|IN)>/>/g;
	s/LIVEGEEZLANG/$langOut/g;

	#
	#  Downloadable Font Links
	#
	$_ = AddWebFont ( $file, $_ ) if ( $file->{request}->{WebFont} );

	#
	#  Encoding Specific updates:
	#
	s/(<head>(\s+)?)/$1<META HTTP-EQUIV="content-type" content="text-html; charset=utf-8">$2/i if ( $file->{request}->{sysOut}->{xfer} eq "utf8" );

	s/(value="7-bit")>/$1 checked>/ if ( $file->{request}->{sysOut}->{'7-bit'} eq "true" );

	if ( $file->{request}->{sysOut}->{sysName} =~ "JIS" ) {  # this should be in the jis filter, but this is easier
		s/\&laquo;/þü/ig;
		s/\&#171;/þü/g;
		s/\&raquo;/þý/ig;
		s/\&#187;/þý/g;
	}

	s/(<body)/<base href="$file->{doc_root}">\n$1/i if ( !$file->{baseUpdated} && $file->{request}->{config}->{set_local_base} );

	$_;
}


sub FileBuffer
{
my $file = shift;


	my $seraFile = $file->{uris}->{source};

	my $fileStream = ($file->{isZipped}) ? "gzip -d --stdout $seraFile |" : "$seraFile";

	# if ( $file->{request}->{sysIn} ) {
	# 	printf STDERR "Converting $file->{request}->{file} in language $file->{request}->{sysIn}->{langNum}";
	# 	printf STDERR " out language $file->{request}->{sysOut}->{langNum}\n";
	# }
	# else {
	# 	printf STDERR "No Language Set! Dumping $file->{request}->{file}.\n";
	# }

	open ( FILE, $fileStream );

	# printf STDERR "Converting[$$] $fileStream  => $file->{request}->{sysOut}->{sysName}\n";
	# printf STDERR "Error<0>[$$]: [$!]  [$@]\n";
	$_ = ( $file->{request}->{sysIn} )
	     ? Convert::Ethiopic::ConvertEthiopicFileToString (
		 \*FILE,
	 	 $file->{request}->{sysIn},
	 	 $file->{request}->{sysOut}
	       )
	     : join ( "", <FILE> )
	   ;
	# printf STDERR "Error<1>[$$]: [$!]  [$@]\n";
	close ( FILE );
	# printf STDERR "Done[$$] $fileStream\n";


	# printf STDERR "HTML::Directives Start[$$] $seraFile\n";
	#
	# unless parsed and we have a symbol other than LIVEGEEZSYS
	#

	#
	# Parse LIVEGEEZ directives if we are working with a source file that 
	# has not been thru it.
	#
	#  Update LIVEGEEZLINK and <a href...><sera></sera></a> if remote
	#  SERA file (PostUpdateHREF) and base stuff.
	#
	#  A local SERA file needs Directives processing if any
	#
	$_ = LiveGeez::Directives::ParseDirectives ( $file, $_ ) if ( !$file->{refsUpdated} && /LIVEGEEZ[^S]/i );
	# printf STDERR "HTML::Directives Done[$$] $seraFile\n";

	$_ = UpdateForSysOut ( $file, $_ );

	$_ = HTML::Entities::encode ( $_, "\200-\377" )
	     if ( $file->{request}->{sysOut}->{'7-bit'} eq "true" );

	$file->{htmlData} = $_;

	1;
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::HTML - HTML Conversions for LiveGe'ez

=head1 SYNOPSIS

FileBuffer ( $f );  # Where $f is a File.pm object.

=head1 DESCRIPTION

HTML.pm contains the routines for conversion of HTML document content between
Ethiopic encoding systems and for pre-interpretation of HTML markups for
compliance with the LiveGe'ez Remote Processing Protocol.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
