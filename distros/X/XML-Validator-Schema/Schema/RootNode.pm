package XML::Validator::Schema::RootNode;
use strict;
use warnings;

use base 'XML::Validator::Schema::ElementNode';

use XML::Validator::Schema::Util qw(_err);
use Carp qw(croak);

=head1 NAME

XML::Validator::Schema::RootNode - the root node in a schema document

=head1 DESCRIPTION

This is an internal module used by XML::Validator::Schema to represent
the root node in an XML Schema document.  Holds references to the
libraries for the schema document and is responsible for hooking up
named types to their uses in the node tree at the end of parsing.

=cut

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);

    # start up with empty libraries
    $self->{type_library}      = XML::Validator::Schema::TypeLibrary->new;
    $self->{element_library}   = XML::Validator::Schema::ElementLibrary->new;
    $self->{attribute_library} = XML::Validator::Schema::AttributeLibrary->new;

    return $self;
}

# finish typing and references
sub compile {
    my $self = shift;
    my $element_library = $self->{element_library};

    # put global elements into the library (could move this to ::ElementNode)
    foreach my $d ($self->daughters) {
        if (ref($d) eq 'XML::Validator::Schema::ElementNode') {
            $element_library->add(name => $d->{name},
                                  obj  => $d);
        }
    }


    # complete all element refs first, forming a complete tree
    foreach my $element ($self->descendants) {
        $self->complete_ref($element);
    }

    # completa all element types, including their attributes
    foreach my $element ($self->descendants) {
        $self->complete_type($element);
    }

}

sub complete_ref {
    my ($self, $ref) = @_;

    # handle any unresolved attribute types
    if ($ref->{attr}) {
        $self->complete_attr_ref($_) 
          for (grep { $_->{unresolved_ref} } (@{$ref->{attr}}));
    }

    # all done unless unresolved
    return unless $ref->{unresolved_ref};

    my $name = $ref->{name};
    my ($element) = $self->{element_library}->find(name => $ref->{name});
    _err("Found unresolved reference to element '$name'")
      unless $element;



    # replace the current element
    $ref->replace_with($element->copy_at_and_under);

    return;
}

sub complete_type {
    my ($self, $element) = @_;
    my $library = $self->{type_library};

    # handle any unresolved attribute types
    if ($element->{attr}) {
        $self->complete_attr_type($_) 
          for (grep { $_->{unresolved_type} } (@{$element->{attr}}));
    }

    # all done unless unresolved
    return unless $element->{unresolved_type};

    # get type data
    my $type_name = $element->{type_name};
    my $type = $library->find(name => $type_name);

    # isn't there?
    _err("Element '<$element->{name}>' has unrecognized type '$type_name'.") 
      unless $type;


    if ($type->isa('XML::Validator::Schema::ComplexTypeNode')) {
        # can't have daughters for this to work
        _err("Element '<$element->{name}>' is using a named complexType and has sub-elements of its own.  That's not supported.")
          if $element->daughters;
    
        # replace the current element with one based on the complex node
        my $new_node = $type->copy_at_and_under;
        $new_node->name($element->{name});
        $new_node->{attr} = [ @{ $new_node->{attr} || [] }, 
                              @{ $element->{attr} || [] } ];
        $element->replace_with($new_node);


    } elsif ($type->isa('XML::Validator::Schema::SimpleType')) {
        $element->{type} = $type;

    } else {
        croak("Library returned '$type'!");
    }

    # fixed it
    delete $element->{unresolved_type};
}

sub complete_attr_type {
    my ($self, $attr) = @_;

    my $type = $self->{type_library}->find(name => $attr->{type_name});
    _err("Attribute '<$attr->{name}>' has unrecognized ".
         "type '$attr->{type_name}'.")
      unless $type;

    $attr->{type} = $type;
    delete $attr->{unresolved_type};
}

sub complete_attr_ref {
    my ($self, $ref) = @_;

    my $attr = $self->{attribute_library}->find(name => $ref->{name});
    _err("Attribute reference '$ref->{name}' not found.")
      unless $attr;
    
    # clone, keep use
    my $use = $ref->{required};
    %$ref = %$attr;
    $ref->{required} = $use;

    return;
}



1;
