use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE html [
  <!ELEMENT foo (boo|hoo)* >
  <!ELEMENT boo (#PCDATA)* >
  <!ELEMENT hoo EMPTY>
]>
<foo><boo>text</boo><hoo/></foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sdtd|html_ed|foo:(boo|hoo)*_ed|boo:(#PCDATA)*_ed|hoo:EMPTY_edtd');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_dtd {
    my ($self, $dtd) = @_;
    #warn("startDTD:\n");
    #Dump($dtd);
    $self->{data} .= '_sdtd|' . $dtd->{Name};
}

sub end_dtd {
    my ($self, $dtd) = @_;
    #warn("endDTD:\n");
    #Dump($dtd);
    $self->{data} .= '_edtd';
}

sub element_decl {
    my ($self, $ed) = @_;
    #warn("elDecl:$ed->{Name},$ed->{Model}\n");
    #Dump($ed);
    $self->{data} .= "_ed|$ed->{Name}:$ed->{Model}";
}
