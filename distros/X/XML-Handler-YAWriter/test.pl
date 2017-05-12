# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Handler::YAWriter;
use XML::Parser::PerlSAX;
use IO::File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $xml_file = new IO::File( '>linux.2.xml' );
my $handler = new XML::Handler::YAWriter(
	'Output' => $xml_file,
	'Pretty' => { 'CatchWhiteSpace' => 1 }
	);
my $parser = new XML::Parser::PerlSAX( 'Handler' => $handler );

   $parser->parse( 'Source' => { 'SystemId' => 'linux.1.xml' } );
   $xml_file->close();

print "ok 2\n";

   $xml_file = new IO::File( '>linux.3.xml' );
   $handler->{'Output'} = $xml_file;
   $handler->{'Pretty'}{'CatchWhiteSpace'}=0;
   $handler->{'Pretty'}{'NoWhiteSpace'}=1;
   $handler->{'Pretty'}{'NoComments'}=1;
   $handler->{'Pretty'}{'AddHiddenNewline'}=1;
   $handler->{'Pretty'}{'AddHiddenAttrTab'}=1;
   $parser->parse( 'Source' => { 'SystemId' => 'linux.1.xml' } );
   $xml_file->close();

print "ok 3\n";

   $handler->{'AsFile'} = 'linux.4.xml';
   $handler->{'Pretty'}{'CatchWhiteSpace'}=0;
   $handler->{'Pretty'}{'NoWhiteSpace'}=0;
   $handler->{'Pretty'}{'NoComments'}=0;
   $handler->{'Pretty'}{'AddHiddenNewline'}=0;
   $handler->{'Pretty'}{'AddHiddenAttrTab'}=0;
   $handler->{'Pretty'}{'PrettyWhiteNewline'}=1;
   $handler->{'Pretty'}{'PrettyWhiteIndent'}=1;
   $parser->parse( 'Source' => { 'SystemId' => 'linux.3.xml' } );

print "ok 4\n";

   $handler->{'AsFile'} = 'action.tst';
   $handler->{'Pretty'} = {
	NoProlog => 1,
	NoWhiteSpace => 1,
	CatchEmptyElement => 1,
	PrettyWhiteIndent => 1,
	PrettyWhiteNewline => 1
	};
   $parser->parse( 'Source' => { 'SystemId' => 'action.xml' } );

print "ok 5\n";

   $handler->{'AsFile'} = 'directory.tst';
   $handler->{'Pretty'} = {
        'NoWhiteSpace'       => 1,
        'PrettyWhiteNewLine' => 1,
        'PrettyWhiteIndent'  => 1,
        'CatchEmptyElement'  => 1,
        'AddHiddenAttrTab'   => 1,
        'CompactAttrIndent'  => 1
	};
   $parser->parse( 'Source' => { 'SystemId' => 'directory.xml' } );

print "ok 6\n";

   $handler->{'AsFile'} = 'cdataout.xml';
   $handler->{'Pretty'} = {
        'NoWhiteSpace' 	     => 1,
        'PrettyWhiteNewLine' => 1,
        'PrettyWhiteIndent'  => 1,
        'CatchEmptyElement'  => 1,
        'CompactAttrIndent'  => 1
	};
   $parser->parse( 'Source' => { 'SystemId' => 'cdatain.xml' } );

print "ok 7\n";

   $handler->{'AsFile'} = 'nullout.xml';
   $handler->{'Pretty'} = {
        CompactAttrIndent => 1,
        NoComments => 1,
        PrettyWhiteNewline => 1,
        PrettyWhiteIndent => 1,
        NoWhiteSpace => 1,
        CatchEmptyElement => 1
	};
   $parser->parse( 'Source' => { 'SystemId' => 'nullin.xml' } );

print "ok 8\n";
