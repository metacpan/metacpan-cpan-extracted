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
ADR;TYPE=home;TYPE=pref:;;123 Main Street;Somewhere;Someplace;90210;U.S.A
TEL;TYPE=:+001.555.555-1212
TITLE:Counsel
AGENT:BEGIN:VCARD
FN:Susan Thomas
TEL:+1-919-555-1234
EMAIL;INTERNET:sthomas\@host.com
END:VCARD
ORG:Department of Justice;No-fun Police
CATEGORIES:friends,enemies
UID:2456383
END:vCard

begin:vcard
version:3.0
n:Bobman;Sue;;;
fn:Sue Bobman
nickname:thesuebob
photo;VALUE=uri:http://www.abc.com/pub/photos/foobar.gif
bday:1972-12-01 00:00:00
adr;type=home;type=pref:;;123 Main Street;Somewhere;Someplace;90210;U.S.A
adr;type=work:POB 155;4th floor;456 Work Street;Somewhere;California;90210;U.S.A
tel;type=:+001.555.555-1212
title:Doctor
org:Department of Justice;No-fun medic
categories:friends,enemies
uid:2456552
end:vcard
VCARD

my $use_writer = 0;
my $use_simple = 0;

eval "require XML::SAX::Writer";
$use_writer = ($@) ? 0 : 1;

if ($use_writer) {
  eval "require XML::Simple";
  $use_simple = ($@) ? 0 : 6;
}

plan tests => (6 + $use_writer + $use_simple);

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

ok($driver->parse($vcard),"Parsed vCard");

# diag($output);

if ($use_simple) {
  my $ref   = &XML::Simple::XMLin($output);

  cmp_ok($ref->{'vCard'}->[0]->{'adr'}{'street'}, 
	 "eq", "123 Main Street", "VCARD ADR: street");

  cmp_ok($ref->{'vCard'}->[0]->{'tel'}->{content}, 
	 "eq", "+001.555.555-1212", "VCARD ADR: tel");

  cmp_ok($ref->{'vCard'}->[0]->{'agent'}{'vCard'}->{'fn'},
	 "eq", "Susan Thomas",    "AGENT VCARD: fn");

  cmp_ok($ref->{'vCard'}->[1]->{'fn'}, 
	 "eq", "Sue Bobman",      "Multiple VCARD: fn");

  cmp_ok($ref->{'vCard'}->[1]->{'adr'}->[1]->{'region'},
	 "eq", "California",      "Multiple ADR: region");

  cmp_ok($ref->{'vCard'}->[0]->{'adr'}->{'del.type'},
	 "eq", "home,pref", "TYPE: list params");
}

# $Id: 001-parse.t,v 1.10 2003/02/18 23:04:42 asc Exp $
