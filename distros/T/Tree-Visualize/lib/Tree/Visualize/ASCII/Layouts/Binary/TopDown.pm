
package Tree::Visualize::ASCII::Layouts::Binary::TopDown;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tree::Visualize::ASCII::Layouts::Binary);

use Tree::Visualize::Exceptions;
use Tree::Visualize::Connector::Factory;

sub drawConnections {
    my ($self, $current, $left, $right) = @_;
    # prepare the connections
    my ($left_connection, $right_connection) = (undef, undef);
    my $conn_factory = Tree::Visualize::Connector::Factory->new();
    # get the left connection if we need it
    $left_connection = $conn_factory->get(
                                output => 'ASCII',
                                layout => 'TopDown',
                                connector_type => 'LeftRightConnector'
                                )->drawLeftConnector($current, $left)
                                    if defined $left;
    # get the right connection if we need it
    $right_connection = $conn_factory->get(
                                output => 'ASCII',
                                layout => 'TopDown',
                                connector_type => 'LeftRightConnector'
                                )->drawRightConnector($current, $right)
                                    if defined $right;
    # return our connections
    return ($left_connection, $right_connection);
}

sub assembleDrawing {
    my ($self, $current, $children, $connections) = @_;
    # get the children ...
    my ($left, $right) = @{$children};                                                
    # if we have no left of no right, then just return
    # otherwise we need to process them ...
    unless (!$left && !$right) {
        # stash the width of the current for later
        my $orig_current_width = $current->width();
        # get the connections ...
        my ($left_connection, $right_connection) = @{$connections};
        # paste the connections
        $current->pasteLeft($left_connection)   if defined $left_connection;                                
        $current->pasteRight($right_connection) if defined $right_connection;   
        
        my $bottom = "";
        if ($left) {
            $left->padRight(" " x $orig_current_width);
            if ($right) {
                $bottom = $left->pasteRight($right);
            }
            else {
                $bottom = $left;
            }
        }
        elsif ($right) {
            $bottom = $right->padLeft(" " x $orig_current_width);
        }
        # however, if we have them, then add them to the output
        $current = $current->pasteBottom($bottom);
    }
#     # just debugging
#     if (DEBUG) {
#         debug->log("=" x 80);
#         debug->log(join "\n" => map { "[$_]" } $current->getLinesAsArray());
#         debug->log("=" x 80);    
#     }
    return $current;
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Layouts::Binary::TopDown - A TopDown Tree::Binary and Tree::Binary::Search layout

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Layouts::Binary::TopDown;

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

