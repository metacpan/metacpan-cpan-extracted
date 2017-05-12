package VMOMI::SimpleType;

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);

sub new {
    my ($class, $val) = @_;
    return bless { val => $val }, $class;
}

sub deserialize {
    my ($class, $reader) = @_;
    my ($self, $content);
        
    return undef if not defined $reader;
    $content = $reader->readInnerXml();
    $self    = { val => decode_utf8($content) };
    return bless $self, $class; 
}

sub serialize {
    my ($self, $tag, $emit_type) = @_;
    my ($node, $value);
    
    $node = new XML::LibXML::Element($tag);
    if ($emit_type) {
        $node->setAttribute('xsi:type', $emit_type);
    }
    
    $value = encode_utf8($self->{'val'});
    $node->appendText($value);
    
    return $node;
}

sub TO_JSON {
    my $self = shift;

    my $class = ref($self);
    $class =~ s/VMOMI:://;
    return {_class => $class, val => $self->{'val'}};
}

sub val {
    my $self = shift;
    $self->{'val'} = shift if @_;
    return $self->{'val'};
}


1;
