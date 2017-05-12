use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new(
    Handler => $handler,
);

$parser->parse_string("<?xml version='1.0'?><!-- comment --><foo/>");

#warn join(":", @{$handler->{events}});

ok(join(":", @{$handler->{events}}) eq '1:1:1:0:1');

package TestH;
#use Devel::Peek;

sub new { bless {events => [0,0,0,0,0]}, shift }

sub characters {
    my ($self, $chars) = @_;
    $self->{events}->[3]++;
    #warn("Chars:\n");
    #Dump($chars);
}

sub start_element {
    my ($self, $el) = @_;
    $self->{events}->[1]++;
    #warn("Start:\n");
    #Dump($el);
}

sub end_element {
    my ($self, $el) = @_;
    $self->{events}->[2]++;
    #warn("End:\n");
    #Dump($el);
}

sub xml_decl {
    my ($self, $el) = @_;
    $self->{events}->[4]++;
    #warn("XMLdecl:\n");
    #Dump($el);
}

sub comment {
    my ($self, $el) = @_;
    $self->{events}->[0]++;
    #warn("Comment:\n");
    #Dump($el);
}
