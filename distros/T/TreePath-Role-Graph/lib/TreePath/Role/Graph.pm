package TreePath::Role::Graph;
$TreePath::Role::Graph::VERSION = '0.07';
use Moose::Role;
use MooseX::Types::Path::Class;
use GraphViz2;

requires 'tree';

has 'output' => ( is       => 'rw',
                  isa      => 'Path::Class::File',
                  coerce   => 1,
                  required => 1,
                  default => sub { '/tmp/tpgraph.png' },
               );

has 'colors' => (is       => 'rw',
                isa      => 'HashRef',
               );

sub graph {
    my $self = shift;
    my $var  = shift;

    my $g = GraphViz2->new();
    foreach my $id ( sort { $a cmp $b } keys %{$self->tree}) {
        my $node   = $self->tree->{$id};
        my $parent = $node->{$self->_get_key_name('parent', $node)};

        my @keys_children = sort grep {/^children.*/} keys %$node;

        my $label_keys_children = '';
        foreach my $k ( @keys_children ) {
            $label_keys_children .= "<_${k}_>$k|";
        }
        if ( defined $label_keys_children && $label_keys_children ne '') {
            chop($label_keys_children);
            $label_keys_children = "{$label_keys_children}|";
        }

        my $label = "{ $label_keys_children "
            . $node->{$self->_get_key_name('search', $node)}
            . " (". $node->{$self->_get_key_name('source', $node)} . '_' . $node->{$self->_get_key_name('primary', $node)}
            .")}";

        my $fg_color = 'black';
        if ( defined $self->colors && defined $self->colors->{$node->{$self->_get_key_name('source', $node)}}) {
            $fg_color = $self->colors->{$node->{$self->_get_key_name('source', $node)}}->{fg};
        }
        my $key_obj = $self->_obj_key($node);
        $g->add_node( name => $key_obj, label => $label, shape => 'record', color => $fg_color);

        if ( $parent ){
            my $key_children = $self->_key_children($node, $parent);
            my $key_parent = $self->_obj_key($parent);
            $g->add_edge( from => $key_obj, to => "$key_parent:_${key_children}_"  );
            }
    }

    $g-> run(format => 'png', output_file => $self->output);
    $self->_log($self->output . " generate.");
}



=head1 NAME

TreePath::Role::Graph - Role to visualize TreePath Graph

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    package TPGraph;
    use Moose;

    extends 'TreePath';
    with 'TreePath::Role::Graph';

    1;

    use TPGraph;

    my $colors_source = {
                   'T1' => { fg => 'blue'},
                   'T2' => { fg => 'magenta'},
                   'T3' => { fg => 'brown'},
            };

    # get tree from hash, dbix, file
    $tp = TPGraph->new(  conf   => $tree,
                         colors => $colors_source,
                         output => '/tmp/test.png' );

    $tp->graph;

=head1 METHODS

=head2 graph

  $tp->graph

=cut

=head1 SEE ALSO

L<TreePath>

=cut

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapullse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-treepath-role-graph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TreePath-Role-Graph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TreePath::Role::Graph


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TreePath-Role-Graph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TreePath-Role-Graph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TreePath-Role-Graph>

=item * Search CPAN

L<http://search.cpan.org/dist/TreePath-Role-Graph/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of TreePath::Role::Graph
