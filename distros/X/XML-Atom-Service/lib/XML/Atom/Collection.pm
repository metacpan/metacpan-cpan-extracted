package XML::Atom::Collection;

use warnings;
use strict;
use Carp;

use XML::Atom;
use XML::Atom::Service;
use base qw(XML::Atom::Base);

__PACKAGE__->mk_attr_accessors(qw(href));

sub element_name { 'collection' }

sub element_ns { $XML::Atom::Service::DefaultNamespace }

sub title {
    my($self, $title) = @_;
    my $ns_uri = $XML::Atom::Util::NS_MAP{$XML::Atom::DefaultVersion};
    my $atom   = XML::Atom::Namespace->new(atom => $ns_uri);
    if (defined $title) {
        $self->set($atom, 'title', $title);
    }
    else {
        $self->get($atom, 'title');
    }
}

__PACKAGE__->mk_object_list_accessor('categories' => 'XML::Atom::Categories');

# accessors to text elements, multiple which there can be
unless (XML::Atom::Base->can('mk_elem_list_accessor')) {
    use XML::Atom::Util qw(childlist create_element);

    *XML::Atom::Base::mk_elem_list_accessor = sub {
        my($class, $name, $moniker) = @_;

        no strict 'refs'; ## no critic

        *{"$class\::$name"} = sub {
            my($obj, @args) = @_;
            my $ns_uri = $class->element_ns || $obj->ns;
            if (@args) {
                # setter: clear existent elements first
                my @elem = childlist($obj->elem, $ns_uri, $name);
                for my $el (@elem) {
                    $obj->elem->removeChild($el);
                }

                # add the new elements for each
                my $adder = "add_$name";
                for my $add_elem (@args) {
                    $obj->$adder($add_elem);
                }
            }
            else {
                # getter:
                my @children = map { $_->textContent } childlist( $obj->elem, $ns_uri, $name );
                wantarray ? @children : $children[0];
            }
        };

        if ($moniker) {
            *{"$class\::$moniker"} = sub {
                my($obj, @args) = @_;
                if (@args) {
                    return $obj->$name(@args);
                }
                else {
                    my @obj = $obj->$name;
                    return wantarray ? @obj : \@obj;
                }
            };
        }

        *{"$class\::add_$name"} = sub {
            my($obj, $stuff) = @_;
            my $ns_uri = $class->element_ns || $obj->ns;
            my $elem = create_element($ns_uri, 'accept');
            $elem->appendText($stuff);
            $obj->elem->appendChild($elem);
        };
    };
}

__PACKAGE__->mk_elem_list_accessor('accept', 'accepts');

1;
__END__

=head1 NAME

XML::Atom::Collection - Collection object

=head1 SYNOPSIS

  my $categories = XML::Atom::Categories->new;
  $categories->href('http://example.com/cats/forMain.cats');
  $categories->add_category($category);

  my $collection = XML::Atom::Collection->new;
  $collection->href('http://example.org/reilly/main');
  $collection->title('My Blog Entries');
  $collection->categories($categories);

  # Get a list of the categories elements
  my @categories = $collection->categories;

=head1 METHODS

=head2 XML::Atom::Collection->new

=head2 $collection->href

=head2 $collection->title

=head2 $collection->accept

=head2 $collection->accepts

=head2 $collection->add_accept

=head2 $collection->categories

=head2 $collection->element_name

=head2 $collection->element_ns

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

