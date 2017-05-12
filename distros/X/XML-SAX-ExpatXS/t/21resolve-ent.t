use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE root [
  <!ENTITY external SYSTEM "TEST:external">
]>
<root>
&external;
</root>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sD_sDtd_eDec(external,,TEST:external)_eDtd_sE(root)_sEnt(external)_rE(t/external.xml)_sE(boo)_eE_eEnt(external)_eE_eD');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub resolve_entity {
    my ($self, $ent) = @_;
    #warn("resEnt:$ent->{SystemId}\n");
    if ($ent->{SystemId} =~ s/^TEST:/t\//) {$ent->{SystemId} .= '.xml';}
    $self->{data} .= "_rE($ent->{SystemId})";

    return {SystemId => $ent->{SystemId}};
}

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
    #warn("StartEl:$el->{Name}\n");
    #Dump($el);
    $self->{data} .= "_sE($el->{Name})";
}

sub end_element {
    my ($self, $el) = @_;
    #warn("EndEl:$el->{Name}\n");
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
