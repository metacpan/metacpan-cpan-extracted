use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE html [
  <!ELEMENT foo (boo|hoo)* >
  <!ATTLIST foo
            id      ID      #REQUIRED
            type    (small|medium|big)  "medium">
  <!ELEMENT boo (#PCDATA)* >
  <!ATTLIST boo
            method  CDATA   #FIXED "POST">
]>
<foo id="e1" type="small"><boo method="POST">text</boo></foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sdtd|html_ad|foo:id:ID:#REQUIRED_ad|foo:type:(small|medium|big):medium_ad|boo:method:CDATA:#FIXED:POST_edtd');

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

sub attribute_decl {
    my ($self, $ad) = @_;
    #warn("atDecl:$ad->{eName},$ad->{aName},$ad->{Type},$ad->{Mode},$ad->{Value}\n");
    #Dump($ad);
    $self->{data} .= "_ad|$ad->{eName}:$ad->{aName}";
    $self->{data} .= ":$ad->{Type}" if defined $ad->{Type};
    $self->{data} .= ":$ad->{Mode}" if defined $ad->{Mode};
    $self->{data} .= ":$ad->{Value}" if defined $ad->{Value};
}
