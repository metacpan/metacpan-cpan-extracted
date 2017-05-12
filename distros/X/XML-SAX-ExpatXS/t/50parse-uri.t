use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

$parser->parse_uri('t/file.xml');
$parser->parse_uri('t/file2.xml');

#warn $handler->{data};
ok($handler->{data} eq '_setDL|t/file.xml||+_sd|t/file.xml||+_se|t/file.xml||iso-8859-1+_ed|t/file.xml||iso-8859-1+_setDL|t/file2.xml||+_sd|t/file2.xml||+_se|t/file2.xml||ISO-8859-2+_ed|t/file2.xml||ISO-8859-2+');

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
