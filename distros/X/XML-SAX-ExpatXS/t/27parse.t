use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler,
                                     Source => {
                                        SystemId => 't/file.xml',
				        PublicId => 'XML::SAX::ExpatXS/test1',
                                        Encoding => 'ISO-8859-1',
                                        }
                                    );

$parser->parse();

#warn $handler->{data};
ok($handler->{data} eq '_setDL|t/file.xml|XML::SAX::ExpatXS/test1|ISO-8859-1+_sd|t/file.xml|XML::SAX::ExpatXS/test1|ISO-8859-1+_se|t/file.xml|XML::SAX::ExpatXS/test1|ISO-8859-1+_ed|t/file.xml|XML::SAX::ExpatXS/test1|ISO-8859-1+');

package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }

sub set_document_locator {
    my ($self, $loc) = @_;
    $self->{Locator} = $loc;
    #warn("setDocLoc\n");
    $self->{data} .= '_setDL|' . $self->{Locator}->{SystemId};
    $self->{data} .= '|' . $self->{Locator}->{PublicId};
    $self->{data} .= '|' . $self->{Locator}->{Encoding} . '+';
    $self->{done} = 0;
}

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartDoc\n");
    $self->{data} .= '_sd|' . $self->{Locator}->{SystemId};
    $self->{data} .= '|' . $self->{Locator}->{PublicId};
    $self->{data} .= '|' . $self->{Locator}->{Encoding} . '+';
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("EndDoc\n");
    $self->{data} .= '_ed|' . $self->{Locator}->{SystemId};
    $self->{data} .= '|' . $self->{Locator}->{PublicId};
    $self->{data} .= '|' . $self->{Locator}->{Encoding} . '+';
}

sub start_element {
    my ($self, $el) = @_;
    #warn("StartEl\n");
    unless ($self->{done}) {
      $self->{data} .= '_se|' . $self->{Locator}->{SystemId};
      $self->{data} .= '|' . $self->{Locator}->{PublicId};
      $self->{data} .= '|' . $self->{Locator}->{Encoding} . '+';
      $self->{done} = 1;
    }
}
