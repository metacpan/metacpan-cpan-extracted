use strict;
use Test::More;

my $use_writer = 0;
my $use_simple = 0;

eval "require XML::SAX::Writer";
$use_writer = ($@) ? 0 : 1;

if ($use_writer) {
  eval "require XML::Simple";
  $use_simple = ($@) ? 0 : 1;
}

plan tests => (6 + $use_writer + $use_simple);

use_ok("XML::SAXDriver::vCard");
use_ok("XML::SAX::ParserFactory");
use_ok("LWP::Simple");

my $output = "";
my $writer = undef;
my $parser = undef;
my $driver = undef;

if ($use_writer) {
  $writer = XML::SAX::Writer->new(Output=>\$output);
  like($writer,qr/XML::(?:SAX::Writer|Filter::BufferText)/,"The object isa ".ref($writer));
}

$parser = XML::SAX::ParserFactory->parser(Handler=>$writer);
can_ok($parser,"get_handler");

$driver = XML::SAXDriver::vCard->new(Handler=>$parser);
isa_ok($driver,"XML::SAXDriver::vCard");

ok($driver->parse_uri("http://perl.aaronland.net/xml/saxdriver/vcard/tests/test.vcd"),"Parsed vCard");

if ($use_simple) {
  my $ref = &XML::Simple::XMLin($output);
  cmp_ok($ref->{'vCard'}{'adr'}{'street'},"eq","123 Main Street",$ref->{'vCard'}{'adr'}{'street'});

}

# $Id: 003-parse_uri.t,v 1.4 2003/02/17 15:18:09 asc Exp $
