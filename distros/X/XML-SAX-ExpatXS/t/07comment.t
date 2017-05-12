use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo>
  <item>abc</item>
  <!-- comment text -->
</foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq ' comment text ');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub comment {
    my ($self, $com) = @_;
    #warn("Com:$com->{Data}\n");
    #Dump($com);
    $self->{data} .= $com->{Data};
}
