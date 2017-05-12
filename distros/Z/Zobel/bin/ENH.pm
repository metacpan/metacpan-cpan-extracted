package ENH;
use base qw (Exporter);

BEGIN
{
	use strict;
	use vars qw( $ustr $sstr @EXPORT );
	require 5.000;

	@EXPORT = qw(
		OpenFrameSet
		ProcessFramesFile
		ProcessNoFramesFile
	);

	use LiveGeez::File;
	use LiveGeez::Services;
	use LiveGeez::HTML;
	use Convert::Ethiopic::Date;
	use Convert::Ethiopic::String;
	use Convert::Ethiopic::Number;

	$ustr = new Convert::Ethiopic::String ( Convert::Ethiopic::System->new ( "UTF8" ) );
	$sstr = new Convert::Ethiopic::String;
}



sub UpdateHTMLBuffer
{
my $file = shift;



	$file->{htmlData} =~
		s/<ENH date="today">/DateSomething($file->{request})/ie;


	$file->{htmlData} =~
		s/<body/writeMenuHeader ($file->{request})."<body"/ie
			if ( $file->{request}->{mainPage} eq "true" );


}



sub writeMenuHeader 
{
my $request = shift;
my $sys     =  ( $request->{pragma} )
            ?   "$request->{sysOut}->{sysName}&pragma=$request->{pragma}"
            :    $request->{sysOut}->{sysName}
            ;

<<HEADER;
<script language="JavaScript">
<!--
var system = "$sys";
var urlPrefix = "$request->{scriptBase}?sys=" + system + "&file=/";

function updateURLPrefix(newSystem) {
    system = parent.system = newSystem;
    urlPrefix = "$request->{scriptBase}?sys=" + system + "&setcookie=true&frames=yes" + "&file=/index.sera.html";
}

function openLink(sys) {
    updateURLPrefix(sys);
    window.open(urlPrefix, '_top');
}

function openSpecials (file) {
    window.open(urlPrefix + file, '_top');
}
//------------------------------------------------------------------ -->
</script>


<SCRIPT LANGUAGE="JavaScript">
<!-- Original:  Randy Bennett (rbennett\@thezone.net) -->
<!-- Web Site:  http://home.thezone.net/~rbennett/utility/javahead.htm -->

<!-- Begin
function setupDescriptions() {
var x = navigator.appVersion;
y = x.substring(0,4);
if (y>=4) setVariables();
}
var x,y,a,b;
function setVariables(){
if (navigator.appName == "Netscape") {
h=".left=";
v=".top=";
dS="document.";
sD="";
}
else
{
h=".pixelLeft=";
v=".pixelTop=";
dS="";
sD=".style";
   }
}
var isNav = (navigator.appName.indexOf("Netscape") !=-1);
function popLayer(){
desc = "<table cellpadding=3 border=1 bgcolor=F7F7F7><td>";

desc += word;

desc += "</td></table>";

if(isNav) {
document.object1.document.write(desc);
document.object1.document.close();
document.object1.left=x+25;
document.object1.top=y;
}
else {
object1.innerHTML=desc;
eval(dS+"object1"+sD+h+(x+25));
eval(dS+"object1"+sD+v+y);
   }
}
function hideLayer(a){
if(isNav) {
eval(document.object1.top=a);
}
else object1.innerHTML="";
}
function handlerMM(e){
x = (isNav) ? e.pageX : event.clientX;
y = (isNav) ? e.pageY : event.clientY;
}
if (isNav){
document.captureEvents(Event.MOUSEMOVE);
}
document.onmousemove = handlerMM;
//  End -->
</script>


HEADER

}



sub writeMailToUpdate
{
my $file = shift;
my $string;
my $mailToString = ( $file->{request}->{frames} eq "no" ) 
                 ?   "mailToURL"
                 :   "parent.mailToURL"
                 ;

	$string = qq(\n<script language="JavaScript">
<!--
  $mailToString += "$file->{request}->{file}";
//------------------------------------------------------------------ -->
</script>\n\n);


	$string;
}



