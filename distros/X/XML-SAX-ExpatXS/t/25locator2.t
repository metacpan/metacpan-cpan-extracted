use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="iso-8859-2"?>
<foo>
  <boo att1="val1"
       att2="val2">
    koko mato
    roto pedo
  </boo>
  <hoo/>
</foo>
_xml_

$parser->parse_string($xml);

$parser->set_feature('http://xmlns.perl.org/sax/join-character-data',0);
$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_setDL|1|1|_sd|1|1|_se|2|5|_ch|3|2|_se|4|19|_ch|7|2|_ee|7|8|_ch|8|2|_se|8|8|_ee|8|8|_ch|8|9|_ee|9|6|_ed|9|7|iso-8859-2|1.0||_setDL|1|1|_sd|1|1|_se|2|5|_ch|2|6|_ch|3|2|_se|4|19|_ch|4|20|_ch|5|13|_ch|5|14|_ch|6|13|_ch|6|14|_ch|7|2|_ee|7|8|_ch|7|9|_ch|8|2|_se|8|8|_ee|8|8|_ch|8|9|_ee|9|6|_ed|9|7|iso-8859-2|1.0||');

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

sub start_prefix_mapping {
    my ($self, $map) = @_;
    #warn("StartPM:\n");
    $self->{data} .= '|_sm|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

sub end_prefix_mapping {
    my ($self, $map) = @_;
    #warn("EndPM:\n");
    $self->{data} .= '|_em|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}

sub processing_instruction {
    my ($self, $pi) = @_;
    #warn("PI:\n");
    $self->{data} .= '|_pi|' . $self->{Locator}->{LineNumber};
    $self->{data} .= '|' . $self->{Locator}->{ColumnNumber};
}
