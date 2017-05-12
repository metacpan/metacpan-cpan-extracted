# -*- tab-width: 4 -*-
# ex: set tabstop=4:

=head1 NAME

XML::TinyXML::Node - Tinyxml Node object

=head1 SYNOPSIS

=over 4

  use XML::TinyXML::Node;

  $node = XML::TinyXML::Node->new("child", "somevalue", { attribute => "value" });

  $attr = $node->getAttribute("attribute");
  or
  $attr = $node->getAttribute(1); # attribute at index 1
  or
  @attrs = $node->getAttributes(); # returns all attributes in the node
  
=back

=head1 DESCRIPTION

Node representation for the TinyXML API

=head1 INSTANCE VARIABLES

=over 4

=item * _attr

Reference to the underlying XmlNodeAttributePtr object (which is a binding to the XmlNode C structure)

=back

=head1 METHODS

=over 4

=cut

package XML::TinyXML::NodeAttribute;
 
use strict;
use warnings;

our $VERSION = "0.34";

=item new ($attr)

Wrap the XmlNodeAttributePtr C structure exposing accessor to its members

=cut
sub new {
    my ($class, $attr) = @_;
    return undef unless(UNIVERSAL::isa($attr, "XmlNodeAttributePtr"));
    my $self = bless({ _attr => $attr }, $class);
    return $self;
}

=item name ([$newName])

Get/Set the name of the attribute

=cut
sub name {
    my ($self, $newName) = @_;
    return defined($newName)
           ? $self->{_attr}->name($newName)
           : $self->{_attr}->name;
}

=item value ([$newValue])

Get/Set the value of the attribute

=cut
sub value {
    my ($self, $newValue) = @_;
    return defined($newValue)
           ? $self->{_attr}->value($newValue)
           : $self->{_attr}->value;
}

=item node (])

Get the XML::TinyXML::Node to which this attribute belongs

=cut
sub node {
    my $self = shift;
    return XML::TinyXML::Node->new($self->{_attr}->node);
}

=item path ()

Returns the unique path identifying this attribute

(can be used in xpath expressions)

=cut
sub path {
    my $self = shift;
    return sprintf("%s/\@%s", $self->{_attr}->node->path, $self->name);
}

=item type ()

Returns the type of this node

(at the moment it will return always the string : "ATTRIBUTE" 
 which can be used to distinguish attribute-nodes from xml-nodes
 in @sets returned by xpath selections)

=cut
sub type {
    return "ATTRIBUTE";
}

1;

=back

=head1 SEE ALSO

=over 4

XML::TinyXML::Node XML::TinyXML

=back

=head1 AUTHOR

xant, E<lt>xant@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by xant

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
