use Test::More;
use XML::XPath;
use XML::XPath::Parser;
use XML::XPath::XMLParser;

my $p = XML::XPath->new(filename => 'examples/test.xml');
ok($p);

my $pp = XML::XPath::Parser->new();
ok($pp);

$pp->parse("variable('amount', number(number(./rate/text()) * number(./units_worked/text())))");

my $path = $pp->parse('.//
           tag/
           child::*/
           processing-instruction("Fred")/
           self::node()[substr("33", 1, 1)]/
           attribute::ra[../@gunk]
                   [(../../@att="va\'l") and (@bert = "geee")]
                   [position() = child::para/fred]
                   [0 -.3]/
           geerner[(farp | blert)[predicate[@vee]]]');

ok($path);
ok($path->as_string);

my $nodes = $p->find('/timesheet//wednesday');
is($nodes->size, 2);

done_testing();