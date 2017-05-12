use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE root [
  <!NOTATION n1Name PUBLIC "nPubId1">
  <!NOTATION n2Name SYSTEM "nSysId2">
  <!NOTATION n3Name PUBLIC "nPubId3" "nSysId3">
]>
<root/>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sd_nd|n1Name|nPubId1|_nd|n2Name||nSysId2_nd|n3Name|nPubId3|nSysId3_se_ee_ed');

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
    $self->{data} .= '_nd|' . $not->{Name};
    $self->{data} .= '|' . $not->{PublicId};
    $self->{data} .= '|' . $not->{SystemId};
}

