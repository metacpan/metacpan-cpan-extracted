use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo/>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'start|end');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_document {
    my ($self, $doc) = @_;
    #warn("Start:\n");
    #Dump($doc);
    $self->{data} .= 'start';
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("End:\n");
    #Dump($doc);
    $self->{data} .= '|end';
}
