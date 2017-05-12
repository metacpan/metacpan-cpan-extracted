package VMOMI::ManagedObjectReference;
use base 'VMOMI::ComplexType';

use strict;
use warnings;

our @class_members = (
    ['type',  undef, 0, 1],
    ['value', undef, 0, 1],
);

sub serialize {
    my ($self, $tag, $emit_type) = @_;
    my ($type, $value, $node);
    
    $type   = $self->{'type'};
    $value  = $self->{'value'};
    
    $node = new XML::LibXML::Element($tag);
    if ($emit_type) {
        $node->setAttribute('xsi:type', 'ManagedObjectReference');
    }
    $node->setAttribute('type', $type);
    $node->appendText($value);
    
    return $node;
}

sub deserialize {
    my ($class, $reader) = @_;
    
    return undef if not defined $reader;
    
    my $self = {
        type    => $reader->getAttribute('type'),
        value   => $reader->readInnerXml,
    };
    
    return bless $self, $class;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
