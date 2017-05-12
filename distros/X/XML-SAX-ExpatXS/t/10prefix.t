use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<root xmlns="ns1">
<foo xmlns:p="ns2">hoo</foo>
</root>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sd_spm||ns1_se_spm|p|ns2_se_ee_epm|p_ee_epm|_ed');

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

sub start_prefix_mapping {
    my ($self, $map) = @_;
    #warn("StartPM:\n");
    #Dump($map);
    $self->{data} .= '_spm|' . $map->{Prefix};
    $self->{data} .= '|' . $map->{NamespaceURI};
}

sub end_prefix_mapping {
    my ($self, $map) = @_;
    #warn("EndPM:\n");
    #Dump($map);
    $self->{data} .= '_epm|' . $map->{Prefix};
}
