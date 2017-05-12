use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo>data1
  <boo>data2
       data3
    <hoo>data4</hoo>
  </boo>
  data5
</foo>
_xml_

$parser->parse_string($xml);

$parser->set_feature('http://xmlns.perl.org/sax/join-character-data', 0);
$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'ch(data1N  )ch(data2N       data3N    )ch(data4)ch(N  )ch(N  data5N)ch(data1)ch(N)ch(  )ch(data2)ch(N)ch(       data3)ch(N)ch(    )ch(data4)ch(N)ch(  )ch(N)ch(  data5)ch(N)');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_element {
    my ($self, $el) = @_;
    #warn("Start:$el->{Name}\n");
    #Dump($el);
    #$self->{data} .= "sE($el->{NamespaceURI}:$el->{LocalName})";
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:$el->{Name}\n");
    #Dump($el);
    #$self->{data} .= "eE($el->{NamespaceURI}:$el->{LocalName})";
}

sub characters {
    my ($self, $char) = @_;
    $char->{Data} =~ s/\n/N/g;
    #warn("char:$char->{Data}\n");
    #Dump($char);
    $self->{data} .= "ch($char->{Data})";
}
