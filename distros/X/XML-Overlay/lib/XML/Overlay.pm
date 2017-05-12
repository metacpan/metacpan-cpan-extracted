package XML::Overlay;

use strict;
use warnings;
use vars qw/$VERSION/;
use base qw/Class::XML/;

$VERSION = "0.01";

__PACKAGE__->has_children('target' => 'XML::Overlay::target');

sub process {
  my ($self, $context) = @_;
  my @changes;
  foreach ($self->target) {
    push(@changes, $_->action_closure($context));
  }
  foreach (@changes) {
    $_->();
  }
}

=head1 NAME

XML::Overlay - Apply overlays to XML documents

=head1 SYNOPSIS

  # Original XML document:
  <blub>
    <foo meh="3" />
    <bar>
      <spam bleem="3" />
    </bar>
  </blub>

  # Overlay document:
  <Overlay>
    <target xpath="/child::foo">
      <action type="setAttribute" attribute="att">bar</action>
      <action type="insertBefore">
        <spam />
      </action>
      <action type="removeAttribute" attribute="meh" />
    </target>
    <target xpath="//spam">
      <action type="insertAfter">
        <meh1 />
        <meh2 />
      </action>
      <action type="delete" />
    </target>
  </Overlay>

  my $o_tree = XML::Overlay->new(xml => $o_source); # Load overlay doc

  my $d_tree = Class::XML->new(xml => $d_source); # Load initial doc

  $o_tree->process($d_tree);

  print "${d_tree}"; # Class::XML used above for overloaded stringify

  # Outputs:
  <blub>
    
        <spam />
      <foo att="bar" />
    <bar>
      
        <meh1 />
        <meh2 />
      
    </bar>
  </blub>

=head1 DESCRIPTION

XML::Overlay is a simple collection of Class::XML modules that provide a
mechanism somewhat inspired by Mozilla's XUL Overlays, but designed for
manipulating general XML documents. The overlay document contains one or more
B<target> elements, each with an B<xpath> attribute which specifies what nodes
of the source document should be captured and transformed; each B<target>
element contains one or more B<action> elements which specifies the action(s)
to perform on each XPath node captured by the parent.

Note that the XPath tree is modified in-place, so ensure you process a copy if
you want your original document intact afterwards as well!

=head1 DETAILS

=head2 Tags

=head3 Overlay

The root of an XML::Overlay document; any attributes are ignored, as are any
children that aren't a B<target> tag

=head3 target

Has a single significant attribute, B<xpath>, which specifies an XPath
expression that is evaluated against the document being transformed to work
out which nodes this transform should target. Its only significant children
are B<action> tags, which each specify a single action which is performed in
order of the tags' appearance against the target nodeset. Any other children
and attributes are ignored.

=head3 action

Has two significant attributes, B<type> and B<attribute>; B<type> specifies
the type of action to be performed (see below for a full list). B<attribute>
names the attribute to be affected by actions which act upon attributes of the
target node(s).

=head2 Allowable B<action> types

=head3 setAttribute

Sets the attribute specified by the B<attribute> attribute on the B<action>
tag to the string value of the tag's contents

=head3 removeAttribute

Removed the attribute specified by the B<attribute> attribute on the B<action>
tag

=head3 appendChild

Appends the contents of the B<action> tag at the end of the child nodes of the
target node(s)

=head3 insertBefore

Inserts the contents of the B<action> tag before each target node

=head3 insertAfter

Inserts the contents of the B<action> tag after each target node

=head3 delete

Deletes all target nodes and any children thereof

=head1 AUTHOR

Matt S Trout <mstrout@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
