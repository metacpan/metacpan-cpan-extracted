#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::AsString is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: AsString.pm,v 1.6 1999/08/25 17:08:09 kmacleod Exp $
#

use strict;

package XML::Grove::AsString;
use Data::Grove::Visitor;

sub new {
    my $class = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    return bless $self, $class;
}

sub as_string {
    my $self = shift; my $object = shift; my $fh = shift;

    if (defined $fh) {
	return ();
    } else {
	return join('', $object->accept($self, $fh));
    }
}

sub visit_document {
    my $self = shift; my $document = shift;

    return $document->children_accept($self, @_);
}

sub visit_element {
    my $self = shift; my $element = shift;

    return $element->children_accept($self, @_);
}

sub visit_entity {
    my $self = shift; my $entity = shift; my $fh = shift;

    my $mapper = $self->{EntityMap};
    return '' if (!defined $mapper);

    my $mapping;
    if (ref($mapper) eq 'CODE') {
	$mapping = &$mapper($entity->{Data},
			    $self->{EntityMapOptions});
    } else {
	$mapping = $mapper->lookup($entity->{Data},
				   $self->{EntityMapOptions});
    }

    if ($self->{EntityMapFilter}) {
	my $filter = $self->{Filter};
	if (defined $filter) {
	    $mapping = &$filter($mapping);
	}
    }

    return $self->_print($fh, $mapping);
}

sub visit_pi {
    return ();
}

sub visit_comment {
    return ();
}

sub visit_characters {
    my $self = shift; my $characters = shift; my $fh = shift;

    my $data = $characters->{Data};
    if (defined ($self->{Filter})) {
	$data = &{$self->{Filter}}($data);
    }

    return $self->_print($fh, $data);
}

sub _print {
    my $self = shift; my $fh = shift; my $string = shift;

    if (defined $fh) {
	$fh->print($string);
	return ();
    } else {
	return ($string);
    }
}

package XML::Grove;

sub as_string {
    my $xml_object = shift;

    return XML::Grove::AsString->new(@_)->as_string($xml_object);
}

package XML::Grove::Element;

sub attr_as_string {
    my $element = shift; my $attr = shift;

    my $writer = new XML::Grove::AsString (@_);
    return $element->attr_accept ($attr, $writer);
}

1;

__END__

=head1 NAME

XML::Grove::AsString - output content of XML objects as a string

=head1 SYNOPSIS

 use XML::Grove::AsString;

 # Using as_string method on XML::Grove::Document or XML::Grove::Element:
 $string = $xml_object->as_string OPTIONS;
 $string = $element->attr_as_string $attr, OPTIONS;

 # Using an XML::Grove::AsString instance:
 $writer = new XML::Grove::AsString OPTIONS;

 $string = $writer->as_string($xml_object);
 $writer->as_string($xml_object, $file_handle);

=head1 DESCRIPTION

Calling `C<as_string>' on an XML object returns the character data
contents of that object as a string, including all elements below that
object.  Calling `C<attr_as_string>' on an element returns the
contents of the named attribute as a string.  Comments, processing
instructions, and, by default, entities all return an empty string.

I<OPTIONS> may either be a key-value list or a hash containing the
options described below.  I<OPTIONS> may be modified directly in the
object.  The default options are no filtering and entities are mapped
to empty strings.

=head1 OPTIONS

=over 4

=item Filter

`C<Filter>' is an anonymous sub that gets called to process character
data before it is appended to the string to be returned.  This can be
used, for example, to escape characters that are special in output
formats.  The `C<Filter>' sub is called like this:

    $string = &$filter ($character_data);

=item EntityMap

`C<EntityMap>' is an object that accepts `C<lookup>' methods or an
anonymous sub that gets called with the entity replacement text (data)
and mapper options as arguments and returns the corresponding
character replacements.  It is called like this if it is an object:

    $replacement_text = $entity_map->lookup ($entity_data,
					     $entity_map_options);

or this if it is a sub:

    $replacement_text = &$entity_map ($entity_data,
				      $entity_map_options);

=item EntityMapOptions

`C<EntityMapOptions>' is a hash passed through to the `C<lookup>'
method or anonymous sub, the type of value is defined by the entity
mapping package or the anonymous sub.

=item EntityMapFilter

`C<EntityMapFilter>' is a flag to indicate if mapped entities should
be filtered after mapping.

=back

=head1 EXAMPLES

Here is an example of entity mapping using the Text::EntityMap module:

    use Text::EntityMap;
    use XML::Grove::AsString;

    $html_iso_dia = Text::EntityMap->load ('ISOdia.2html');
    $html_iso_pub = Text::EntityMap->load ('ISOpub.2html');
    $html_map = Text::EntityMap->group ($html_iso_dia,
					$html_iso_pub);

    $element->as_string (EntityMap => $html_map);

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
