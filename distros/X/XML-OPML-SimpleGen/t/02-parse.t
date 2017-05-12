#!perl -T
use Test::More ;

eval "use XML::OPML";
plan skip_all => "XML::OPML required for parse tests" if ($@);
plan tests => 2;

require_ok( 'XML::OPML::SimpleGen' );

my $obj = XML::OPML::SimpleGen->new();
$obj->insert_outline(text => 'test');
my $data = $obj->as_string;

my $opml = new XML::OPML;


$opml->parse($data);


isa_ok($opml, 'XML::OPML');

exit;
