use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $source = {
   PublicId => undef,
   SystemId => 't/file.xml',
   Encoding  => 'iso-8859-2',
   };
my $parser = XML::SAX::ExpatXS->new( Handler => $handler, Source => $source );

$parser->parse();

#warn "$handler->{enc}\n";
ok($handler->{enc} eq 'iso-8859-2|iso-8859-2|iso-8859-1|iso-8859-2|iso-8859-2');

package TestH;
#use Devel::Peek;

sub new { bless {start => 0, end => 0}, shift }


sub set_document_locator {
    my ($self, $loc) = @_;
    $self->{loc} = $loc;
    #warn("LocEncoding:$self->{loc}{Encoding}\n");
    $self->{enc} .= $self->{loc}{Encoding} . '|';
}

sub start_document {
    my ($self, $doc) = @_;
    #warn("StartEncoding:$self->{loc}{Encoding}\n");
    $self->{enc} .= $self->{loc}{Encoding} . '|';
}

sub end_document {
    my ($self, $doc) = @_;
    #warn("EndEncoding:$self->{loc}{Encoding}\n");
    $self->{enc} .= $self->{loc}{Encoding};
}

sub xml_decl {
    my ($self, $decl) = @_;
    #warn("DeclEncoding:$decl->{Encoding}\n");
    #warn("DecLocEncoding:$self->{loc}{Encoding}\n");
    $self->{enc} .= $decl->{Encoding} . '|';
    $self->{enc} .= $self->{loc}{Encoding} . '|';
}
