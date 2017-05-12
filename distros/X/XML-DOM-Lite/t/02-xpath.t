# vim:set ft=perl:
use lib 'lib';

use Test::More 'no_plan';
use XML::DOM::Lite qw(Parser XPath);

my $xmlstr = '<page foo="bar"><para title="thing">para thing</para></page>';
my $parser = Parser->new(whitespace => 'strip');
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

my $xpath = XPath->new;
my $nlist = $xpath->evaluate(q{//para[@title='thing']}, $doc);
is(scalar(@$nlist), 1);
is($nlist->[0], $doc->documentElement->firstChild);
is($nlist->[0]->nodeName, 'para');
