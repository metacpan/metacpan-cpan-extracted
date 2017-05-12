use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<p1:foo xmlns:p1="ns1"
        xmlns:p2="ns2"
	a1="v1"		
        p2:a2="v2"/>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'p1:foo|foo|ns1|p1|a1|a1|||v1|p2:a2|a2|ns2|p2|v2|p1:foo|foo|ns1|p1|');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_element {
    my ($self, $el) = @_;
    #warn("Start:\n");
    #Dump($el);
    $self->{data} .= $el->{Name} . '|';
    $self->{data} .= $el->{LocalName} . '|';
    $self->{data} .= $el->{NamespaceURI} . '|';
    $self->{data} .= $el->{Prefix} . '|';

    $self->{data} .= $el->{Attributes}->{'{}a1'}->{Name} . '|';
    $self->{data} .= $el->{Attributes}->{'{}a1'}->{LocalName} . '|';
    $self->{data} .= $el->{Attributes}->{'{}a1'}->{NamespaceURI} . '|';
    $self->{data} .= $el->{Attributes}->{'{}a1'}->{Prefix} . '|';
    $self->{data} .= $el->{Attributes}->{'{}a1'}->{Value} . '|';

    $self->{data} .= $el->{Attributes}->{'{ns2}a2'}->{Name} . '|';
    $self->{data} .= $el->{Attributes}->{'{ns2}a2'}->{LocalName} . '|';
    $self->{data} .= $el->{Attributes}->{'{ns2}a2'}->{NamespaceURI} . '|';
    $self->{data} .= $el->{Attributes}->{'{ns2}a2'}->{Prefix} . '|';
    $self->{data} .= $el->{Attributes}->{'{ns2}a2'}->{Value} . '|';
}

sub end_element {
    my ($self, $el) = @_;
    #warn("End:\n");
    #Dump($el);
    $self->{data} .= $el->{Name} . '|';
    $self->{data} .= $el->{LocalName} . '|';
    $self->{data} .= $el->{NamespaceURI} . '|';
    $self->{data} .= $el->{Prefix} . '|';
}
