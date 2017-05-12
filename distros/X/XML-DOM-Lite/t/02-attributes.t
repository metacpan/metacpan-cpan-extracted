# vim:set ft=perl:
use lib 'lib';

use Test::More 'no_plan';
use XML::DOM::Lite qw(Parser);

my $xmlstr = '<page foo="bar"><para title="thing">para thing</para></page>';
my $parser = Parser->new(whitespace => 'strip');
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

my $page = $doc->documentElement;

# attributes as hashref
my %atts = %{$page->attributes};
is($atts{"foo"}, "bar", '$atts{foo} eq "bar"');
is($page->attributes->{foo}, 'bar',
    '$page->attributes->{foo} eq "bar"');

# attributes as nodelist
ok($page->attributes->length == 1);
for (my $x = 0; $x < $page->attributes->length; $x++) {
    ok($page->attributes->item($x)->nodeName eq 'foo');
    ok($page->attributes->item($x)->nodeValue eq 'bar');
}

# attributes as arrayref
ok(@{$page->attributes} == 1);
foreach (@{$page->attributes}) {
    ok($_->nodeName eq 'foo');
    ok($_->nodeValue eq 'bar');
}
