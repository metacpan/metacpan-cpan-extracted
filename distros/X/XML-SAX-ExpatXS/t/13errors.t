use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

my $xml =<<_xml_;
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<!DOCTYPE html PUBLIC "pub" "sys">
<foo>
  <wrong&>
</foo>
_xml_

eval { $parser->parse_string($xml) };

#warn $handler->{data};
ok($handler->{data} eq '_ferr|not well-formed (invalid token) at line 4, column 9, byte 105|not well-formed (invalid token)|4|9||');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }


sub warning {
    my ($self, $ex) = @_;
    #warn("Warn\n");
    #Dump($ex);
    $self->{data} .= '_warn|' . $ex->{Message};
    $self->{data} .= '|' . $ex->{Exception};
    $self->{data} .= '|' . $ex->{LineNumber};
    $self->{data} .= '|' . $ex->{ColumnNumber};
}

sub error {
    my ($self, $ex) = @_;
    #warn("Error\n");
    #Dump($ex);
    $self->{data} .= '_err|' . $ex->{Message};
    $self->{data} .= '|' . $ex->{Exception};
    $self->{data} .= '|' . $ex->{LineNumber};
    $self->{data} .= '|' . $ex->{ColumnNumber};
}

sub fatal_error {
    my ($self, $ex) = @_;
    #warn("fatError\n");
    #Dump($ex);
    $self->{data} .= '_ferr|' . $ex->{Message};
    $self->{data} .= '|' . $ex->{Exception};
    $self->{data} .= '|' . $ex->{LineNumber};
    $self->{data} .= '|' . $ex->{ColumnNumber};
    $self->{data} .= '|' . $ex->{PublicId};
    $self->{data} .= '|' . $ex->{SystemId};
}