sub DateSomething
{
my $r = shift;

	my $eu     = new Convert::Ethiopic::Date ( "today" );
	my $et     = $eu->convert;
	# my $number = new Convert::Ethiopic::Number ( $et->{year}, $r->{sysOut} )->convert;
	# my $number = new Convert::Ethiopic::Number ( $et->{year} )->convert;
	my $n = new Convert::Ethiopic::Number ( $et->{year} );

	$ustr->sysOut ( $r->{sysOut} );
	$sstr->sysOut ( $r->{sysOut} );
	my $number = $ustr->convert ( $n->convert );

	my $etDayName = "<font color=red>"
	           . $ustr->convert ( $et->getEthiopicDayName )
	           . "</font>"
	;


	$etDayName =~ s/"/\\"/g;

	my $string  = "<script languages=\"JavaScript\">\nword = \"$etDayName\";\n</script>\n\n";

	$string .= "<table width=640 cellpadding=0 cellspacing=0>\n  <tr><td align=left width=33%>"
	        . $eu->getMonthName
	        . " $eu->{date}, $eu->{year}</td>\n"
	        . "<td align=center width=34%><font color=teal size=+1><font color=teal><b>"
	;


	# my $englishName = $et->getEthiopicDayName;
	my $englishName = "Talbot";

	$string .= $sstr->convert ( "ye".$r->{sysOut}->HTMLName."  dre geS" )
	        . "</b></font></td><td align=right><a href=\"http://enh.ethiopiaonline.net/ECalendars/ecalendars.cgi?sys=$r->{sysOut}->{sysName}\" onMouseOver=\"popLayer(); status='$englishName';return true;\" onMouseOut=\"hideLayer(-50)\"><font color=\"black\">";

	
	$et->{langOut} = $r->{sysOut}->{lang};
	$string .= $ustr->convert ( $et->getMonthName . " $et->{date}፣ " )
	        .  "$number</font></a></td></tr></table>\n";

	my $download = ( $r->{sysOut}->{lang} eq "tir" )
	               ? "tir-et.exe"
		       : "amh-uni.exe"
		       ;
	$string .= "<hr>Welcome to the <b><i>new</i></b> ENH!  You appear to be accessing the site for the first time or your configuration has been lost.  The ENH now uses minty fresh Unicode by default.  Please try installing our <a href=\"ftp://ftp.geez.org/pub/fonts/TrueType/$download\"><font color=\"blue\">Unicode font and keyboard</font></a> or any of the <a href=\"/info/faq.html#FreeFonts\"><font color=\"blue\">free fonts</font></a> available on the Internet.  Help is here for configuring <a href=\"http://www.ethioindex.com/configunicode5.html\"><font color=\"blue\">IE 5.x</font></a> and <a href=\"http://www.ethioindex.com/configunicode4.html\"><font color=\"blue\">IE 4</font></a> for Ethiopic Unicode."
		if ( $r->{FirstTime} );



	$string;
}



