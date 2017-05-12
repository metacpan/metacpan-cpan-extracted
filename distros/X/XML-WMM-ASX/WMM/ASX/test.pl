# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::WMM::ASX;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$f  = XML::WMM::ASX->new;
$t  = $f->header;
$t .= $f->abstract(text=>"This text will show up as a ToolTip for the show");
$t .= $f->title( text=>"Show Title");
$t .= $f->author( text=>"ccz");
$t .= $f->copyright( text=>"2000 ccz");
$t .= $f->logo( path  => "http://some.com/icons/apache_pb.gif",
		style => "ICON");
$t .= $f->base( path => "http://www.microsoft.com/windows/windowsmedia" );
$t .= $f->startentry;
$t .= $f->ref ( type => "http",
	        path => "some.com/m991012.asf", );
$t .= $f->duration ( value => "00:00:30" );
$t .= $f->banner ( path => "http://perl.com/unknown.jpg",
                   moreinfo =>"http://www.microsoft.com/windows/windowsmedia", 
                   abstract =>"This is a tooltip for clip 1.",);
$t .= $f->endentry;
$t .= $f->end;

$wanted = (<<END);
<ASX version = "3" >
<ABSTRACT>This text will show up as a ToolTip for the show</ABSTRACT>
<TITLE>Show Title</TITLE>
<AUTHOR>ccz</AUTHOR>
<COPYRIGHT>2000 ccz</COPYRIGHT>
<Logo HREF = "http://some.com/icons/apache_pb.gif" Style = "ICON" />
<Base HREF = "http://www.microsoft.com/windows/windowsmedia" />
<ENTRY>
<ref HREF="http://some.com/m991012.asf" /> 			      
<Duration value = "00:00:30" />
<BANNER HREF="http://perl.com/unknown.jpg">
<ABSTRACT>This is a tooltip for clip 1.</ABSTRACT>
<MoreInfo href = "http://www.microsoft.com/windows/windowsmedia" />
</BANNER>
</ENTRY>
</ASX>
END

print ($t eq $wanted? "ok 2\n" : "not ok 2\n");



