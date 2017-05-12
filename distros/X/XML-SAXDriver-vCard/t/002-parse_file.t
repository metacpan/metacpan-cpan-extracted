use strict;
use Test::More;

my $vcard = <<VCARD;
BEGIN:vCard
VERSION:3.0
N:Bobman;Bob;;;
FN:Bob Bobman
NICKNAME:thebobman
PHOTO;VALUE=uri:http://www.abc.com/pub/photos/jqpublic.gif
BDAY:1970-12-01 00:00:00
ADR;TYPE=home,pref:;;123 Main Street;Somewhere;Someplace;90210;U.S.A
TEL;TYPE=:+001.555.555-1212
TITLE:Counsel
ORG:Department of Justice;No-fun Police
CATEGORIES:friends,enemies
UID:2456383
END:vCard
VCARD

my $use_writer = 0;
my $use_simple = 0;

eval "require XML::SAX::Writer";
$use_writer = ($@) ? 0 : 1;

if ($use_writer) {
  eval "require XML::Simple";
  $use_simple = ($@) ? 0 : 1;
}

plan tests => (8 + $use_writer + $use_simple);

use_ok("XML::SAXDriver::vCard");
use_ok("XML::SAX::ParserFactory");
use_ok("FileHandle");

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

my $fh = FileHandle->new(">test.vcd");
isa_ok($fh,"FileHandle");

print $fh $vcard;
$fh->close();

ok($driver->parse_file("test.vcd"),"Parsed vCard: test.vcd");
ok($driver->parse_uri("file://test.vcd"),"Parsed vCard : file://test.vcd");

if ($use_simple) {
  my $ref = &XML::Simple::XMLin($output);
  cmp_ok($ref->{'vCard'}{'adr'}{'street'},"eq","123 Main Street",$ref->{'vCard'}{'adr'}{'street'});

}

# $Id: 002-parse_file.t,v 1.4 2003/02/17 15:18:09 asc Exp $
