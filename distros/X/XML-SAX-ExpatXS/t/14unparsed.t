use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE root [
  <!NOTATION nName PUBLIC "nPubId" "nSysId">
  <!ENTITY ueName1  PUBLIC "uePubId" "ueSysId" NDATA nName >
  <!ENTITY ueName2  SYSTEM "ueSysId" NDATA nName>
]>
<root/>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data}, '_sd_nd_ue|ueName1|uePubId|ueSysId|nName_ue|ueName2||ueSysId|nName_se_ee_ed');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc:\n");
    #Dump($el);
    $self->{data} .= '_sd';
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("EndDoc:\n");
    #Dump($el);
    $self->{data} .= '_ed';
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl:\n");
    #Dump($el);
    $self->{data} .= '_se';
}

sub end_element {
    my ($self, $el) = @_;
    #warn("EndEl:\n");
    #Dump($el);
    $self->{data} .= '_ee';
}

sub notation_decl {
    my ($self, $not) = @_;
    #warn("NotDecl:\n");
    #Dump($not);
    $self->{data} .= '_nd';
}

sub unparsed_entity_decl {
    my ($self, $ue) = @_;
    #warn("uEntDecl:\n");
    #Dump($ue);
    $self->{data} .= '_ue|' . $ue->{Name};
    $self->{data} .= '|' . $ue->{PublicId};
    $self->{data} .= '|' . $ue->{SystemId};
    $self->{data} .= '|' . $ue->{Notation};
}
