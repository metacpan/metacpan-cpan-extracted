package XML::Atom::Workspace;

use warnings;
use strict;
use Carp;

use XML::Atom;
use XML::Atom::Service;
use base qw(XML::Atom::Base);

sub element_name { 'workspace' }

sub element_ns { $XML::Atom::Service::DefaultNamespace }

sub title {
    my($self, $title) = @_;
    my $ns_uri = $XML::Atom::Util::NS_MAP{$XML::Atom::DefaultVersion};
    my $atom   = XML::Atom::Namespace->new(atom => $ns_uri);
    if (defined $title) {
	$self->set( $atom, 'title', $title );
    }
    else {
	$self->get( $atom, 'title' );
    }
}

__PACKAGE__->mk_object_list_accessor('collection' => 'XML::Atom::Collection', 'collections');

1;
__END__

=head1 NAME

XML::Atom::Workspace - Workspace object

=head1 SYNOPSIS

  my $categories = XML::Atom::Categories->new;
  $categories->href('http://example.com/cats/forMain.cats');
  $categories->add_category($category);

  my $collection = XML::Atom::Collection->new;
  $collection->href('http://example.org/reilly/main');
  $collection->title('My Blog Entries');
  $collection->categories($categories);

  my $workspace = XML::Atom::Workspace->new;
  $workspace->title('Main Site');
  $workspace->add_collection($collection);

  # Get lists of the collection and categories elements
  my @collection = $workspace->collections;
  my @categories = $collection[0]->categories;

=head1 METHODS

=head2 XML::Atom::Workspace->new

=head2 $workspace->title

=head2 $workspace->collection

=head2 $workspace->add_collection

=head2 $workspace->element_name

=head2 $workspace->element_ns

=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>

=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

