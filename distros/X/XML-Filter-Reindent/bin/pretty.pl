#!/home1/enno/bin/perl -w
#
# Usage: perl pretty.pl URL > out.xml
#

use strict;

my $url = shift;

use XML::Parser::PerlSAX;
use XML::Filter::Reindent;
use XML::Handler::Composer;

my $composer = new XML::Handler::Composer (Newline => "\n");

my $reindent = new XML::Filter::Reindent (Handler => $composer);

my $parser = new XML::Parser::PerlSAX (KeepCDATA => 1, 
				       UseAttributeOrder => 1,
				       Handler => $reindent);

$parser->parse (Source => { SystemId => $url });
