use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<foo>hoo</foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sd_sdtd|html|-//W3C//DTD XHTML 1.0 Strict//EN|http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd_edtd_se');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc:\n");
    #Dump($el);
    $self->{data} .= '_sd';
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl:\n");
    #Dump($el);
    $self->{data} .= '_se';
}

sub start_dtd {
    my ($self, $dtd) = @_;
    #warn("startDTD:\n");
    #Dump($dtd);
    $self->{data} .= '_sdtd|' . $dtd->{Name};
    $self->{data} .= '|' . $dtd->{PublicId};
    $self->{data} .= '|' . $dtd->{SystemId};
}

sub end_dtd {
    my ($self, $dtd) = @_;
    #warn("endDTD:\n");
    #Dump($dtd);
    $self->{data} .= '_edtd';
}
