package VMOMI::PrimitiveType;

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);

use constant P5NS => 'VMOMI';

sub new {
    my ($class, $val, $type) = @_;
    my $self = { val => $val, type => $type };
    return bless $self, $class;
}

sub serialize {
    my ($self, $tag) = @_;
    my ($node, $value, $xsd_type);
    
    $xsd_type = "xsd:" . $self->{'type'};
    $node = new XML::LibXML::Element($tag);
    $node->setAttribute('xsi:type', $xsd_type);
    
    $value = encode_utf8($self->{'val'});
    $node->appendText($value);
    
    return $node;
}

sub val {
    my $self = shift;
    $self->{'val'} = shift if @_;
    return $self->{'val'};
}

1;