sub OpenFrameSet
{
my ( $request, $frame ) = ( shift, shift );
my $frameRoot = "misc/Frames";
my $file      = $request->{file};
my $sysOut    = $request->{sysOut}->{sysName};
my ( $fileSysOut, $sysPragmaOut );


	$sysOut      .= ".$request->{sysOut}->{xfer}"
			 		  if ( $request->{sysOut}->{xfer} ne "notv" );
	$sysPragmaOut = ( $request->{pragma} )
	              ?  "$sysOut&pragma=$request->{pragma}"
	              :   $sysOut
	              ;

	$fileSysOut   =   $request->{sysOut}->{sysName};
	$fileSysOut  .= ".$request->{sysOut}->{xfer}"
					  if ( $request->{sysOut}->{xfer} ne "notv" );
	$fileSysOut  .= ".7-bit"
					  if ( $request->{sysOut}->{'7-bit'} );
	$fileSysOut  .= ".$request->{sysOut}->{options}"
					  if ( $request->{sysOut}->{options} );
	$fileSysOut  .= ".$request->{sysOut}->{lang}";


my $TOP 	  =  ( -e "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html"
			  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/addtop.sera.html"
			  ;
my $LEFT	  =  ( -e "$FileCacheDir/$frameRoot/left.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/left.$fileSysOut.html"
			  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/left.sera.html"
			  ;
my $RIGHT  =  ( -e "$FileCacheDir/$frameRoot/right.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/right.$fileSysOut.html"
			  :  "$scriptBase?sysPragmaOut=$fileSysOut&file=$frameRoot/right.sera.html"
			  ;

my $cacheFile = $file;
$cacheFile  =~ s/sera/$fileSysOut/;
$cacheFile .= ".gz";

my $FILE	   =  ( -e "$FileCacheDir/$cacheFile" && $ENV{HTTP_ACCEPT_ENCODING} =~ "gzip" && $ENV{HTTP_USER_AGENT} !~ "MSIE" )
            ? "$FileCacheDir/$cacheFile"
            : "$scriptBase?sys=$sysPragmaOut&file=$file&frames=skip"
            ;
# my ( $FILE )   =  "$scriptBase?sys=$sysPragmaOut&file=$file&frames=skip";


	open (FRAME, "$webRoot/$frame") || $r->DieCgi ( "!: Can't Open $frame\n" );

	while ( <FRAME> ) {
		s/LIVEGEEZFILE/$FILE/;
		s/LIVEGEEZTOP/$TOP/;
		s/LIVEGEEZLEFT/$LEFT/;
		s/LIVEGEEZRIGHT/$RIGHT/;
		print;
	}

}



sub ProcessFramesFile
{


	my $f = LiveGeez::File->new ( $_[0] );


	#
	# Read data into ->{htmlData} if file is cached.
	#
	if ( $f->{isCached} ) {
		$f->DisplayFromCache;
	}
	else {

		#
		# Translate buffer.
		#
		FileBuffer ( $f );


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ( $f );


		#
		# Display it!
		#
		$f->DisplayFileAndCache;
	}

}



sub ProcessNoFramesFile
{
my $r = shift;
my $articleFile = $r->{file};
my $TEMPLATETOP = "misc/NoFrames/left.sera.html";
my $TEMPLATEBOT = "misc/NoFrames/right.sera.html";



	my $f  = LiveGeez::File->new ( $r );


	#=======================================================================
	#
	# If we've done this before, just display and quit.
	#
	if ( $f->{isCached} ) {
		$f->DisplayFromCache;
	} else {
		#=======================================================================
		#
		# Otherwise create the file from components, display and cache.
		#


		#=======================================================================
		#
		# Top of File
		#

		$r->{file}  = $TEMPLATETOP;
		my $top = LiveGeez::File->new ( $r );


		#=======================================================================
		#
		# Middle of File
		#

		$f->{Title}  = $1 if ( $f->{htmlData} =~ /<title>([^<]+)<\/title>/is );
		$f->{htmlData} =~ s/<(\/)?html>//ogi;
		$f->{htmlData} =~ s/<(\/)?head>//ogi;
		$f->{htmlData} =~ s/<title>([^>]+)<\/title>//ois;
		$f->{htmlData} =~ s/<(\/)?body([^>]+)?>//ogis;
		# $f->{htmlData} =~ s/<\/body>//i;


		#=======================================================================
		#
		# Bottom of File
		#

		$r->{file}  = $TEMPLATEBOT;
		my $bot     = LiveGeez::File->new ( $r );


		#=======================================================================
		#
		# All together now...
		#
		$f->{htmlData} = $top->{htmlData} 
					      . $f->{htmlData} 
					      . $bot->{htmlData} 
					      ;

		$r->{file} = $articleFile;


		#
		# Translate buffer.
		#
		FileBuffer ( $f );


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ( $f );


		#
		# Display it.
		#
		$f->DisplayFileAndCache;
	}


}
1;

__END__


=head1 NAME

ENH -- Specialized Front End to the LiveGe'ez Package.

=head1 SYNOPSIS

use ENH;

=head1 DESCRIPTION

ENH.pm is called by the "G.pl" script used at The Ethiopian New Headlines
and Tobia for specialized file output for HTML formatting with frames, etc.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
