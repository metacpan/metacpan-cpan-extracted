use Test;
BEGIN { plan tests => 2 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE html PUBLIC "pub" "virtual.dtd">
<foo>&int;</foo>
_xml_

$parser->parse_string($xml);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_edtd_se_ee');

$parser->set_feature('http://xml.org/sax/features/external-parameter-entities', 1);
$handler->{data} = '';
$parser->parse_string($xml);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_sent|[dtd]_eent_edtd_se_char|value_ee');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc:\n");
    $self->{data} .= '_sd';
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl:\n");
    $self->{data} .= '_se';
}

sub end_element {
    my ($self, $el) = @_;
    #warn("EndEl:\n");
    $self->{data} .= '_ee';
}

sub start_dtd {
    my ($self, $dtd) = @_;
    #warn("startDTD:\n");
    $self->{data} .= '_sdtd|' . $dtd->{Name};
    $self->{data} .= '|' . $dtd->{PublicId};
    $self->{data} .= '|' . $dtd->{SystemId};
}

sub end_dtd {
    my ($self, $dtd) = @_;
    #warn("endDTD:\n");
    $self->{data} .= '_edtd';
}

sub start_entity {
    my ($self, $ent) = @_;
    #warn("startEnt:$ent->{Name}\n");
    $self->{data} .= '_sent|' . $ent->{Name};
}

sub end_entity {
    my ($self, $ent) = @_;
    #warn("endEnt:\n");
    $self->{data} .= '_eent';
}

sub resolve_entity {
    my ($self, $ent) = @_;
    #warn("resolveEnt:\n");
    return {String => '<!ENTITY int "value">'};
}

sub characters {
    my ($self, $char) = @_;
    #warn("Char:$char->{Data}\n");
    $self->{data} .= '_char|' . $char->{Data};
}
