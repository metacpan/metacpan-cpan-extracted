# Provided by Axel Eckenberger, Nov 3, 2005

use Test;
BEGIN { plan tests => 4 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler);

my $xml =<<_xml_;
<!DOCTYPE html PUBLIC "pub" "virtual.dtd" [
	<!ENTITY ext PUBLIC "ext" "external.xml">
]>
<foo>&int;&ext;</foo>
_xml_

###################### Test 1 ######################
# Tests the default settings
# Note: _skip|int occurs as dtd is not parsed
$handler->{data} = '';
$parser->set_feature('http://xml.org/sax/features/external-parameter-entities', 0); # = default
$parser->set_feature('http://xml.org/sax/features/external-general-entities'  , 1); # = default
$parser->parse_string($xml);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_skip|[dtd]_edtd_se_skip|int_sent|ext_eent_char|external_ee');

###################### Test 2 ######################
# Tests turning the parsing of the parameter enties
# on.
$handler->{data} = '';
$parser->set_feature('http://xml.org/sax/features/external-parameter-entities', 1);
$parser->set_feature('http://xml.org/sax/features/external-general-entities'  , 1);
$parser->parse_string($xml);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_sent|[dtd]_eent_edtd_se_char|value_sent|ext_eent_char|external_ee');

###################### Test 3 ######################
# Tests turning the parsing of external general 
# entities off.
$handler->{data} = '';
$parser->set_feature('http://xml.org/sax/features/external-parameter-entities', 1);
$parser->set_feature('http://xml.org/sax/features/external-general-entities'  , 0);
$parser->parse_string($xml);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_sent|[dtd]_eent_edtd_se_char|value_skip|ext_ee');

###################### Test 3 ######################
# Tests skipping all entities except parameter 
# entities, i.e. skips both internal and external
# general entities event when they are declared 
# or not.
$handler->{data} = '';
$parser->set_feature('http://xml.org/sax/features/external-parameter-entities', 1);
$parser->set_feature('http://xml.org/sax/features/external-general-entities'  , 0);
$parser->parse_string($xml, NoExpand => 1);

ok($handler->{data}, '_sd_sdtd|html|pub|virtual.dtd_sent|[dtd]_eent_edtd_se_skip|int_skip|ext_ee');
print '_sd_sdtd|html|pub|virtual.dtd_sent|[dtd]_eent_edtd_se_skip|int_skip|ext_ee', "\n";
print $handler->{data}, "\n";

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
    
    return {String => '<!ENTITY int "value">'} if ($ent->{PublicId} eq "pub");
    return {String => 'external'} if ($ent->{PublicId} eq "ext");
    
    return undef;
}

sub characters {
    my ($self, $char) = @_;
    #warn("Char:$char->{Data}\n");
    $self->{data} .= '_char|' . $char->{Data};
}

sub skipped_entity {
	my ($self, $ent) = @_;
	#warn("skippedEnt:$ent->{Name}\n");
	$self->{data} .= '_skip|' . $ent->{Name};
}
