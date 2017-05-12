
package Tree::Visualize::ASCII::Connectors::TopDown::LeftRightConnector;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Connector::IConnector);

sub drawLeftConnector {
    my ($self, $to, $from) = @_;
    # check the args first
    $self->checkArgs($to, $from);       
    # get the left index of the TOP CORNER, then the right
    # index of the TOP CORNER, divide this by two and you 
    # have found the middle of the top-most left node, which
    # is where you want to attach your connector.
    #....V
    #        (node0)
    # (node1)
    #
    my $left_index = $from->getFirstConnectionPointIndex();           
    # now we need to calculate the renaming left
    # space between the center of the topmost left 
    # box (where are attaching our connector) and 
    # the the place where the new node we are connecting
    # to will be.
    #    V..V
    #        (node0)
    # (node1)
    #
    my $left_line_length = $from->width() - $left_index;             
    # we then add the connectors to the current node
    #    +---(node0)
    # (node1)
    #        
    # NOTE:
    # this part is kind of a hack, becuase
    # it assumed a box which is 3 lines tall
    # this should be changed to accomadate other
    # size boxes.
    my $left_arm = Tree::Visualize::ASCII::BoundingBox->new(
                    (" " x $left_line_length) . "\n" . 
                    ("+" . ("-" x ($left_line_length - 1))) . "\n" . 
                    ("|" . (" " x ($left_line_length - 1)))
                    );
    # add padding to the left arm
    return $left_arm->padLeft(" " x $left_index);
}

sub drawRightConnector {
    my ($self, $to, $from) = @_;
    # check the args first
	$self->checkArgs($to, $from);      
    # get the first instance of TOPCORNER which
    # is the begining of the topmost box, then
    # get the last instance of it which is the 
    # end of that same box. Then divide by two
    # to get the middle, which is where we want 
    # the connector to go.
    #        ...V
    # (node0)
    #        (node2)
    #
    my $right_index = $from->getFirstConnectionPointIndex();                   
    # Now add the connectors to the current node       
    # (node0)---+
    #        (node2)
    #        
    # NOTE:
    # this part is kind of a hack, becuase
    # it assumed a box which is 3 lines tall
    # this should be changed to accomadate other
    # size boxes.
    my $right_arm = Tree::Visualize::ASCII::BoundingBox->new(
                        (" " x ($right_index + 1))   . "\n" . 
                        ("-" x ($right_index)) . "+" . "\n" . 
                        (" " x $right_index) . "|"
                        );   
    # combine the current box with the right arm
    return $right_arm->padRight(" " x ($from->width() - $right_index));
}


1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Connectors::TopDown::LeftRightConnector - A connector for TopDown layouts

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Connectors::TopDown::LeftRightConnector;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<drawLeftConnector>

=item B<drawRightConnector>

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

