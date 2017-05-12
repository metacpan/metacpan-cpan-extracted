package XML::LibXML::Overlay::Document;

use strict;
use warnings;

use base qw(XML::LibXML::Document);

use Carp qw( croak );

sub apply_to {
    my $self = shift;
    my ($target_doc) = @_;
    
    my @overlay_targets = $self->findnodes('/overlay/target');
    
    foreach my $overlay_target (@overlay_targets) {
        my $xpath = $overlay_target->getAttribute('xpath');
        if (not $xpath) {
            croak "missing xpath attribute for target node";
        }
        my @actions = $overlay_target->findnodes('action');
        
        # find all nodes target nodes in the target document
        my @target_nodes = $target_doc->findnodes($xpath);
        
        foreach my $target_node (@target_nodes) {
            $self->_apply_actions($target_node, \@actions);
            
        }
    }
    
    return $target_doc;
}

sub _apply_actions {
    my $self = shift;
    my ($target_node, $actions) = @_;
    
    # applay each $action to $target_node    
    foreach my $action (@$actions) {
        my $type = $action->getAttribute('type');
        my $attribute = $action->getAttribute('attribute');
        my @action_children = $action->childNodes();
        if (not $type) {
            croak "missing type attribute for action node";
        }
        
        if ( $type eq 'appendChild' ) {
            foreach my $action_child (@action_children) {
                $target_node->appendChild($action_child->cloneNode(1));
            }
        }
        elsif ( $type eq 'delete' ) {
            $target_node->unbindNode();
        }
        elsif ( $type eq 'insertBefore' ) {
            foreach my $action_child (@action_children) {
                $target_node->parentNode->insertBefore($action_child->cloneNode(1), $target_node);
            }
        }
        elsif ( $type eq 'insertAfter' ) {
            foreach my $action_child (reverse(@action_children)) {
                $target_node->parentNode->insertAfter($action_child->cloneNode(1), $target_node);
            }
        }
        elsif ( $type eq 'setAttribute' ) {
            $target_node->setAttribute($attribute, $action->textContent());
        }
        elsif ( $type eq 'removeAttribute' ) {
            $target_node->removeAttribute($attribute);
        }
    }
}

1;
__END__

=head1 NAME

XML::LibXML::Overlay::Document - Overlays for XML files

=head1 DETAILS

XML::LibXML::Overlay::Document inherits from XML::LibXML::Document. So you can
use XML::LibXML::Overlay::Document like XML::LibXML::Document.

=head1 METHODS

=head2 apply_to

    $overlay->apply_to($target);

Takes a L<XML::LibXML::Document> and applies the changes specified by the $overlay
document. For more informations about who to use overlay see L<XML::LibXML::Overlay>.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::Overlay>

=head1 AUTHOR

Alexander Keusch, C<< <kalex at cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

