package XML::LibXML::Overlay;

use strict;
use warnings;

our $VERSION = '0.2';

use base qw(XML::LibXML);

use XML::LibXML::Overlay::Document;

sub load_xml {
    my $self = shift;

    my $dom = $self->SUPER::load_xml(@_);
    bless $dom, 'XML::LibXML::Overlay::Document';

    return $dom;
}

1;
__END__

=head1 NAME

XML::LibXML::Overlay - Overlays for XML files

=head1 SYNOPSIS

  # target.xml:
  ####
  # <catalog>
  #   <book id="book0" delete="me">
  #     <author>Larry Wall</author>
  #     <author>Tom Christiansen</author>
  #     <author>Delete Me!</author>
  #     <title>Programming Perl: There's More Than One Way To Do It</title>
  #     <isbn>9780596000271</isbn>
  #   </book>
  #   <book id="book2">
  #     <author>Elliotte Rusty Harold</author>
  #     <author>W. Scott Means</author>
  #     <title>XML in a Nutshell: A Desktop Quick Reference</title>
  #     <isbn>9780596007645</isbn>
  #   </book>
  # </catalog>

  # overlay.xml
  ####
  # <overlay>
  #   <target xpath="/catalog/book[@id='book0']/author[text()='Delete Me!']">
  #     <action type="delete" />
  #   </target>
  #   <target xpath="/catalog/book[@id='book2']">
  #     <action type="insertBefore">
  #       <book id="book2">
  #         <author>Mark Jason Dominus</author>
  #           <title>Higher-Order Perl. Transforming Programs with Programs</title>
  #           <isbn>9781558607019</isbn>
  #       </book>
  #     </action>
  #   </target>
  # </overlay>

  use XML::LibXML;
  use XML::LibXML::Overlay;

  my $overlay = XML::LibXML::Overlay->load_xml(
    'location' => '/path/to/overlay.xml',
  );
  my $target = XML::LibXML->load_xml(
    'location' => '/path/to/target.xml',
  );

  $overlay->apply_to($target);

  # do whatever you want with $target

=head1 DESCRIPTION

XML::LibXML::Overlay allowes to apply overlay files to XML files. This modul is
a rewirte of XML::Overlay, but it uses plain XML::LibXML instead of the Class::XML
thru XML::Parser stack.

=head1 DETAILS

XML::LibXML::Overlay inherits from XML::LibXML. So you can use XML::LibXML::Overlay
like XML::LibXML. The only difference is, that L</load_xml> returns a
XML::LibXML::Overlay::Document instead of a XML::LibXML::Document.

=head2 Tags

Following Tags can be used in a overlay document.

=head3 overlay

Specifies the root element, and contains any target element.

=head3 target

Selectes one or more nodes of the target document given by the <i>xpath</i> attribute.
Target Elements contain any number of action elements.

=head3 action

The attributes <i>type</i> and <i>attribute</i> of action nodes specify a action
which sould be applied to the target element.

=head2 Action attributes

Following attributes can be used to specify an action.

=head3 appendChild

Appends the content of the action element as child to the end of the target nodes.

=head3 delete

Deletes the target element.

=head3 insertBefore

Inserts the content of the action element as sibling before the target nodes.

=head3 insertAfter

Inserts the content of the action element as sibling after the target nodes.

=head3 setAttribute

Sets the value of the specified attribute to the content of the action node.

=head3 removeAttribute

Removes the specified attribute.

=head1 METHODS

=head2 load_xml

Can be used as L<XML::LibXML/load_xml>, but returns a L<XML::LibXML::Overlay::Document>
instead of a L<XML::LibXML::Document>.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::Overlay>

=head1 AUTHOR

Alexander Keusch, C<< <kalex at cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
