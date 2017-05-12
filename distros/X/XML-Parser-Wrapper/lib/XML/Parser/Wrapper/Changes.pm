# Original authors: don
# $Revision: 1599 $


=pod

=head1 NAME

XML::Parser::Wrapper::Changes - List of significant changes to XML::Parser::Wrapper

=head1 CHANGES

=head2 Version 0.15

=over 4

=item Added C<XML::SAX::Base> to the prerequisites in F<Makefile.PL> to fix automated testing failure

=back

=head2 Version 0.14

=over 4

=item Added new methods C<get_xml_decl> and C<get_doctype>.

=item Created F<Changes.pm> file from entries in F<WhatsNew>.

=back


=head2 Version 0.13

=over 4

=item Change formatting in documentation.

=item Added method to output jsonML, but, it's not fully tested so it's not documented

=back


=head2 Version 0.12

=over 4

=back


=head2 Version 0.11

=over 4

=item Added methods to update attributes and text nodes

=item Added methods to remove child nodes.

=back


=head2 Version 0.10

=over 4

=item Documented the C<new_doc()> method.

=item Fixed issues with attributes when using SAX parsers

=item split C<escape_xml()> into C<escape_xml_body()> and C<escape_xml_attr()>


=back


=head2 Version 0.09

=over 4


=back


=head2 Version 0.08

=over 4

=item C<new()> now returns a reusable object if no parameters are passed

=item added an escape for single quote => &#39;

=back


=head2 Version 0.07

=over 4

=item new method C<update_node()>

=item new method C<update_kid()>

=back


=head2 Version 0.06

=over 4

=item new method C<add_child()>/C<add_kid()>

=item new method C<to_xml()>


=back


=head2 Version 0.05

=over 4

=item got rid of warning when calling C<$node-E<gt>kid_if($name)-E<gt>text> when the child node does not exist


=back


=head2 Version 0.04

=over 4

=item new methods C<simple_data()> and C<dump_simple_data()>


=back


=head2 Version 0.03

=over 4

=item new method <html()>

=item new C<method xml()>


=back


=head2 Version 0.02

=over 4

=item new method C<first_element_if()>

=item take optional parameter to C<first_element()> to return the first child element with the given name

=item take optional parameter to <elements()> to return a list of child elements with the given name


=back





=cut

1;

