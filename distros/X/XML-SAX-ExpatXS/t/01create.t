use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $parser = XML::SAX::ExpatXS->new(
    Handler => TestH->new(),
);

ok($parser);

$parser->parse_string("<foo>fffffggg</foo>");

$parser->parse_string("<x:foo xmlns:x='urn:foob' x:bar='glib'/>");

package TestH;
#use Devel::Peek;

sub new { bless {}, shift }

sub characters {
    my ($self, $chars) = @_;
    #warn("Chars:\n");
    #Dump($chars);
}

sub start_element {
    my ($self, $el) = @_;
    #warn("Start:\n");
    #Dump($el);
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:\n");
    #Dump($el);
}
