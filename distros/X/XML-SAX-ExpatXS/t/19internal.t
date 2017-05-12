use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE root [
  <!ENTITY internal "int_entity_value">
]>
<root>
&internal;
</root>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sD_sDtd_iDec(internal,int_entity_value)_eDtd_sE(root)_ch(Nint_entity_valueN)_eE_eD');

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

sub internal_entity_decl {
    my ($self, $ent) = @_;
    #warn("IntEntDecl:$ent->{Name}\n");
    #Dump($ent);
    $self->{data} .= "_iDec($ent->{Name},$ent->{Value})";
}

sub characters {
    my ($self, $ch) = @_;
    $ch->{Data} =~ s/\n/N/g;
    #warn("Char:$ch->{Data}\n");
    #Dump($ch);
    $self->{data} .= "_ch($ch->{Data})";
}
