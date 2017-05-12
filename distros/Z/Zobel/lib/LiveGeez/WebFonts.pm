package LiveGeez::WebFonts;
use base qw(Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT %WebFonts);


	require 5.000;
	require Exporter;

	@EXPORT = qw(
		AddWebFont
	);

	%WebFonts = (
		PFR	=>	{
			AmharicBook 	=>	'http://iethiopia.com/pfr/AB.pfr',
		},
	)
}



sub WritePFRHeader
{

	my $pfrHeader = qq (<link HXBURNED REL="fontdef" SRC="$WebFonts{PFR}{$_[0]}">\n  <script LANGUAGE="JavaScript" SRC="http://www.geez.org/pfr/tdserver.js"></script>\n<link>\n);
	
	$_ = $_[1];

	# s|(<head>(\s+)?)|$1<link HXBURNED REL="fontdef" SRC="$WebFonts{PFR}{$_[0]}">\n  <script LANGUAGE="JavaScript" SRC="http://www.bitstream.com/wfplayer/tdserver.js"></script>$2|i;

	s/(<head>(\s+)?)/$1$pfrHeader$2/i
		# unless ( m|http://www.bitstream.com/wfplayer/tdserver.js|i );
		unless ( m/tdserver.js/i );

	$_;
}



sub WriteEFTHeader
{

	my $eftHeader = qq (<link href="http://www.waltainfo.com/vg.css" rel="STYLESHEET" type="text/css">);

	$_ = $_[1];
	# s|(<head>(\s+)?)|$1<LINK href="http://www.waltainfo.com/vg.css" rel=STYLESHEET type=text/css>$2|i;

	s/(<head>(\s+)?)/$1$eftHeader$2/
		unless ( m|http://www.waltainfo.com/vg.css|i );

	$_;
}


sub AddWebFont
{

	if ( $_[0]->{request}->{WebFont} eq "PFR" ) {
		$_ = WritePFRHeader ( $_[0]->{request}->{sysOut}->{sysName}, $_[1] );
	}
	elsif ( $_[0]->{request}->{WebFont} eq "WEFT" ) {
		$_ = WriteEFTHeader ( $_[0]->{request}->{sysOut}->{sysName}, $_[1] );
	}


	$_;
}


1;

__END__
