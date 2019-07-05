package XML::XPathScript::Processor::LibXML;
our $AUTHORITY = 'cpan:YANICK';
$XML::XPathScript::Processor::LibXML::VERSION = '2.00';
use strict;
use warnings;

use base qw/ XML::XPathScript::Processor /;

sub get_namespace {
        my $ns = $_[1]->getNamespaces();
        return $ns ? $ns->getData() : () ;
}

sub is_text_node {
    # little catch: XML::LibXML::Comment is a
    # XML::LibXML::Text
    return     $_[1]->isa('XML::LibXML::Text')
           && !$_[1]->isa('XML::LibXML::Comment');
}

sub get_attributes     { return $_[1]->attributes }
sub get_text_content   { return $_[1]->textContent }
sub get_child_nodes    { return $_[1]->childNodes }
sub get_node_name      { return $_[1]->localname }
sub get_qualified_name { return $_[1]->nodeName }
sub is_element_node    { return $_[1]->isa( 'XML::LibXML::Element' ); }
sub is_comment_node    { return $_[1]->isa( 'XML::LibXML::Comment' ); }
sub is_pi_node         { return $_[1]->isa( 'XML::LibXML::PI' ); }
sub is_nodelist        { return $_[1]->isa( 'XML::LibXML::NodeList' ); }

sub get_attribute {
    return $_[1]->isa( 'XML::LibXML::Namespace' )
         ? sprintf(q{ %s="%s"}, $_[1]->getName(), $_[1]->value())
         : $_[1]->toString( 0, 1 )
         ;
}

sub translate_node {
    my ( $self, $node, $params ) = @_;
    $node = $node->documentElement if $node->isa( 'XML::LibXML::Document' );
    return $self->SUPER::translate_node( $node, $params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript::Processor::LibXML

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
