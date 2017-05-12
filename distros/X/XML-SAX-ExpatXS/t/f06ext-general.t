use Test;
BEGIN { plan tests => 2 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE root [
  <!ENTITY external PUBLIC "extPubID" "t/external.xml">
]>
<root>
&external;
</root>
_xml_

$parser->parse_string($xml);

$parser->set_feature('http://xml.org/sax/features/external-general-entities', 0);

ok($handler->{data}, '_sD_sDtd_eDec(external,extPubID,t/external.xml)_eDtd_sE(root)_sEnt(external)_sE(boo)_eE_eEnt(external)_eE_eD');
$handler->{data} = '';

$parser->parse_string($xml);

ok($handler->{data}, '_sD_sDtd_eDec(external,extPubID,t/external.xml)_eDtd_sE(root)_eE_eD');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc:\n");
    #Dump($el);
    $self->{data} .= '_sD';
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("EndDoc:\n");
    #Dump($el);
    $self->{data} .= '_eD';
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl:\n");
    #Dump($el);
    $self->{data} .= "_sE($el->{Name})";
}

sub end_element {
    my ($self, $el) = @_;
    #warn("EndEl:\n");
    #Dump($el);
    $self->{data} .= '_eE';
}

sub start_dtd {
    my ($self, $dtd) = @_;
    #warn("StartDTD:\n");
    #Dump($el);
    $self->{data} .= '_sDtd';
}

sub end_dtd {
    my ($self, $dtd) = @_;
    #warn("EndDTD:\n");
    #Dump($dtd);
    $self->{data} .= '_eDtd';
}

sub external_entity_decl {
    my ($self, $ent) = @_;
    #warn("ExtEntDecl:$ent->{Name}\n");
    #Dump($ent);
    $self->{data} .= "_eDec($ent->{Name},$ent->{PublicId},$ent->{SystemId})";
}

sub start_entity {
    my ($self, $ent) = @_;
    #warn("StartEnt:$ent->{Name}\n");
    #Dump($ent);
    $self->{data} .= "_sEnt($ent->{Name})";
}

sub end_entity {
    my ($self, $ent) = @_;
    #warn("EndEnt:$ent->{Name}\n");
    #Dump($ent);
    $self->{data} .= "_eEnt($ent->{Name})";
}
