use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );
$handler->{Parser} = $parser;

my $xml =<<_xml_;
<?xml version="1.0"?>
<foo>
  <boo att1="val1">
    koko mato
    roto pedo
  </boo>
  <hoo/>
</foo>
_xml_

$parser->set_feature('http://xmlns.perl.org/sax/join-character-data',1);
$parser->set_feature('http://xmlns.perl.org/sax/recstring',1);
$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq '|_sd||_se|<foo>|_ch| |_se|<boo att1="val1">|_ch| koko mato roto pedo |_ee|</boo>|_ch| |_se|<hoo/>|_ee||_ch||_ee|</foo>|_ed|');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_document {
    my ($self, $doc) = @_;
    my $str = ${$self->{Parser}->{ParseOptions}->{RecognizedString}};
    #warn("StartDoc:$str\n");
    $self->{data} .= '|_sd|' . $str;
}

sub end_document {
    my ($self, $doc) = @_;
    my $str = ${$self->{Parser}->{ParseOptions}->{RecognizedString}};
    #warn("EndDoc:$str\n");
    $self->{data} .= '|_ed|' . $str;
    $self->{data} =~ s/\n//g;
    $self->{data} =~ s/(\s+)/ /g;
}

sub start_element {
    my ($self, $el) = @_;
    my $str = ${$self->{Parser}->{ParseOptions}->{RecognizedString}};
    #warn("StartEl:$str\n");
    $self->{data} .= '|_se|' . $str;
}

sub end_element {
    my ($self, $el) = @_;
    my $str = ${$self->{Parser}->{ParseOptions}->{RecognizedString}};
    #warn("EndEl:$str\n");
    $self->{data} .= '|_ee|' . $str;
}

sub characters {
    my ($self, $char) = @_;
    my $str = ${$self->{Parser}->{ParseOptions}->{RecognizedString}};
    #warn("Char:$str\n");
    $self->{data} .= '|_ch|' . $str;
}

