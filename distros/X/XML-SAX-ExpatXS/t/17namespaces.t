use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo xmlns="nsDef">
  <p:boo xmlns:p="nsP1">
    <hoo xmlns="">
      <p:woo xmlns:p="nsP2"/>
    </hoo>
  </p:boo>
</foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'sP(:nsDef)sE(nsDef:foo)sP(p:nsP1)sE(nsP1:boo)sP(:)sE(:hoo)sP(p:nsP2)sE(nsP2:woo)eE(nsP2:woo)eP(p)eE(:hoo)eP()eE(nsP1:boo)eP(p)eE(nsDef:foo)eP()');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_element {
    my ($self, $el) = @_;
    #warn("Start:$el->{Name}\n");
    #Dump($el);
    $self->{data} .= "sE($el->{NamespaceURI}:$el->{LocalName})";
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:$el->{Name}\n");
    #Dump($el);
    $self->{data} .= "eE($el->{NamespaceURI}:$el->{LocalName})";
}

sub start_prefix_mapping {
    my ($self, $map) = @_;
    #warn("sPref:$map->{Prefix}\n");
    #Dump($map);
    $self->{data} .= "sP($map->{Prefix}:$map->{NamespaceURI})";
}

sub end_prefix_mapping {
    my ($self, $map) = @_;
    #warn("ePref:$map->{Prefix}\n");
    #Dump($map);
    $self->{data} .= "eP($map->{Prefix})";
}
