# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\nLoading ... "; }
END {print "not ok 1\n" unless $loaded;}

use XML::Filter::Hekeln;
use XML::Handler::YAWriter;
use XML::Parser::PerlSAX;
use IO::File;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "Format ... ";

$script = <<'!HERE!';
#	this is a Hekeln Script
#	beware that tabulators and newlines are of importance
#	rftm: perldoc XML::Hekeln

start_element:repository
!	$self->handle('start_document',{});
<	html	>
<	body	>
<	h1	>
	XML-Edifact Repository
</	h1	>
<	h2	>
	~name~
</	h2	>
<	p	>
	Agency: ~agency~
<	br	>
	Code: ~code~
<	br	>
	Version: ~version~
<	br	>
	Description: ~desc~
</	p	>
<	hr	>

end_element:repository
</	body	>
</	html	>
!	$self->handle('end_document',{});

start_element:segment
<	h2	>
	Segment: ~code~ - ~name~
</	h2	>
<	p	>
	Description: ~desc~
</	p	>
<	ul	>

end_element:segment
</	ul	>
<	hr	>

start_element:composite
<	li	>
	~code~ - ~name~ - ~flag~
<	ul	>

end_element:composite
</	ul	>
</	li	>

start_element:element
<	li	>
	~code~ - ~name~ - ~flag~ ~repr~

end_element:element
</	li	>

start_element:chartest
<	li	>
	Characters: 
++	chartest

end_element:chartest
--	chartest
</	li	>

characters:chartest
	~Data~

start_element:cdatatest
<	li	>
++	cdatatest

end_element:cdatatest
--	cdatatest
</	li	>

start_cdata:cdatatest
	[CDATA STARTS]

end_cdata:cdatatest
	[CDATA ENDS]

characters:cdatatest
	~Data~
!HERE!

my $xml_file = new IO::File( '>sdsd.html' );
my $handler = new XML::Handler::YAWriter(
	'Output' => $xml_file,
	'Pretty' => {
		'CatchEmptyElement' => 1,
		'AddHiddenAttrTab' => 1,
		'AddHiddenNewLine' => 1,
		'NoProlog' => 1,
		'NoDTD' => 1
		}
	);

my $hekeln = new XML::Filter::Hekeln(
#	'Debug'  => 1,
	'Handler' => $handler,
	'Script' => $script
	);

my $parser = new XML::Parser::PerlSAX( 'Handler' => $hekeln );
   $parser->parse( 'Source' => { 'SystemId' => 'sdsd.xml' } );
   $xml_file->close();

print "ok 2\n";
