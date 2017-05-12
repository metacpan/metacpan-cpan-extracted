#!perl -T

use Test::More tests => 6;
use Data::Dumper;

use XML::Snap;

my $xml = XML::Snap->new('test');
isa_ok ($xml, 'XML::Snap');
is ($xml->name, 'test');
ok ($xml->is('test'));


$xml = XML::Snap->parse ('<test2><this><this2/></this></test2>');
isa_ok ($xml, 'XML::Snap');
is ($xml->name, 'test2');
ok ($xml->is('test2'));