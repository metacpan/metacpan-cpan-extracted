package LiveGeez::Services;
use base qw(Exporter);



BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT $fortuneDir $u);

	$VERSION = '0.20';

	require 5.000;

	@EXPORT = qw(
		ProcessRequest
		ProcessDate
		ProcessFortune
		ProcessNumber
		ProcessString
		AboutLiveGeez
	);

	require LiveGeez::File;
	require Convert::Ethiopic;
	require Convert::Ethiopic::Date;
	require Convert::Ethiopic::String;
	use Convert::Ethiopic::System qw($unicode $utf8);
	require HTML::Entities;

	$fortuneDir = "/path/to/fortunes";

	$u = new Convert::Ethiopic::System ( "UTF8" );
}


#------------------------------------------------------------------------------#
#
# "ProcessFortune"
#
#	Opens a stream to the fortune routine and grabs an Ethiopic fortune in
#	UTF8 and returns the result converted in the $sysOut system.  This works
#	presently with any cgi "fortune" querry.  It has not been tested yet
#	with inline <LIVEGEEZ game="fortune" src="database"> markups.
#	
#	"phrase" pragma is checked to return response as complete HTML document.
#
#------------------------------------------------------------------------------#
sub ProcessFortune
{
my $request = shift;


	open (FORTUNE, "fortune $fortuneDir |");
	my $fortune = Convert::Ethiopic::ConvertEthiopicFileToString (
		\*FORTUNE,
               $u,
               $request->{sysOut},
	);
	close (FORTUNE);

	$fortune =~ s/\n/<br>$&/g;

	$fortune = HTML::Entities::encode($fortune, "\200-\377")
	           if ( $request->{sysOut}->{'7-bit'} eq "true" );

	$fortune = $request->TopHtml ( "Your Ethiopian Fortune!" )
	         . $fortune
	         . $request->BotHtml 
	           if ( $request->{phrase} );

	$fortune;

}


#------------------------------------------------------------------------------#
#
# "ProcessNumber"
#
#    Service for numeral conversion between Arabic and Ethiopic systems.
#	
#    "phrase" pragma is checked to return response as complete HTML document. 
#
#------------------------------------------------------------------------------#
sub ProcessNumber
{
my $request = shift;


	my $uNumber = Convert::Ethiopic::Number->new ( $request->{number} )->convert;

	my $eNumber = Convert::Ethiopic::String->new (
	 	      $uNumber,
	 	      $u,
	 	      $request->{sysOut},
	)->convert ( 1 );

	$eNumber    = $request->TopHtml ( "Converting $request->{number} into Ethiopic..." )
	            . "$request->{number} is "
	            . "$eNumber\n"
	            . $request->BotHtml
	              if ( $request->{phrase} );

	$eNumber;

}


sub ProcessString 
{
my $request = shift;


	my $eString = Convert::Ethiopic::String->new (
	 	      $request->{string},
	 	      $request->{sysIn},
	 	      $request->{sysOut},
	)->convert ( 1 );

	return $eString if ( $request->{pragma} eq "plain-text" );

	if ( $request->{sysOut}->{sysName} eq "sera" ) {
		$eString =~ s/<</&#171;/g;
		$eString =~ s/>>/&#187;/g;
	}

	$eString = HTML::Entities::encode($eString, "\200-\377")
	           if ( $request->{sysOut}->{'7-bit'} eq "true" );

	$eString =~ s/\xa0/&nbsp;/g   # wish HTML::Entities didn't do this..
	            unless ( $request->{sysOut}->{xferNum} == $utf8 );

	$eString = $request->TopHtml ( "Your Ethiopic Phrase!" )
	         . "<pre>\n"
	         . "$eString\n"
	         . "</pre>\n"
	         . $request->BotHtml
	           if ( $request->{phrase} );

	$eString;

}


#------------------------------------------------------------------------------#
#
# "AboutLiveGeez"
#
#    Tell the enquiring mind about the LiveGe'ez / LibEth.  This is the current
#    default response to any "about" querry.  Later we might add extras such as
#    AboutGFF, AboutENH, etc.
#
#------------------------------------------------------------------------------#
sub AboutLiveGeez
{
my $request = shift;


	$request->print ( $request->TopHtml ( "About LiveGe'ez &amp; LibEth" ) );
	my $leVersion = Convert::Ethiopic::LibEthVersion;
	$request->print( <<ABOUT );
<h1 align="center">About LiveGe'ez &amp; LibEth</h1>

<p>This is the GFF implementation of the LiveGe'ez Remote Processing Protocal.  Ethiopic web service is performed through a collection of CGI scripts (Zobel v.0.20) written in Perl interfaced with the LibEth library (v. $leVersion).</p>
<h3>For More Information Visit:</h3>
<ul>
  <li> <a href="http://libeth.sourceforge.net/">LibEth</a>
  <li> <a href="http://libeth.sourceforge.net/Zobel/">Zobel</a>
  <li> <a href="http://libeth.sourceforge.net/LiveGeez.html">LiveGe'ez</a>
</ul>
ABOUT

	$request->print ( $request->BotHtml );
	exit (0);

}


