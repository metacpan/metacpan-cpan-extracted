# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw( $loaded %checksums $md5);

BEGIN { $| = 1; print "1..2\nLoading ... "; }
END {print "not ok 1\n" unless $loaded;}

use XML::Filter::Digest;
use XML::Handler::YAWriter;
use XML::Parser::PerlSAX;
use IO::File;
use Digest::MD5;
use Data::Dumper;

%checksums = (
	'REC-xpath.jumplist' => "6402987c5eefaed51117f1067914914f",
	);

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "Script ... ";

my $script = new XML::Script::Digest(
    'Source' => {
        'SystemId' => 'REC-xpath.digest'
    } )->parse();

print "ok 2\n";

# print Dumper($script);

print "Format ... ";

# $XML::XPath::Debug=1;

my $ya = new XML::Handler::YAWriter( 
	'AsFile' => "REC-xpath.jumplist",
	'Pretty' => {
		'PrettyWhiteIndent' => 1,
		'PrettyWhiteNewline' => 1
		}
	);

my $digest = new XML::Filter::Digest(
	'Source' => { 'SystemId' => 'REC-xpath.xhtml' },
	'Handler'=> $ya,
	'Script' => $script
	)->parse();

$md5=Digest::MD5->new->addfile(
	new IO::File( "<REC-xpath.jumplist" )
    )->hexdigest;

print $md5." ... ";
print "not " if $md5 ne $checksums{'REC-xpath.jumplist'};

print "ok 3\n";

# print Dumper($digest);
