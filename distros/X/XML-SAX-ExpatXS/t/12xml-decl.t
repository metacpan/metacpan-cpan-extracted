use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<foo/>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '_sd_xmld|1.0|utf-8|yes_se');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub xml_decl {
    my ($self, $decl) = @_;
    #warn("xmlDecl\n");
    #Dump($decl);
    $self->{data} .= '_xmld|' . $decl->{Version};
    $self->{data} .= '|' . $decl->{Encoding};
    $self->{data} .= '|' . $decl->{Standalone};
}

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
