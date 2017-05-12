
package Tree::Visualize::ASCII::Layouts::Simple::TopDown;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tree::Visualize::ASCII::Layouts::Simple);

use Tree::Visualize::Exceptions;
use Tree::Visualize::ASCII::BoundingBox;
use Tree::Visualize::Connector::Factory;

sub drawConnections {
    return ();
}

sub assembleDrawing {
    my ($self, $current, $children, $connections) = @_; 
    
    my @children = @{$children};
    
    if (@children) {
        # gather all the children
        my $child_output;
        foreach my $child (@children) {
            # if we have no output yet then ...
            unless ($child_output) {
                # just draw the child
                $child_output = $child;
            }
            # if we do have output then,...
            else {
                # just combine the output with 
                # the newly drawn child
                $child_output = $child_output->padRight(" ")->pasteRight($child);        
            }
        }
        
        # the size of the child output
        my $child_output_width = $child_output->width();
        
        # get the padding needed
        my ($padding, $child_padding) = (0, 0);
        if ($child_output->width() > $current->width()) {
            $padding = ($child_output->width() / 2) - ($current->width() / 2);
        }
        else {
            $child_padding = ($current->width() / 2) - ($child_output->width() / 2);        
        }   
        
        $current->padLeft(" " x $padding)->padRight(" " x $padding) if $padding;
        $child_output->padLeft(" " x $child_padding)->padRight(" " x $child_padding) if $child_padding; 
        
        my $first_child_line = ($child_output->getLinesAsArray())[0];
        my $space_until = index($first_child_line, "|");
        my $bar_uptil = $child_output->width() - rindex($first_child_line, "|");
        
        my $child_bar = Tree::Visualize::ASCII::BoundingBox->new(
                        (" " x $space_until) .  
                        ("_" x (($child_output->width() / 2) - $space_until)) . 
                        "|" . 
                        ("_" x (($child_output->width() / 2) - $bar_uptil + 1)) .
                        (" " x ($bar_uptil - 1))
                        ); 
                                      
        $current->pasteBottom($child_bar)->pasteBottom($child_output);
    }
    
    my $top_branch = Tree::Visualize::ASCII::BoundingBox->new(
                            (" " x ($current->width() / 2)) . 
                            "|" . 
                            (" " x ($current->width() / 2))
                            );    
    return $current->pasteTop($top_branch);        
}	


1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Layouts::Simple::TopDown - A TopDown Tree::Simple layout

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Layouts::Simple::TopDown;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<assembleDrawing>

=item B<drawConnections>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the B<CODE COVERAGE> section in L<Tree::Visualize> for more inforamtion.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

