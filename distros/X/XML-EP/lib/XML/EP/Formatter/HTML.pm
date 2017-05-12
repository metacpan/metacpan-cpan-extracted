# -*- perl -*-

package XML::EP::Formatter::HTML;

$XML::EP::Formatter::HTML = '0.01';


sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));
}

sub Format {
    my $self = shift;  my $ep = shift;  my $xml = shift;
    my $response = $ep->Response();
    $response->ContentType("text/html") unless $response->ContentType();
    my $fh = $ep->Request()->FileHandle();
    XML::DOM::setTagCompression(sub {1});

    $xml->setXMLDecl(undef);

    print $fh $ep->Response->Headers();

    $xml->printToFileHandle($fh);
}
