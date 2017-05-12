# vim:set ft=perl:
use lib 'lib';

use Test::More qw(no_plan);

use XML::DOM::Lite qw(Parser Serializer :constants);

my $nodeval = "This is some white\n\nspace with\n a few\n\n new line chars";

my $xmlstr = <<"XML";
<root>$nodeval</root>
XML

my $parser = Parser->new();
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

ok($doc->documentElement->firstChild->nodeValue eq $nodeval);

$parser = Parser->new(whitespace => 'strip');
$doc = $parser->parse($xmlstr);
ok($doc->documentElement->firstChild->nodeValue eq $nodeval);

$parser = Parser->new(whitespace => 'normalize');
$doc = $parser->parse($xmlstr);

my $stripped = $nodeval;
$stripped =~ s/[ \r\n\t]+/ /g;

ok($doc->documentElement->firstChild->nodeValue eq $stripped);
ok($doc->documentElement->firstChild->nodeValue ne $nodeval);
