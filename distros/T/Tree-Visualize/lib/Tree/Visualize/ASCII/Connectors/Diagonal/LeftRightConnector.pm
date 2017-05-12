
package Tree::Visualize::ASCII::Connectors::Diagonal::LeftRightConnector;

use strict;
use warnings;

use Tree::Visualize::ASCII::BoundingBox;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Connector::IConnector);

sub drawLeftConnector {
    my ($self, $current, $left, $right) = @_;
    $self->checkArgs($current, $left); 
    
    my $left_spacing = 1;
    if (defined($right) && ref($right) && UNIVERSAL::isa($right, "Tree::Visualize::ASCII::BoundingBox")) {
        $left_spacing = ($right->height() - $current->height()) || 1;
    }
    $left_spacing++ unless $left_spacing == 1;
    my $connectors = (" " x int($current->width() / 2)) . "|" . (" " x int($current->width() / 2));
    return Tree::Visualize::ASCII::BoundingBox->new("$connectors\n" x $left_spacing);       
}

sub drawRightConnector {
    my ($self, $current, $right, $left) = @_;
    $self->checkArgs($current, $right); 
    
    my $right_spacing = 1;
    if (defined($left) && ref($left) && UNIVERSAL::isa($left, "Tree::Visualize::ASCII::BoundingBox")) {
        $right_spacing = ($left->width() - $current->width()) || 1;
    }
    $right_spacing++ unless $right_spacing == 1;
    my $space = (" " x $right_spacing);
    return Tree::Visualize::ASCII::BoundingBox
                                    ->new(
                                        ("$space\n" x int($current->height() / 2)) . 
                                        ("-" x $right_spacing)
                                        );
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Connectors::Diagonal::LeftRightConnector - A connector for Diagonal layouts

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Connectors::Diagonal::LeftRightConnector;

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