sub ProcessDate
{
my $request = shift;
my ( $day, $month, $year ) = split ( ",", $request->{date} );
my $returnDate;


	#
	# Instantiate new date objects
	#

	my ($date, $xdate, $euro, $orth );
	if (  $request->{calIn} eq "euro" ) {
		$euro = $date = Convert::Ethiopic::Date->new ( $request->{calIn}, $day, $month, $year );
		$orth = $xdate = $date->convert;
	}
	else {
		$orth = $date = Convert::Ethiopic::Date->new ( $request->{calIn}, $day, $month, $year );
		$euro = $xdate = $date->convert;
	}


	return "$xdate->{date},$xdate->{month},$xdate->{year}"
		if ( $request->{'date-only'} );

	$orth->lang ( $request->{sysOut}->{langNum} );


	if ( $request->{'is-holiday'} && $request->{phrase} ) {
		$returnDate = $orth->isEthiopianHoliday;

		if ( $returnDate ) {
			my ( $Day, $Month ) = $orth->getDayMonthYearDayName;
			$phrase  = "$Day�� $Month $orth->{date} ";
			$phrase .= ( $request->{lang} eq "amh" ) ?  "ቀን" : "መዓልቲ";
			$phrase .= " $returnDate ";
			$phrase .= ( $request->{lang} eq "amh" ) ? "ነው።" : "እዩ።" ;
			$phrase = Convert::Ethiopic::String->new (
	 	      			$phrase,	
			             	$u,
					$request->{sysOut},
			)->convert ( 1 );
		}
		else {
			$phrase = "$date->{date}/$date->{month}/$date->{year} is <u>not</u> a holiday.\n"
		}

		$returnDate = $request->TopHtml ( "Checking Holidy for $date->{year}/$date->{month}/$date->{year}" )
		            . $phrase
		            . $request->BotHtml
		            ;
	}
	elsif ( $request->{'is-holiday'} ) {
		$returnDate  = ( $orth->isEthiopianHoliday ) ? "1" : "0" ;
		$returnDate .= "\n";
	}
	elsif ( !$request->{phrase} ) {

		my ( $etDoW, $etMonthName, $etNumYear, $etDayName ) 
		                  = $orth->getDayMonthYearDayName;
		my ($euDoW)       = $euro->getEuroDayOfWeek;
		my ($euMonthName) = $euro->getEuroMonthName;
		my ($etDate)      = "$etDoW፣ $etMonthName $orth->{date} $etNumYear ";


		#
		# blocked for now bedause of the LCInfo difference on zendro
		#
		# if ( $request->{sysOut}->{LCInfo} ) {
			my $s = new Convert::Ethiopic::String ( $etDate, $u, $request->{sysOut} );
			             	
			$etDate = $s->convert ( 1 );

			$s->string ( $etDayName );
			$etDayName = $s->convert ( 1 );
		# }

		if ( $request->{calIn} eq "euro" ) {
			#
			# Convert from European -> Ethiopian
			#
			$phrase = $request->TopHtml ( "From The European Calendar To The Ethiopian" )
			        . "<h3>$euDoW, $euMonthName $euro->{date}, $euro->{year}"
			        . " <i><font color=blue><u>is</u></font></i> "
			        . $etDate
			        . " <i>(<font color=red>$etDayName</font>)</i></h3>\n"
			        ;
		}
		else {
			#
			# Convert from Ethiopian -> European
			#
			$phrase = $request->TopHtml ( "From The Ethiopian Calendar To The European" )
			        . "<h3>"
			        . $etDate
			        . " <i><font color=blue><u>is</u></font></i> "
			        . "$euDoW, $euMonthName $euro->{date}, $euro->{year}"
			        . " <i>(<font color=red>$etDayName</font>)</i></h3>\n"
			        ;
		}


		$phrase     =~ s/፣/,/ unless ( $request->{sysOut}->{LCInfo} );

		$returnDate = $phrase . $request->BotHtml;
					 
  	}

	$returnDate = HTML::Entities::encode($returnDate, "\200-\377")
	              if ( $request->{sysOut}->{'7-bit'} eq "true" );


	$returnDate;

}


sub ProcessRequest
{
my $r = shift;


	
	if ( $r->{type} eq "file") {
		# Only SERA supported at this time...
		# $r->HeaderPrint;
		my $f = LiveGeez::File->new ( $r );
		$f->Display;
	}
	else {

	$r->{'x-gzip'} = 0;
	$r->HeaderPrint;

	if ( $r->{type} eq "calendar" ) {

		# What time is it??
		$r->DieCgi ( "Unsupported Calendar System: $r->{calIn}" )
		        if ( $r->{calIn} && $r->{calIn}   !~ /(ethio)|(euro)/ );
		$r->DieCgi ( "Unsupported Calendar System: $r->{calOut}" )
		        if ( $r->{calOut} && $r->{calOut} !~ /(ethio)|(euro)/ );
		
    		$r->print ( ProcessDate ( $r ) );
	}
	elsif ( $r->{type} eq "string" ) {
		# Only SERA supported at this time...
		$r->print ( ProcessString ( $r ) );
	}
	elsif ( $r->{type} eq "number" ) {
		# We have a number request...
		$r->print ( ProcessNumber ( $r ) );
	}
	elsif ( $r->{type} eq "game-fortune" ) {
		# A random fortune from our vast library...
		$r->print ( ProcessFortune ( $r ) );
	}
	elsif ( $r->{type} eq "about" ) {
		#  For folks who want to know more... 
		AboutLiveGeez ( $r );
	}
	else {
		return ( 0 );
	}
	}

	1;

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::Services - Request Processing Services for LiveGe'ez

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

Services.pm provides request processing services for a LiveGe'ez query
as specified in the LiveGe'ez Remote Processing Protocol.  "ProcessRequest"
takes a LiveGe'ez LiveGeez::Request object and performs the appropriate
service.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
