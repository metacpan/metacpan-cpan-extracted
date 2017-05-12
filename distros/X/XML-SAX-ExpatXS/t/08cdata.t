use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo>
<![CDATA[<abc&d>]]>
</foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'start|<abc&d>|end');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub start_cdata {
    my ($self, $cd) = @_;
    #warn("StartCD:\n");
    #Dump($cd);
    $self->{data} .= 'start|';
}

sub end_cdata {
    my ($self, $cd) = @_;
    #warn("EndCD:\n");
    #Dump($cd);
    $self->{data} .= '|end';
}

sub characters {
    my ($self, $char) = @_;
    #warn("Char:$char->{Data}\n");
    #Dump($char);
    $self->{data} .= $char->{Data} unless $char->{Data} =~ /^\s*$/;
}
