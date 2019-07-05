use strict;
use warnings;

package XML::XPathScript::Processor::XPath;
our $AUTHORITY = 'cpan:YANICK';
$XML::XPathScript::Processor::XPath::VERSION = '2.00';
use base qw/ XML::XPathScript::Processor /;

sub get_namespace { 
        my $prefix = $_[1]->getPrefix or return;
        return $_[1]->getNamespace( $prefix )->getExpanded();
}

sub get_attributes     { $_[1]->getAttributeNodes }
sub get_text_content   { $_[1]->getData }
sub get_child_nodes    { $_[1]->getChildNodes }
sub get_node_name      { $_[1]->getName && $_[1]->getLocalName }
sub get_qualified_name { $_[1]->getName }
sub is_element_node    { $_[1]->isa( 'XML::XPath::Node::Element' ); }
sub is_text_node       { $_[1]->isa( 'XML::XPath::Node::Text' ); }
sub is_comment_node    { $_[1]->isa( 'XML::XPath::Node::Comment' ); }
sub is_pi_node         { $_[1]->isa( "XML::XPath::Node::PI" ); }
sub is_nodelist        { $_[1]->isa( 'XML::XPath::NodeSet' ); }
sub get_attribute      { $_[1]->toString }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript::Processor::XPath

=head1 VERSION

version 2.00

=head1 AUTHORS

=over 4

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Dominique Quatravaux <domq@cpan.org>

=item *

Matt Sergeant <matt@sergeant.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2008, 2007 by Matt Sergeant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
