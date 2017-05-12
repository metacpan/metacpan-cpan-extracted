use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0"?>
<foo>
  <boo>koko</boo>
</foo>
_xml_

$parser->parse_string($xml);

$parser->set_feature('http://xmlns.perl.org/sax/locator',0);
$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_setDL|1|1|_sd|1|1|_se|2|5|_ch|3|2|_se|3|7|_ch|3|11|_ee|3|17|_ch|3|18|_ee|4|6|_ed|4|7|utf-8|1.0||_setDL|1|1|_sd|1|1|_se|1|22|_ch|1|22|_se|1|22|_ch|1|22|_ee|1|22|_ch|1|22|_ee|1|22|_ed|4|7|utf-8|1.0||');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub set_document_locator {
    my ($self, $loc) = @_;
    #warn("setDocLoc\n");
    #Dump($loc);
    $self->{Locator} = $loc;
    $self->{data} .= '_setDL|' . $loc->{LineNumber};
    $self->{data} .= '|' . $loc->{ColumnNumber};
}

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc:\n");
    $self->{data} .= '|_sd|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("EndDoc:\n");
    #Dump($self->{Locator});
    $self->{data} .= '|_ed|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
    $self->{data} .= '|' . $self->{Locator}->{Encoding};
    $self->{data} .= '|' . $self->{Locator}->{XMLVersion};
    $self->{data} .= '|' . $self->{Locator}->{PublicId};
    $self->{data} .= '|' . $self->{Locator}->{SystemId};
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl:\n");
    $self->{data} .= '|_se|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

sub end_element {
    my ($self, $el) = @_;
    #warn("EndEl:\n");
    $self->{data} .= '|_ee|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

sub characters {
    my ($self, $char) = @_;
    #warn("char:\n");
    $self->{data} .= '|_ch|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

