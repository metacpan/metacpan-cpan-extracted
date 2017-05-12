#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::IDs is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: IDs.pm,v 1.2 1999/08/17 15:01:28 kmacleod Exp $
#

use strict;

package XML::Grove::IDs;

use Data::Grove::Visitor;

sub new {
    my ($type, $name, $elements) = @_;
    $name = 'id' if(!defined $name);
    return (bless {Name => $name, Elements => $elements}, $type);
}

sub visit_document {
    my $self = shift; my $grove = shift; my $hash = shift;
    $grove->children_accept ($self, $hash);
}

sub visit_element {
    my $self = shift; my $element = shift; my $hash = shift;

    if(!$self->{Elements} or $self->{Elements}{$element->{Name}}) {
           my $id = $element->{Attributes}{$self->{Name}};
           $hash->{$id} = $element
               if (defined $id);
    }

    $element->children_accept ($self, $hash);
}

###
### Extend the XML::Grove::Document and XML::Grove::Element packages with our
### new function.
###

package XML::Grove::Document;

sub get_ids {
    my $self = shift;

    my $hash = {};
    $self->accept(XML::Grove::IDs->new(@_), $hash);
    return $hash;
}

package XML::Grove::Element;

sub get_ids {
    my $self = shift;

    my $hash = {};
    $self->accept(XML::Grove::IDs->new(@_), $hash);
    return $hash;
}

1;

__END__

=head1 NAME

XML::Grove::IDs - return an index of `id' attributes in a grove

=head1 SYNOPSIS

 use XML::Grove::IDs;

 # Using get_ids method on XML::Grove::Document or XML::Grove::Element:
 $hash = $grove_object->get_ids($attr_name, $elements);

 # Using an XML::Grove::IDs instance:
 $indexer = XML::Grove::IDs->new($attr_name, $elements);
 my $hash = {};
 $grove_object->accept($indexer, $hash);

=head1 DESCRIPTION

C<XML::Grove::IDs> returns a hash index of all nodes in a grove with
an `id' attribute.  The keys of the hash are the ID attribute value
and the value at that key is the element.  `C<$attr_name>' and
`C<$elements>' are optional.  The attribute name defaults to `C<id>'
if `C<$attr_name>' is not supplied.  Indexing can be restricted to
only certain elements, by name, by providing a hash containing NAME=>1
values.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3), Data::Grove::Visitor(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
