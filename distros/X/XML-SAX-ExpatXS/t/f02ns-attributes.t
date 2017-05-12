use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo xmlns="http://ns1" id="e1">
  <p:boo xmlns:p="http://ns2" id="e2"/>
</foo>
_xml_

$parser->parse_string($xml);
$parser->set_feature('http://xmlns.perl.org/sax/ns-attributes', 0);
$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'foo({}id/{}xmlns)p:boo({http://www.w3.org/2000/xmlns/}p/{}id)foo({}id)p:boo({}id)');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_element {
    my ($self, $el) = @_;
    #warn("Start:$el->{Name}:$el->{Attributes}\n");
    #Dump($el);
    $atts = join('/', sort keys %{$el->{Attributes}});
    $self->{data} .= "$el->{Name}($atts)";
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:$el->{Name}\n");
    #Dump($el);
}

sub start_prefix_mapping {
    my ($self, $map) = @_;
    #warn("sPref:$map->{Prefix}\n");
    #Dump($map);
    #$self->{data} .= "sP($map->{Prefix}:$map->{NamespaceURI})";
}

sub end_prefix_mapping {
    my ($self, $map) = @_;
    #warn("ePref:$map->{Prefix}\n");
    #Dump($map);
    #$self->{data} .= "eP($map->{Prefix})";
}
