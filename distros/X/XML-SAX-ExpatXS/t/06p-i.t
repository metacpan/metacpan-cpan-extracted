use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<foo>
  <item>abc</item>
  <?PItarget PIdata and more data?>
</foo>
_xml_

$parser->parse_string($xml);

#warn $handler->{data};
ok($handler->{data} eq 'PItarget|PIdata and more data');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub processing_instruction {
    my ($self, $pi) = @_;
    #warn("PI:$pi->{Target}\n");
    #Dump($pi);
    $self->{data} .= $pi->{Target} . '|';
    $self->{data} .= $pi->{Data};
}
