#!/usr/bin/perl
BEGIN {
    unshift @INC, "blib/lib", "blib/arch";
}

use strict;
use XML::STX;

use XML::SAX::Expat;

use XML::SAX::Writer;

(@ARGV == 2 ) || die ("Usage: stx-filter.pl stylesheet.stx data.xml\n\n");

my $templ_uri = shift;
my $data_uri = shift;

my $p = XML::STX::Parser->new();
my $parser_t = XML::SAX::Expat->new(Handler => $p);
my $stylesheet =  $parser_t->parse_uri($templ_uri);

my $writer = XML::SAX::Writer->new();
my $stx = XML::STX->new(Handler => $writer, Sheet => $stylesheet );
my $parser = XML::SAX::Expat->new(Handler => $stx);
$parser->parse_uri($data_uri);

exit 0;
