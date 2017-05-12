#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::Sub is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: Sub.pm,v 1.3 1999/09/02 20:56:58 kmacleod Exp $
#

use strict;

package XML::Grove::Sub;

use Data::Grove::Visitor;

sub new {
    my $type = shift;
    return (bless {}, $type);
}

sub visit_document {
    my $self = shift; my $document = shift; my $sub = shift;
    return (&$sub($document, @_),
	    $document->children_accept ($self, $sub, @_));
}

sub visit_element {
    my $self = shift; my $element = shift; my $sub = shift;
    return (&$sub($element, @_),
	    $element->children_accept ($self, $sub, @_));
}

sub visit_entity {
    my $self = shift; my $entity = shift; my $sub = shift;
    return (&$sub($entity, @_));
}

sub visit_pi {
    my $self = shift; my $pi = shift; my $sub = shift;
    return (&$sub($pi, @_));
}

sub visit_comment {
    my $self = shift; my $comment = shift; my $sub = shift;
    return (&$sub($comment, @_));
}

sub visit_characters {
    my $self = shift; my $characters = shift; my $sub = shift;
    return (&$sub($characters, @_));
}

###
### Extend the XML::Grove::Document and XML::Grove::Element packages with our
### new function.
###

package XML::Grove::Document;

sub filter {
    my $self = shift; my $sub = shift;

    return ($self->accept(XML::Grove::Sub->new, $sub, @_));
}

package XML::Grove::Element;

sub filter {
    my $self = shift; my $sub = shift;

    return ($self->accept(XML::Grove::Sub->new, $sub, @_));
}

1;

__END__

=head1 NAME

XML::Grove::Sub - run a filter sub over a grove

=head1 SYNOPSIS

 use XML::Grove::Sub;

 # Using filter method on XML::Grove::Document or XML::Grove::Element:
 @results = $grove_object->filter(\&sub [, ...]);

 # Using an XML::Grove::Sub instance:
 $filterer = XML::Grove::Sub->new();
 @results = $grove_object->accept($filterer, \&sub [, ...]);

=head1 DESCRIPTION

C<XML::Grove::Sub> executes a sub, the filter, over all objects in a
grove and returns a list of all the return values from the sub.  The
sub is called with the grove object as it's first parameter and
passing the rest of the arguments to the call to `C<filter()>' or
`C<accept()>'.

=head1 EXAMPLE

The following filter will return a list of all `C<foo>' or `C<bar>'
elements with an attribute `C<widget-no>' beginning with `C<A>' or
`C<B>'.

  @results = $grove_obj->filter(sub {
      my $obj = shift;

      if ($obj->isa('XML::Grove::Element')
	  && (($obj->{Name} eq 'foo')
	      || ($obj->{Name} eq 'bar'))
	  && ($obj->{Attributes}{'widget-no'} =~ /^[AB]/)) {
	  return ($obj);
      }
      return ();
  });

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3), Data::Grove::Visitor(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
